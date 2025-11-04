// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SplitBaseUpgradeable
 * @notice Base upgradeable contract for SplitBase project.
 * @dev This contract contains minimal storage and initialization logic.
 * Future implementations (V1, V2, ...) must preserve storage layout.
 */

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SplitBaseUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // ==============================
    // Storage
    // ==============================

    // Example storage variable (to ensure correct layout)
    uint256 internal _version;

    // ==============================
    // Initialization
    // ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes base ownership and version number.
     * @dev Can only be called once (initializer).
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _version = 1;
    }

    // ==============================
    // UUPS Upgrade Authorization
    // ==============================

    /**
     * @dev Authorizes contract upgrades. Restricted to owner.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ==============================
    // Helpers
    // ==============================

    function getVersion() external view returns (uint256) {
        return _version;
    }
}
