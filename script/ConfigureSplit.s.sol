// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {SplitBaseUpgradeable} from "../src/SplitBaseUpgradeable.sol";

contract ConfigureSplit is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY");
        
        string memory recipientsEnv = vm.envString("RECIPIENTS");
        string memory sharesEnv = vm.envString("SHARES");
        
        address[] memory recipients = parseAddresses(recipientsEnv);
        uint256[] memory shares = parseShares(sharesEnv);
        
        require(recipients.length == shares.length, "Length mismatch");
        
        vm.startBroadcast();
        
        SplitBaseUpgradeable split = SplitBaseUpgradeable(payable(proxy));
        split.configureSplit(recipients, shares);
        
        vm.stopBroadcast();
        
        console2.log("Split configured:");
        console2.log("Proxy:", proxy);
        console2.log("Recipients:", recipients.length);
        console2.log("Total shares:", sumShares(shares));
    }
    
    function parseAddresses(string memory input) internal pure returns (address[] memory) {
        bytes memory data = bytes(input);
        uint256 count = 1;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == ",") count++;
        }
        
        address[] memory result = new address[](count);
        uint256 idx = 0;
        uint256 start = 0;
        
        for (uint256 i = 0; i <= data.length; i++) {
            if (i == data.length || data[i] == ",") {
                result[idx++] = parseAddress(substring(input, start, i));
                start = i + 1;
            }
        }
        
        return result;
    }
    
    function parseShares(string memory input) internal pure returns (uint256[] memory) {
        bytes memory data = bytes(input);
        uint256 count = 1;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == ",") count++;
        }
        
        uint256[] memory result = new uint256[](count);
        uint256 idx = 0;
        uint256 start = 0;
        
        for (uint256 i = 0; i <= data.length; i++) {
            if (i == data.length || data[i] == ",") {
                result[idx++] = vm.parseUint(substring(input, start, i));
                start = i + 1;
            }
        }
        
        return result;
    }
    
    function substring(string memory str, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }
    
    function parseAddress(string memory str) internal pure returns (address) {
        return vm.parseAddress(str);
    }
    
    function sumShares(uint256[] memory shares) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            total += shares[i];
        }
        return total;
    }
}
