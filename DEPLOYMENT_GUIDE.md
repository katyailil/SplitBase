# 🚀 SplitBase Deployment Guide

## 📋 Prerequisites

### GitHub Secrets (Required)

Set these in: **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example |
|------------|-------------|---------|
| `PRIVATE_KEY` | Deployer private key (without 0x) | `abc123...` |
| `BASESCAN_API_KEY` | BaseScan API key for verification | `ABC123...` |
| `BASE_SEPOLIA_RPC_URL` | Base Sepolia RPC endpoint | `https://sepolia.base.org` |
| `BASE_MAINNET_RPC_URL` | Base Mainnet RPC endpoint | `https://mainnet.base.org` |

### Get API Keys

- **BaseScan API**: [https://basescan.org/myapikey](https://basescan.org/myapikey)
- **Base RPC**: Public endpoints or [Alchemy](https://alchemy.com), [Infura](https://infura.io)

---

## 🔄 Upgrade Existing Proxy

**Use this to update logic without changing proxy address.**

### Steps:

1. Go to **Actions** tab
2. Select **upgrade** workflow
3. Click **Run workflow**
4. Choose network: `sepolia` or `mainnet`
5. Click **Run workflow** button

### What Happens:

✅ Deploys new implementation contract  
✅ Verifies on BaseScan  
✅ Upgrades proxy to new implementation  
✅ Updates `deployments/*.json`  
✅ Auto-commits changes  

### Verify Success:

```bash
# Check new implementation
cast call PROXY_ADDRESS "getVersion()(uint256)" --rpc-url RPC_URL
