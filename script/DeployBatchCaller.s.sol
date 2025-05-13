// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "src/BatchCallAndSponsor.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "lib/openzeppelin-contracts/contracts/utils/Create2.sol";

contract DeployBatchCaller is Script {
    BatchCallAndSponsor public batchCaller;
    // This salt will be used for CREATE2 deployment
    bytes32 public constant SALT = keccak256("BatchCallAndSponsor-v1");

    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");
        // Get the bytecode of the contract
        bytes memory bytecode = type(BatchCallAndSponsor).creationCode;

        // Start broadcasting transactions with Alice's private key.
        vm.startBroadcast(deployerPk);

        // Deploy using CREATE2
        address payable deployedAddress = payable(Create2.deploy(0, SALT, bytecode));

        // Cast the deployed address to BatchCallAndSponsor
        batchCaller = BatchCallAndSponsor(deployedAddress);

        vm.stopBroadcast();
        // Log the deployed address
        console2.log("BatchCallAndSponsor deployed to:", deployedAddress);
    }
}
