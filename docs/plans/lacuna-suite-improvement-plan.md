# Lacuna Suite Improvement Plan

Status: active implementation tracker (updated 2026-06-14)

This document started as a full-repository review plan for making Lacuna a
first-class Omarchy Quickshell plugin suite. It is now the canonical progress
tracker for that improvement pass: completed items are recorded with the files
or checks that enforce them, and remaining work is listed as a concrete
backlog.

Current validation baseline:

- `./scripts/check.sh` passes.
- Current full suite result: 86 Python tests passing.
- The check script validates example JSON, plugin manifests, vendored-file
  equality, optional `qmllint`/`shellcheck`, and the Python tests.

## Phase Status

| Phase | Status | Notes |
| --- | --- | --- |
| Phase 1: Stop the bleeding | Done | Drift, retry loops, license, CI, and vendored-file checks are implemented. |
| Phase 2: State and command correctness | Mostly done | Main state pipeline, command queue, installer hygiene, and nightlight detection are fixed. A few smaller correctness items remain. |
| Phase 3: Performance | Partly done | Login-shell I/O and system-stats spawn pressure are reduced. Polling and settings refresh cost still need follow-up. |
| Phase 4: Architecture | Open | Sync tooling controls duplication, but structural decomposition and multi-monitor behavior remain backlog. |
| Phase 5: Distribution, versioning, docs | Mostly done | Suite version, update command, CI coverage, manifest checks, and docs status markers exist. Release bump workflow remains. |

Architecture update 2026-06-14: the Lacuna Bar host refactor checklist is
complete. `lacuna.bar` is the dedicated bar option host, `lacuna.menu`
delegates to the hosted menu when available, installer activation preserves the
Lacuna host layout contract, and frame/flyout geometry rules are covered by
tests.

## Completed Work

### Phase 1: Stop The Bleeding

#### 1.1 Re-sync the drifted settings window

Status: done.

The canonical `lacuna.shell-settings/settings/OmarchyShellSettingsWindow.qml`
copy now syncs to `lacuna.menu/settings/OmarchyShellSettingsWindow.qml`.
Tone-aware shell accent handling is preserved in both copies.

Acceptance:

- `scripts/sync-vendored --check` passes.
- `tests/test_vendored_files.py` catches future drift.

#### 1.2 Add a vendored-file equality test

Status: done.

Implemented `scripts/sync-vendored` and wired it into `scripts/check.sh`.
Vendored equality now covers:

- `shared/qml/simple-bar/ColorProfile.qml` to simple widget copies, with
  intentional richer variants excluded.
- `shared/qml/simple-bar/MotionTokens.qml` to simple widget copies, with
  intentional richer variants excluded.
- `lacuna.shell-settings/settings/*` to `lacuna.menu/settings/*`.
- `lacuna.shell-settings/components/*` to `lacuna.menu/components/*`.
- `lacuna.shell-settings/Service.qml` to
  `lacuna.menu/services/OmarchyShellSettingsService.qml`.
- `lacuna.shell-settings/CommandRunner.qml` to
  `lacuna.menu/services/CommandRunner.qml`.
- `lacuna.shell-settings/scripts/omarchy-shell-settings-state.py` to
  `lacuna.menu/scripts/omarchy-shell-settings-state.py`.
- `lacuna.state/Service.qml` to `lacuna.menu/services/LacunaSettings.qml`.

Acceptance:

- `scripts/sync-vendored --check` passes.
- A deliberate edit to one side of a vendored pair fails `./scripts/check.sh`.

#### 1.3 Fix permanent optional-file retry loops

Status: done for the originally identified targets.

Optional missing settings/theme files now fall back to defaults instead of
spinning on unconditional `retry.restart()` loops in the simple color profile,
menu theme service, and theme widget paths.

Acceptance:

- `tests/test_qml_contracts.py` pins the no-login-shell and FileView contracts
  touched by this work.
- Remaining unrelated retry behavior, such as desktop-clock theme retry, is
  outside the original target list and should be judged separately if it causes
  real runtime cost.

#### 1.4 Add a license

Status: done.

`LICENSE` exists at the repository root and `README.md` references it.

#### 1.5 Add CI

Status: done.

`.github/workflows/check.yml` runs `./scripts/check.sh` on push and pull
request. `scripts/check.sh` includes manifest JSON validation, config JSON
validation, vendored equality, Python tests, optional QML lint, and optional
shell lint.

## Phase 2: State And Command Correctness

### 2.1 `lacuna.state` save pipeline and `LacunaSettings.qml`

Status: implemented; manual Omarchy smoke still recommended.

Implemented:

- Replaced load/save shell processes with `FileView.reload()`,
  `FileView.text()`, and `FileView.setText()`.
- Enabled `atomicWrites: true`.
- Added a last-writer-wins queued payload path for writes while a write is in
  progress.
- Added suppression for self-triggered FileView reloads.
- Added explicit quick-launch touch tracking so an intentional empty quick
  launch list is not resurrected by the pre-load pending-save merge.
- Kept `lacuna.state/Service.qml` and
  `lacuna.menu/services/LacunaSettings.qml` byte-synced through vendored
  tooling.

