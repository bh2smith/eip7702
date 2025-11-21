// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "src/EOAMultisend.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "lib/openzeppelin-contracts/contracts/utils/Create2.sol";

contract DeployMultisend is Script {
    EOAMultisend public multisend;

    // This salt will be used for CREATE2 deployment
    // Using ./mine-address.sh 7702e0abc
    bytes32 public constant SALT = 0x000000000000000000000000000000000000000000000000b80000000452e7c9;

    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPk);

        // Get the bytecode of the contract
        bytes memory bytecode = type(EOAMultisend).creationCode;
        console2.logBytes32(keccak256(bytecode));
        // Deploy using CREATE2
        address payable deployedAddress = payable(Create2.deploy(0, SALT, bytecode));

        // Cast the deployed address to EOAMultisend
        multisend = EOAMultisend(deployedAddress);

        vm.stopBroadcast();

        // Log the deployed address
        console2.log("EOAMultisend deployed to:", deployedAddress);
    }
}
