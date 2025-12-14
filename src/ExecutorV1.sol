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

contract ExecutorV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error Unauthorized();
    error InvalidPool();
    error InvalidAmount();
    error ExecutionFailed();
    error PoolNotRegistered();

    event ExecutionScheduled(uint256 indexed poolId, address indexed executor, uint256 amount, uint256 scheduledAt);
    event ExecutionCompleted(
        uint256 indexed poolId,
        address indexed payer,
        address indexed token,
        uint256 requestedAmount,
        uint256 distributedAmount,
        uint256 executedAt
    );
    event ExecutorAdded(uint256 indexed poolId, address indexed executor);
    event ExecutorRemoved(uint256 indexed poolId, address indexed executor);

    ISplitBase public splitBase;
    IERC20Upgradeable public usdc;

    mapping(uint256 => mapping(address => bool)) public executors;
    mapping(uint256 => address) public poolOwners;

    modifier onlyPoolOwner(uint256 poolId) {
        if (poolOwners[poolId] != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyExecutor(uint256 poolId) {
        if (!executors[poolId][msg.sender] && poolOwners[poolId] != msg.sender) revert Unauthorized();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _splitBase, address _usdc) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        splitBase = ISplitBase(_splitBase);
        usdc = IERC20Upgradeable(_usdc);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function registerPool(uint256 poolId) external {
        ISplitBase.Pool memory pool = splitBase.getPool(poolId);
        if (pool.owner == address(0)) revert InvalidPool();
        if (pool.owner != msg.sender) revert Unauthorized();
        poolOwners[poolId] = msg.sender;
    }

    function addExecutor(uint256 poolId, address executor) external onlyPoolOwner(poolId) {
        executors[poolId][executor] = true;
        emit ExecutorAdded(poolId, executor);
    }

    function removeExecutor(uint256 poolId, address executor) external onlyPoolOwner(poolId) {
        executors[poolId][executor] = false;
        emit ExecutorRemoved(poolId, executor);
    }

    function execute(uint256 poolId, uint256 amount) external whenNotPaused nonReentrant onlyExecutor(poolId) {
        if (amount == 0) revert InvalidAmount();
        if (poolOwners[poolId] == address(0)) revert PoolNotRegistered();

        usdc.safeTransferFrom(msg.sender, address(this), amount);
        usdc.forceApprove(address(splitBase), amount);

        uint256 distributed = splitBase.executePayout(poolId, amount);

        uint256 remaining = usdc.balanceOf(address(this));
        if (remaining > 0) {
            usdc.safeTransfer(msg.sender, remaining);
        }

        usdc.forceApprove(address(splitBase), 0);

        emit ExecutionCompleted(poolId, msg.sender, address(usdc), amount, distributed, block.timestamp);
    }

    function scheduleExecution(uint256 poolId, uint256 amount) external whenNotPaused onlyExecutor(poolId) {
        if (poolOwners[poolId] == address(0)) revert PoolNotRegistered();
        if (amount == 0) revert InvalidAmount();
        emit ExecutionScheduled(poolId, msg.sender, amount, block.timestamp);
    }

    // Allow delegatecall during UUPS upgradeToAndCall with empty data
    fallback() external payable {}
    receive() external payable {}
}
