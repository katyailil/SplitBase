// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract AdminUUPS is Initializable, UUPSUpgradeable {
    address private _admin;

    modifier onlyAdmin() {
        require(msg.sender == _admin, "NOT_ADMIN");
        _;
    }

    function __AdminUUPS_init(address admin_) internal onlyInitializing {
        _admin = admin_;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    // Однократная установка администратора после апгрейда через прокси
    function bootstrapAdmin(address admin_) external onlyProxy {
        require(_admin == address(0), "ADMIN_ALREADY_SET");
        require(admin_ != address(0), "ZERO_ADDR");
        _admin = admin_;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "ZERO_ADDR");
        _admin = newAdmin;
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    uint256[49] private __gap;
}
