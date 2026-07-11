# Quattro P0 — Core Foundation Plan

Status: complete (validated 2026-07-10)

This plan makes the intentional Lacuna bar/frame architecture dependable on
Omarchy Quattro. It is the prerequisite for the P1 and P2 plans.

## Goal

Users should be able to install, configure, restart, update, and recover the
Lacuna core without losing the full-screen frame, sidebar geometry, layout
settings, or shell usability.

## Non-goals

- Replacing `lacuna.bar` with the stock Omarchy bar.
- Redesigning the Lacuna visual language.
- Adding new topbar features.
- Changing existing optional effect renderers.
- Expanding the media provider feature set.

## Workstream 1 — Baseline and compatibility record

Tasks:

- Record the supported Omarchy and Quickshell revisions.
- Record the Omarchy bar source revision used by `lacuna.bar`.
- Document which copied files are upstream-derived and which are Lacuna-owned.
- Add an upgrade checklist for changes to Omarchy bar injection, sizing,
  orientation, theme, widget registry, and shell configuration APIs.
- Keep the stock bar reset path documented as a recovery operation.

Primary files:

- `lacuna.bar/OmarchyBar.qml`
- `lacuna.bar/OmarchyBarAdapter.qml`
- `lacuna.bar/Bar.qml`
- `lacuna.bar/manifest.json`
- `scripts/sync-vendored`
- `docs/architecture/overview.md`
- `docs/architecture/plugin-contracts.md`

Acceptance:

- A reviewer can identify the upstream base and Lacuna-owned changes without
  comparing an entire file manually.
- A Quattro revision change produces an explicit compatibility result.
- The custom bar remains the selected host after shell restart.

## Workstream 2 — Canonical state and layout schema

Tasks:

- Define one canonical layout-entry shape for menu and state services.
- Preserve JSON-safe metadata instead of dropping unknown valid fields.
- Define behavior for string-form entries: support them consistently or reject
  them explicitly.
- Persist per-style bar layouts in the canonical Lacuna settings state.
- Ensure entries that report `visible: false` can still contribute measurable
  layout geometry when appropriate.
- Keep `shell.json` as Omarchy composition state and
  `~/.config/omarchy/lacuna/settings.json` as Lacuna runtime state.
- Add versioned migration handling for future schema changes.

Primary files:

- `lacuna.state/Service.qml`
- `lacuna.menu/services/LacunaSettings.qml`
- `lacuna.bar/BarModel.js`
- `lacuna.menu/menu/MenuWindow.qml`
- `config/settings.example.json`
- `tests/fixtures/full-settings.json`

Acceptance:

- Menu and state services normalize the same shape.
- Layout and subsettings survive reload, restart, style changes, and migration.
- Rapid updates do not lose the last write.
- Corrupt settings are backed up and replaced with safe defaults.
- Contract tests cover every normalization rule.

## Workstream 3 — Frame, seam, and layer contract

Tasks:

- Keep the attachment edge square and use the documented molding connector.
- Keep the single shared `curveKappa` source.
- Preserve selective exposed-corner rounding and fill-only attached shells.
- Keep frame surfaces mapped according to the layer policy.
- Verify frame occlusion does not paint over the custom bar or sidebar.
- Reconcile the documented layer order with live `hyprctl layers` output.

Primary files:

- `lacuna.menu/components/LacunaGeometry.qml`
- `lacuna.menu/menu/MenuSurface.qml`
- `lacuna.bar/LacunaFrameWindow.qml`
- `lacuna.bar/LacunaFrameBorderWindow.qml`
- `lacuna.bar/Bar.qml`
- `docs/lacuna-design-system/02-geometry.md`
- `docs/architecture/layer-stacking.md`
- `tests/test_qml_contracts.py`
- `tests/test_qml_geometry.py`

Acceptance:

- Geometry tests cover full/compact bar modes, frame modes, connector states,
  flyout attachment, and exposed corners.
- Layer-policy tests cover every frame, bar, sidebar, reserve, and border
  surface.
- A shell restart does not change frame/bar/sidebar stacking behavior.

## Workstream 4 — Multi-monitor policy

Tasks:

- Decide whether the sidebar follows focus, a configured output, or all
  outputs.
- Define frame and reserve behavior for horizontal, vertical, and rotated
  monitors.
- Define behavior when monitors are added, removed, or reordered.
- Record the policy before changing runtime behavior.

Acceptance:

- The policy is documented in architecture docs.
- Geometry tests cover at least one multi-monitor matrix.
- Live smoke confirms the sidebar never opens on an unintended output.

## Workstream 5 — Installer, update, and recovery

Tasks:

- Add dependency preflight before staging or enabling the core bundle.
- Stage changes transactionally and retain the previous working copies.
- Make failed rescan/restart operations recoverable.
- Preserve the prior `shell.json` and Lacuna settings state before updates.
- Verify `lacuna.bar`, required core plugins, and the intended layout as one
  operation.
- Keep `omarchy plugin bar reset` as a documented emergency path.

Primary files:

- `scripts/lacuna`
- `scripts/dev`
- `docs/install.md`
- `tests/test_lacuna_installer.py`
- `tests/test_manifest_contracts.py`

Acceptance:

- Dry-run shows every file and configuration mutation.
- A failed update restores the previous staged state.
- Uninstall does not remove state without explicit user intent.
- Core install and recovery are covered by deterministic installer tests.

## Workstream 6 — P0 validation

Required checks:

```bash
./scripts/check.sh
python3 -m pytest tests/test_qml_contracts.py tests/test_qml_geometry.py
python3 -m pytest tests/test_lacuna_installer.py tests/test_manifest_contracts.py
./scripts/dev deploy lacuna.bar lacuna.menu lacuna.state --dry-run
omarchy plugin list
omarchy-shell shell listPlugins
omarchy-shell shell debugBarGeometry
hyprctl layers
```

P0 is complete when the core shell can be installed, configured, restarted,
updated, and recovered without violating the custom frame/bar contract.

## Completion record

Implemented on 2026-07-10:

- Added the Quattro compatibility ledger and executable compatibility check,
  including the tested Omarchy/Quickshell revision, upstream bar hashes,
  vendored-source ownership, upgrade checklist, and stock-bar recovery path.
- Made the state schema explicitly versioned and migratable, preserved unknown
  JSON-safe metadata, normalized string-form layout entries, and exposed
  per-style bar-layout persistence helpers shared by the menu/state services.
- Recorded the live layer-order reconciliation and added a focused-monitor
  sidebar policy with deterministic fallback across monitor changes.
- Added transactional installer/developer-deploy rollback, runtime state
  snapshots, dependency preflight, core bundle checks, and failure-injection
  coverage.
- Added the read-only `scripts/quattro-p0-smoke` matrix for live plugin,
  geometry, monitor, and layer verification.

Validation completed:

```text
./scripts/check.sh                         244 passed, 2 skipped
scripts/quattro-compatibility --check      compatible
scripts/quattro-p0-smoke                    PASS
live deploy                                 lacuna.bar, lacuna.menu, lacuna.state verified
live focused-output smoke                   sidebar followed focused DP-3
```
