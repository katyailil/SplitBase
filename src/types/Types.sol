// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Types {
    enum BucketType {
        TEAM,
        INVESTORS,
        TREASURY,
        REFERRALS,
        SECURITY_FUND,
        GRANTS,
        CUSTOM
    }

    enum SourceType {
        BASE_PAY,
        PROTOCOL_FEES,
        GRANTS,
        DONATIONS,
        PARTNERSHIPS,
        OTHER
    }

    struct BucketMetadata {
        BucketType bucketType;
        string name;
        string description;
        bool active;
    }

    struct SourceMetadata {
        SourceType sourceType;
        string name;
        string description;
    }

    struct DistributionRecord {
        uint256 distributionId;
        uint256 timestamp;
        uint256 totalAmount;
        SourceType source;
        string sourceIdentifier;
        uint256 recipientCount;
        bytes32 txHash;
    }

    struct BucketAllocation {
        BucketType bucket;
        uint256 amount;
        uint256 recipientCount;
    }
}
