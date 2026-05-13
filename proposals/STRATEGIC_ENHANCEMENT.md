**Strategic improvement:**  
Adopt a **pull-based “cumulative index” distribution model** (accrual + claim), instead of fully push-based recipient payouts per cycle.

### Why this is high impact
As pools grow, push distribution is O(n) per cycle and can become gas-heavy or brittle (one bad recipient path can disrupt execution).  
A cumulative index model makes funding/distribution updates near **O(1)** and moves payout gas to recipients (or delegated claim bots), which is much more scalable for frequent treasury operations.

### What it looks like (high level)
- Store `accUSDCPerShare` per pool (high precision scalar, e.g., 1e27).
- On incoming revenue, increment accumulator once.
- Per recipient store `shares` + `rewardDebt`.
- Claimable = `shares * accUSDCPerShare - rewardDebt`.
- On claim, transfer USDC and update debt.
- On recipient/share changes, force-settle (checkpoint) before mutation.

### Strategic benefits
- Predictable gas at scale  
- Better liveness (no full-cycle failure due to one recipient path)  
- Cleaner automation with bots/subaccounts  
- Preserves on-chain auditability and source/bucket attribution with evented checkpoints