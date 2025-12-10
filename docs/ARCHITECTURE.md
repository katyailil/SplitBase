# SplitBase Architecture

## Overview

SplitBase is a production-grade revenue distribution infrastructure for Base L2. It enables transparent, programmable splitting of USDC revenue across teams, investors, treasury reserves, and partners with full on-chain auditability.

## Core Concepts

### Source

A **Source** represents where revenue originates. This abstraction allows you to track and attribute distributions based on income type.

**Source Types:**
- `BASE_PAY` - Fiat-to-USDC conversions via Base Pay
- `PROTOCOL_FEES` - Revenue from protocol operations or transaction fees
- `GRANTS` - Grant funding from ecosystem programs or foundations
- `DONATIONS` - Community donations or contributions
- `PARTNERSHIPS` - Revenue from integration partnerships or affiliates
- `OTHER` - Custom revenue sources

**Use Cases:**
- Track which revenue streams contribute most to distributions
- Generate analytics by revenue source for investor reports
- Separate grant funding from operating revenue in accounting
- Build dashboards showing Base Pay vs protocol fee contributions

### Pool

A **Pool** is a named revenue distribution scheme with its own set of recipients and rules. Organizations typically create separate pools for different revenue streams or business units.

**Pool Properties:**
- `name` - Human-readable identifier (e.g., "DAO Core Revenue")
- `description` - Purpose and scope of the pool
- `owner` - Address authorized to manage recipients and execute payouts
- `totalShares` - Sum of all recipient shares for proportional calculation
- `active` - Whether the pool accepts new distributions
- `distributionCount` - Number of payouts executed

**Examples:**
- **"Main Protocol Revenue"** - Core protocol fees split among stakeholders
- **"Product X Revenue"** - Dedicated pool for a specific product line
- **"Grant Distribution Pool"** - Distributing ecosystem grant funding
- **"Partnership Referrals"** - Splitting referral fees with integration partners

### Bucket

A **Bucket** categorizes recipients within a pool by their role or purpose. This semantic layer enables structured analytics and clear understanding of where funds flow.

**Standard Bucket Types:**
- `TEAM` - Core team members, contributors, employees
- `INVESTORS` - Equity investors, token holders, backers
- `TREASURY` - Reserve funds, operational reserves, DAO treasury
- `REFERRALS` - Referral partners, affiliates, integrators
- `SECURITY_FUND` - Bug bounties, security audits, insurance reserves
- `GRANTS` - Ecosystem grants, developer funding, community programs
- `CUSTOM` - Custom categories for specialized use cases

**Why Buckets Matter:**
- **Transparency**: External observers can see % going to team vs investors vs treasury
- **Analytics**: Dashboard can show "35% to TEAM, 25% to INVESTORS, 40% to TREASURY"
- **Governance**: DAO proposals can target specific bucket percentages
- **Compliance**: Clear categorization for financial reporting and audits

### Recipient

A **Recipient** is an individual Ethereum address receiving funds from a pool. Each recipient has:

- `account` - Ethereum address receiving funds
- `shares` - Weight determining proportional allocation
- `bucket` - Category classification (TEAM, INVESTORS, etc.)
- `active` - Whether currently included in distributions

**Share Calculation:**
```
recipientAmount = (totalPayoutAmount × recipientShares) / poolTotalShares
```

### Distribution

A **Distribution** is a historical record of a payout execution. Every distribution captures:

- `distributionId` - Unique sequential ID within the pool
- `timestamp` - When the payout occurred
- `totalAmount` - Total USDC distributed
- `source` - Revenue source type (BASE_PAY, PROTOCOL_FEES, etc.)
- `sourceIdentifier` - External reference (e.g., "base-pay-tx-0x123...")
- `recipientCount` - Number of recipients who received funds
- `txHash` - Block hash for additional verification

**Use Cases:**
- Build distribution history dashboards
- Generate CSV exports for accounting
- Prove specific payouts occurred on-chain
- Analyze revenue trends over time by source type

## Data Flow

```
Revenue Source → Pool → Buckets → Recipients

Example:
Base Pay Payment ($10,000 USDC)
    ↓
"DAO Core Revenue" Pool
    ↓
Split by Buckets:
├─ TEAM (40%) → $4,000
│  ├─ Alice: $2,000
│  └─ Bob: $2,000
├─ INVESTORS (30%) → $3,000
│  └─ Investor Fund: $3,000
└─ TREASURY (30%) → $3,000
   └─ Treasury Multisig: $3,000
```

