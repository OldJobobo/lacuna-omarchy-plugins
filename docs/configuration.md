# Configuration

Status: reference

Lacuna splits Omarchy-visible plugin settings from Lacuna runtime state.

## Omarchy Shell Configuration

Bar-widget options belong in Omarchy's shell config:

```text
~/.config/omarchy/shell.json
```

Omarchy Settings writes plugin bar-widget schema values inline to this file.
Each Lacuna bar widget exposes its user-facing options through its
`manifest.json` schema.

`config/shell.lacuna-native-replacements.example.json` shows the recommended
topbar layout with Lacuna replacements for Clock, SystemUpdate, Weather,
NotificationCenter, Indicators, Audio, Network, Bluetooth, and Power.

Activating `lacuna.bar` through the installer applies the Lacuna-owned host
layout automatically and removes stock `omarchy.*` bar modules from that
layout.

## Lacuna Runtime State

Lacuna runtime state lives here:

```text
~/.config/omarchy/lacuna/settings.json
```

This file stores Lacuna app/runtime state such as:

- `colorProfile`
- `customQuickLaunchApps`
- `preferredApps`
- frame/sidebar preferences

Use `semantic` for the foreground-first color profile or `colorful` to let
Lacuna topbar modules draw from active Omarchy theme colors.

## Theme Ownership

Lacuna uses a unified color model: normal entries share the active theme
accent, while destructive actions keep the danger/urgent color. See
`docs/lacuna-design-system/01-color.md` for the rationale.

The desktop clock uses ImageMagick's `magick` command for adaptive wallpaper
contrast sampling. Without it, the clock still renders with theme colors.
