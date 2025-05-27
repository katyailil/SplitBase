// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISplitBase} from "./interfaces/ISplitBase.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract Executor {
    error Unauthorized();
    error InvalidPool();
    error ExecutionFailed();

    event ExecutionScheduled(uint256 indexed poolId, address indexed executor, uint256 amount, uint256 scheduledAt);
    event ExecutionCompleted(uint256 indexed poolId, uint256 amount, uint256 executedAt);
    event ExecutorAdded(uint256 indexed poolId, address indexed executor);
    event ExecutorRemoved(uint256 indexed poolId, address indexed executor);

    ISplitBase public immutable splitBase;
    IERC20 public immutable usdc;

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

    constructor(address _splitBase, address _usdc) {
        splitBase = ISplitBase(_splitBase);
        usdc = IERC20(_usdc);
    }

    function registerPool(uint256 poolId) external {
        ISplitBase.Pool memory pool = splitBase.getPool(poolId);
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

    function execute(uint256 poolId, uint256 amount) external onlyExecutor(poolId) {
        if (!usdc.transferFrom(msg.sender, address(this), amount)) revert ExecutionFailed();
        if (!usdc.approve(address(splitBase), amount)) revert ExecutionFailed();

        splitBase.executePayout(poolId, amount);

        emit ExecutionCompleted(poolId, amount, block.timestamp);
    }

    function scheduleExecution(uint256 poolId, uint256 amount) external onlyExecutor(poolId) {
        emit ExecutionScheduled(poolId, msg.sender, amount, block.timestamp);
    }
}
