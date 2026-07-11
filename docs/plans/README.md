# Lacuna Plan Index

Status: current planning ledger (reviewed 2026-07-11)

This is the meta index for every document in `docs/plans/`. It records which
plans are proposed, complete, implemented, reverted, or superseded. The
canonical project priority queue remains the [Quattro roadmap](../roadmap.md);
an entry here does not make a historical plan active again.

## Active Release Tracks

| Plan | State | Role and next boundary |
| --- | --- | --- |
| [Sidebar And Settings Flyout Stability](./sidebar-settings-flyout-stability-plan.md) | Completed and user-verified | Keeps the shared layer-shell surface at a fixed width so settings flyouts cannot squeeze or redraw the persistent sidebar. |
| [Quattro P1 — Product Integration](./quattro-p1-product-integration-plan.md) | In progress; beta product readiness | Close settings, accessibility, media recovery, native integration, and bundle acceptance gates. |
| [Quattro P2 — Release And Evolution](./quattro-p2-release-and-evolution-plan.md) | In progress alongside P1 | Close compatibility, diagnostics, packaging, migration, documentation, beta, and RC gates. |

## Separate Non-Blocking Proposals

These documents are not part of the beta or RC critical path.

| Plan | State | Role and boundary |
| --- | --- | --- |
| [Surface Transition Pipeline Repair](./lacuna-surface-transition-pipeline-plan.md) | Proposed; ready for implementation | Optional interaction/transition work tracked separately from release readiness. |
| [Shell Layout Presets And Agent Orchestration](./lacuna-shell-layout-presets-agent-orchestration-plan.md) | Proposed feature | Built-in per-monitor/workspace layout presets and the first Agent Orchestration shell mode. Not yet represented in runtime settings or QML. |
| [Issue Creation](./lacuna-issue-creation-plan.md) | Draft operations plan | A prepared GitHub issue-creation batch. It is not an implementation phase and should be revalidated before creating external issues. |

## Implemented Or Complete Work

| Plan | State | Current authority |
| --- | --- | --- |
| [Quattro P0 — Core Foundation](./quattro-p0-core-foundation-plan.md) | Complete; validated 2026-07-10 | Foundation checkpoint for settings, geometry, installation, recovery, and validation. |
| [Lacuna Bar Refactor](./lacuna-bar-refactor-plan.md) | Complete | Current custom bar-host composition; living behavior is in source and architecture docs. |
| [Bar Size Mode](./lacuna-bar-size-mode-plan.md) | Implemented | Retained as design notes and a manual smoke checklist. |
| [Fake Fullscreen Frame](./lacuna-fake-fullscreen-frame-plan.md) | Complete | Frame implementation record; current geometry and stacking rules live in architecture/design-system docs. |
| [Layer Stacking](./lacuna-layer-stacking-plan.md) | Complete and live-verified | Historical execution record; [layer-stacking policy](../architecture/layer-stacking.md) is authoritative. |
| [Media Player Rebrand](./lacuna-media-player-rebrand-plan.md) | Implemented | Compatibility and validation record for the canonical Media Player IDs, state migration, and provider settings. |
| [Panel Control Refactor](./lacuna-panel-control-refactor-plan.md) | Complete; superseded | Implemented controller work folded into the later Lacuna Bar architecture. |
| [Panel UI Overhaul](./lacuna-panel-ui-overhaul-plan.md) | Complete; superseded | Implemented transition/host work folded into later refactors. |
| [Settings Panel](./lacuna-settings-panel-plan.md) | Done | Dedicated settings surface is implemented. |
| [Theme Preloader](./lacuna-theme-preloader-plan.md) | Done | Service plugin, scripts, manifests, and tests exist. |
| [Visual Regression Tests](./lacuna-visual-regression-test-plan.md) | Executed | Runtime QML behavior, geometry, and opt-in live visual test layers now exist. |
| [Workspaces Plugin](./lacuna-workspaces-plugin-plan.md) | Done | Lacuna workspace bar widget is implemented. |
| [Background Video Transitions](./lacuna-youtube-video-transition-plan.md) | Implemented | Readiness-gated source swaps, cache/prefetch, failure recovery, and watchdog behavior are present and tested. |

## Reverted Or Superseded Records

| Plan | State | Why it remains |
| --- | --- | --- |
| [Animation Pipeline](./lacuna-animation-pipeline-plan.md) | Fully reverted | Records the rolled-back ambience optimization/consolidation experiment; it is not active work. |
| [Unified Menu Color Model](./lacuna-menu-unified-color-model.md) | Superseded | Canonical color rules moved to the [design-system color specification](../lacuna-design-system/01-color.md). |
| [Noctalia-Inspired Refactor](./lacuna-noctalia-inspired-refactor-plan.md) | Superseded | Its completed checkpoint fed the panel/control and bar refactors. |
| [Suite Improvement Plan](./lacuna-suite-improvement-plan.md) | Superseded historical tracker | Replaced as project control by the roadmap and Quattro phase plans. |
| [Omarchy Shell Refactor](./omarchy-shell-refactor-plan.md) | Superseded | Historical migration from standalone Lacuna to the current plugin-suite architecture. |

## Status Rules

- **Proposed:** decision-complete enough to implement, but its feature is not
  present in the current source.
- **Draft:** requires review or authorization before its external or
  implementation actions are taken.
- **Implemented/complete:** the planned repository behavior exists; live
  deployment must still be repeated after later changes that affect the shell.
- **Superseded:** retained for rationale and history, but not a current source
  of truth.
- **Reverted:** the attempted implementation was deliberately removed and must
  not be inferred as current behavior.

## Current Reference Set

- [Roadmap](../roadmap.md): priority order and Quattro delivery phases.
- [Architecture overview](../architecture/overview.md): runtime ownership and
  plugin composition.
- [Plugin contracts](../architecture/plugin-contracts.md): Omarchy entry-point
  and injection contracts.
- [Omarchy integration](../architecture/omarchy-integration.md): native service
  policy.
- [Layer stacking](../architecture/layer-stacking.md): layer-shell mapping and
  stacking rules.
- [Geometry](../lacuna-design-system/02-geometry.md): frame, seam, connector,
  and attached-flyout rules.

## Release Planning Rule

The suite is already versioned `0.1.0`. The active sequence is
`0.1.0-beta.N` to `0.1.0-rc.N` to `0.1.0`. P1 and P2 are parallel readiness
tracks; neither optional visual work nor unrelated proposed features block
that sequence.
