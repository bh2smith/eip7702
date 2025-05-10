// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "src/BatchCallAndSponsor.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

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
