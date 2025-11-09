# SplitBase

On-chain revenue splitter on Base with upgradeable proxy (UUPS). Funds sent to the proxy are split by predefined shares; recipients withdraw on demand.

## Networks

- Base Mainnet — see `deployments/8453.json`  
- Base Sepolia — see `deployments/84532.json`

## Deploy

1. Add secrets: `PK`, `RPC_BASE`, `RPC_BASE_SEPOLIA`, `BASESCAN_API_KEY`.
2. Run workflow **deploy** with input `basesepolia` or `base`.
3. Download artifacts and check `deployments/*.json`.

## Upgrade

Use a CI job that calls the upgrade script and updates `implementation` and `txHashImpl` in `deployments/*.json`.

## Contract

- Pattern: UUPS
- Storage: keep layout stable across upgrades
- Shares: permille, sum must be 1000
- Functions: `release(address)`

## Integrations (next)

- Base Pay API
- Base Account SDK
- OnchainKit UI
