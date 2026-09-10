# Vault Example

A self-contained vault implementation based on VaultKit, demonstrating
access control, NAV-based share pricing, and deposit and redeem workflows
on Canton.

The example separates the contracts shared with depositors from the manager's
private processing logic through an interface package. A two-participant sandbox
shows how both parties interact while using different sets of DAR files.

## Layout

```text
vault-example/
├── multi-package.yaml
├── interface/
│   ├── daml.yaml
│   └── daml/
├── public/
│   ├── daml.yaml
│   └── daml/
├── private/
│   ├── daml.yaml
│   └── daml/
├── test/
│   ├── daml.yaml
│   ├── Onboarding/
│   ├── Deposit/
│   ├── Redeem/
│   └── Integration/
└── sandbox/
```

- `interface/`: interfaces and shared types used across the package boundary.
- `public/`: contracts that counterparties interact with. Depends on `interface/`.
- `private/`: manager-side implementations. Depends on `interface/` and `public/`.
- `test/`: one Daml Script package, grouped by feature. Its source root is `.`.
  It depends on all three implementation packages.
  Folder names match Daml module names, for example `Onboarding/Access.daml`
  declares `module Onboarding.Access where`.
- `sandbox/`: the two-participant environment for the depositor and manager.

The example owns its contracts and interfaces and has no dependencies on the
patterns' packages. Daml Script is confined to the test package.

Interfaces, their modules, and files use the `I` prefix (for example,
`IAccessAttestation.daml`). Their view records use the `Info` suffix.

## Admin-led access

The `manager` creates a `Vault` and administers access in two steps:

- `AccessAttestation` records the depositor's onboarding approval and the
  `vaultIds` it covers. An optional `evidenceHash` references off-ledger evidence.
- `Vault.GrantAccess` reads the active approval through `IAccessAttestation`,
  checks the manager, depositor, and vault scope, and creates a `VaultAccess`
  referencing that approval. The choice keeps the vault active.

Both contracts are signed by the manager and observed by the depositor. Each
has a manager-controlled `Revoke` choice that archives that contract. Issuing
access requires the manager's authorization; the depositor has no access-request
choice.

`IAccessAttestation` and `IVaultAccess` expose their views from the interface
package. Operations using a permission must fetch both active contracts and
check the manager, depositor, and vault scope. Storing the attestation's contract
ID alone does not validate it when the manager creates `VaultAccess` directly.

### Vault identity

`Vault` exposes `vaultId`, `manager`, and `name` through `IVault`. Its contract
key is `(manager, vaultId)`, maintained by the manager. `VaultAccess` retains
those identity fields, so the same key can be reconstructed without storing
another field. The key resolves a concrete `Vault`; its contract ID can then
be converted to `ContractId IVault` for interface-based interactions.

Canton 3.5 permits duplicate keys. Keeping one active vault per key is the
manager's operational responsibility. Key-based lookups require appropriate
contract visibility and authorization.

`test/Onboarding/Access.daml` covers vault lookup by key, interface reads,
onboarding approval, and the manager granting a permission visible to the depositor.

## Build and test

From the repository root:

```sh
make build-vault-example
make test-vault-example
```

`make build` and `make test` include the example alongside the patterns.
The example can also be built independently with `dpm build --all` from this
directory.

## Participants and packages

| Participant | Packages |
| --- | --- |
| Depositor | `interface`, `public` |
| Manager | `interface`, `public`, `private` |

The depositor submits requests through the public contracts. The manager
processes those requests using the private implementations, and the depositor
receives the public results. The interface package defines the shared boundary
between these layers.
