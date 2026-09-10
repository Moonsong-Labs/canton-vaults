<p align="center">
  <img src=".github/assets/banner.png" alt="Moonsong Labs" width="100%">
</p>

# Canton Vaults Design Patterns

Building patterns for a **vault standard on the Canton Network**, written in Daml.

These reference implementations are extracted from the on-ledger core of
[VaultKit](https://vaults.moonsonglabs.dev/), a vault product operated by
[Moonsong Labs](https://moonsonglabs.com/). This repository implements each as a **separate, tested Daml
package** so the design can inspire vault standards and implementations on
Canton.

## Patterns

Each directory under `patterns/` holds **a pattern's packages, tests, and README**
with the problem, parties, contracts, and invariants.

| Pattern | Description |
| --- | --- |
| [`vault-access`](patterns/01-vault-access/README.md) | A **general KYB attestation and per-vault permission**, each revocable by the manager. The permission's `Deposit` choice validates access and holdings, opens a token-standard allocation, and creates the deposit request **in one transaction**. |
| [`pluggable-component`](patterns/02-pluggable-component/README.md) | A **Daml interface with an abstract function** that a host contract calls without knowing which template implements it, so behavior can be swapped without redeploying the host. Fee models (`IFee`) are the worked example. |
| [`public-private-split`](patterns/03-public-private-split/README.md) | A **public-private DAR file split** for logic that must stay private or changes often. Three layers with one dependency direction: interface, public, and private. Counterparties vet the interface and public packages; the manager vets all three. Private changes never touch the public layer. Comes with a two-participant sandbox (`make sandbox-public-private`). |

Patterns are **not audited** and intended as design references only. Each one
showcases a single design solution on its own.

## Vault example

[`vault-example/`](vault-example/README.md) is a self-contained vault example
based on VaultKit. It demonstrates deposit and redeem flows across interface,
public, and private packages, with a separate test package and a two-participant
sandbox showing the interaction between the depositor and the manager.

## Build and test

Daml SDK 3.5.2 through `dpm`.

```sh
make build
make test
```

For one pattern, use `make build-<pattern_folder>` or
`make test-<pattern_folder>`, including the folder's numeric prefix:

```sh
make build-01-vault-access
make test-03-public-private-split
```

Each build includes the selected pattern's production packages. Each test
command builds those packages first and runs the selected pattern's tests.
Patterns are self-contained. `make build` and `make test` cover all patterns
and the vault example. To run only the example:

```sh
make build-vault-example
make test-vault-example
```

`make sandbox-public-private` runs the two-participant demo from the
public-private-split pattern. CI runs the same check with `make sandbox-smoke`.
It needs Java 17 or newer and a Canton 3.5 runtime JAR; see the
[pattern's README](patterns/03-public-private-split/README.md#run-the-tests).

Without a local SDK, the `Dockerfile` provides the toolchain:

```sh
docker build -t canton-vaults-dev .
docker run --rm -v "$PWD":/workspace -w /workspace canton-vaults-dev make build test
```

## License

MIT. See [LICENSE](LICENSE).
