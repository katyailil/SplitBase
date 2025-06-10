// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {SplitBase} from "../src/SplitBase.sol";
import {Registry} from "../src/Registry.sol";
import {Executor} from "../src/Executor.sol";

contract DeployScript is Script {
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying from:", deployer);
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

        SplitBase splitBase = new SplitBase(usdcAddress);
        console.log("SplitBase deployed at:", address(splitBase));

        Registry registry = new Registry();
        console.log("Registry deployed at:", address(registry));

        Executor executor = new Executor(address(splitBase), usdcAddress);
        console.log("Executor deployed at:", address(executor));

        vm.stopBroadcast();
    }
}
