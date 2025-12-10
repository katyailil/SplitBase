// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Types} from "../types/Types.sol";
import {ISplitBase} from "./ISplitBase.sol";

interface ISplitBaseV2 is ISplitBase {
    struct RecipientV2 {
        address account;
        uint256 shares;
        Types.BucketType bucket;
        bool active;
    }

    struct PoolV2 {
        address owner;
        string name;
        string description;
        uint256 totalShares;
        uint256 recipientCount;
        bool active;
        uint256 lastExecutionTime;
        uint256 totalDistributed;
        uint256 distributionCount;
    }

    event PoolCreatedV2(
        uint256 indexed poolId,
        address indexed owner,
        string name,
        string description
    );

    event RecipientAddedV2(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 shares,
        Types.BucketType indexed bucket
    );

    event RecipientUpdatedV2(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 newShares,
        Types.BucketType bucket
    );

    event PayoutExecutedV2(
        uint256 indexed poolId,
        uint256 indexed distributionId,
        uint256 totalAmount,
        Types.SourceType indexed source,
        string sourceIdentifier,
        uint256 timestamp
    );

    event BucketPayout(
        uint256 indexed poolId,
        uint256 indexed distributionId,
        Types.BucketType indexed bucket,
        uint256 amount,
        uint256 recipientCount
    );

    function createPoolV2(string calldata name, string calldata description)
        external
        returns (uint256 poolId);

    function addRecipientV2(
        uint256 poolId,
        address recipient,
        uint256 shares,
        Types.BucketType bucket
    ) external;

    function updateRecipientV2(
        uint256 poolId,
        address recipient,
        uint256 newShares,
        Types.BucketType bucket
    ) external;

    function executePayoutV2(
        uint256 poolId,
        uint256 amount,
        Types.SourceType source,
        string calldata sourceIdentifier
    ) external returns (uint256 distributionId);

    function getPoolV2(uint256 poolId) external view returns (PoolV2 memory);

    function getRecipientV2(uint256 poolId, address recipient)
        external
        view
        returns (RecipientV2 memory);

    function getDistribution(uint256 poolId, uint256 distributionId)
        external
        view
        returns (Types.DistributionRecord memory);

    function getBucketRecipients(uint256 poolId, Types.BucketType bucket)
        external
        view
        returns (address[] memory);

    function getBucketTotalShares(uint256 poolId, Types.BucketType bucket)
        external
        view
        returns (uint256);
}
