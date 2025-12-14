// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {SplitBaseV2} from "../src/SplitBaseV2.sol";

contract UpgradeToV2Script is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable proxyAddress = payable(vm.envAddress("PROXY_ADDRESS"));

        console.log("Upgrading to SplitBaseV2...");
        console.log("Proxy address:", proxyAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        vm.startBroadcast(deployerPrivateKey);

        SplitBaseV2 newImplementation = new SplitBaseV2();
        console.log("SplitBaseV2 implementation deployed at:", address(newImplementation));

        SplitBaseV2 proxy = SplitBaseV2(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), abi.encodeCall(proxy.initializeV2, ()));
        console.log("Upgrade to V2 complete");

        vm.stopBroadcast();

        console.log("\n=== Verification Command ===");
        console.log("forge verify-contract");
        console.log("  Address:", address(newImplementation));
        console.log("  Contract: src/SplitBaseV2.sol:SplitBaseV2");
        console.log("  Chain ID:", block.chainid);
    }
}
