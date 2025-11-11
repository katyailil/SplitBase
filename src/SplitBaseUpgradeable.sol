// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SplitBaseUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 internal _version;

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        _version = 1;
    }

    function getVersion() external view returns (uint256) {
        return _version;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // helper for next versions
    function setVersion(uint256 v) external onlyOwner {
        _version = v;
    }
}
