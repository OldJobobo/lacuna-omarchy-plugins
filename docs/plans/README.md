# Lacuna Plans And Historical Notes

Status: reference

This folder contains documents that are not primary project references:
implementation plans, migration outlines, active trackers, completed plans, and
superseded design notes.


## Current Control Surfaces

- `../roadmap.md`: current project priorities and operating cadence.
- `../issues.md`: GitHub issue grouping, labels, and milestone mapping.

Use this folder for implementation plans and historical notes, not for the
current short priority queue.

## Active Or Recently Canonical Trackers

- `lacuna-suite-improvement-plan.md`: repository improvement tracker and
  backlog.
- `lacuna-bar-refactor-plan.md`: completed Lacuna Bar architecture plan and
  decisions.
- `lacuna-bar-size-mode-plan.md`: implemented bar-size mode notes and smoke
  checklist.
- `lacuna-youtube-video-transition-plan.md`: active plan to speed up
  background-video track transitions and eliminate stuck-black-screen states.
- `lacuna-layer-stacking-plan.md`: completed deterministic layer-stacking
  rework (frame/bar/sidebar/video-cover) and the rules for adding surfaces;
  living policy in `docs/architecture/layer-stacking.md`.
- `lacuna-visual-regression-test-plan.md`: planned test-gap closure for
  visual/UI regressions — runtime QML behavior harness, geometry math tests,
  and opt-in live pixel/stacking probes.
- `lacuna-animation-pipeline-plan.md`: planned ambience-overlay performance
  rework — vsync-aligned frame driving, GPU shader/particle migration, and
  per-monitor ambience host consolidation.

## Completed Or Superseded Plans

- `omarchy-shell-refactor-plan.md`: historical migration plan from standalone
  Lacuna to Omarchy plugin architecture.
- `lacuna-noctalia-inspired-refactor-plan.md`: superseded panel/control and
  motion refactor notes.
- `lacuna-panel-ui-overhaul-plan.md`: completed panel transition refactor.
- `lacuna-panel-control-refactor-plan.md`: completed panel controller refactor.
- `lacuna-fake-fullscreen-frame-plan.md`: completed frame overlay plan.
- `lacuna-settings-panel-plan.md`: completed settings panel plan.
- `lacuna-theme-preloader-plan.md`: theme preloader plan.
- `lacuna-workspaces-plugin-plan.md`: workspaces plugin plan.
- `lacuna-menu-unified-color-model.md`: superseded design note retained as a
  pointer to the current design-system color spec.
