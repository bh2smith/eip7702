// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "src/EOAMultisend.sol";
import "test/MockERC20.sol";

contract EOAMultisendTest is Test {
    // Alice's address and private key (EOA with no initial contract code).
    address payable ALICE_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant ALICE_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // Bob's address and private key (Bob will execute transactions on Alice's behalf).
    address constant BOB_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant BOB_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    // The contract that Alice will delegate execution to.
    EOAMultisend public implementation;

    // ERC-20 token contract for minting test tokens.
    MockERC20 public token;

    function setUp() public {
        // Deploy the delegation contract (Alice will delegate calls to this contract).
        implementation = new EOAMultisend();

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new MockERC20();

        // Fund accounts
        vm.deal(ALICE_ADDRESS, 10 ether);
        token.mint(ALICE_ADDRESS, 1000e18);
    }

    function testDirectExecution() public {
        console2.log("Sending 1 ETH from Alice to Bob and transferring 100 tokens to Bob in a single transaction");

        // Encode the ETH transfer call
        bytes memory ethTransferData = "";
        bytes memory ethTransferEncoded = abi.encodePacked(
            uint8(0), // operation (0 for call)
            BOB_ADDRESS, // to
            uint256(1 ether), // value
            uint256(0), // data length
            ethTransferData // data
        );

        // Encode the token transfer call
        bytes memory tokenTransferData = abi.encodeCall(ERC20.transfer, (BOB_ADDRESS, 100e18));
        bytes memory tokenTransferEncoded = abi.encodePacked(
            uint8(0), // operation (0 for call)
            address(token), // to
            uint256(0), // value
            uint256(tokenTransferData.length), // data length
            tokenTransferData // data
        );

        // Combine both encoded calls
        bytes memory encodedCalls = abi.encodePacked(ethTransferEncoded, tokenTransferEncoded);

        vm.signAndAttachDelegation(address(implementation), ALICE_PK);

        vm.startPrank(ALICE_ADDRESS);
        EOAMultisend(ALICE_ADDRESS).execute(encodedCalls);
        vm.stopPrank();

        assertEq(BOB_ADDRESS.balance, 1 ether);
        assertEq(token.balanceOf(BOB_ADDRESS), 100e18);
    }

    function testSponsoredExecution() public {
        console2.log("Sending 1 ETH from Alice to a random address while the transaction is sponsored by Bob");
        address recipient = makeAddr("recipient");
        bytes memory encodedCalls = abi.encodePacked(
            uint8(0), // operation (0 for call)
            recipient, // to
            uint256(1 ether), // value
            uint256(0), // data length
            "" // data
        );

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);

        // Verify that Alice's account now temporarily behaves as a smart contract.
        bytes memory code = address(ALICE_ADDRESS).code;
        require(code.length > 0, "no code written to Alice");

        bytes32 digest = keccak256(abi.encodePacked(block.chainid, EOAMultisend(ALICE_ADDRESS).nonce(), encodedCalls));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // As Bob, execute the transaction via Alice's temporarily assigned contract.
        EOAMultisend(ALICE_ADDRESS).execute(encodedCalls, signature);

        vm.stopBroadcast();

        assertEq(recipient.balance, 1 ether);
    }

    function testWrongSignature() public {
        console2.log("Test wrong signature: Execution should revert with 'Invalid signature'.");

        bytes memory data = abi.encodeCall(MockERC20.mint, (BOB_ADDRESS, 50));
        bytes memory encodedCalls = abi.encodePacked(
            uint8(0), // operation (0 for call)
            address(token), // to
            uint256(0), // value
            uint256(data.length), // data length
            data // data
        );

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);

        bytes32 digest = keccak256(abi.encodePacked(EOAMultisend(ALICE_ADDRESS).nonce(), encodedCalls));
        // Sign with the wrong key (Bob's instead of Alice's).
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(EOAMultisend.InvalidSignature.selector);
        EOAMultisend(ALICE_ADDRESS).execute(encodedCalls, signature);
        vm.stopBroadcast();
    }

    function testReplayAttack() public {
        console2.log("Test replay attack: Reusing the same signature should revert.");

        bytes memory encodedCalls = abi.encodePacked(
            uint8(0), // operation (0 for call)
            makeAddr("recipient"), // to
            uint256(1 ether), // value
            uint256(0), // data length
            "" // data
        );

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);

        uint256 nonceBefore = EOAMultisend(ALICE_ADDRESS).nonce();
        bytes32 digest = keccak256(abi.encodePacked(block.chainid, nonceBefore, encodedCalls));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // First execution: should succeed.
        EOAMultisend(ALICE_ADDRESS).execute(encodedCalls, signature);
        vm.stopBroadcast();

        // Attempt a replay: reusing the same signature should revert because nonce has incremented.
        vm.expectRevert(EOAMultisend.InvalidSignature.selector);
        EOAMultisend(ALICE_ADDRESS).execute(encodedCalls, signature);
    }
}
