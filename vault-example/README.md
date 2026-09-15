# Vault Example

## Overview

A self-contained vault based on VaultKit that shows how the patterns in this
repository fit together and how a vault could incorporate them.

The example shows how to:

- Onboard depositors with a revocable attestation and per-vault permission.
- Accept deposits in Token Standard V2-compatible tokens and mint vault
  shares as Token Standard holdings with CIP-112 events, with settlement,
  minting, and fee collection in one transaction.
- Invest the treasury in other tokenized assets through counterparty-signed
  offers, with both legs of the trade settling atomically.
- Report a valuation snapshot that sets the share price.
- Redeem shares partially, burning the redeemed lot and paying out at the
  current price.
- Keep fee, pricing, and investment policy in a private package that only the
  manager's participant installs.

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
3. **Investment.** A counterparty signs a `TradeOffer` for each asset. The
   manager exercises `Vault.Buy`; the private `TradeHandler` checks the offer
   against the allowed assets and trade limit, then `ExecuteTrade` settles the
   cash and asset legs together. The vault ends with 4 treasury fund units,
   6 credit fund units, 1 property fund unit, and 100 USDCx.
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

The feature tests under `Onboarding/`, `Valuation/`, `Deposit/`, `Redeem/`,
and `Investment/` cover each step in isolation, including a failed asset
delivery that rolls back the cash payment.

## Simplifications

- Valuation is a manual snapshot set by the manager. No oracle, freshness
  check, or reconciliation with issued shares.
- The only fee model is a flat fee of one unit, for both deposits and
  redemptions.
- Access is admin-led. The depositor-led request path from the `vault-access`
  pattern is not included.
- Demo assets do not support cancelling or withdrawing allocations, so
  `Cancel` and `Reject` on a `DepositRequest` fail against them. Share
  reservations can be cancelled and withdrawn.
- `sandbox/` is a placeholder. There is no two-participant deployment yet.

## Run the tests

From the repository root:

```sh
make build-vault-example
make test-vault-example
```

`make build` and `make test` include the example alongside the patterns.
