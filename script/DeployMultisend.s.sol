// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "src/EOAMultisend.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract DeployMultisend is Script {
    EOAMultisend public multisend;

    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPk);

        multisend = new EOAMultisend();

        vm.stopBroadcast();
    }
}
