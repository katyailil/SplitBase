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
```

### Send Payment

```solidity
// Send ETH
payable(splitBaseProxy).transfer(1 ether);

// Or send ERC-20
token.approve(splitBaseProxy, amount);
splitBase.depositToken(tokenAddress, amount);
```

### Withdraw Funds

```solidity
// Withdraw ETH
splitBase.withdrawETH();

// Withdraw ERC-20
splitBase.withdrawToken(tokenAddress);
```

## 🏗️ Architecture

### Storage Structure

```solidity
struct Split {
    address[] recipients;
    uint256[] shares;
    uint256 totalShares;
    bool active;
}
```

### Key Mappings

- `pendingETH`: Track pending ETH withdrawals per recipient
- `pendingTokens`: Track pending token withdrawals per recipient and token
- `totalETHReceived`: Total ETH processed
- `totalTokensReceived`: Total tokens processed per token address

### Events

- `SplitUpdated`: Configuration changes
- `PaymentReceived`: ETH received
- `TokenPaymentReceived`: Token received
- `ETHWithdrawn`: ETH withdrawn
- `TokenWithdrawn`: Token withdrawn
- `SplitActivated/Deactivated`: Status changes

## 🛠️ Development

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- Base RPC URLs
- BaseScan API Key

### Build

```bash
forge install
forge build
```

### Test

```bash
forge test -vv
```

## 🔄 Upgrade Process

1. Set GitHub Secrets:
   - `PRIVATE_KEY`: Deployer private key
   - `BASESCAN_API_KEY`: For verification
   - `BASE_SEPOLIA_RPC_URL`: Testnet RPC
   - `BASE_MAINNET_RPC_URL`: Mainnet RPC

2. Run GitHub Actions:
   - Go to **Actions** → **upgrade**
   - Select network: `sepolia` or `mainnet`
   - Click **Run workflow**

3. Automatic Process:
   - ✅ Deploy new implementation
   - ✅ Verify on BaseScan
   - ✅ Upgrade proxy to new implementation
   - ✅ Update deployment manifest
   - ✅ Commit changes

## 📦 Release Process

```bash
# Via GitHub Actions
Actions → release → Enter version tag (e.g., v1.0.0)
```

Creates a GitHub release with deployment manifests.

## 🔒 Security

- ✅ Admin-only upgrade authorization
- ✅ ReentrancyGuard patterns
- ✅ SafeERC20 for token transfers
- ✅ Custom errors for gas efficiency
- ✅ OpenZeppelin battle-tested contracts

## 🌐 Base Ecosystem Integration

- **Base Pay**: Native payment integration
- **Base Account SDK**: Smart wallet support
- **OpenZeppelin**: Industry-standard upgradeable contracts
- **Foundry**: Modern Solidity development

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.

## 📞 Support

- GitHub Issues: [Report Bug](https://github.com/katyailil/SplitBase/issues)
- Base Discord: [Join Community](https://discord.gg/buildonbase)

---

**Built with ❤️ on Base** | [Base.org](https://base.org) | [BaseScan](https://basescan.org)
