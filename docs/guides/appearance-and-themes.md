# Appearance and themes

Status: user guide for the latest beta

Lacuna follows the active Omarchy theme. It does not impose a brand color:
Omarchy owns hue while Lacuna owns the frame, seams, depth, typography, and
motion.

## Change the theme or wallpaper

Continue using Omarchy's normal theme and wallpaper controls. Lacuna updates its
bar, sidebar, flyouts, frame, and supported widgets from the active palette.

If a theme change leaves one surface stale, wait for the transaction to finish,
then restart the shell:

```bash
omarchy restart shell
```

## Choose a color profile

Open **Lacuna Settings → Appearance** and choose:

- **Semantic** — the default, restrained profile. Non-destructive shell chrome
  shares the current theme accent and foreground hierarchy.
- **Colorful** — lets supported bar widgets use more of the current theme's
  palette for at-a-glance roles. Warning and urgent states still keep their
  semantic meaning.

The menu remains visually unified in either profile.

## Configure the frame

Lacuna Settings controls frame presentation, including whether full-frame
paint, border, shadow, molding pieces, and rounded exposed content corners are
shown. These options affect Lacuna's shell geometry, not the Hyprland client
border configuration.

Change one structural setting at a time, especially on a multi-monitor setup.
True fullscreen applications suppress Lacuna's frame, bars, overlays, input
surfaces, and reserved zones on their output.

## Configure the desktop clock

The desktop clock follows theme colors. If ImageMagick's `magick` command is
available, it can sample the wallpaper for adaptive contrast. Without it, the
clock falls back to theme-derived colors and remains usable.

## Motion and accessibility

Lacuna reveals attached surfaces from their seam rather than making them appear
abruptly. Reduced-motion behavior follows the shell's supported setting path;
do not edit animation internals to disable individual transitions. If motion
appears broken rather than merely unwanted, include the current theme and
Quickshell version in a support report.
