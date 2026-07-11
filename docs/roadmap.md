# Lacuna Quattro Roadmap

Status: active project control (updated 2026-07-10)

This is the canonical roadmap for turning Lacuna into a first-class desktop
enhancement for Omarchy Quattro. It is intentionally narrower than the full
plugin inventory: the priority is a dependable custom shell layer with a
coherent frame, bar, sidebar, state model, and upgrade path.

## Product Position

Lacuna is a custom Omarchy/Quickshell desktop layer. It is not a skin that
must fit inside the stock Omarchy bar.

The defining product decisions are:

- `lacuna.bar` is the intentional custom bar host because Lacuna's full-screen
  frame and sidebar choreography require control the stock bar does not expose.
- Lacuna runs inside Omarchy's single Quickshell process and follows Omarchy's
  plugin, service, IPC, and shell configuration contracts.
- Lacuna owns the frame, sidebar, geometry, visual language, and distinctive
  interaction surfaces.
- Omarchy services remain the preferred source of mature system state and
  orchestration.
- Settings and subsettings are durable product behavior: they must survive
  reloads, restarts, updates, and migrations without changing meaning.

The goal is not to reduce Lacuna to stock Omarchy. The goal is to make the
custom shell boundary deliberate, testable, and safe to evolve.

## Scope

### Core Quattro surface

- `lacuna.bar` and its full-screen frame host
- `lacuna.menu`, `lacuna.state`, and `lacuna.shell-settings`
- sidebar, flyout, seam, connector, and frame geometry
- bar layout persistence and settings normalization
- theme integration and design-system contracts
- native Omarchy service interoperability
- installation, update, recovery, and release compatibility

### Product integration surface

- audio, network, Bluetooth, power, tray, notifications, media, and system
  status widgets
- keyboard, focus, tooltip, and accessible interaction behavior
- multi-monitor sidebar and frame policy
- media-player lifecycle, provider settings, and failure recovery
- curated plugin bundles and user-facing configuration

### Deferred feature work

Optional visual-surface changes are tracked separately and do not block this
roadmap. Existing surfaces remain protected by their current contracts while
the core shell is stabilized.

## Operating Rules

1. Preserve the custom bar and full-screen frame architecture. Improve the
   compatibility boundary instead of replacing the product decision.
2. Preserve the geometry language: square attachment edges, molding
   connectors, one shared curve constant, exposed-corner rounding, and
   fill-only attached shells.
3. Keep `shell.json` as the Omarchy composition interface and Lacuna settings
   as the runtime state interface. Do not create a second competing registry.
4. Prefer Omarchy services for state and commands while allowing Lacuna to
   provide the presentation and interaction model.
5. Any implementation change that affects visible or stateful behavior needs
   a runtime, geometry, or integration test in addition to source contracts.
6. Every release must be recoverable to a known-good shell configuration.

## Delivery Phases

### P0 — Core foundation

Status: complete (validated 2026-07-10)

Make the custom bar/frame shell dependable before adding more surface area.

Deliverables:

- canonical settings and layout-entry schema
- reliable state persistence and migrations
- custom bar compatibility ledger and upgrade checks
- geometry and layer-order acceptance coverage
- explicit multi-monitor policy
- installer preflight, staging, rollback, and stock-bar recovery
- core shell smoke matrix on current Quattro

Plan: [P0 Core Foundation](plans/quattro-p0-core-foundation-plan.md)

### P1 — Product integration

Make the core shell feel complete and native to Omarchy without surrendering
Lacuna's identity.

Deliverables:

- native-service integration matrix
- accessible keyboard and pointer interaction
- settings UI completeness and subsetting round trips
- media lifecycle and provider failure recovery
- clean core/native/advanced bundle boundaries
- menu and settings maintenance boundaries

Plan: [P1 Product Integration](plans/quattro-p1-product-integration-plan.md)

### P2 — Release and evolution

Make the suite easy to maintain, diagnose, upgrade, and extend.

Deliverables:

- Quattro compatibility matrix and release workflow
- diagnostics and plugin health reporting
- generated or checked documentation inventory
- stable version/migration procedures
- optional bundle curation and upgrade notes
- carefully bounded structural cleanup after behavior is covered

Plan: [P2 Release And Evolution](plans/quattro-p2-release-and-evolution-plan.md)

## Cross-Phase Acceptance Gates

The suite is ready for a first-class Quattro release when all of these are
true:

- `./scripts/check.sh` passes with current documentation and manifest state.
- A clean install can activate `lacuna.bar`, the core bundle, and the intended
  layout without manual repair.
- A failed update can restore the previous plugin copies and shell settings.
- The frame, bar, sidebar, and flyouts preserve geometry across bar sizes,
  themes, restarts, and supported monitor layouts.
- Settings and subsettings round-trip through reload, restart, and migration
  tests.
- Native services and Lacuna widgets do not issue competing orchestration or
  duplicate user-visible state.
- Media failures fall back without trapping the shell in a broken state.
- Keyboard, focus, tooltip, and accessible-name checks cover the core shell.
- The support matrix records the tested Omarchy/Quickshell revisions.
- The documentation index, version, manifests, and release notes agree.

## Source Of Truth Map

| Decision | Canonical document |
| --- | --- |
| Product priorities | This roadmap |
| Core execution | [P0 plan](plans/quattro-p0-core-foundation-plan.md) |
| Product integration | [P1 plan](plans/quattro-p1-product-integration-plan.md) |
| Release and maintenance | [P2 plan](plans/quattro-p2-release-and-evolution-plan.md) |
| Runtime boundaries | [Architecture overview](architecture/overview.md) |
| Plugin contracts | [Plugin contracts](architecture/plugin-contracts.md) |
| Omarchy services | [Omarchy integration](architecture/omarchy-integration.md) |
| Geometry | [Lacuna geometry specification](lacuna-design-system/02-geometry.md) |
| Layer order | [Layer stacking policy](architecture/layer-stacking.md) |
| Install/update behavior | [Install and update](install.md) |
| Validation | [Testing](development/testing.md) |
| Historical work | [Plans index](plans/README.md) |

## Current Baseline

- Target environment: Omarchy 4.0.0 alpha/Quattro development builds.
- Runtime model: one long-running Quickshell process with top-level Lacuna
  plugin directories.
- The repository check currently reports 244 passing tests and 2 environment
  skips; rerun the check before using that count for a release decision.
- The working tree contains media-player rebrand work that should be reviewed
  and published separately from core shell stabilization.
