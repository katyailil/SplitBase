// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {SplitBaseV1} from "../src/SplitBaseV1.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        console.log("Upgrading proxy at:", proxyAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        vm.startBroadcast(deployerPrivateKey);

        SplitBaseV1 newImplementation = new SplitBaseV1();
        console.log("New implementation deployed at:", address(newImplementation));

        SplitBaseV1 proxy = SplitBaseV1(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade complete");

        vm.stopBroadcast();
    }
}
