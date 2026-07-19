# Configuration

Status: reference

Lacuna splits Omarchy-visible plugin settings from Lacuna runtime state.

## Omarchy Shell Configuration

Bar-widget options belong in Omarchy's shell config:

```text
~/.config/omarchy/shell.json
```

This host-owned path follows Omarchy's shell contract and remains under
`~/.config` even when `XDG_CONFIG_HOME` points elsewhere. Omarchy Settings
writes plugin bar-widget schema values inline to this file.
Each Lacuna bar widget exposes its user-facing options through its
`manifest.json` schema.

`config/shell.lacuna-native-replacements.example.json` shows the recommended
topbar layout with Lacuna replacements for Clock, SystemUpdate, Weather,
NotificationCenter, Indicators, Audio, Network, Bluetooth, and Power.

Activating `lacuna.bar` through the installer applies the Lacuna-owned host
layout automatically and removes stock `omarchy.*` bar modules from that
layout. It also writes `bar.transparent` as `false`: Lacuna's unified
bar/frame/sidebar surface is intentionally opaque and does not expose the
stock bar's transparency toggle.

## Lacuna Runtime State

Lacuna-owned runtime state honors `XDG_CONFIG_HOME` and lives here:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/settings.json
```

This file stores Lacuna app/runtime state such as:

- `colorProfile`
- `customQuickLaunchApps`
- `preferredApps`
- `mediaPlayer` presentation, quality, and provider-filter preferences
- frame/sidebar preferences
- portrait bar presentation

Portrait split bars are enabled by default:

```json
{
  "barPresentation": {
    "portraitSplit": true
  }
}
```

When enabled, logical portrait outputs with a top or bottom bar redistribute
usage, telemetry, theme, and wallpaper widgets to a companion on the opposite
horizontal edge. Landscape and vertical-edge bars remain single-surface. This
setting never rewrites `shell.json`; set it to `false` to restore a single bar
on every output.

Media Player defaults are:

```json
{
  "mediaPlayer": {
    "presentationMode": "auto",
    "videoQuality": "adaptive",
    "providerFilter": "all"
  }
}
```

Player queue, history, favorites, repeat mode, and volume are stored separately
in `~/.config/omarchy/lacuna/media-player.json`. Version 3 state is migrated to
version 4 on load. See `docs/architecture/media-player.md` for the worker,
search, synchronization, and handoff contracts.

Use `semantic` for the foreground-first color profile or `colorful` to let
Lacuna topbar modules draw from active Omarchy theme colors.

## Theme Ownership

Lacuna uses a unified color model: normal entries share the active theme
accent, while destructive actions keep the danger/urgent color. See
`docs/lacuna-design-system/01-color.md` for the rationale.

The desktop clock uses ImageMagick's `magick` command for adaptive wallpaper
contrast sampling. Without it, the clock still renders with theme colors.
