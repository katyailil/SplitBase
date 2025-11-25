// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {SplitBaseV1} from "../src/SplitBaseV1.sol";
import {RegistryV1} from "../src/RegistryV1.sol";
import {ExecutorV1} from "../src/ExecutorV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployProxyScript is Script {
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==============================================");
        console.log("DEPLOYING UPGRADEABLE CONTRACTS (UUPS PROXIES)");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        address usdcAddress;
        if (block.chainid == 8453) {
            usdcAddress = BASE_USDC;
            console.log("Network: Base Mainnet");
        } else if (block.chainid == 84532) {
            usdcAddress = BASE_SEPOLIA_USDC;
            console.log("Network: Base Sepolia");
        } else {
            revert("Unsupported network");
        }
        console.log("USDC:", usdcAddress);
        console.log("==============================================\n");

        vm.startBroadcast(deployerPrivateKey);

        // ====== 1. DEPLOY SPLITBASE ======
        console.log("1/3 Deploying SplitBase...");
        SplitBaseV1 splitBaseImpl = new SplitBaseV1();
        bytes memory splitBaseInitData = abi.encodeCall(SplitBaseV1.initialize, (usdcAddress));
        ERC1967Proxy splitBaseProxy = new ERC1967Proxy(address(splitBaseImpl), splitBaseInitData);
        console.log("  Implementation:", address(splitBaseImpl));
        console.log("  Proxy (USE THIS):", address(splitBaseProxy));

        // ====== 2. DEPLOY REGISTRY ======
        console.log("\n2/3 Deploying Registry...");
        RegistryV1 registryImpl = new RegistryV1();
        bytes memory registryInitData = abi.encodeCall(RegistryV1.initialize, ());
        ERC1967Proxy registryProxy = new ERC1967Proxy(address(registryImpl), registryInitData);
        console.log("  Implementation:", address(registryImpl));
        console.log("  Proxy (USE THIS):", address(registryProxy));

        // ====== 3. DEPLOY EXECUTOR ======
        console.log("\n3/3 Deploying Executor...");
        ExecutorV1 executorImpl = new ExecutorV1();
        bytes memory executorInitData = abi.encodeCall(ExecutorV1.initialize, (address(splitBaseProxy), usdcAddress));
        ERC1967Proxy executorProxy = new ERC1967Proxy(address(executorImpl), executorInitData);
        console.log("  Implementation:", address(executorImpl));
        console.log("  Proxy (USE THIS):", address(executorProxy));

        vm.stopBroadcast();

        console.log("\n==============================================");
        console.log("DEPLOYMENT COMPLETE - USE PROXY ADDRESSES!");
        console.log("==============================================");
        console.log("SplitBase Proxy:  ", address(splitBaseProxy));
        console.log("Registry Proxy:   ", address(registryProxy));
        console.log("Executor Proxy:   ", address(executorProxy));
        console.log("==============================================");
        console.log("All contracts owned by:", deployer);
        console.log("All contracts are UPGRADEABLE via UUPS pattern");
        console.log("==============================================");

        _saveDeployment(
            block.chainid,
            deployer,
            address(splitBaseProxy),
            address(splitBaseImpl),
            address(registryProxy),
            address(registryImpl),
            address(executorProxy),
            address(executorImpl)
        );
    }

    function _saveDeployment(
        uint256 chainId,
        address deployer,
        address splitBaseProxy,
        address splitBaseImpl,
        address registryProxy,
        address registryImpl,
        address executorProxy,
        address executorImpl
    ) internal {
        string memory network = chainId == 8453 ? "base" : "base-sepolia";

        string memory json = "deployment";
        vm.serializeString(json, "network", network);
        vm.serializeUint(json, "chainId", chainId);
        vm.serializeAddress(json, "deployer", deployer);
        vm.serializeUint(json, "timestamp", block.timestamp);

        vm.serializeAddress(json, "splitBaseProxy", splitBaseProxy);
        vm.serializeAddress(json, "splitBaseImplementation", splitBaseImpl);
        vm.serializeAddress(json, "registryProxy", registryProxy);
        vm.serializeAddress(json, "registryImplementation", registryImpl);
        vm.serializeAddress(json, "executorProxy", executorProxy);
        string memory finalJson = vm.serializeAddress(json, "executorImplementation", executorImpl);

        string memory filename = string.concat("./deployments/", vm.toString(chainId), ".json");
        vm.writeJson(finalJson, filename);

        console.log("\nDeployment data saved to:", filename);
    }
}
