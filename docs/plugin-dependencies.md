# Lacuna Plugin Install Groups

Omarchy installs plugins from trusted sources one plugin at a time. It does not
currently enforce dependency metadata, so Lacuna records install intent in each
manifest under the ignored `lacuna` metadata block and mirrors it here for
users.

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

## Bundle-Only Plugins

These plugins are intentionally not advertised as standalone installs:

- Core menu bundle: `lacuna.state`, `lacuna.shell-settings`, `lacuna.menu`,
  `lacuna.menu-button`.
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

This metadata is for Lacuna tests, docs, and future tooling. Omarchy ignores it
when validating or installing plugins.
