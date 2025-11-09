// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {SplitBaseV1} from "../src/implementations/SplitBaseV1.sol";

interface IUUPS {
    function upgradeTo(address newImplementation) external;
}

interface ISplitBaseV1 {
    function initialize(address[] memory recs, uint256[] memory shrs, address owner) external;
}

contract UpgradeUUPS is Script {
    function run() external {
        string memory network = vm.envString("ENV_NETWORK");
        string memory proxyKey = string.concat("PROXY_ADDRESS_", network);
        address proxy = vm.envAddress(proxyKey);

        string memory recCsv = vm.envString("RECIPIENTS");
        string memory shrCsv = vm.envString("SHARES");

        address[] memory recs = _parseAddresses(recCsv);
        uint256[] memory shrs = _parseUints(shrCsv);

        vm.startBroadcast();
        SplitBaseV1 newImpl = new SplitBaseV1();
        IUUPS(proxy).upgradeTo(address(newImpl));
        ISplitBaseV1(proxy).initialize(recs, shrs, msg.sender);
        vm.stopBroadcast();

        console2.log("New implementation deployed:", address(newImpl));
        console2.log("Proxy upgraded:", proxy);
    }

    function _parseAddresses(string memory csv) internal pure returns (address[] memory) {
        string[] memory parts = _split(csv);
        address[] memory out = new address[](parts.length);
        for (uint256 i; i < parts.length; i++) {
            out[i] = vm.parseAddress(parts[i]);
        }
        return out;
    }

    function _parseUints(string memory csv) internal pure returns (uint256[] memory) {
        string[] memory parts = _split(csv);
        uint256[] memory out = new uint256[](parts.length);
        for (uint256 i; i < parts.length; i++) {
            out[i] = vm.parseUint(parts[i]);
        }
        return out;
    }

    function _split(string memory s) internal pure returns (string[] memory) {
        bytes memory b = bytes(s);
        uint256 count;
        for (uint256 i; i < b.length; i++) {
            if (b[i] == ",") count++;
        }

        string[] memory parts = new string[](count + 1);
        uint256 last;
        uint256 p;

        for (uint256 i; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                bytes memory chunk = new bytes(i - last);
                for (uint256 j; j < chunk.length; j++) {
                    chunk[j] = b[last + j];
                }
                parts[p++] = string(chunk);
                last = i + 1;
            }
        }

        return parts;
    }
}