Acceptance:

- `tests/test_qml_contracts.py::test_lacuna_settings_uses_fileview_for_load_save`
  pins the FileView path.
- `tests/test_qml_contracts.py::test_lacuna_settings_has_pending_save_merge_for_quick_launch_state`
  pins the quick-launch touch guard.

Manual smoke still needed before release:

- Rapidly toggle multiple Lacuna menu settings.
- Confirm no lost writes in `~/.config/omarchy/lacuna/settings.json`.
- Confirm no visible reload flicker after writes.

### 2.2 CommandRunner queue blocking

Status: done.

Implemented:

- Terminal commands beginning with `foot ` or `xdg-terminal-exec ` are
  detached with `setsid -f`, so they do not block later menu commands.
- Non-terminal commands use `bash -c`, not `bash -lc`.
- Failure notification delivery is queued so a second failure is not dropped
  while `notify-send` is still running.
- Command payloads are no longer logged on command failure.

Acceptance:

- `tests/test_qml_contracts.py::test_command_runners_do_not_log_successful_command_payloads`
  pins the failure queue and redacted logging shape.
- Manual smoke: launch a terminal from the menu, then immediately trigger a
  second menu command. The second command should run without waiting for the
  terminal to close.

### 2.3 Installer semantics and hygiene

Status: done.

Implemented in `scripts/lacuna`:

- CLI `uninstall` with no `--all` or `--plugin` now refuses implicit removal.
- Interactive uninstall still offers the picker.
- Backup pruning keeps the latest two backups per plugin by default.
- Staging ignores `__pycache__`.

Acceptance:

- `tests/test_lacuna_installer.py::test_uninstall_requires_all_or_plugin_selection`
- `tests/test_lacuna_installer.py::test_prune_backups_keeps_latest_two_per_plugin`
- `tests/test_lacuna_installer.py::test_stage_plugin_ignores_pycache_directories`

### 2.4 Smaller correctness items

Status: partial.

Done:

- Nightlight detection now treats observed temperatures below 5000K as on and
  preserves observed warm/neutral temperatures where possible.
- `CommandRunner` failure logging no longer prints the command payload.
- `LacunaFrameReserveWindow` appends the edge name to its base layer namespace,
  so the four frame reserve windows resolve to unique Wayland layer
  namespaces even when `MenuWindow.qml` passes the same frame-reserve base.
- `BarSizeMode.qml`'s `theme` branch is reachable again: settings
  normalization accepts `theme`, the menu segment exposes it, and the helper
  script restores the snapshotted theme bar size.

Open:

- No smaller correctness items are currently open in this phase.

## Phase 3: Performance

### 3.1 Replace noninteractive `bash -lc` spawns

Status: mostly done.

Done:

- `lacuna.system-stats/Widget.qml` reads `/proc/stat` and `/proc/meminfo`
  through FileView and runs `df -P /` directly.
- `lacuna.state/Service.qml` and `LacunaSettings.qml` load/save through
  FileView.
- `lacuna.menu/services/LacunaMenuState.qml` persists `menu.state` through
  FileView.
- Noninteractive QML process paths use `bash -c` or direct argv.

Intentional exception:

- Interactive terminal sessions in `lacuna.menu/menu/MenuCommandCatalog.qml`
  and `lacuna.shell-settings/Panel.qml` still use `bash -lc` so terminal
  sessions match normal user shell/profile setup. The code comments document
  this exception.

Acceptance:

- `tests/test_qml_contracts.py::test_qml_processes_do_not_use_noninteractive_login_shells`
- `tests/test_qml_contracts.py::test_lacuna_menu_state_uses_fileview_for_load_save`
- `tests/test_qml_contracts.py::test_topbar_tooltip_targets_expose_hover_state`

### 3.2 `lacuna.settings-persistence` polling

Status: open.

Current behavior still polls managed idle/nightlight status every 3 seconds
after restore completes. Reduce the settled interval to 30-60 seconds or
replace polling with watchers on Omarchy toggle state files.

Acceptance:

- After restore completes, no 3-second steady-state polling remains.
- Idle and nightlight state still self-heal after external changes.

### 3.3 `omarchy-shell-settings-state.py` refresh cost

Status: partial.

Done:

- The state script uses direct `subprocess.run` capture and no longer shells
  through `bash -lc` plus tempfile redirection.

Open:

- Independent probes are still serial.
- QML still requests broad refreshes after settings actions.

Acceptance for completion:

- Measure before/after with `time python3 lacuna.shell-settings/scripts/omarchy-shell-settings-state.py`.
- Either parallelize independent probes or add domain-scoped refresh requests
  so common actions do not refresh the full matrix unnecessarily.

### 3.4 Overlay timers

Status: intentionally deferred.

CRT and VHS timers are gated on `effectVisible`. Do not rewrite them without a
profiling signal. If profiling shows QML-thread churn, move noise/jitter to
shader time uniforms or `FrameAnimation`.

## Phase 4: Architecture

### 4.1 Decide the core-bundle duplication strategy

Status: minimum complete; structural decision still open.

