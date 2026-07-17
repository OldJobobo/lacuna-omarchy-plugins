# Changelog

All notable changes to the Lacuna Omarchy plugin suite are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the suite version lives in [`VERSION`](VERSION) and is mirrored into every
`manifest.json`.

## [Unreleased]

### Fixed
- Settings service no longer shadows its `loaded()` signal; the signal fires
  and the pending-save replay runs (`lacuna.state`, `lacuna.menu`).
- Corrupt `settings.json` is backed up to `settings.json.bak` and flagged via
  `recoveredFromCorruptSettings` instead of silently restoring defaults.
- Shell-settings state load gained a timeout watchdog so a hung helper process
  can no longer wedge the service; failures mark the data stale and retry.
- `BarSizeMode` debounces theme-name changes and verifies a patched
  `shell.toml` re-parses to the intended sizes before writing.
- `MenuWindow` flyout focus-clear debounce uses a `Timer` instead of
  `Date.now()` arithmetic.
- Theme parse fallbacks now emit diagnostics via the new `LacunaLog` helper
  instead of failing silently.
- Media-player worker shutdown now reaps provider subprocesses, preventing the
  process-group lifecycle check from failing under container PID 1.
- GitHub release jobs now run the complete project gate before publishing.

### Changed
- The Bézier corner constant `curveKappa` is defined once in a shared
  `LacunaGeometry` component and referenced everywhere (was duplicated across
  seven files in three plugins).
- `sync-vendored` derives its divergent-copy exclusions from each plugin's
  `manifest.lacuna.vendorExclude` and gained an explicit `--fix` alias.
- `SidebarState` names the persisted preference (`desiredDefaultMode`) and the
  session toggle (`runtimeCollapsed`) distinctly and persists the real collapse.
- Extracted pure value validators/converters out of `MenuWindow` into a
  stateless `MenuValueHelpers` component.

### Added
- `LacunaLog`: a level-gated, prefixed logging helper shared across plugins.
- A structural plugin load-smoke test (`tests/test_plugin_load_smoke.py`)
  enforcing entry-point integrity and self-contained relative imports.
- Plugin stability tiers via `manifest.lacuna.stability` (`stable`,
  `experimental`, `deprecated`); the installer marks non-stable plugins.
  `lacuna.compact-pill` is deprecated (removal targeted for `0.2.0`).
- Distribution scaffolding: `CHANGELOG.md`, `CONTRIBUTING.md`, GitHub
  PR/issue templates, lint config (`.shellcheckrc`, `ruff.toml`,
  `.pre-commit-config.yaml`), and a tag-triggered release workflow.
- Test coverage for the ambience overlays, desktop clock,
  settings-persistence, script pill, and `desktop-app-catalog.py`; CI now
  installs pytest and reports coverage.
- AUR packaging scaffold for `lacuna-omarchy-plugins`, including synchronized
  `.SRCINFO`, package validation, system payload layout, and maintainer docs.

[Unreleased]: https://github.com/jsbrown7/lacuna-omarchy-plugins/compare/HEAD
