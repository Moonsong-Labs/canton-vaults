PATTERN_PACKAGES := \
	patterns/01-vault-access/interface \
	patterns/01-vault-access \
	patterns/02-pluggable-component/interface \
	patterns/02-pluggable-component \
	patterns/03-public-private-split/interface \
	patterns/03-public-private-split/public \
	patterns/03-public-private-split/private

PATTERN_TEST_PACKAGES := $(patsubst %/daml.yaml,%,$(wildcard patterns/*/test/daml.yaml))
PATTERNS := $(notdir $(patsubst %/test,%,$(PATTERN_TEST_PACKAGES)))

# OpenZeppelin daml-lint, pinned to the commit the baseline was reviewed with.
DAML_LINT_REPO := https://github.com/OpenZeppelin/daml-lint
DAML_LINT_REV := cba698832991f640f0e0d8a9e2bfb683717c6024
DAML_LINT ?= daml-lint
DAML_LINT_BASELINE := .github/daml-lint-baseline.txt
# Non-test sources only; daml-lint would otherwise also scan tests and .daml build caches.
DAML_LINT_SOURCES := $(filter-out %/test/daml,$(wildcard patterns/*/daml patterns/*/*/daml vault-example/*/daml))

.PHONY: clean build test build-patterns test-patterns sandbox-smoke sandbox-public-private \
	build-vault-example test-vault-example install-daml-lint lint \
	$(addprefix build-,$(PATTERNS)) $(addprefix test-,$(PATTERNS))

# Remove local Daml build artifacts.
clean:
	@find . -name .daml -type d -prune -exec rm -rf {} +

build: build-patterns build-vault-example

test: test-patterns test-vault-example

build-patterns: $(addprefix build-,$(PATTERNS))

$(addprefix build-,$(PATTERNS)): build-%:
	@for p in $(filter patterns/$* patterns/$*/%,$(PATTERN_PACKAGES)); do \
		echo "== $$p"; \
		(cd $$p && dpm build --enable-multi-package no -Werror=unused-dependency \
			--ghc-option=-Wunused-imports --ghc-option=-Werror=unused-imports) || exit 1; \
	done

$(addprefix test-,$(PATTERNS)): test-%: build-%
	@dpm test --package-root patterns/$*/test --all --show-coverage

test-patterns: build-patterns
	@for p in $(PATTERN_TEST_PACKAGES); do \
		echo "== $$p"; \
		dpm test --package-root $$p --all --show-coverage || exit 1; \
	done

build-vault-example:
	@cd vault-example && dpm build --all

test-vault-example: build-vault-example
	@dpm test --package-root vault-example/test --all --show-coverage

install-daml-lint:
	cargo install --locked --git $(DAML_LINT_REPO) --rev $(DAML_LINT_REV) daml-lint

# Fails on findings missing from the reviewed baseline and on baseline entries that no longer occur.
# CRITICAL findings fail before the comparison, so they cannot be baselined.
lint:
	@mkdir -p log
	@$(DAML_LINT) $(DAML_LINT_SOURCES) --format markdown --output log/daml-lint.md --fail-on critical
	@$(DAML_LINT) $(DAML_LINT_SOURCES) --format json --output log/daml-lint.json --fail-on critical
	@jq -r '.findings[] | "\(.severity) \(.detector) \(.file): \(.message)"' log/daml-lint.json \
		> log/daml-lint.unsorted.txt
	@LC_ALL=C sort log/daml-lint.unsorted.txt > log/daml-lint.txt
	@grep -v -e '^#' -e '^$$' $(DAML_LINT_BASELINE) | LC_ALL=C sort > log/daml-lint-baseline.txt
	@if ! cmp -s log/daml-lint-baseline.txt log/daml-lint.txt; then \
		echo "daml-lint findings differ from $(DAML_LINT_BASELINE)."; \
		echo "New findings (fix them, or review them and add them to the baseline):"; \
		LC_ALL=C comm -13 log/daml-lint-baseline.txt log/daml-lint.txt | sed 's/^/  + /'; \
		echo "Resolved findings (remove them from the baseline):"; \
		LC_ALL=C comm -23 log/daml-lint-baseline.txt log/daml-lint.txt | sed 's/^/  - /'; \
		exit 1; \
	fi
	@echo "daml-lint: all $$(wc -l < log/daml-lint.txt | tr -d ' ') findings are in the reviewed baseline."

# Two-participant demo from the public-private-split pattern.
sandbox-smoke: sandbox-public-private

sandbox-public-private: build-03-public-private-split
	@bash patterns/03-public-private-split/sandbox/run.sh
