# SplitBase

Advanced on-chain revenue distribution system for Base network.

## Overview

SplitBase provides programmable USDC payout splitting across multiple recipients using upgradeable smart contracts. Built for production treasury infrastructure on Base L2.

High-precision share calculations ensure accurate distribution across all recipients with minimal rounding errors.

## Architecture

- **Core Pool Logic**: Dynamic recipient configurations with percentage/unit-based shares
- **Registry**: Centralized pool management and discovery
- **Executor**: Base Pay integration for automated execution flows
- **Upgradeability**: UUPS proxy pattern with static addresses

## Features

- Create and manage payout pools with flexible share models
- Execute distribution cycles with precise accounting
- Support for Base smart wallets and sub-accounts
- Full upgradeability without address changes
- Event emissions optimized for Subgraph indexing

## Development

```bash
forge build
forge test
forge test --gas-report
```

## Deployment

```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
```

## License

MIT
