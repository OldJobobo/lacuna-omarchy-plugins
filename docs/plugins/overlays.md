# Overlay Plugins

Status: reference

Overlay plugins provide desktop ambience and visual effects. They are separate
from bar widgets and menu surfaces.

## Current Overlay Family

- `lacuna.aurora-drift`
- `lacuna.background-vignette`
- `lacuna.cinematic-light-overlay`
- `lacuna.crt-overlay`
- `lacuna.rainfall-overlay`
- `lacuna.vhs-overlay`
- `lacuna.desktop-clock`

## Runtime Rule

Overlay plugins must load inside Omarchy shell like every other Lacuna plugin.
They must not start a second Quickshell process.

## Desktop Clock

`lacuna.desktop-clock` uses ImageMagick's `magick` command for adaptive
wallpaper contrast sampling. Without it, the clock still renders with theme
colors.
