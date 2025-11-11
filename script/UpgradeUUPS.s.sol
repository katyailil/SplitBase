// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

interface IUUPS {
    function upgradeTo(address newImplementation) external;
}

contract UpgradeUUPS is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY");
        vm.startBroadcast();
        address impl = _deployImplementation();
        IUUPS(proxy).upgradeTo(impl);
        vm.stopBroadcast();
        console2.log("Implementation", impl);
        console2.log("Proxy", proxy);
    }

    function _deployImplementation() internal returns (address) {
        bytes memory code = _implCreationCode();
        address deployed;
        assembly {
            deployed := create(0, add(code, 0x20), mload(code))
        }
        return deployed;
    }

    function _implCreationCode() internal pure returns (bytes memory) {
        return hex"60";
    }
}
