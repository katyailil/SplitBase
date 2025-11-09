// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SplitBaseV1
 * @notice First working implementation of the SplitBase revenue splitter (UUPS-ready).
 * @dev Storage layout must remain append-only across versions. Keep variables order intact.
 *
 * Storage layout (must match prior implementation order):
 * 0) _version
 * 1) recipients
 * 2) shares
 * 3) TOTAL_SHARES
 * 4) released
 * 5) totalReceived
 *
 * Owner controls upgrades (UUPS). Recipients withdraw their accrued portion via `release`.
 */

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SplitBaseV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // -------------------------
    // Storage (keep order!)
    // -------------------------

    uint256 internal _version;
    address[] public recipients;
    uint256[] public shares; // permille; must sum to TOTAL_SHARES
    uint256 public constant TOTAL_SHARES = 1000;

    mapping(address => uint256) public released; // how much was withdrawn by recipient
    uint256 public totalReceived;                // cumulative ETH received by the contract

    // -------------------------
    // Errors / Events
    // -------------------------

    error InvalidParams();
    error NothingToRelease();
    error NotARecipient();

    error TransferFailed();

    event PaymentReceived(address indexed from, uint256 amount);
    event PaymentReleased(address indexed to, uint256 amount);

    // -------------------------
    // Init / UUPS
    // -------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize recipients and shares, set the owner.
     * @dev Call this once on the proxy (during initial deployment) OR ensure previous
     *      version already had compatible storage and initialization. Reverts if recipients
     *      length is zero or shares sum != TOTAL_SHARES.
     */
    function initialize(
        address[] memory _recipients,
        uint256[] memory _shares,
        address initialOwner
    ) public reinitializer(2) {
        __UUPSUpgradeable_init();
        if (owner() == address(0)) {
            __Ownable_init(initialOwner);
        }

        if (_recipients.length == 0 || _recipients.length != _shares.length) revert InvalidParams();

        uint256 sum;
        for (uint256 i; i < _recipients.length; i++) {
            if (_recipients[i] == address(0) || _shares[i] == 0) revert InvalidParams();
            recipients.push(_recipients[i]);
            shares.push(_shares[i]);
            sum += _shares[i];
        }
        if (sum != TOTAL_SHARES) revert InvalidParams();
        _version = 2;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getVersion() external view returns (uint256) {
        return _version;
    }

    // -------------------------
    // Core logic
    // -------------------------

    /// @notice Accept ETH. Increments totalReceived and emits event.
    receive() external payable {
        totalReceived += msg.value;
        emit PaymentReceived(msg.sender, msg.value);
    }

    /// @notice Pending amount owed to `account` based on shares and total received.
    function pending(address account) public view returns (uint256) {
        uint256 idx = _indexOf(account);
        uint256 entitled = (totalReceived * shares[idx]) / TOTAL_SHARES;
        return entitled - released[account];
    }

    /// @notice Withdraw pending amount for `account`.
    function release(address payable account) public {
        uint256 amount = pending(account);
        if (amount == 0) revert NothingToRelease();
        released[account] += amount;

        (bool ok, ) = account.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit PaymentReleased(account, amount);
    }

    /// @notice View recipients and shares.
    function getRecipients() external view returns (address[] memory, uint256[] memory) {
        return (recipients, shares);
    }

    // -------------------------
    // Internal helpers
    // -------------------------

    function _indexOf(address account) internal view returns (uint256) {
        for (uint256 i; i < recipients.length; i++) {
            if (recipients[i] == account) return i;
        }
        revert NotARecipient();
    }
}
