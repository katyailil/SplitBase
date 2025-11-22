// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {SplitBaseV1} from "../src/SplitBaseV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployProxyScript is Script {
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying proxy from:", deployer);
        console.log("Chain ID:", block.chainid);

        address usdcAddress;
        if (block.chainid == 8453) {
            usdcAddress = BASE_USDC;
            console.log("Deploying to Base Mainnet");
        } else if (block.chainid == 84532) {
            usdcAddress = BASE_SEPOLIA_USDC;
            console.log("Deploying to Base Sepolia");
        } else {
            revert("Unsupported network");
        }

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        SplitBaseV1 implementation = new SplitBaseV1();
        console.log("Implementation deployed at:", address(implementation));

        // Prepare initialization data
        bytes memory initData = abi.encodeCall(SplitBaseV1.initialize, (usdcAddress));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));
        console.log("USDC address:", usdcAddress);

        console.log("\n=== IMPORTANT ===");
        console.log("Use proxy address for interactions:", address(proxy));
        console.log("Proxy owner:", deployer);

        vm.stopBroadcast();
    }
}
