# Lacuna Plugin Catalog

Status: reference

Omarchy installs plugins from trusted sources one plugin at a time. It does not
currently enforce dependency metadata, so Lacuna records install intent in each
manifest under the ignored `lacuna` metadata block and mirrors it here for
users. The machine-readable release/package inventory is generated from these
manifests at `config/release-inventory.json`; maintainers verify it with
`scripts/release-inventory --check` before building an artifact.

## Plugin Areas

- [Bar Plugins](bar.md)
- [Menu And Sidebar Plugins](menu.md)
- [Widget Plugins](widgets.md)
- [Overlay Plugins](overlays.md)

## Standalone A-La-Carte Plugins

These plugins can be installed individually from the Lacuna source:

- `lacuna.audio`
- `lacuna.aurora-drift`
- `lacuna.background-vignette`
- `lacuna.bar-size-pill`
- `lacuna.bluetooth`
- `lacuna.cinematic-light-overlay`
- `lacuna.claude-usage`
- `lacuna.clock`
- `lacuna.codex-usage`
- `lacuna.crt-overlay`
- `lacuna.desktop-clock`
- `lacuna.idle-inhibitor`
- `lacuna.indicators`
- `lacuna.mpris`
- `lacuna.network`
- `lacuna.nightlight`
- `lacuna.notifications`
- `lacuna.power`
- `lacuna.rainfall-overlay`
- `lacuna.screen-recording`
- `lacuna.script-pill`
- `lacuna.settings-persistence`
- `lacuna.system-stats`
- `lacuna.system-update`
- `lacuna.temperature`
- `lacuna.theme`
- `lacuna.tray`
- `lacuna.vhs-overlay`
- `lacuna.voxtype`
- `lacuna.wallpaper`
- `lacuna.weather`
- `lacuna.workspaces`

`lacuna.theme` and `lacuna.wallpaper` work without companions, but
`lacuna.theme-preloader` is recommended when users want the full Lacuna
theme/background workflow.

## Bar Option Plugins

- `lacuna.bar`: Lacuna's primary Omarchy bar host. It is selected through
  `bar.id` with `omarchy plugin bar use lacuna.bar`, not placed in
  `bar.layout`. The Lacuna installer treats it as the owner of the bar layout
  and strips stock `omarchy.*` bar widgets when applying the Lacuna host layout.

## Reusable Extraction Candidates

These plugins should stay free of unnecessary Lacuna frame/sidebar coupling so
they can later become more universal plugins without changing the first Lacuna
Bar refactor:

- `lacuna.theme`
- `lacuna.wallpaper`
- `lacuna.claude-usage`
- `lacuna.codex-usage`

For the active Lacuna Bar refactor, keep the current plugin IDs and document
the boundary only. Extraction should happen in a later pass after tests prove
the modules do not depend on Lacuna-specific host behavior.

## Bundle-Only Plugins

These plugins are intentionally not advertised as standalone installs:

- Core menu/bar bundle: `lacuna.bar`, `lacuna.state`,
  `lacuna.shell-settings`, `lacuna.menu`, `lacuna.menu-button`.
- Theme helper bundle: `lacuna.theme-preloader` with `lacuna.theme` and
  `lacuna.wallpaper`.
- Legacy compact bundle: `lacuna.compact-pill` with `lacuna.bar-size-pill`.

## Metadata Contract

Every plugin manifest includes:

- `lacuna.standalone`: whether the plugin is user-facing as an a-la-carte
  install.
- `lacuna.bundle`: one of `standalone`, `core`, `theme`, or `legacy`.
- `lacuna.requires`: companion plugins required for the advertised workflow.
- `lacuna.recommends`: optional companions that improve the workflow.
- `lacuna.stability` (optional, default `stable`): see below.
- `lacuna.vendorExclude` (optional): plugin-relative paths whose vendored copy
  intentionally diverges from the canonical source, so `scripts/sync-vendored`
  skips them.

This metadata is for Lacuna tests, docs, and future tooling. Omarchy ignores it
when validating or installing plugins.

## Stability Tiers

`lacuna.stability` marks how settled a plugin is. Absent means `stable`. The
installer appends a `[tier]` marker to non-stable plugins in its menus.

- `stable` (default): supported; safe to depend on.
- `experimental`: a proving ground that may change or be promoted/removed.
  Currently: `lacuna.script-pill` (the script-backed widget experiment path).
- `deprecated`: kept for compatibility, slated for removal. Currently:
  `lacuna.compact-pill` (superseded by `lacuna.bar-size-pill`); planned for
  removal in the `0.2.0` release.
