# Overlay Plugins

Status: reference

Overlay plugins provide desktop ambience and visual effects. They are separate
from bar widgets and menu surfaces.

## Current Overlay Family

- `lacuna.ambience-host` (ordered renderer)
- `lacuna.aurora-drift`
- `lacuna.background-vignette`
- `lacuna.cinematic-light-overlay`
- `lacuna.crt-overlay`
- `lacuna.dust-motes-overlay`
- `lacuna.film-grain-overlay`
- `lacuna.god-rays-overlay`
- `lacuna.rainfall-overlay`
- `lacuna.vhs-overlay`
- `lacuna.desktop-clock`

## Ordered Ambience Rendering

`lacuna.ambience-host` is the real renderer for the eight animated effects.
It keeps fixed Bottom and Overlay surfaces mapped and composes every active
effect as a sibling item. `backgroundEffects.activeEffects` is front to back:
array index 0 (shown as #1 in Settings) is topmost. Reordering changes sibling
`z` values immediately without remapping either layer-shell surface.

The eight legacy effect plugins remain their a-la-carte settings and fallback
surfaces. When the host is enabled in `shell.json`, their own windows are
suppressed; removing the host entry restores standalone rendering. Existing
installs should use `./scripts/lacuna install --profile ambience --activate` so
the installer refreshes installed fallbacks before enabling the host and keeps
their inline settings unchanged.

## Runtime Rule

Overlay plugins must load inside Omarchy shell like every other Lacuna plugin.
They must not start a second Quickshell process. The host is self-contained and
does not import files from sibling installed plugins.

## Desktop Clock

`lacuna.desktop-clock` uses ImageMagick's `magick` command for adaptive
wallpaper contrast sampling. Without it, the clock still renders with theme
colors.
