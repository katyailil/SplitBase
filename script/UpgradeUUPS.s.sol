// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {SplitBaseUpgradeable} from "../src/SplitBaseUpgradeable.sol";

interface IUUPS {
    function upgradeTo(address newImplementation) external;
}

contract UpgradeUUPS is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY");
        vm.startBroadcast();
        SplitBaseUpgradeable impl = new SplitBaseUpgradeable();
        IUUPS(proxy).upgradeTo(address(impl));
        vm.stopBroadcast();
        console2.log("Implementation", address(impl));
        console2.log("Proxy", proxy);
    }
}
