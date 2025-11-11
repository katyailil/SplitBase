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
        UUPSUpgradeable.__UUPSUpgradeable_init();
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "ZERO_ADDR");
        _admin = newAdmin;
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}
}