## Events for Analytics

SplitBase emits rich events optimized for indexing with The Graph or Goldsky:

### `PoolCreatedV2`
```solidity
event PoolCreatedV2(
    uint256 indexed poolId,
    address indexed owner,
    string name,
    string description
)
```

### `RecipientAddedV2`
```solidity
event RecipientAddedV2(
    uint256 indexed poolId,
    address indexed recipient,
    uint256 shares,
    BucketType indexed bucket
)
```

### `PayoutExecutedV2`
```solidity
event PayoutExecutedV2(
    uint256 indexed poolId,
    uint256 indexed distributionId,
    uint256 totalAmount,
    SourceType indexed source,
    string sourceIdentifier,
    uint256 timestamp
)
```

### `BucketPayout`
```solidity
event BucketPayout(
    uint256 indexed poolId,
    uint256 indexed distributionId,
    BucketType indexed bucket,
    uint256 amount,
    uint256 recipientCount
)
```

**All three indexed fields can be efficiently queried:**
- Find all payouts from a specific pool
- Find all distributions from a specific source type
- Find all payments to a specific bucket
- Aggregate total distributions by source over time

## Contract Architecture

### SplitBaseV1 (Base Layer)

Core payout logic with recipient management. Provides fundamental splitting functionality.

**Key Functions:**
- `createPool()` - Create new distribution pool
- `addRecipient(poolId, address, shares)` - Add recipient
- `executePayout(poolId, amount)` - Distribute funds

### SplitBaseV2 (Enhanced Layer)

Extends V1 with bucket semantics, source tracking, and distribution history.

**New V2 Functions:**
- `createPoolV2(name, description)` - Create named pool
- `addRecipientV2(poolId, address, shares, bucket)` - Add recipient with bucket
- `executePayoutV2(poolId, amount, source, sourceIdentifier)` - Execute with metadata
- `getBucketRecipients(poolId, bucket)` - Query recipients by bucket
- `getBucketTotalShares(poolId, bucket)` - Get bucket allocation
- `getDistribution(poolId, distributionId)` - Retrieve distribution record

**Backward Compatibility:**
- All V1 functions still work unchanged
- Existing V1 pools can be upgraded to use V2 features
- V1 and V2 functions can be mixed in the same pool

### RegistryV1

Global registry for pool discovery and ecosystem visibility.

**Purpose:**
- Pools opt-in to public registry for discoverability
- Enables ecosystem-wide analytics and dashboards
- Supports metadata for external indexing

### ExecutorV1

Authorized execution pattern for secure payout operations.

**Purpose:**
- Pool owners can delegate execution rights to specific addresses
- Enables automated payout bots or scheduled executions
- Separates management permissions from execution permissions

## Storage Layout & Upgradeability

SplitBase uses the UUPS (Universal Upgradeable Proxy Standard) pattern:

- **Proxy Contract**: Static address users interact with
- **Implementation Contract**: Upgradeable logic contract
- **Storage Gaps**: Reserved slots for future upgrades

**Upgrade Safety:**
- V2 adds new storage variables at the end only
- V1 storage layout remains unchanged
- 44-slot storage gap reserved for future versions

## Integration Patterns

### Basic Integration (V1)

```solidity
// Create pool
uint256 poolId = splitBase.createPool();

// Add recipients
splitBase.addRecipient(poolId, teamMember1, 100);
splitBase.addRecipient(poolId, investor1, 200);

// Execute payout
usdc.approve(address(splitBase), amount);
splitBase.executePayout(poolId, amount);
```

### Advanced Integration (V2)

```solidity
// Create named pool
uint256 poolId = splitBase.createPoolV2(
    "Protocol Revenue Q1",
    "Main protocol revenue distribution for Q1 2025"
);

// Add recipients with bucket categorization
splitBase.addRecipientV2(poolId, alice, 100, Types.BucketType.TEAM);
splitBase.addRecipientV2(poolId, bob, 150, Types.BucketType.TEAM);
splitBase.addRecipientV2(poolId, investorFund, 300, Types.BucketType.INVESTORS);
splitBase.addRecipientV2(poolId, treasury, 450, Types.BucketType.TREASURY);

// Execute with source tracking
usdc.approve(address(splitBase), amount);
uint256 distributionId = splitBase.executePayoutV2(
    poolId,
    amount,
    Types.SourceType.BASE_PAY,
    "base-pay-invoice-2025-01-15"
);

// Query distribution history
Types.DistributionRecord memory record = splitBase.getDistribution(poolId, distributionId);
```

