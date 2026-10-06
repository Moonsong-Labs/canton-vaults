# daml-lint parser bugs

Minimal examples for daml-lint commit `cba698832991f640f0e0d8a9e2bfb683717c6024`.
Each Daml file contains a failing case and a control case, with a comment stating
the actual and expected findings.

See [REPORT.md](REPORT.md) for the full parser review and proposed fixes.

Run from the repository root:

```sh
# Install the pinned linter.
make install-daml-lint

# Run all examples.
daml-lint lint-bugs --format markdown

# Run one issue.
daml-lint lint-bugs/keyword-prefix --format markdown

# Run one file.
daml-lint lint-bugs/keyword-prefix/KeywordPrefix.daml --format markdown
```

These examples are intentionally outside the project's `make lint` scan.

## Examples

| File | Actual | Expected |
|---|---|---|
| `keyword-prefix/KeywordPrefix.daml` | 1 MEDIUM: `WithWatchers` | 2 MEDIUM: `WithObservers` and `WithWatchers` |
| `block-comments/BlockComments.daml` | 1 MEDIUM: `WithoutEnsure` | 2 MEDIUM: `WithCommentedEnsure` and `WithoutEnsure` |
| `colon-spacing/ColonSpacing.daml` | 1 MEDIUM: `WithSpace` | 2 MEDIUM: `WithoutSpace` and `WithSpace` |
| `inline-with/InlineWith.daml` | 1 MEDIUM: `WithOnNextLine` | 2 MEDIUM: `WithOnHeader` and `WithOnNextLine` |