Done:

- Vendored sync tooling and CI equality checks make the current duplication
  safe enough to maintain.

Open:

- Investigate whether the settings UI can live only in
  `lacuna.shell-settings` and be embedded or opened by `lacuna.menu` through
  plugin-service resolution. If the Omarchy plugin loader does not permit
  that, document the limitation in `docs/plugin-dependencies.md`.

Acceptance:

- Either remove the duplicated settings UI, or record why duplication remains
  required and keep it under `scripts/sync-vendored`.

### 4.2 Decompose `MenuWindow.qml`

Status: open.

Recommended extractions:

- `RestartConfirmDialog.qml` for the inline restart confirmation overlay.
- Action dispatch module or table for sidebar/settings/quick-access action
  routing.
- A `lacunaSettings.update(patchFn)` helper to reduce repeated
  normalize/mutate/save blocks.

Acceptance:

- No behavior change.
- Existing QML contract tests updated for moved signatures.
- Menu restart confirmation, shell settings actions, and quick-launch actions
  still smoke-test correctly.

### 4.3 Multi-monitor sidebar

Status: open.

The menu still needs a deliberate multi-monitor design. The previous finding
was that the sidebar was pinned to the first screen while overlays already
model all screens. Spec before implementation.

Acceptance:

- A short dedicated spec records whether Lacuna follows the focused monitor,
  a configured monitor, or both.
- Implementation survives shell restart and monitor changes without opening
  the sidebar on the wrong display.

### 4.4 Small structural cleanups

Status: open/low priority.

Backlog:

- Promote repeated QML `quote()` helpers only if duplication keeps growing.
- Name or document magic timing constants where local context does not explain
  what the delay synchronizes with.
- Keep the BarSizeMode live-theme rewrite contract documented in
  `docs/plans/lacuna-bar-size-mode-plan.md` or README as the implementation evolves.

## Phase 5: Distribution, Versioning, Docs

### 5.1 Suite versioning and an `update` command

Status: mostly done.

Done:

- Root `VERSION` exists.
- Manifest versions are checked against root `VERSION`.
- `status` reports staged/enabled state and installed vs repo version.
- `./scripts/lacuna update` restages installed plugins whose source differs
  from the installed copy, prunes backups, and rescans once.
- `README.md` documents the update command.

Open:

- Add a release/version bump workflow that updates root `VERSION`, manifests,
  and any release notes in one command or documented procedure.

Acceptance:

- `tests/test_manifest_contracts.py::test_manifest_versions_match_suite_version`
- `tests/test_lacuna_installer.py::test_status_reports_staged_vs_enabled_plugins`
- `tests/test_lacuna_installer.py::test_update_dry_run_lists_only_changed_installed_plugins`

### 5.2 `check.sh` coverage

Status: done.

Implemented:

- All `config/*.json` examples are validated.
- All plugin manifests are JSON-validated.
- Manifest contract tests enforce required entry points per kind, valid Lacuna
  bundle metadata, real `requires`/`recommends` plugin IDs, and suite-version
  consistency.

Acceptance:

- `scripts/check.sh`
- `tests/test_manifest_contracts.py`

### 5.3 Docs refresh

Status: done.

Implemented:

- `AGENTS.md` now points at `./scripts/check.sh` and `python3 -m pytest`.
- Every top-level doc under `docs/*.md` has a `Status:` marker in the opening
  lines.
- `status` reports staged vs enabled plugin state instead of only directory
  presence.

Acceptance:

- `tests/test_docs_contracts.py`
- `tests/test_lacuna_installer.py::test_status_reports_staged_vs_enabled_plugins`

## Remaining Backlog

Priority order:

1. Manual smoke-test the new FileView settings save path inside Omarchy shell.
2. Reduce settled polling in `lacuna.settings-persistence/Service.qml`.
3. Reduce `omarchy-shell-settings-state.py` refresh latency through scoped or
   parallel probes.
4. Decide whether settings UI duplication can be structurally removed.
5. Decompose `MenuWindow.qml` without behavior changes.
6. Spec and implement multi-monitor sidebar behavior.
7. Add a release/version bump workflow.

## Explicitly Out Of Scope

- Rewriting the regex-based TOML parsing in `Theme.qml` and
  `BarSizeMode.qml`. It is pragmatic and working; revisit only if Omarchy
  theme files grow syntax it mishandles.
- Removing intentional ColorProfile variants for mpris, workspaces, theme, or
  wallpaper. These are recorded as exclusions in the vendored-file tooling.
- Replacing string-contract tests wholesale. They are brittle by design, but
  cheap and effective for this QML-heavy plugin suite.

## Completion Criteria

The improvement pass is release-ready when:

- `./scripts/check.sh` passes.
- Manual Omarchy smoke covers the settings save path, command runner terminal
  detach behavior, update command, and core menu open/close flows.
- The Phase 2.4 and Phase 3.2/3.3 open items are either implemented or
  explicitly deferred with rationale.
- Phase 4 has either a structural implementation or a documented decision to
  keep duplication under sync tooling.
- The release/version bump workflow is documented or scripted.
