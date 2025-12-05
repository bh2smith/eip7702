// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "src/EOAMultisend.sol";
import "lib/openzeppelin-contracts/contracts/utils/Create2.sol";

contract PreviewAddress is Script {
    function run() external view {
        uint256 deployerPk = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerPk);

        console2.log("===========================================");
        console2.log("CREATE2 Deployment Preview");
        console2.log("===========================================");
        console2.log("");
        console2.log("Your deployer address:", deployer);
        console2.log("");
        console2.log("To mine a salt for a specific prefix:");
        console2.log("  ./mine-address.sh", deployer, "<prefix>");
        console2.log("");
        console2.log("Example (for 0xE0ABC prefix):");
        console2.log("  ./mine-address.sh", deployer, "e0abc");
        console2.log("");
        console2.log("===========================================");
    }
}

