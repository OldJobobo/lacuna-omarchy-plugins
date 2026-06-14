# Contributing to Lacuna

Lacuna is a suite of Omarchy shell (Quickshell/QML) plugins. Thanks for helping
improve it. This guide covers the workflow; deeper architecture and geometry
rules live in [`AGENTS.md`](AGENTS.md) and [`CLAUDE.md`](CLAUDE.md).

## Ground rules

- **One Quickshell process.** No plugin may start a second Quickshell instance.
- **Plugins are self-contained.** Never import across plugin directories or rely
  on the repo root as a runtime import path. The only sanctioned cross-plugin
  imports are those backed by a hard dependency declared in `lacuna.requires`
  (enforced by `tests/test_plugin_load_smoke.py`).
- **Prefer Omarchy-native services** for already-rich surfaces (audio, network,
  battery, tray…). `lacuna.script-pill` is the experiment path.
- **Shared templates are vendored.** Edit the canonical copy first (see
  `shared/qml/simple-bar/` and `lacuna.shell-settings/components/`), then run
  `scripts/sync-vendored --fix`. Divergent copies are declared per plugin via
  `manifest.lacuna.vendorExclude`.

## Development workflow

1. Branch off `master` (never commit straight to it).
2. Make your change. Keep the diff focused and match surrounding style.
3. Run the full gate before pushing:

   ```bash
   ./scripts/check.sh    # manifest/config JSON, qmllint, shellcheck, vendored parity, pytest
   ```

   Targeted runs while iterating:

   ```bash
   python3 -m pytest tests/test_qml_contracts.py -k <name>
   qmllint path/to/Changed.qml
   ```

4. For QML changes, smoke-test live (see `CLAUDE.md`): symlink the plugin into
   `~/.config/omarchy/plugins/<id>/`, then `omarchy plugin rescan` and toggle.

Optional but recommended: `pip install pre-commit && pre-commit install` to run
ruff, shellcheck, vendored-parity, and pytest before each commit.

## Conventions

- 2-space indentation for QML and JSON.
- Plugin directories use full IDs (`lacuna.script-pill`).
- Runtime actions go through Omarchy commands (e.g. `omarchy restart shell`).
- Commits are concise and imperative (`Add script pill manifest`).
- Tests are stdlib `unittest` run via pytest. `tests/test_qml_contracts.py` is
  source-contract style — it asserts exact strings/structures, so renaming a
  covered symbol intentionally breaks tests. Update them in the same change.

## Adding a plugin

1. Create `lacuna.<name>/` at the repo root with a `manifest.json` declaring
   `kinds`, `entryPoints`, and a `lacuna` dependency block.
2. Add it to the relevant bundle/profile in `docs/plugin-dependencies.md` and
   the installer (`scripts/lacuna`) if it belongs to a profile.
3. Vendor any shared helpers and run `scripts/sync-vendored --check`.
4. Add contract tests and ensure `./scripts/check.sh` is green.

## Releasing

Bump [`VERSION`](VERSION) (mirrored into every manifest — a test enforces this),
move the `CHANGELOG.md` `[Unreleased]` entries under the new version, and tag
`v<version>`.
