// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SplitBaseUpgradeable} from "../src/SplitBaseUpgradeable.sol";

contract DeployProxyV2 is Script {
    function run(address owner_) external {
        vm.startBroadcast();
        SplitBaseUpgradeable impl = new SplitBaseUpgradeable();
        bytes memory initData = abi.encodeWithSelector(
            SplitBaseUpgradeable.initialize.selector,
            owner_
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        vm.stopBroadcast();
        console2.log("Implementation", address(impl));
        console2.log("Proxy", address(proxy));
        console2.log("Owner", owner_);
    }
}
