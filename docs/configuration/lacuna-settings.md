# Lacuna Settings

Status: user guide for the latest beta

Open the sidebar and select the gear control to reach Lacuna Settings. Changes
are saved to Lacuna-owned state and survive normal shell reloads and updates.

## Overview

Shows the current Lacuna state and provides routes to the settings areas. Use it
as the first check when a setting appears not to apply.

## Appearance

Controls Lacuna's visual language rather than the active Omarchy theme itself:

- Lacuna, Omarchy, or Material design style;
- semantic or colorful bar profile;
- full-frame presentation;
- frame spacing/presentation behavior;
- theme shortcuts.

Use Omarchy Settings to choose the actual theme and wallpaper.

## Animations

Controls ordered background effects, foreground overlay behavior, effect
intensity/settings, and the background vignette. The active list is front to
back, with item 1 topmost.

See [Desktop ambience](../guides/desktop-ambience.md).

## Layout

Controls supported Lacuna presentation choices, including:

- theme, compact, or full bar sizing;
- sidebar off, full, or rail presentation;
- automatic or selected monitor behavior;
- whether shell settings open as a flyout or window;
- portrait split presentation where exposed.

Use Omarchy Settings for the bar's screen edge and widget composition.

## Media Player

Controls Jellyfin enablement, server/account details, and preferred audio
language. The Media Player surface itself owns YouTube account connection and
playback presentation controls. Credentials remain user-owned and are preserved
by safe reset.

Never include API keys, cookies, or authenticated provider output in a public
issue. See [Media Player](../guides/media-player.md).

## Preferred Apps

Maps common roles such as files, editor, email, and Discord to system defaults
or selected applications. It also supports Lacuna's custom launch entries.

If an application is absent, verify its desktop entry before creating a custom
command.

## Desktop Clock

Controls desktop-clock placement and presentation. Adaptive wallpaper contrast
uses ImageMagick when available and falls back to theme colors otherwise.

## Lacuna Tools

Provides plugin maintenance and menu/runtime behavior. Use the normal
`lacuna-shell` lifecycle commands for package-wide install, update, reset, and
uninstall operations; do not use a maintenance control as a substitute for a
failed installer recovery.

## About

Shows Lacuna and plugin metadata. Use it together with `lacuna-shell status`
when reporting a problem.
