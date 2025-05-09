// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract DeployBatchCaller is Script {
    BatchCallAndSponsor public batchCaller;

    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerPk);
        console.log("Deployer:", deployer);

        // Start broadcasting transactions with Alice's private key.
        vm.startBroadcast(deployerPk);

        // Deploy the delegation contract (Alice will delegate calls to this contract).
        batchCaller = new BatchCallAndSponsor();

        vm.stopBroadcast();
    }
}
