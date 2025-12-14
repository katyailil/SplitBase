// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISplitBase {
    struct Recipient {
        address account;
        uint256 shares;
        bool active;
    }

    struct Pool {
        address owner;
        uint256 totalShares;
        uint256 recipientCount;
        bool active;
        uint256 lastExecutionTime;
        uint256 totalDistributed;
    }

    event PoolCreated(uint256 indexed poolId, address indexed owner);
    event RecipientAdded(uint256 indexed poolId, address indexed recipient, uint256 shares);
    event RecipientUpdated(uint256 indexed poolId, address indexed recipient, uint256 newShares);
    event RecipientRemoved(uint256 indexed poolId, address indexed recipient);
    event PayoutExecuted(
        uint256 indexed poolId,
        address indexed payer,
        address indexed token,
        uint256 requestedAmount,
        uint256 distributedAmount,
        uint256 recipientCount
    );
    event PoolStatusChanged(uint256 indexed poolId, bool active);

    function createPool() external returns (uint256 poolId);
    function addRecipient(uint256 poolId, address recipient, uint256 shares) external;
    function updateRecipient(uint256 poolId, address recipient, uint256 newShares) external;
    function removeRecipient(uint256 poolId, address recipient) external;
    function executePayout(uint256 poolId, uint256 amount) external returns (uint256 distributed);
    function setPoolStatus(uint256 poolId, bool active) external;
    function getPool(uint256 poolId) external view returns (Pool memory);
    function getRecipient(uint256 poolId, address recipient) external view returns (Recipient memory);
}
