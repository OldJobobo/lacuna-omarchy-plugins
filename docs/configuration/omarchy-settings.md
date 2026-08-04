# Omarchy Settings

Status: user guide for the latest beta

Lacuna runs inside Omarchy, so Omarchy remains the authority for host-level
configuration. Lacuna Settings complements it rather than replacing it.

## Appearance

Use **Omarchy Settings → Appearance** for the active theme, wallpaper, and font.
Lacuna follows the resulting palette automatically.

## Windows and monitors

Use **Omarchy Settings → Windows** for gaps, bar placement, and monitor scale.
Lacuna derives its frame and flyout geometry from the resulting output layout.

After a major display-layout change, restart the shell and verify each monitor.

## Plugins and widgets

Use **Omarchy Settings → Plugins** to inspect plugin activation and options.
Bar-widget schemas are stored with Omarchy's shell configuration, so individual
widget choices belong here even when the widget is a Lacuna widget.

The normal installer already applies the curated Lacuna layout. Removing core
Lacuna entries or mixing replacement widgets can produce a valid but
non-canonical setup; make one change at a time.

## System settings

Continue using Omarchy Settings for:

- default applications;
- power profiles and nightlight;
- idle, lock, screensaver, and suspend behavior;
- notifications;
- runtime diagnostics and host configuration files.

Lacuna may present controls for these services, but Omarchy owns the underlying
state and commands.

## Bar transparency

Lacuna's connected bar is intentionally opaque. Activating `lacuna.bar`
normalizes the host transparency setting to false because transparent bar
paint breaks the visual connection with the frame, sidebar, and flyouts. The
stock bar's double-click transparency behavior is not part of Lacuna's bar.

## Avoid competing edits

Do not edit `shell.json` while Omarchy Settings or Lacuna's installer is writing
it. For advanced manual work, close settings surfaces, make a backup, validate
JSON, and restart the shell once.
