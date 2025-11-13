# 💎 SplitBase

**Professional on-chain revenue splitter built on Base** with UUPS upgradeable architecture.

[![Base](https://img.shields.io/badge/Base-Mainnet-blue)](https://base.org)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-orange)](https://soliditylang.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-v5.0.2-purple)](https://openzeppelin.com)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-red)](https://getfoundry.sh/)

## 🌟 Features

- ⚡ **Automatic Revenue Distribution** - Split incoming ETH and ERC-20 tokens by configurable shares
- 🔐 **UUPS Upgradeable** - Safe upgrades without changing proxy address
- 💰 **Multi-Token Support** - Handle ETH and any ERC-20 token
- 📊 **On-Chain Tracking** - Complete event history for all transactions
- 🛡️ **Battle-Tested** - Built with OpenZeppelin upgradeable contracts
- 🚀 **Gas Optimized** - Efficient storage and execution patterns
- ✅ **Verified on BaseScan** - Full source code verification

## 📍 Deployments

### Base Mainnet (Chain ID: 8453)
- **Proxy**: `0x349dc2d7bf09e753428abf5677dcb5f3b97961dc`
- **Implementation**: See [deployments/8453.json](deployments/8453.json)
- **BaseScan**: [View Contract](https://basescan.org/address/0x349dc2d7bf09e753428abf5677dcb5f3b97961dc)

### Base Sepolia Testnet (Chain ID: 84532)
- **Proxy**: `0x408371f962e80a6ced4d4d856f67b113e87ad770`
- **Implementation**: See [deployments/84532.json](deployments/84532.json)
- **BaseScan**: [View Contract](https://sepolia.basescan.org/address/0x408371f962e80a6ced4d4d856f67b113e87ad770)

## 🚀 Quick Start

### Configure Split

```solidity
address[] memory recipients = [0xAlice, 0xBob, 0xCharlie];
uint256[] memory shares = [50, 30, 20]; // 50%, 30%, 20%

splitBase.configureSplit(recipients, shares);
