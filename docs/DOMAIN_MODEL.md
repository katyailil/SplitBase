# SplitBase Domain Model

## Introduction

This document defines the core business concepts in SplitBase. These concepts are formalized in the smart contract code but are explained here in plain language for integration partners, auditors, and ecosystem participants.

## Domain Model Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  Source (WHERE money comes from)                            │
│  ├─ Base Pay                                                │
│  ├─ Protocol Fees                                           │
│  ├─ Grants                                                  │
│  ├─ Donations                                               │
│  ├─ Partnerships                                            │
│  └─ Other                                                   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  Pool (WHAT the distribution scheme is)                     │
│  - Name: "DAO Core Revenue"                                 │
│  - Description: "Main protocol revenue distribution"         │
│  - Owner: 0x...                                             │
│  - Total Shares: 1000                                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  Buckets (HOW recipients are categorized)                   │
│  ├─ TEAM (40% of shares)                                    │
│  ├─ INVESTORS (30% of shares)                               │
│  ├─ TREASURY (20% of shares)                                │
│  ├─ REFERRALS (5% of shares)                                │
│  ├─ SECURITY_FUND (3% of shares)                            │
│  ├─ GRANTS (2% of shares)                                   │
│  └─ CUSTOM (flexible category)                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  Recipients (WHO receives the funds)                         │
│  ├─ Alice (TEAM, 200 shares)                                │
│  ├─ Bob (TEAM, 200 shares)                                  │
│  ├─ Investor Fund (INVESTORS, 300 shares)                   │
│  ├─ Treasury Multisig (TREASURY, 200 shares)                │
│  └─ Partner A (REFERRALS, 50 shares)                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  Distribution (RECORD of what happened)                      │
│  - Distribution ID: 1                                        │
│  - Total Amount: 10,000 USDC                                │
│  - Source: BASE_PAY                                         │
│  - Source Identifier: "base-pay-tx-0x123..."               │
│  - Timestamp: 2025-12-10 14:30:00 UTC                       │
│  - Recipients Count: 5                                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Entity Definitions

### 1. Source

**What it is:** The origin of revenue flowing into the system.

**Why it matters:** Organizations need to track which revenue streams contribute to distributions. This is critical for:
- Financial reporting ("We distributed $50k from Base Pay this month")
- Investor relations ("Protocol fees generated $X, grants contributed $Y")
- Performance analysis ("Base Pay is our fastest-growing revenue source")

**Enum Values:**
| Source Type       | Description                                  | Example Use Case                        |
|-------------------|----------------------------------------------|-----------------------------------------|
| `BASE_PAY`        | Fiat-to-crypto conversions via Base Pay    | Invoice payments, subscriptions         |
| `PROTOCOL_FEES`   | Revenue from protocol operations            | Transaction fees, swap fees             |
| `GRANTS`          | Ecosystem grants and funding                | Base ecosystem grants, foundation funds |
| `DONATIONS`       | Community contributions                     | DAO donations, crowdfunding             |
| `PARTNERSHIPS`    | Affiliate or integration revenue            | Referral fees, revenue sharing          |
| `OTHER`           | Custom or unspecified sources               | Ad hoc payments, misc revenue           |

**Code Example:**
```solidity
// When executing a payout, specify the source
splitBase.executePayoutV2(
    poolId,
    amount,
    Types.SourceType.BASE_PAY,  // <-- Revenue source
    "base-pay-invoice-2025-01-15"
);
```

---

### 2. Pool

**What it is:** A named revenue distribution scheme with its own recipients and share allocations.

**Why it matters:** Different revenue streams or business units may have different distribution rules. Pools provide isolation and clarity.

**Attributes:**
- **Name**: Human-readable identifier (e.g., "Q1 2025 Protocol Revenue")
- **Description**: Purpose and context
- **Owner**: Address with management rights
- **Total Shares**: Sum of all recipient shares
- **Active**: Whether pool accepts new distributions
- **Distribution Count**: Number of payouts executed

**Real-World Examples:**

