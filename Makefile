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

.PHONY: clean build test build-patterns test-patterns sandbox-smoke sandbox-public-private \
	build-vault-example test-vault-example \
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

# Two-participant demo from the public-private-split pattern.
sandbox-smoke: sandbox-public-private

sandbox-public-private: build-03-public-private-split
	@bash patterns/03-public-private-split/sandbox/run.sh
