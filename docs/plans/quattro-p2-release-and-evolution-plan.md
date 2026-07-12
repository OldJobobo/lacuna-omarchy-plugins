# Quattro P2 — Release And Evolution Plan

Status: in progress; beta/RC release-readiness track (reviewed 2026-07-11)

P2 makes the suite maintainable across Quattro updates and safe to extend
after the core shell and product integration contracts are stable.

## Goal

Turn a working Quattro enhancement into a supportable release: compatibility
is visible, failures are diagnosable, documentation stays accurate, and
structural changes do not silently change user behavior.

## Dependencies

- P0 core foundation complete
- P1 beta scope declared before packaging beta
- P1 complete before entering RC
- No unresolved state-schema ambiguity before entering RC

P2 runs alongside P1. Compatibility checks, diagnostics, packaging, and
release rehearsal should not wait for all product work to finish.

## Progress Summary

| Workstream | Status | Current evidence | Remaining release boundary |
| --- | --- | --- | --- |
| Compatibility | Mostly complete for one target | Executable ledger check, vendored parity, and plugin checks exist. | Declare minimum/current/release-tested targets and record release results. |
| Diagnostics | In progress | `scripts/lacuna status` distinguishes staged/enabled versions. | Add core health, active host, migration, monitor policy, failures, and recovery actions. |
| Release and migration | In progress | Version parity tests, changelog, rollback-capable installer, and tag workflow exist. | Add one bump/rehearsal procedure, inventory, migration notes, and committed-tree archive verification. |
| Documentation consistency | In progress | Canonical roadmap/index and docs contracts exist. | Remove drift and validate release claims/links/commands. |
| Structural evolution | Deferred | Existing behavior tests permit later bounded cleanup. | Not a beta/RC gate unless required to fix a blocker. |
| P2 validation | Pending | Local checks and compatibility pass. | Run beta and RC artifact rehearsals. |

## Workstream 1 — Quattro compatibility matrix

Tasks:

- Record minimum supported, current development, and release-tested Omarchy
  revisions.
- Record the paired Quickshell revision and required system packages.
- Run manifest validation and plugin load smoke against each supported target.
- Run custom-bar injection, geometry, installer, and shell restart checks on
  the current target before publishing.
- Track upstream changes affecting `Bar.qml`, `PluginRegistry`, shell config,
  IPC, services, and widget injection.

Primary files:

- `.github/workflows/check.yml`
- `lacuna.bar/OmarchyBarAdapter.qml`
- `scripts/sync-vendored`
- `docs/development/release.md`
- `docs/architecture/plugin-contracts.md`

Acceptance:

- A release identifies the exact tested Omarchy/Quickshell pair.
- Compatibility failures identify the changed contract.
- Unsupported revisions fail with a useful preflight message.

## Workstream 2 — Diagnostics and health reporting

Tasks:

- Add a suite-level status command or diagnostic view for loaded, disabled,
  failed, and missing plugins.
- Report active bar host, core bundle state, shell configuration source, and
  migration status.
- Report the current frame/sidebar policy and monitor assignment.
- Include redacted media/provider status without exposing credentials.
- Make failure output actionable: plugin, phase, likely cause, and recovery
  command.

Primary files:

- `scripts/lacuna`
- `scripts/dev`
- `docs/development/troubleshooting.md`
- `tests/test_lacuna_installer.py`
- `tests/test_status_scripts.py`

Acceptance:

- A user can distinguish missing, disabled, failed, and stale-installed
  plugins without reading QML logs.
- Diagnostics never print secrets or full command payloads.
- Every reported failure has a documented recovery path.

## Workstream 3 — Release and migration workflow

Tasks:

- Create one version-bump procedure for `VERSION`, manifests, changelog, and
  release notes.
- Generate a release inventory of plugin IDs, kinds, stability, bundle, and
  required companions.
- Add migration notes for settings schema changes and bar-layout changes.
- Verify archives exclude generated files and preserve plugin-relative paths.
- Document upgrade, rollback, stock-bar recovery, and uninstall behavior.

Primary files:

- `VERSION`
- `scripts/lacuna`
- `scripts/release*`
- `docs/development/release.md`
- `README.md`
- `docs/plugins/README.md`

Acceptance:

- Version and manifest checks fail on drift.
- A release archive can be installed from a clean checkout.
- Upgrade notes describe every user-visible state migration.
- Rollback can restore the previous core bar and settings state.

The release workflow may remain in `.github/workflows/release.yml`; a new
`scripts/release*` helper is required only if it removes duplicated or
error-prone manual steps.

## Workstream 4 — Documentation consistency

Tasks:

- Keep `docs/roadmap.md` as the only current priority queue.
- Keep P0, P1, and P2 plans synchronized with roadmap status.
- Mark completed and historical plans clearly.
- Remove stale test counts, statuses, and unsupported installation claims.
- Add documentation contract checks for links, status markers, version claims,
  and current command names.

Acceptance:

- A new contributor can find the roadmap, architecture, install, test, and
  release paths from `docs/README.md`.
- No historical plan presents itself as the current control surface.
- Documentation checks pass in `./scripts/check.sh`.

## Workstream 5 — Bounded structural evolution

Tasks:

- Decompose `MenuWindow.qml` only where behavior tests already describe the
  boundary.
- Reduce duplicated settings and helper code only through explicit sync or
  supported plugin resolution.
- Keep `lacuna.bar` frame ownership separate from feature widgets.
- Centralize repeated diagnostics, migration, and command-result handling.
- Do not change public plugin IDs or settings keys without migration coverage.

Acceptance:

- Structural changes preserve existing runtime behavior.
- Every extracted boundary has a focused contract test.
- Vendored copies remain synchronized or are explicitly documented variants.

## Workstream 6 — P2 validation

Required checks:

```bash
./scripts/check.sh
python3 -m pytest
./scripts/lacuna status
./scripts/lacuna install --dry-run
./scripts/lacuna update --dry-run
omarchy plugin list
omarchy-shell shell listPlugins
omarchy-shell shell listShellConfig
```

P2 is complete when a release can be installed, diagnosed, upgraded, rolled
back, and understood without relying on private project knowledge.

## Promotion Gates

### Beta

- Version set to `0.1.0-beta.1` in `VERSION` and every manifest.
- The normal installer path activates the canonical omakase setup without a
  profile-selection decision.
- Changelog contains beta scope, migrations, known limitations, and supported
  Omarchy/Quickshell versions.
- Archive is built from committed files and its inventory is verified.
- Clean install, restart, failed update rollback, uninstall, and stock-bar
  recovery are recorded.

### Release candidate

- P1 beta blockers and beta feedback are closed or removed from supported
  scope.
- Diagnostics and every recovery action are release-ready.
- `0.1.0-rc.1` archive passes the complete rehearsal without manual repair.
- Only blocker fixes may enter subsequent RC builds.

### Stable

- Promote the verified RC lineage to `0.1.0` without adding features.
- Re-run version parity, archive inventory, checksum, clean install, and smoke
  checks before tagging.
