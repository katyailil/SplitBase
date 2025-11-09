// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SplitBaseV1} from "../src/implementations/SplitBaseV1.sol";

contract DeployUUPS is Script {
    function run() external {
        string memory recCsv = vm.envString("RECIPIENTS");
        string memory shrCsv = vm.envString("SHARES");

        address[] memory recs = _parseAddresses(recCsv);
        uint256[] memory shrs = _parseUints(shrCsv);

        vm.startBroadcast();

        // 1) Deploy implementation
        SplitBaseV1 impl = new SplitBaseV1();

        // 2) Prepare init calldata
        bytes memory initData = abi.encodeWithSelector(
            SplitBaseV1.initialize.selector,
            recs,
            shrs,
            msg.sender // initialOwner
        );

        // 3) Deploy proxy pointing to impl
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        vm.stopBroadcast();

        
    }

    function _parseAddresses(string memory csv) internal pure returns (address[] memory) {
        string[] memory parts = _split(csv);
        address[] memory out = new address[](parts.length);
        for (uint256 i; i < parts.length; i++) out[i] = vm.parseAddress(parts[i]);
        return out;
    }

    function _parseUints(string memory csv) internal pure returns (uint256[] memory) {
        string[] memory parts = _split(csv);
        uint256[] memory out = new uint256[](parts.length);
        for (uint256 i; i < parts.length; i++) out[i] = vm.parseUint(parts[i]);
        return out;
    }

    function _split(string memory s) internal pure returns (string[] memory) {
        bytes memory b = bytes(s);
        uint256 count;
        for (uint256 i; i < b.length; i++) if (b[i] == ",") count++;
        string[] memory parts = new string[](count + 1);
        uint256 last;
        uint256 p;
        for (uint256 i; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                bytes memory chunk = new bytes(i - last);
                for (uint256 j; j < chunk.length; j++) chunk[j] = b[last + j];
                parts[p++] = string(chunk);
                last = i + 1;
            }
        }
        return parts;
    }
}
