// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "src/Faucet.sol";

contract DeployFaucet is Script {
    Faucet public faucet;

    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPk);
        faucet = new Faucet();
        vm.stopBroadcast();
    }
}
