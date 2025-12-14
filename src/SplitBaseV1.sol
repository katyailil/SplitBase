// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ISplitBase} from "./interfaces/ISplitBase.sol";

contract SplitBaseV1 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ISplitBase
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error Unauthorized();
    error InvalidPool();
    error InvalidRecipient();
    error InvalidShares();
    error InvalidAmount();
    error InsufficientBalance();
    error PoolInactive();
    error TransferFailed();

    IERC20Upgradeable public usdc;
    uint256 private _nextPoolId;

    mapping(uint256 => Pool) private _pools;
    mapping(uint256 => mapping(address => Recipient)) private _recipients;
    mapping(uint256 => address[]) private _recipientList;

    modifier poolExists(uint256 poolId) {
        if (_pools[poolId].owner == address(0)) revert InvalidPool();
        _;
    }

    modifier onlyPoolOwner(uint256 poolId) {
        if (_pools[poolId].owner != msg.sender) revert Unauthorized();
        _;
    }

    modifier activePool(uint256 poolId) {
        if (!_pools[poolId].active) revert PoolInactive();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _usdc) external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        usdc = IERC20Upgradeable(_usdc);
        _nextPoolId = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function createPool() public whenNotPaused returns (uint256 poolId) {
        poolId = _nextPoolId++;
        _pools[poolId] = Pool({
            owner: msg.sender,
            totalShares: 0,
            recipientCount: 0,
            active: true,
            lastExecutionTime: 0,
            totalDistributed: 0
        });
        emit PoolCreated(poolId, msg.sender);
    }

    function addRecipient(uint256 poolId, address recipient, uint256 shares)
        public
        poolExists(poolId)
        onlyPoolOwner(poolId)
        whenNotPaused
    {
        if (recipient == address(0)) revert InvalidRecipient();
        if (shares == 0) revert InvalidShares();
        if (_recipients[poolId][recipient].account != address(0)) revert InvalidRecipient();

        _recipients[poolId][recipient] = Recipient({account: recipient, shares: shares, active: true});
        _recipientList[poolId].push(recipient);
        _pools[poolId].totalShares += shares;
        _pools[poolId].recipientCount++;

        emit RecipientAdded(poolId, recipient, shares);
    }

    function updateRecipient(uint256 poolId, address recipient, uint256 newShares)
        public
        poolExists(poolId)
        onlyPoolOwner(poolId)
        whenNotPaused
    {
        if (_recipients[poolId][recipient].account == address(0)) revert InvalidRecipient();
        if (newShares == 0) revert InvalidShares();

        uint256 oldShares = _recipients[poolId][recipient].shares;
        _recipients[poolId][recipient].shares = newShares;
        _pools[poolId].totalShares = _pools[poolId].totalShares - oldShares + newShares;

        emit RecipientUpdated(poolId, recipient, newShares);
    }

    function removeRecipient(uint256 poolId, address recipient)
        external
        poolExists(poolId)
        onlyPoolOwner(poolId)
        whenNotPaused
    {
        if (_recipients[poolId][recipient].account == address(0)) revert InvalidRecipient();

        uint256 shares = _recipients[poolId][recipient].shares;
        _pools[poolId].totalShares -= shares;
        _pools[poolId].recipientCount--;
        _recipients[poolId][recipient].active = false;

        emit RecipientRemoved(poolId, recipient);
    }

    function executePayout(uint256 poolId, uint256 amount)
        public
        whenNotPaused
        nonReentrant
        poolExists(poolId)
        onlyPoolOwner(poolId)
        activePool(poolId)
        returns (uint256 distributed)
    {
        if (amount == 0) revert InvalidAmount();
        if (_pools[poolId].totalShares == 0) revert InvalidShares();

        Pool storage pool = _pools[poolId];
        address[] memory recipients = _recipientList[poolId];
        uint256 activeRecipients;

        for (uint256 i = 0; i < recipients.length; i++) {
            Recipient memory r = _recipients[poolId][recipients[i]];
            if (!r.active) continue;
            activeRecipients++;

            uint256 share = (amount * r.shares) / pool.totalShares;
            if (share > 0) {
                usdc.safeTransferFrom(msg.sender, r.account, share);
                distributed += share;
            }
        }

        pool.lastExecutionTime = block.timestamp;
        pool.totalDistributed += distributed;

        emit PayoutExecuted(poolId, msg.sender, address(usdc), amount, distributed, activeRecipients);
    }

    function setPoolStatus(uint256 poolId, bool active)
        external
        poolExists(poolId)
        onlyPoolOwner(poolId)
    {
        _pools[poolId].active = active;
        emit PoolStatusChanged(poolId, active);
    }

    function getPool(uint256 poolId) public view returns (Pool memory) {
        return _pools[poolId];
    }

    function getRecipient(uint256 poolId, address recipient) public view returns (Recipient memory) {
        return _recipients[poolId][recipient];
    }

    function getRecipientList(uint256 poolId) public view returns (address[] memory) {
        return _recipientList[poolId];
    }
}