| Pool Name                  | Purpose                                           | Typical Recipients                |
|----------------------------|---------------------------------------------------|-----------------------------------|
| "Main Protocol Revenue"    | Core protocol income splitting                   | Team, investors, treasury         |
| "Product X Earnings"       | Dedicated product line                           | Product team, partners            |
| "Grant Distribution"       | Distributing ecosystem grants                    | Projects, developers, grantees    |
| "Partnership Referrals"    | Splitting referral fees                          | Affiliates, integrators           |

**Code Example:**
```solidity
uint256 poolId = splitBase.createPoolV2(
    "DAO Core Revenue",
    "Main revenue pool for DAO operations and contributor compensation"
);
```

---

### 3. Bucket

**What it is:** A semantic category grouping recipients by role or purpose within a pool.

**Why it matters:**
- **Transparency**: Stakeholders can see what % goes to each category
- **Governance**: DAOs can vote on target bucket percentages
- **Analytics**: Dashboards show clear breakdown of fund flows
- **Compliance**: Structured categorization for financial audits

**Bucket Types:**

| Bucket Type      | Typical Purpose                              | Example Recipients                    |
|------------------|----------------------------------------------|---------------------------------------|
| `TEAM`           | Core contributors and employees             | Developers, designers, ops team       |
| `INVESTORS`      | Equity investors and token holders          | VC funds, angel investors             |
| `TREASURY`       | Reserve funds and operational capital       | DAO treasury, reserve multisig        |
| `REFERRALS`      | Affiliate and referral partners             | Integration partners, affiliates      |
| `SECURITY_FUND`  | Security audits and bug bounties            | Audit firms, bug bounty programs      |
| `GRANTS`         | Ecosystem grants and developer funding      | Community projects, open source devs  |
| `CUSTOM`         | Organization-specific categories            | Any custom use case                   |

**Analytics Value:**

With buckets, you can generate reports like:
```
Distribution #42 (Dec 10, 2025)
Total: 100,000 USDC from BASE_PAY

Breakdown by Bucket:
├─ TEAM:         40,000 USDC (40%) → 3 recipients
├─ INVESTORS:    30,000 USDC (30%) → 2 recipients
├─ TREASURY:     25,000 USDC (25%) → 1 recipient
└─ REFERRALS:     5,000 USDC (5%)  → 2 recipients
```

**Code Example:**
```solidity
// Add team members
splitBase.addRecipientV2(poolId, alice, 200, Types.BucketType.TEAM);
splitBase.addRecipientV2(poolId, bob, 200, Types.BucketType.TEAM);

// Add investors
splitBase.addRecipientV2(poolId, investorFund, 300, Types.BucketType.INVESTORS);

// Add treasury
splitBase.addRecipientV2(poolId, treasury, 250, Types.BucketType.TREASURY);

// Query bucket info
uint256 teamShares = splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM);
address[] memory teamMembers = splitBase.getBucketRecipients(poolId, Types.BucketType.TEAM);
```

---

### 4. Recipient

**What it is:** An individual Ethereum address receiving funds from a pool, with assigned shares and bucket classification.

**Attributes:**
- **Account**: Ethereum address
- **Shares**: Weight for proportional distribution
- **Bucket**: Category (TEAM, INVESTORS, etc.)
- **Active**: Whether currently receiving distributions

**Share Calculation:**

The amount a recipient receives is calculated as:
```
recipientAmount = (totalPayoutAmount × recipientShares) / poolTotalShares
```

**Example:**

Pool has 1000 total shares, payout is 10,000 USDC:
- Alice (200 shares): 10,000 × (200/1000) = 2,000 USDC
- Bob (300 shares): 10,000 × (300/1000) = 3,000 USDC
- Treasury (500 shares): 10,000 × (500/1000) = 5,000 USDC

