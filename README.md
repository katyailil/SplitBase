# SplitBase

Production-grade on-chain revenue distribution system for Base network.

## Overview

SplitBase provides programmable USDC payout splitting across multiple recipients using upgradeable smart contracts. Built for production treasury infrastructure on Base L2.

High-precision share calculations ensure accurate distribution across all recipients with minimal rounding errors.

## Key Benefits

- **No Intermediaries**: Direct on-chain distribution without trust assumptions
- **Transparent**: All operations recorded on Base blockchain
- **Efficient**: Optimized gas usage for frequent distributions

## Architecture

- **Core Pool Logic**: Dynamic recipient configurations with percentage/unit-based shares
- **Bucket Semantics**: Structured categorization (TEAM, INVESTORS, TREASURY, etc.)
- **Source Tracking**: Revenue attribution (Base Pay, protocol fees, grants, etc.)
- **Registry**: Centralized pool management and discovery
- **Executor**: Base Pay integration for automated execution flows
- **Upgradeability**: UUPS proxy pattern with static addresses

**📚 Documentation:**
- [Architecture Guide](./docs/ARCHITECTURE.md) - Technical architecture and integration patterns
- [Domain Model](./docs/DOMAIN_MODEL.md) - Business concepts explained for non-developers

## Features

- Create and manage payout pools with flexible share models
- **Bucket categorization** (TEAM, INVESTORS, TREASURY, REFERRALS, SECURITY_FUND, GRANTS)
- **Revenue source tracking** (Base Pay, protocol fees, grants, donations, partnerships)
- **Distribution history** with full on-chain audit trail
- Execute distribution cycles with precise accounting
- Support for Base smart wallets and sub-accounts
- Full upgradeability without address changes (V1 → V2 compatible)
- Event emissions optimized for Subgraph indexing and analytics dashboards
- Gas-optimized execution for cost-effective operations

## Development

```bash
forge build
forge test
forge test --gas-report
forge snapshot
```

## Deployment

### Setup

```bash
cp .env.example .env
# Add your PRIVATE_KEY and BASESCAN_API_KEY
```

### Manual Deployment

**Deploy to Base Sepolia:**
```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
```

**Deploy upgradeable proxy:**
```bash
forge script script/DeployProxy.s.sol --rpc-url base_sepolia --broadcast --verify
```

**Upgrade existing proxy:**
```bash
PROXY_ADDRESS=0x... forge script script/Upgrade.s.sol --rpc-url base_sepolia --broadcast
```

### GitHub Actions Deployment

Use workflow dispatch for automated deployments:
- **Deploy**: Actions → Deploy to Base → Run workflow
- **Deploy Proxy**: Actions → Deploy Upgradeable Proxy → Run workflow
- **Upgrade**: Actions → Upgrade Contract → Run workflow

## Security

For security concerns, please contact the team directly.

## License

MIT
