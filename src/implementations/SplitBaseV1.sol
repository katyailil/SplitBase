// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/AdminUUPS.sol";

contract SplitBaseV1 is AdminUUPS {
    uint256 internal _version;

    function initialize(address admin_) public initializer {
        __AdminUUPS_init(admin_);
        _version = 1;
    }

    function getVersion() external view returns (uint256) {
        return _version;
    }

    function setVersion(uint256 v) external onlyAdmin {
        _version = v;
    }
}
