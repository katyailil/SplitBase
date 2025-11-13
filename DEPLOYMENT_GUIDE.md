# 🚀 SplitBase Deployment Guide

## 📋 Prerequisites

### GitHub Secrets (Required)

Set these in: **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example |
|------------|-------------|---------||
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
```

---

## 🆕 Deploy New Proxy (First Time)

**⚠️ Only use for new deployments! Existing proxies are in `deployments/*.json`**

### Steps:

1. Go to **Actions** tab
2. Select **deploy_new_proxy** workflow
3. Click **Run workflow**
4. Choose network: `sepolia` or `mainnet`
5. Click **Run workflow** button

### What Happens:

✅ Deploys implementation  
✅ Deploys ERC1967 proxy  
✅ Initializes proxy with your address as admin  
✅ Verifies both contracts  
✅ Creates/updates `deployments/*.json`  
✅ Auto-commits  

---

## ⚙️ Configure Split Recipients

**Set who receives payments and their shares.**

### Steps:

1. Go to **Actions** tab
2. Select **configure_split** workflow
3. Click **Run workflow**
4. Fill parameters:
   - **Network**: `sepolia` or `mainnet`
   - **Recipients**: `0xAddress1,0xAddress2,0xAddress3`
   - **Shares**: `50,30,20` (percentages)
5. Click **Run workflow** button

### Example:

```
Recipients: 0x742d35Cc6634C0532925a3b8....,0x123456789abcdef....
Shares: 60,40
```

This splits 60% to first address, 40% to second.

### Verify:

```bash
cast call PROXY "getSplitConfig()(address[],uint256[],uint256,bool)" --rpc-url RPC_URL
```

---

## 📦 Create Release

**Package deployment manifests as a GitHub release.**

### Steps:

1. Go to **Actions** tab
2. Select **release** workflow
3. Click **Run workflow**
4. Enter tag: `v1.0.0`
5. Choose if pre-release: `true`/`false`
6. Click **Run workflow** button

### What Happens:

✅ Creates GitHub release with tag  
✅ Attaches `deployments/*.json` files  
✅ Generates release notes  
✅ Lists proxy and implementation addresses  

---

## 🧪 Testing in Sepolia

### 1. Upgrade to new implementation:

```bash
Actions → upgrade → sepolia → Run
```

### 2. Configure split:

```bash
Actions → configure_split → sepolia
Recipients: YOUR_ADDRESS_1,YOUR_ADDRESS_2
Shares: 70,30
```

### 3. Send test payment:

```bash
cast send PROXY_ADDRESS --value 0.001ether --rpc-url BASE_SEPOLIA_RPC --private-key YOUR_KEY
```

### 4. Check pending funds:

```bash
cast call PROXY "getPendingETH(address)(uint256)" YOUR_ADDRESS --rpc-url BASE_SEPOLIA_RPC
```

### 5. Withdraw:

```bash
cast send PROXY "withdrawETH()" --rpc-url BASE_SEPOLIA_RPC --private-key YOUR_KEY
```

---

## 🌐 Production Deployment (Mainnet)

### Pre-flight Checklist:

- [ ] Tested in Sepolia
- [ ] Verified contracts on Sepolia BaseScan
- [ ] Split configuration correct
- [ ] Test payments and withdrawals successful
- [ ] Sufficient ETH for gas (~0.005 ETH recommended)

### Deploy:

1. **Upgrade** (if proxy exists):
   ```
   Actions → upgrade → mainnet → Run
   ```

2. **Configure split**:
   ```
   Actions → configure_split → mainnet → Run
   ```

3. **Verify on BaseScan**:
   - Mainnet: [https://basescan.org/address/PROXY_ADDRESS](https://basescan.org)

4. **Create release**:
   ```
   Actions → release → v1.0.0 → Run
   ```

---

## 🔍 Verify Contracts Manually

If auto-verification fails:

```bash
Actions → Verify on BaseScan
- Network: mainnet/sepolia
- Implementation: 0x...
- Proxy: 0x... (optional)
```

---

## 📊 Current Deployments

### Base Mainnet (8453)
```json
{
  "proxy": "0x349dc2d7bf09e753428abf5677dcb5f3b97961dc",
  "implementation": "0x275099a4126a2ddced4d352b2dc2edddc37107a2"
}
```

### Base Sepolia (84532)
```json
{
  "proxy": "0x408371f962e80a6ced4d4d856f67b113e87ad770",
  "implementation": "0x13a8f49c41133a2f3d5e6cbb18626ee242b0e4f4"
}
```

---

## 🆘 Troubleshooting

### Error: "replacement transaction underpriced"

- Workflow auto-retries with higher gas
- If persistent, wait 1-2 minutes and re-run

### Error: "ONLY_ADMIN"

- Only admin can upgrade/configure
- Admin = deployer address from `PRIVATE_KEY`

### Verification Failed

- Run manual verification workflow
- Check API key is correct
- BaseScan may take 1-2 minutes to index

### "No proxy found"

- Check `deployments/*.json` exists
- Ensure network matches (sepolia vs mainnet)
- Deploy new proxy if needed

---

## 🔗 Resources

- [Base Docs](https://docs.base.org)
- [BaseScan](https://basescan.org)
- [Foundry Book](https://book.getfoundry.sh)
- [OpenZeppelin Upgrades](https://docs.openzeppelin.com/upgrades-plugins)

---

**Questions?** Open an issue: [GitHub Issues](https://github.com/katyailil/SplitBase/issues)