### Base Pay Integration

```solidity
// Receive Base Pay payment callback
function onBasePay Payment(bytes32 invoiceId, uint256 amount) external {
    // Approve SplitBase to spend USDC
    usdc.approve(address(splitBase), amount);

    // Execute distribution with Base Pay source
    splitBase.executePayoutV2(
        poolId,
        amount,
        Types.SourceType.BASE_PAY,
        string(abi.encodePacked("invoice-", invoiceId))
    );
}
```

## Analytics & Dashboards

### Key Metrics You Can Build

**Pool-Level:**
- Total distributed over time
- Distribution frequency
- Active vs inactive recipients
- Bucket allocation percentages

**Source-Level:**
- Revenue by source type
- Base Pay vs Protocol Fees contribution ratio
- Grant funding utilization
- Partnership revenue performance

**Bucket-Level:**
- Team allocation trends
- Investor return amounts
- Treasury reserve growth
- Referral payout totals

**Recipient-Level:**
- Individual earning history
- Share percentage over time
- Participation in distributions

### Sample Subgraph Queries

```graphql
query PoolDistributions($poolId: BigInt!) {
  distributions(where: { poolId: $poolId }, orderBy: timestamp, orderDirection: desc) {
    id
    distributionId
    totalAmount
    source
    sourceIdentifier
    timestamp
    bucketPayouts {
      bucket
      amount
      recipientCount
    }
  }
}

query RevenueBySource {
  bucketPayouts(groupBy: source) {
    source
    totalAmount: sum(amount)
    count
  }
}
```

## Security Considerations

### Access Control
- Pool owners have exclusive management rights
- Only authorized executors (or owner) can trigger payouts
- Upgrades restricted to protocol owner

### Precision & Rounding
- Uses integer division for share calculation
- Dust (rounding errors) stays in the sender's account
- Fuzz tested across wide range of share configurations

### Upgradeability
- UUPS pattern allows fixing bugs without address changes
- Storage gaps prevent collisions in future versions
- Initialization protected against re-initialization attacks

### On-Chain Verification
- All payouts recorded on-chain with full attribution
- Distribution history immutable and publicly auditable
- Events optimized for external verification

## Future Extensions

Potential enhancements for V3+:

- **Time-Based Vesting**: Recipients with cliff and vesting schedules
- **Dynamic Weighting**: Shares that adjust based on performance metrics
- **Multi-Token Support**: Distribute tokens beyond USDC
- **Scheduled Payouts**: Automated distribution triggers
- **Governance Integration**: On-chain voting for bucket percentages
- **Streaming Payments**: Continuous flow instead of discrete distributions

## Gas Optimization

SplitBase is optimized for production use:

- Batch recipient operations in single transaction
- Efficient storage layout minimizes SLOAD costs
- Events use indexed fields for fast filtering
- No unnecessary storage of duplicate data

**Typical Gas Costs:**
- Create Pool: ~185k gas
- Add Recipient: ~100k gas
- Execute Payout (3 recipients): ~450k gas
- Execute Payout (10 recipients): ~1.2M gas

## Development & Testing

### Running Tests

```bash
forge test                    # Run all tests
forge test -vv                # Verbose output
forge test --gas-report       # Include gas costs
forge snapshot                # Save gas snapshot
```

### Coverage

```bash
forge coverage                # Generate coverage report
```

### Fuzz Testing

All payout calculations are fuzz tested across:
- Payment amounts: 1,000 - 1,000,000 USDC
- Share distributions: 1 - 1,000,000 shares per recipient
- Recipient counts: 1 - 50 recipients per pool

## Deployment

### Base Sepolia (Testnet)
```bash
forge script script/DeployProxy.s.sol --rpc-url base_sepolia --broadcast --verify
```

### Base Mainnet (Production)
```bash
forge script script/DeployProxy.s.sol --rpc-url base --broadcast --verify
```

### Upgrades
```bash
PROXY_ADDRESS=0x... forge script script/Upgrade.s.sol --rpc-url base --broadcast
```

## Support & Resources

- **Documentation**: `docs/`
- **Test Contracts**: `test/`
- **Example Integrations**: `examples/`
- **Gas Reports**: `forge snapshot`

---

**Built for Base L2 | Production-Grade Revenue Infrastructure**
