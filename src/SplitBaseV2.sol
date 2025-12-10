// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SplitBaseV1} from "./SplitBaseV1.sol";
import {ISplitBaseV2} from "./interfaces/ISplitBaseV2.sol";
import {Types} from "./types/Types.sol";

contract SplitBaseV2 is SplitBaseV1, ISplitBaseV2 {
    mapping(uint256 => PoolMetadata) private _poolMetadata;
    mapping(uint256 => mapping(address => Types.BucketType)) private _recipientBuckets;
    mapping(uint256 => uint256) private _distributionCounter;
    mapping(uint256 => mapping(uint256 => Types.DistributionRecord)) private _distributions;
    mapping(uint256 => mapping(Types.BucketType => address[])) private _bucketRecipients;
    mapping(uint256 => mapping(Types.BucketType => uint256)) private _bucketShares;

    struct PoolMetadata {
        string name;
        string description;
    }

    uint256[44] private __gap;

    function initializeV2() external reinitializer(2) {
        // V2 initialization logic if needed
    }

    function createPoolV2(string calldata name, string calldata description)
        external
        override
        returns (uint256 poolId)
    {
        poolId = createPool();
        _poolMetadata[poolId] = PoolMetadata({name: name, description: description});
        emit PoolCreatedV2(poolId, msg.sender, name, description);
    }

    function addRecipientV2(
        uint256 poolId,
        address recipient,
        uint256 shares,
        Types.BucketType bucket
    ) external override onlyPoolOwner(poolId) poolExists(poolId) {
        addRecipient(poolId, recipient, shares);
        _recipientBuckets[poolId][recipient] = bucket;
        _bucketRecipients[poolId][bucket].push(recipient);
        _bucketShares[poolId][bucket] += shares;
        emit RecipientAddedV2(poolId, recipient, shares, bucket);
    }

    function updateRecipientV2(
        uint256 poolId,
        address recipient,
        uint256 newShares,
        Types.BucketType newBucket
    ) external override onlyPoolOwner(poolId) poolExists(poolId) {
        Recipient memory r = getRecipient(poolId, recipient);
        if (r.account == address(0)) revert InvalidRecipient();

        Types.BucketType oldBucket = _recipientBuckets[poolId][recipient];
        uint256 oldShares = r.shares;

        if (oldBucket != newBucket) {
            _removeFromBucket(poolId, recipient, oldBucket, oldShares);
            _recipientBuckets[poolId][recipient] = newBucket;
            _bucketRecipients[poolId][newBucket].push(recipient);
            _bucketShares[poolId][newBucket] += newShares;
        } else {
            _bucketShares[poolId][oldBucket] = _bucketShares[poolId][oldBucket] - oldShares + newShares;
        }

        updateRecipient(poolId, recipient, newShares);
        emit RecipientUpdatedV2(poolId, recipient, newShares, newBucket);
    }

    function executePayoutV2(
        uint256 poolId,
        uint256 amount,
        Types.SourceType source,
        string calldata sourceIdentifier
    ) external override onlyPoolOwner(poolId) poolExists(poolId) activePool(poolId) returns (uint256 distributionId) {
        executePayout(poolId, amount);

        distributionId = ++_distributionCounter[poolId];
        _distributions[poolId][distributionId] = Types.DistributionRecord({
            distributionId: distributionId,
            timestamp: block.timestamp,
            totalAmount: amount,
            source: source,
            sourceIdentifier: sourceIdentifier,
            recipientCount: getPool(poolId).recipientCount,
            txHash: blockhash(block.number - 1)
        });

        emit PayoutExecutedV2(poolId, distributionId, amount, source, sourceIdentifier, block.timestamp);

        _emitBucketPayouts(poolId, distributionId, amount);
    }

    function getPoolV2(uint256 poolId) external view override returns (PoolV2 memory) {
        Pool memory p = getPool(poolId);
        PoolMetadata memory meta = _poolMetadata[poolId];
        return PoolV2({
            owner: p.owner,
            name: meta.name,
            description: meta.description,
            totalShares: p.totalShares,
            recipientCount: p.recipientCount,
            active: p.active,
            lastExecutionTime: p.lastExecutionTime,
            totalDistributed: p.totalDistributed,
            distributionCount: _distributionCounter[poolId]
        });
    }

    function getRecipientV2(uint256 poolId, address recipient)
        external
        view
        override
        returns (RecipientV2 memory)
    {
        Recipient memory r = getRecipient(poolId, recipient);
        return RecipientV2({
            account: r.account,
            shares: r.shares,
            bucket: _recipientBuckets[poolId][recipient],
            active: r.active
        });
    }

    function getDistribution(uint256 poolId, uint256 distributionId)
        external
        view
        override
        returns (Types.DistributionRecord memory)
    {
        return _distributions[poolId][distributionId];
    }

    function getBucketRecipients(uint256 poolId, Types.BucketType bucket)
        external
        view
        override
        returns (address[] memory)
    {
        return _bucketRecipients[poolId][bucket];
    }

    function getBucketTotalShares(uint256 poolId, Types.BucketType bucket)
        external
        view
        override
        returns (uint256)
    {
        return _bucketShares[poolId][bucket];
    }

    function _removeFromBucket(uint256 poolId, address recipient, Types.BucketType bucket, uint256 shares)
        internal
    {
        address[] storage recipients = _bucketRecipients[poolId][bucket];
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == recipient) {
                recipients[i] = recipients[recipients.length - 1];
                recipients.pop();
                break;
            }
        }
        _bucketShares[poolId][bucket] -= shares;
    }

    function _emitBucketPayouts(uint256 poolId, uint256 distributionId, uint256 totalAmount) internal {
        Pool memory pool = getPool(poolId);
        address[] memory recipients = getRecipientList(poolId);

        uint256[7] memory bucketAmounts;
        uint256[7] memory bucketCounts;

        for (uint256 i = 0; i < recipients.length; i++) {
            Recipient memory r = getRecipient(poolId, recipients[i]);
            if (!r.active) continue;

            Types.BucketType bucket = _recipientBuckets[poolId][recipients[i]];
            uint256 share = (totalAmount * r.shares) / pool.totalShares;

            bucketAmounts[uint256(bucket)] += share;
            bucketCounts[uint256(bucket)]++;
        }

        for (uint256 b = 0; b <= uint256(Types.BucketType.CUSTOM); b++) {
            uint256 amount = bucketAmounts[b];
            if (amount > 0) {
                emit BucketPayout(poolId, distributionId, Types.BucketType(b), amount, bucketCounts[b]);
            }
        }
    }
}
