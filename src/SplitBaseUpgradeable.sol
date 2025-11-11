// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SplitBaseUpgradeable is Initializable, UUPSUpgradeable {
    address internal _admin;
    uint256 internal _version;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    function initialize(address admin_) external initializer {
        _admin = admin_;
        _version = 1;
    }

    function bootstrapAdmin(address admin_) external {
        require(_admin == address(0), "ADMIN_ALREADY_SET");
        _admin = admin_;
        emit AdminTransferred(address(0), admin_);
    }

    function admin() external view returns (address) {
        return _admin;
    }

    function getVersion() external view returns (uint256) {
        return _version;
    }

    function setVersion(uint256 v) external {
        require(msg.sender == _admin, "ONLY_ADMIN");
        _version = v;
    }

    function transferAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ONLY_ADMIN");
        require(newAdmin != address(0), "ZERO_ADDR");
        emit AdminTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }

    function _authorizeUpgrade(address) internal override {
        require(msg.sender == _admin, "ONLY_ADMIN");
    }
}
