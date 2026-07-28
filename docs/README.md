# Lacuna Documentation

Status: reference

This directory is split by document intent:

- Current user/project documentation stays at the root of `docs/`.
- Stable architecture references live in `docs/architecture/`.
- Plugin catalog and install grouping lives in `docs/plugins/`.
- Contributor workflow documentation lives in `docs/development/`.
- Design-language specifications live in `docs/lacuna-design-system/`.
- UI reference captures live in `docs/screenshots/reference/`.
- Project roadmap and issue grouping live in `roadmap.md` and `issues.md`.
- Implementation plans, migration notes, historical trackers, and superseded
  design notes live in `docs/plans/`.

## Reading Paths

For users:

1. [Install And Update](./install.md)
2. [Configuration](./configuration.md)
3. [Plugin Catalog](./plugins/README.md)

For maintainers:

1. [Roadmap](./roadmap.md)
2. [Issue Map](./issues.md)
3. [Architecture Overview](./architecture/overview.md)
4. [Plugin Contracts](./architecture/plugin-contracts.md)
5. [Services And State](./architecture/services-and-state.md)
6. [Focus And Input Contract](./architecture/focus-and-input.md)
7. [Performance Ownership And Measurement](./architecture/performance.md)
8. [Quattro Compatibility Ledger](./architecture/quattro-compatibility.md)
9. [Testing](./development/testing.md)
10. [Release Workflow](./development/release.md)

For design work:

1. [Lacuna Design Language](./lacuna-design-system/README.md)
2. [UI Reference Screenshots](./screenshots/reference/README.md)

For historical context:

1. [Plans And Historical Notes](./plans/README.md)

## Current References

- `install.md`: install, update, uninstall, and manual source workflows.
- `configuration.md`: Omarchy shell settings and Lacuna runtime state.
- `roadmap.md`: current project priorities and operating cadence.
- `issues.md`: GitHub issue grouping, labels, and milestone mapping.
- `architecture/`: current architecture, plugin contracts, Omarchy
  integration policy, and the Quattro compatibility ledger.
- `plugins/`: plugin catalog, install groups, and manifest metadata.
- `development/`: local setup, testing, troubleshooting, and release notes.
- `lacuna-design-system/`: authored Lacuna design language.
- `screenshots/reference/`: live UI reference screenshots and capture notes.

## Plans And Trackers

Use `plans/README.md` as the complete lifecycle index. Store plans under
`plans/active/`, `plans/proposed/`, `plans/completed/`, or `plans/archive/`;
do not add `*-plan.md` files directly to `docs/` or `docs/plans/`.