**Code Example:**
```solidity
// Add recipient with bucket
splitBase.addRecipientV2(
    poolId,
    0xAliceAddress,     // recipient address
    200,                // shares
    Types.BucketType.TEAM  // bucket category
);

// Update recipient (change shares and/or bucket)
splitBase.updateRecipientV2(
    poolId,
    0xAliceAddress,
    250,                    // new shares
    Types.BucketType.TEAM  // can change bucket too
);

// Query recipient info
ISplitBaseV2.RecipientV2 memory recipient = splitBase.getRecipientV2(poolId, 0xAliceAddress);
```

---

### 5. Distribution

**What it is:** An immutable historical record of a payout execution.

**Why it matters:**
- Provides auditable trail of all distributions
- Enables analytics and reporting
- Links payouts to revenue sources
- Supports compliance and accounting

**Attributes:**
- **Distribution ID**: Sequential ID within pool (1, 2, 3, ...)
- **Timestamp**: When the distribution occurred
- **Total Amount**: USDC distributed
- **Source**: Revenue source type (BASE_PAY, PROTOCOL_FEES, etc.)
- **Source Identifier**: External reference or transaction ID
- **Recipient Count**: Number of recipients who received funds
- **TX Hash**: Block hash for verification

**Use Cases:**

1. **Accounting**: Export distribution history for financial statements
2. **Analytics**: Track revenue trends over time
3. **Auditing**: Verify all claimed payouts actually occurred on-chain
4. **Investor Relations**: Show transparent distribution history

**Code Example:**
```solidity
// Execute payout with source tracking
uint256 distributionId = splitBase.executePayoutV2(
    poolId,
    100_000 * 1e6,  // 100,000 USDC
    Types.SourceType.BASE_PAY,
    "base-pay-invoice-2025-01-15"
);

// Retrieve distribution record
Types.DistributionRecord memory record = splitBase.getDistribution(poolId, distributionId);

// Access distribution data
uint256 amount = record.totalAmount;          // 100,000 USDC
string memory sourceRef = record.sourceIdentifier;  // "base-pay-invoice-2025-01-15"
uint256 timestamp = record.timestamp;         // Unix timestamp
```

---

## Complete Example: Real-World Scenario

### Scenario: DAO Operating a DeFi Protocol on Base

**Setup:**

The DAO creates a pool called "Protocol Revenue Q1 2025" to distribute quarterly revenue among stakeholders.

```solidity
uint256 poolId = splitBase.createPoolV2(
    "Protocol Revenue Q1 2025",
    "Main protocol revenue distribution for Q1 including Base Pay subscriptions and swap fees"
);
```

**Adding Recipients with Buckets:**

```solidity
// Team members (40% allocation)
splitBase.addRecipientV2(poolId, alice, 200, Types.BucketType.TEAM);
splitBase.addRecipientV2(poolId, bob, 200, Types.BucketType.TEAM);

// Investor fund (30% allocation)
splitBase.addRecipientV2(poolId, investorFund, 300, Types.BucketType.INVESTORS);

// Treasury reserve (25% allocation)
splitBase.addRecipientV2(poolId, treasuryMultisig, 250, Types.BucketType.TREASURY);

// Referral partners (5% allocation)
splitBase.addRecipientV2(poolId, partnerA, 50, Types.BucketType.REFERRALS);

// Total shares: 1000
```

**Executing Payouts:**

```solidity
// Week 1: Base Pay subscription revenue
usdc.approve(address(splitBase), 50_000 * 1e6);
splitBase.executePayoutV2(
    poolId,
    50_000 * 1e6,
    Types.SourceType.BASE_PAY,
    "subscriptions-week-1"
);

// Week 2: Protocol swap fees
usdc.approve(address(splitBase), 25_000 * 1e6);
splitBase.executePayoutV2(
    poolId,
    25_000 * 1e6,
    Types.SourceType.PROTOCOL_FEES,
    "swap-fees-week-2"
);

// Week 3: Ecosystem grant
usdc.approve(address(splitBase), 100_000 * 1e6);
splitBase.executePayoutV2(
    poolId,
    100_000 * 1e6,
    Types.SourceType.GRANTS,
    "base-ecosystem-grant-q1"
);
```

**Result:**

Each recipient receives their share from every distribution:

