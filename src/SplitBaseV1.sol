// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ISplitBase} from "./interfaces/ISplitBase.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract SplitBaseV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable, ISplitBase {
    error Unauthorized();
    error InvalidPool();
    error InvalidRecipient();
    error InvalidShares();
    error InsufficientBalance();
    error PoolInactive();
    error TransferFailed();

    IERC20 public usdc;
    uint256 private _nextPoolId;

    mapping(uint256 => Pool) private _pools;
    mapping(uint256 => mapping(address => Recipient)) private _recipients;
    mapping(uint256 => address[]) private _recipientList;

    modifier onlyPoolOwner(uint256 poolId) {
        if (_pools[poolId].owner != msg.sender) revert Unauthorized();
        _;
    }

    modifier poolExists(uint256 poolId) {
        if (_pools[poolId].owner == address(0)) revert InvalidPool();
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
        usdc = IERC20(_usdc);
        _nextPoolId = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createPool() external returns (uint256 poolId) {
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
        external
        onlyPoolOwner(poolId)
        poolExists(poolId)
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
        external
        onlyPoolOwner(poolId)
        poolExists(poolId)
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
        onlyPoolOwner(poolId)
        poolExists(poolId)
    {
        if (_recipients[poolId][recipient].account == address(0)) revert InvalidRecipient();

        uint256 shares = _recipients[poolId][recipient].shares;
        _pools[poolId].totalShares -= shares;
        _pools[poolId].recipientCount--;
        _recipients[poolId][recipient].active = false;

        emit RecipientRemoved(poolId, recipient);
    }

    function executePayout(uint256 poolId, uint256 amount)
        external
        onlyPoolOwner(poolId)
        poolExists(poolId)
        activePool(poolId)
    {
        if (amount == 0) revert InvalidShares();
        if (_pools[poolId].totalShares == 0) revert InvalidShares();

        Pool storage pool = _pools[poolId];
        address[] memory recipients = _recipientList[poolId];
        uint256 distributed = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            Recipient memory r = _recipients[poolId][recipients[i]];
            if (!r.active) continue;

            uint256 share = (amount * r.shares) / pool.totalShares;
            if (share > 0) {
                if (!usdc.transferFrom(msg.sender, r.account, share)) revert TransferFailed();
                distributed += share;
            }
        }

        pool.lastExecutionTime = block.timestamp;
        pool.totalDistributed += distributed;

        emit PayoutExecuted(poolId, distributed, pool.recipientCount);
    }

    function setPoolStatus(uint256 poolId, bool active)
        external
        onlyPoolOwner(poolId)
        poolExists(poolId)
    {
        _pools[poolId].active = active;
        emit PoolStatusChanged(poolId, active);
    }

    function getPool(uint256 poolId) external view returns (Pool memory) {
        return _pools[poolId];
    }

    function getRecipient(uint256 poolId, address recipient) external view returns (Recipient memory) {
        return _recipients[poolId][recipient];
    }

    function getRecipientList(uint256 poolId) external view returns (address[] memory) {
        return _recipientList[poolId];
    }
}
