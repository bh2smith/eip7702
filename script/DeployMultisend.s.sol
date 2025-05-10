// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "src/EOAMultisend.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract DeployBatchCaller is Script {
    EOAMultisend public multisend;

    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPk);

        multisend = new EOAMultisend();

        vm.stopBroadcast();
    }
}
