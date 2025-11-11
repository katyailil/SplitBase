# SplitBase

Revenue splitter on Base with UUPS proxy. Proxy addresses live in `deployments/*.json`. New proxy deployments are disabled; upgrades only.

## Networks
- Base Mainnet: `deployments/8453.json`
- Base Sepolia: `deployments/84532.json`

## Upgrade
1. Set secrets: `PRIVATE_KEY`, `BASESCAN_API_KEY`, `BASE_SEPOLIA_RPC_URL`, `BASE_MAINNET_RPC_URL`, `RECIPIENTS`, `SHARES`
2. Run Actions → `upgrade` with `sepolia` or `mainnet`
3. The workflow deploys a new implementation, upgrades proxy, verifies on BaseScan, updates and commits `deployments/*.json`

## Release
Run Actions → `release` with a tag (e.g. `v0.2.0-rc`) to publish manifests.

## Rollback
Checkout a previous tag and reuse its implementation, or run upgrade again with the desired version.
