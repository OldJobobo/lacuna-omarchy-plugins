# Lacuna Plans And Historical Notes

Status: reference

This folder contains implementation plans, migration outlines, active phase
packets, completed plans, and superseded design notes. The current priority
queue lives in [`../roadmap.md`](../roadmap.md).

## Current Quattro Plans

- [`quattro-p0-core-foundation-plan.md`](quattro-p0-core-foundation-plan.md):
  custom bar/frame compatibility, state, geometry, installation, recovery,
  and core validation.
- [`quattro-p1-product-integration-plan.md`](quattro-p1-product-integration-plan.md):
  native service integration, settings UX, accessibility, multi-surface
  behavior, and media lifecycle.
- [`quattro-p2-release-and-evolution-plan.md`](quattro-p2-release-and-evolution-plan.md):
  compatibility support, diagnostics, release workflow, documentation, and
  bounded structural evolution.

## Current Architecture References

- `../architecture/overview.md`: runtime ownership and plugin composition.
- `../architecture/plugin-contracts.md`: Omarchy entry-point and injection
  contracts.
- `../architecture/omarchy-integration.md`: native services and integration
  policy.
- `../architecture/layer-stacking.md`: layer-shell mapping and stacking rules.
- `../lacuna-design-system/02-geometry.md`: frame, seam, and connector rules.

## Historical Or Superseded Plans

- `lacuna-suite-improvement-plan.md`: superseded broad repository tracker;
  use the Quattro roadmap and phase plans instead.
- `lacuna-bar-refactor-plan.md`: completed custom-bar host decisions.
- `lacuna-bar-size-mode-plan.md`: implemented bar-size mode notes.
- `lacuna-layer-stacking-plan.md`: completed deterministic layer-stack work;
  its rules now live in `docs/architecture/layer-stacking.md`.
- `lacuna-visual-regression-test-plan.md`: historical test-gap closure notes;
  current test work belongs in the P0/P1 plans.
- `omarchy-shell-refactor-plan.md`: historical migration from standalone
  Lacuna to Omarchy plugins.
- `lacuna-panel-ui-overhaul-plan.md`: completed panel transition refactor.
- `lacuna-panel-control-refactor-plan.md`: completed panel controller refactor.
- `lacuna-fake-fullscreen-frame-plan.md`: completed frame-overlay plan.
- `lacuna-settings-panel-plan.md`: completed settings-panel plan.
- `lacuna-theme-preloader-plan.md`: theme-preloader plan.
- `lacuna-workspaces-plugin-plan.md`: workspaces-plugin plan.
- `lacuna-menu-unified-color-model.md`: superseded color-model note.
