# Testing

Status: reference

Run the full local check before publishing changes:

```bash
./scripts/check.sh
```

It validates:

- example JSON
- plugin manifests
- vendored-file equality
- the Python test suite
- optional `qmllint` checks when installed
- optional `shellcheck` checks when installed

Run Python tests directly with:

```bash
python3 -m pytest
```

Run docs contract tests with:

```bash
python3 -m pytest tests/test_docs_contracts.py
```

## Omarchy Smoke Tests

Smoke test loaded plugins with:

```bash
omarchy plugin list
OMARCHY_PATH="$HOME/.local/share/omarchy" omarchy-shell shell summon lacuna.menu "{}"
hyprctl layers
```

For local plugin testing, copy or symlink a plugin directory into:

```text
~/.config/omarchy/plugins/<plugin-id>/
```

Then rescan or restart Omarchy shell:

```bash
omarchy plugin rescan
omarchy restart shell
```

Confirm that each widget appears in Omarchy Settings, can be placed in
`bar.layout`, survives shell restart, and uses injected `bar`, `moduleName`,
and `settings` properties.

For the current Quattro core shell, run the read-only P0 smoke matrix from a
live session:

```bash
scripts/quattro-p0-smoke
```
