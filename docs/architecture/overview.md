# Architecture Overview

Status: reference

This repository is Lacuna's Omarchy plugin integration path. It contains
standalone plugin directories that load inside Omarchy shell without starting a
second Quickshell process.

The older standalone Lacuna shell remains a source reference for behavior,
styling, and workflow ideas. New Omarchy work should happen here as plugins.
The tested Quattro host revision and upgrade checklist live in
[`quattro-compatibility.md`](quattro-compatibility.md).

## Runtime Shape

- `lacuna.bar` is Lacuna's Omarchy bar-option host. It owns the Lacuna frame
  surfaces and applies a Lacuna module layout instead of the stock Omarchy bar
  plugin set.
- `lacuna.menu`, `lacuna.state`, `lacuna.shell-settings`, and
  `lacuna.menu-button` are the core Lacuna sidebar/menu bundle.
- `lacuna.theme`, `lacuna.wallpaper`, and `lacuna.theme-preloader` provide
  theme and wallpaper controls plus the optional preview/background helper
  service.
- `lacuna.*-overlay`, `lacuna.desktop-clock`, and
  `lacuna.background-vignette` provide desktop ambience overlays.
- `lacuna.audio`, `lacuna.network`, `lacuna.bluetooth`,
  `lacuna.notifications`, `lacuna.indicators`, and other `lacuna.*` topbar
  widgets are a-la-carte bar widgets.
- `lacuna.bar-size-pill` is the Omarchy host bar compact/full toggle.
- `lacuna.compact-pill` is the legacy companion for `lacuna.bar-size-pill`;
  prefer `lacuna.bar-size-pill` for new layouts.

## Ownership Rules

- `lacuna.bar` is the target owner for Lacuna frame/sidebar choreography.
- `lacuna.menu` remains a compatibility summon target and delegates to the
  bar-hosted menu when Lacuna Bar is active.
- Specialized widgets own their own interaction animation.
- Simple topbar widgets use vendored helper templates under
  `shared/qml/simple-bar/` to keep hover/color timing consistent without
  cross-plugin imports.
- Runtime actions inside Lacuna should use Omarchy commands, for example
  `omarchy restart shell`. Do not port standalone Lacuna process controls into
  plugins.
