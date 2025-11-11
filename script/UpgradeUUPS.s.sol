// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {SplitBaseV1} from "../src/implementations/SplitBaseV1.sol";

interface IUUPS {
    function upgradeTo(address newImplementation) external;
}

contract UpgradeUUPS is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY");
        vm.startBroadcast();
        SplitBaseV1 impl = new SplitBaseV1();
        IUUPS(proxy).upgradeTo(address(impl));
        vm.stopBroadcast();
        console2.log("Implementation", address(impl));
        console2.log("Proxy", proxy);
    }
}
