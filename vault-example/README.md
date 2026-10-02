# Vault Example

## Overview

A self-contained vault based on VaultKit that shows how the patterns in this
repository fit together and how a vault could incorporate them.

The example shows how to:

- Onboard depositors with a revocable attestation and per-vault permissions.
- Accept Token Standard V2 tokens.
- Issue vault shares as CIP-0112-compatible tokens.
- Invest the treasury in other tokenized assets.
- Simulate changes in the underlying assets by updating the NAV.
- Execute deposit and share mint, and redeem and share burn, as atomic
  transactions.
- Include a simple fee implementation to demonstrate how interfaces can hide
  a private implementation that only the manager's participant installs.

## How it works

[`test/Integration/VaultFlow.daml`](test/Integration/VaultFlow.daml) runs a
portfolio of tokenized fund units end to end and is the best guide to the
example.

1. **Onboarding.** The manager creates a `Vault` and an empty `NAV`, records
   the depositor's approval in an `AccessAttestation`, and exercises
   `Vault.GrantAccess` to issue a `VaultAccess`.
2. **Deposit.** The depositor exercises `VaultAccess.Deposit` with 1,001
   USDCx. The choice locks the funds in an allocation and creates a
   `DepositRequest`. The manager exercises `HandleDeposit`: the private
   `DepositHandler` charges the flat fee of 1, quotes 1,000 shares at price 1,
   and updates `NAV`; `DepositRequest.Consume` then settles 1,000 to the
   treasury and 1 to the fee treasury, mints the `Share`, and records the
   mint event in `ShareRegistry`.
3. **Investment.** A counterparty signs a `TradeOffer` for each asset, listing
   at most 100 holdings to fund it. The manager exercises `Vault.Buy`; the
   private `TradeHandler` checks the offer against the allowed assets and trade
   limit, then `ExecuteTrade` settles the cash and asset legs together. The
   vault ends with 4 treasury fund units, 6 credit fund units, 1 property fund
   unit, and 100 USDCx.
4. **Valuation.** The manager exercises `UpdateNAV` with the revalued
   portfolio. NAV becomes 1,036 for 1,000 shares, so the share price is
   1.036. Selling 2 treasury units and the property unit through `Vault.Sell`
   brings treasury cash to 522 without changing NAV.
5. **Redemption.** The depositor exercises `Share.Redeem` for 500 shares.
   The lot splits into an unlocked remainder and a locked lot reserved by a
   `ShareAllocation`, and a `RedeemRequest` is created. The manager exercises
   `Vault.HandleRedeem`: the private `RedeemHandler` quotes 518 at price
   1.036 less the fee of 1 and updates `NAV`; `ConsumeRedeem` pays 517 to the
   depositor and 1 to the fee treasury, then burns the reserved lot.

Share prices are rounded to ten decimals in the vault's favor: deposits use
NAV per share rounded up and redemptions use it rounded down, and a partial
redemption pays shares times that price rounded down. Rounding remainders stay
with the outstanding shares, so a partial redemption receives less than its
exact pro-rata value by under (shares + 1) × 1e-10, and the last redemption
receives the remaining NAV. The public settlement checks each payout against
its quoted price. `NAV` reports the price rounded to nearest, for display
only. It rejects valuations whose redemption price would fall below 1e-6, and
caps NAV and supply at 1e17 so pricing stays exact. Deposits and redemptions
never lower the price, so these limits can reject a deposit or a revaluation but
never a redemption.

The feature tests under `Onboarding/`, `Valuation/`, `Deposit/`, `Redeem/`,
and `Investment/` cover each step in isolation, including a failed asset
delivery that rolls back the cash payment.

## Simplifications

- Valuation is a manual snapshot set by the manager. No oracle, freshness
  check, or reconciliation with issued shares.
- The only fee model is a flat fee of one unit, capped at half the amount, for
  both deposits and redemptions.
- Access is admin-led. The depositor-led request path from the `vault-access`
  pattern is not included.
- Demo assets do not support cancelling or withdrawing allocations, so
  `Cancel` and `Reject` on a `DepositRequest` fail against them. Share
  reservations can be cancelled and withdrawn.

## Run the tests

From the repository root:

```sh
make build-vault-example
make test-vault-example
```

`make build` and `make test` include the example alongside the patterns.
