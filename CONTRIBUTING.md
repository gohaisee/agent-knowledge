# Contributing

Thanks for improving agent-knowledge. Keep changes small and focused.

## Before you open a PR

```bash
setup/install.sh          # check deps (macOS: setup/install.sh --install)
bin/kb-validate.sh        # lint kb/ before PR if notes changed
tests/run.sh              # integration tests
tests/perf_smoke.sh       # optional local perf check
shellcheck bin/*.sh hooks/*.sh setup/install.sh tests/*.sh
```

CI runs the same checks on every push.

## Adding a knowledge note (`kb/`)

1. Copy `kb/_TEMPLATE.md` to `kb/<category>/<slug>.md`.
2. Use a unique `id` (kebab-case, matches filename slug).
3. Pick a category: `rules` · `preferences` · `best-practices` · `anti-patterns` · `architecture` · `business-logic` · `errors` · `code-reviews` · `playbooks`.
4. Write in plain English — what happened, **why**, **how to apply**. No filler.
5. `id` in frontmatter must match filename (`my-slug.md` → `id: my-slug`). Run `bin/kb-validate.sh`.
6. Run `bin/kb-index.sh` and `bin/kb-search.sh "<topic>"` to verify recall.
7. Demo notes in this repo (`source: demo`) show the style; replace them in your own fork with real project facts.

### Adding a new category

1. Create `kb/<new-category>/` and add at least one note + update `GOVERNANCE.md` category list if needed.
2. Extend `tests/run.sh` frontmatter check if the category has special rules.
3. Document the category in `README.md`.

## Changing scripts (`bin/`, `hooks/`)

- Bash with `set -euo pipefail`.
- Comments explain *why*, not what the code literally does.
- Keep scripts dependency-light: `python3`, `sqlite3`, `jq`, `rg`.
- Add or extend tests in `tests/run.sh` for behavior you change.
- Run `shellcheck` before pushing.

## Hooks and examples

- `examples/cursor/` and `examples/claude/` are templates — users copy and fix paths.
- Do not commit personal `.cursor/` rules or machine-specific absolute paths into this public repo.

## Commits and PRs

- One logical change per PR when possible.
- PR description: what changed and why.
- No `Co-authored-by` trailers from tools — commits should reflect human contributors only.

## Questions

Open a GitHub issue with context: what you tried, what you expected, what happened.
