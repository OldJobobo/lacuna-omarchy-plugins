# Lacuna Plan Index

Status: current planning ledger (reviewed 2026-07-28)

This index covers every document under `docs/plans/`. The canonical project
priority queue remains the [Quattro roadmap](../roadmap.md); placement here
records lifecycle, not priority.

## Directory Layout

| Directory | Meaning |
| --- | --- |
| [`active/`](./active/) | Work that is in progress or waiting on a release gate. |
| [`proposed/`](./proposed/) | Approved proposals and drafts that are not on the beta/RC critical path. |
| [`completed/`](./completed/) | Implemented or validated records retained for rationale and acceptance evidence. |
| [`archive/`](./archive/) | Reverted or superseded plans that are no longer authoritative. |

Use only lifecycle for directory placement. Product area, release phase, and
feature type belong in the index description rather than additional folder
axes.

## Active

| Plan | State | Next boundary |
| --- | --- | --- |
| [Quattro P1 — Product Integration](./active/quattro-p1-product-integration-plan.md) | In progress | Close native ownership, settings, focus safety, media recovery, and canonical omakase behavior. |
| [Quattro P1 Closeout Execution](./active/quattro-p1-closeout-execution-plan.md) | Ready after decision checkpoint | Execute the ordered P1 closeout with review, live deployment, and packaged Beta Exit evidence. |
| [Quattro P2 — Release And Evolution](./active/quattro-p2-release-and-evolution-plan.md) | In progress alongside P1 | Complete support declarations, diagnostics, migration, documentation, beta, and RC gates. |
| [Reliability And Optimization](./active/lacuna-reliability-and-optimization-plan.md) | Phases 0–6 complete; Phase 7 next | Perform bounded structural cleanup without replacing the Quattro roadmap. |
| [AUR Publication Readiness](./active/aur-publication-readiness-plan.md) | Tooling validated; beta publication pending | Publish only after the immutable GitHub artifact and lifecycle gates pass. |

## Proposed And Draft

These plans do not block beta or RC.

| Plan | State | Boundary |
| --- | --- | --- |
| [Surface Transition Pipeline Repair](./proposed/lacuna-surface-transition-pipeline-plan.md) | Proposed; ready | Optional interaction and transition repair. |
| [Portrait Split Bar](./proposed/lacuna-portrait-split-bar-plan.md) | Proposed; ready | Portrait-only companion bar using the canonical Omarchy layout. |
| [Shell Layout Presets And Agent Orchestration](./proposed/lacuna-shell-layout-presets-agent-orchestration-plan.md) | Proposed | Per-monitor/workspace presets and Agent Orchestration mode. |
| [Issue Creation](./proposed/lacuna-issue-creation-plan.md) | Draft | Revalidate and authorize before creating external issues. |

## Completed

| Plan | State | Current authority |
| --- | --- | --- |
| [Quattro P0 — Core Foundation](./completed/quattro-p0-core-foundation-plan.md) | Complete; validated | Foundation checkpoint; current behavior lives in architecture and runtime docs. |
| [Sidebar And Settings Flyout Stability](./completed/sidebar-settings-flyout-stability-plan.md) | Completed and user-verified | Fixed-width shared layer-shell surface contract. |
| [Lacuna Bar Refactor](./completed/lacuna-bar-refactor-plan.md) | Complete | Current custom bar-host composition. |
| [Bar Size Mode](./completed/lacuna-bar-size-mode-plan.md) | Implemented | Design notes and manual smoke checklist. |
| [Clock And Calendar Flyout](./completed/lacuna-clock-calendar-flyout-plan.md) | Implemented and live-verified 2026-07-13 | Adaptive face and read-only calendar behavior. |
| [Fake Fullscreen Frame](./completed/lacuna-fake-fullscreen-frame-plan.md) | Complete | Geometry history; use the current geometry and stacking specifications. |
| [Layer Stacking](./completed/lacuna-layer-stacking-plan.md) | Complete and live-verified | Use the [layer-stacking policy](../architecture/layer-stacking.md) for current behavior. |
| [Media Player Rebrand](./completed/lacuna-media-player-rebrand-plan.md) | Implemented | Canonical IDs, migration, and provider-settings record. |
| [Settings Panel](./completed/lacuna-settings-panel-plan.md) | Done | Dedicated settings surface. |
| [Theme Preloader](./completed/lacuna-theme-preloader-plan.md) | Done | Service, scripts, manifests, and tests. |
| [Visual Regression Tests](./completed/lacuna-visual-regression-test-plan.md) | Executed | Runtime behavior, geometry, and opt-in live visual coverage. |
| [Weather Flyout](./completed/lacuna-weather-flyout-plan.md) | Implemented and live-verified 2026-07-13 | Conditions, forecast, shared state, and attached geometry. |
| [Workspaces Plugin](./completed/lacuna-workspaces-plugin-plan.md) | Done | Lacuna workspace bar widget. |
| [Background Video Transitions](./completed/lacuna-youtube-video-transition-plan.md) | Implemented | Source-swap, cache, recovery, and watchdog lifecycle record. |

## Archive

These files explain past decisions but are not current implementation authority.

| Plan | State | Why retained |
| --- | --- | --- |
| [Animation Pipeline](./archive/lacuna-animation-pipeline-plan.md) | Fully reverted | Records the rolled-back ambience optimization experiment. |
| [Unified Menu Color Model](./archive/lacuna-menu-unified-color-model.md) | Superseded | Canonical rules moved to the [color specification](../lacuna-design-system/01-color.md). |
| [Noctalia-Inspired Refactor](./archive/lacuna-noctalia-inspired-refactor-plan.md) | Superseded | Fed later panel, control, and bar work. |
| [Panel Control Refactor](./archive/lacuna-panel-control-refactor-plan.md) | Complete; superseded | Folded into the Lacuna Bar architecture. |
| [Panel UI Overhaul](./archive/lacuna-panel-ui-overhaul-plan.md) | Complete; superseded | Folded into later refactors. |
| [Suite Improvement Plan](./archive/lacuna-suite-improvement-plan.md) | Superseded tracker | Replaced by the roadmap and Quattro plans. |
| [Omarchy Shell Refactor](./archive/omarchy-shell-refactor-plan.md) | Superseded | Historical migration into the current plugin suite. |

## Status Rules

- **Active:** implementation or release-gate work remains.
- **Proposed:** decision-complete enough to consider, but not current priority.
- **Draft:** requires review or authorization before action.
- **Completed:** planned behavior exists; current contracts may live elsewhere.
- **Archived:** reverted or superseded and never a current source of truth.

When a plan changes lifecycle, move it, update this index and inbound links, and
run `python3 -m pytest tests/test_docs_contracts.py` plus `git diff --check`.

## Current Reference Set

- [Roadmap](../roadmap.md): project priorities and release sequence.
- [Architecture overview](../architecture/overview.md): runtime ownership.
- [Plugin contracts](../architecture/plugin-contracts.md): entry points and injection.
- [Omarchy integration](../architecture/omarchy-integration.md): native service policy.
- [Layer stacking](../architecture/layer-stacking.md): layer-shell mapping rules.
- [Geometry](../lacuna-design-system/02-geometry.md): frame, seam, and connector rules.