| Recipient        | Shares | Week 1 (50k)  | Week 2 (25k)  | Week 3 (100k) | Total    |
|------------------|--------|---------------|---------------|---------------|----------|
| Alice (TEAM)     | 200    | 10,000 USDC   | 5,000 USDC    | 20,000 USDC   | 35,000   |
| Bob (TEAM)       | 200    | 10,000 USDC   | 5,000 USDC    | 20,000 USDC   | 35,000   |
| Investor (INV)   | 300    | 15,000 USDC   | 7,500 USDC    | 30,000 USDC   | 52,500   |
| Treasury (TRES)  | 250    | 12,500 USDC   | 6,250 USDC    | 25,000 USDC   | 43,750   |
| Partner (REF)    | 50     | 2,500 USDC    | 1,250 USDC    | 5,000 USDC    | 8,750    |
| **TOTAL**        | 1000   | **50,000**    | **25,000**    | **100,000**   | **175k** |

**Analytics:**

```
Q1 2025 Summary for "Protocol Revenue Q1 2025"

Total Distributed: 175,000 USDC
Distributions: 3

By Source:
├─ BASE_PAY:        50,000 USDC (28.6%)
├─ PROTOCOL_FEES:   25,000 USDC (14.3%)
└─ GRANTS:         100,000 USDC (57.1%)

By Bucket:
├─ TEAM:           70,000 USDC (40%)
├─ INVESTORS:      52,500 USDC (30%)
├─ TREASURY:       43,750 USDC (25%)
└─ REFERRALS:       8,750 USDC (5%)
```

---

## Semantic Advantages

### Without Buckets (V1)
```
Pool has 5 recipients with shares.
Can't easily tell who is team vs investor vs treasury.
```

### With Buckets (V2)
```
Pool has:
- 2 TEAM recipients (40%)
- 1 INVESTOR recipient (30%)
- 1 TREASURY recipient (25%)
- 1 REFERRAL recipient (5%)

Clear semantic breakdown visible to everyone.
```

---

## Query Patterns

### Get All Team Members in a Pool
```solidity
address[] memory team = splitBase.getBucketRecipients(poolId, Types.BucketType.TEAM);
```

### Get Team's Total Share Percentage
```solidity
uint256 teamShares = splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM);
uint256 totalShares = splitBase.getPoolV2(poolId).totalShares;
uint256 teamPercentage = (teamShares * 100) / totalShares;
```

### Get Distribution History
```solidity
ISplitBaseV2.PoolV2 memory pool = splitBase.getPoolV2(poolId);
uint256 distCount = pool.distributionCount;

for (uint256 i = 1; i <= distCount; i++) {
    Types.DistributionRecord memory dist = splitBase.getDistribution(poolId, i);
    // Process distribution...
}
```

---

## Migration from V1 to V2

Existing V1 pools can adopt V2 features gradually:

```solidity
// Existing V1 pool
uint256 poolId = splitBase.createPool();
splitBase.addRecipient(poolId, alice, 200);
splitBase.addRecipient(poolId, bob, 300);

// Now add V2 recipient with bucket
splitBase.addRecipientV2(poolId, treasury, 500, Types.BucketType.TREASURY);

// Execute with V2 source tracking
splitBase.executePayoutV2(poolId, amount, Types.SourceType.BASE_PAY, "payment-1");

// All recipients receive funds, V2 features work alongside V1
```

---

## Conclusion

SplitBase's domain model provides:

✅ **Clear semantics**: Source, Pool, Bucket, Recipient, Distribution
✅ **Full transparency**: Every distribution categorized and recorded
✅ **Rich analytics**: Query by bucket, source, time, recipient
✅ **Backward compatible**: V1 pools work with V2 features
✅ **Production-ready**: Tested, optimized, upgradeable

**Next Steps:**
- Read `ARCHITECTURE.md` for technical implementation details
- Review `test/SplitBaseV2.t.sol` for integration examples
- Deploy to Base Sepolia for testing
- Index events with The Graph for analytics dashboards
