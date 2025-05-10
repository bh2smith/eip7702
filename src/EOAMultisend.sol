// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/safe-smart-account/contracts/libraries/MultiSendCallOnly.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title EOAMultisend
/// @author bh2smith (inheriting from azf20's Batcher)
/// @notice Simple multicall contract for EOAs via EIP-7702
/// @dev WARNING: THIS CONTRACT IS AN EXPERIMENT AND HAS NOT BEEN AUDITED.
contract EOAMultisend is MultiSendCallOnly {
    ////////////////////////////////////////////////////////////////////////
    // Errors
    ////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when a signature is invalid.
    error InvalidSignature();
    error InvalidAuthority();

    ////////////////////////////////////////////////////////////////////////
    // Functions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Internal nonce used for replay protection.
    uint256 public nonce;

    /// @notice Executes a set of calls.
    /// @param calls - The calls to execute.
    function execute(bytes memory calls) public {
        if (msg.sender != address(this)) revert InvalidAuthority();
        multiSend(calls);
    }

    /// @notice Executes a set of calls on behalf of the Account, given an EOA signature for authorization.
    /// @param calls - The calls to execute.
    /// @param signature - The EOA signature over the calls
    function execute(bytes memory calls, bytes calldata signature) public {
        bytes32 digest = keccak256(abi.encodePacked(block.chainid, nonce++, calls));

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(digest);

        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (signer != address(this)) {
            revert InvalidSignature();
        }

        multiSend(calls);
    }

    fallback() external payable {}
    receive() external payable {}
}
