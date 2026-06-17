# Lacuna Documentation

Status: reference

This directory is split by document intent:

- Current user/project documentation stays at the root of `docs/`.
- Stable architecture references live in `docs/architecture/`.
- Plugin catalog and install grouping lives in `docs/plugins/`.
- Contributor workflow documentation lives in `docs/development/`.
- Design-language specifications live in `docs/lacuna-design-system/`.
- UI reference captures live in `docs/screenshots/reference/`.
- Implementation plans, migration notes, historical trackers, and superseded
  design notes live in `docs/plans/`.

## Reading Paths

For users:

1. [Install And Update](install.md)
2. [Configuration](configuration.md)
3. [Plugin Catalog](plugins/README.md)

For maintainers:

1. [Architecture Overview](architecture/overview.md)
2. [Plugin Contracts](architecture/plugin-contracts.md)
3. [Services And State](architecture/services-and-state.md)
4. [Testing](development/testing.md)
5. [Release Notes](development/release.md)

For design work:

1. [Lacuna Design Language](lacuna-design-system/README.md)
2. [UI Reference Screenshots](screenshots/reference/README.md)

For historical context:

1. [Plans And Historical Notes](plans/README.md)

## Current References

- `install.md`: install, update, uninstall, and manual source workflows.
- `configuration.md`: Omarchy shell settings and Lacuna runtime state.
- `architecture/`: current architecture, plugin contracts, and Omarchy
  integration policy.
- `plugins/`: plugin catalog, install groups, and manifest metadata.
- `development/`: local setup, testing, troubleshooting, and release notes.
- `lacuna-design-system/`: authored Lacuna design language.
- `screenshots/reference/`: live UI reference screenshots and capture notes.

## Plans And Trackers

Use `plans/README.md` as the index for implementation plans and historical
architecture notes. Do not add new `*-plan.md` files to the root `docs/`
directory.
