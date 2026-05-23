# Lacuna Omarchy Plugins

This repository is the Omarchy plugin integration path for Lacuna. It contains
standalone plugin directories that can be installed into
`~/.config/omarchy/plugins/` and loaded by Omarchy shell without starting a
second Quickshell process.

The older standalone Lacuna shell remains a source reference for behavior,
styling, and workflow ideas. New Omarchy work should happen here as plugins.

## Structure

- `plugins/omarchy.lacuna-menu/`: Lacuna menu/sidebar plugin, Lacuna settings
  panels, shared components, and menu assets.
- `plugins/omarchy.lacuna-state/`: shared Lacuna runtime settings service.
- `plugins/omarchy.lacuna-shell-settings/`: separate Omarchy shell settings
  service and panel linked from the Lacuna menu.
- `plugins/omarchy.lacuna-menu-button/`: topbar launcher for the Lacuna menu.
- `plugins/omarchy.lacuna-vhs-overlay/`: desktop-layer VHS tracking line
  ambience overlay.
- `plugins/omarchy.lacuna-workspaces/`: original Lacuna numbered workspace
  switcher as an Omarchy bar widget.
- `plugins/omarchy.lacuna-mpris/`: original Lacuna media pill with playback
  text sweep animation.
- `plugins/omarchy.lacuna-desktop-clock/`: desktop-layer Tektur digital clock.
- `plugins/omarchy.lacuna-*-usage/`: Codex and Claude usage bar widgets.
- `plugins/omarchy.lacuna-theme/` and
  `plugins/omarchy.lacuna-wallpaper/`: active Omarchy theme/background widgets.
- `plugins/omarchy.lacuna-clock/`,
  `plugins/omarchy.lacuna-system-update/`,
  `plugins/omarchy.lacuna-weather/`,
  `plugins/omarchy.lacuna-notifications/`,
  `plugins/omarchy.lacuna-indicators/`,
  `plugins/omarchy.lacuna-audio/`,
  `plugins/omarchy.lacuna-network/`,
  `plugins/omarchy.lacuna-bluetooth/`, and
  `plugins/omarchy.lacuna-power/`: Lacuna-native replacements for the selected
  Omarchy topbar controls. These are button-first replacements; rich native
  popups are not embedded in v1. The system tray stays native.
- `plugins/omarchy.lacuna-system-stats/` and
  `plugins/omarchy.lacuna-temperature/`: system status bar widgets.
- `plugins/omarchy.lacuna-bar-size-pill/`: Omarchy host bar compact/full
  toggle backed by Lacuna bar size mode.
- `plugins/omarchy.lacuna-compact-pill/`: legacy Lacuna UI density toggle,
  retained for existing layouts; prefer `omarchy.lacuna-bar-size-pill`.
- `plugins/omarchy.lacuna-settings-persistence/`: service and panel that keep
  selected Omarchy runtime toggles, currently idle locking and nightlight,
  across shell restarts.
- `shared/qml/simple-bar/`: canonical vendored helper templates for simple
  Lacuna topbar widgets.
- `config/`: example Omarchy shell and Lacuna settings files.
- `docs/omarchy-shell-refactor-plan.md`: implementation plan and phase status.

## Install

Symlink plugin directories into Omarchy's plugin directory:

```bash
mkdir -p ~/.config/omarchy/plugins
ln -sfn "$PWD/plugins/omarchy.lacuna-menu" ~/.config/omarchy/plugins/omarchy.lacuna-menu
ln -sfn "$PWD/plugins/omarchy.lacuna-menu-button" ~/.config/omarchy/plugins/omarchy.lacuna-menu-button
ln -sfn "$PWD/plugins/omarchy.lacuna-state" ~/.config/omarchy/plugins/omarchy.lacuna-state
ln -sfn "$PWD/plugins/omarchy.lacuna-shell-settings" ~/.config/omarchy/plugins/omarchy.lacuna-shell-settings
ln -sfn "$PWD/plugins/omarchy.lacuna-bar-size-pill" ~/.config/omarchy/plugins/omarchy.lacuna-bar-size-pill
ln -sfn "$PWD/plugins/omarchy.lacuna-desktop-clock" ~/.config/omarchy/plugins/omarchy.lacuna-desktop-clock
ln -sfn "$PWD/plugins/omarchy.lacuna-vhs-overlay" ~/.config/omarchy/plugins/omarchy.lacuna-vhs-overlay
ln -sfn "$PWD/plugins/omarchy.lacuna-settings-persistence" ~/.config/omarchy/plugins/omarchy.lacuna-settings-persistence
```

For a full Lacuna topbar, also symlink the native replacement widgets:

```bash
for plugin in \
  omarchy.lacuna-system-update omarchy.lacuna-clock omarchy.lacuna-weather \
  omarchy.lacuna-notifications omarchy.lacuna-indicators omarchy.lacuna-audio \
  omarchy.lacuna-network omarchy.lacuna-bluetooth omarchy.lacuna-power
do
  ln -sfn "$PWD/plugins/$plugin" "$HOME/.config/omarchy/plugins/$plugin"
done
```

Enable panel, overlay, and menu plugins in `~/.config/omarchy/shell.json`,
then reload:

```bash
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell rescanPlugins
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-state true
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-shell-settings true
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-desktop-clock true
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-vhs-overlay true
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-settings-persistence true
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell summon omarchy.lacuna-settings-persistence "{}"
omarchy restart shell
```

Bar widgets are placed in `bar.layout`; menu surfaces are enabled in
`plugins`. Per-widget bar options belong in `shell.json` through Omarchy
Settings. Lacuna runtime state lives in
`~/.config/omarchy/lacuna/settings.json`, including the global
`colorProfile` setting, `customQuickLaunchApps`, and `preferredApps`. Use
`semantic` for the foreground-first profile or `colorful` to let Lacuna topbar
modules draw from the active Omarchy theme colors.

`config/shell.lacuna-native-replacements.example.json` shows the current
recommended topbar layout with Lacuna replacements for Clock, SystemUpdate,
Weather, NotificationCenter, Indicators, Audio, Network, Bluetooth, and Power.

The Lacuna menu uses a unified color model: normal entries share the active
theme accent, while destructive actions keep the danger/urgent color. See
`docs/lacuna-menu-unified-color-model.md` for the rationale.

`omarchy.lacuna-menu` owns Lacuna panel motion and sidebar choreography.
Specialized widgets own their own interaction animation, while simple topbar
widgets use vendored helper templates under `shared/qml/simple-bar/` to keep
hover/color timing consistent without cross-plugin imports.

The desktop clock uses ImageMagick's `magick` command for adaptive wallpaper
contrast sampling. Without it, the clock still renders with theme colors.

## Development

Use `qmllint` for changed QML and validate manifests with
`python3 -m json.tool`. Smoke test loaded plugins with:

```bash
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell listPlugins
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell toggle omarchy.lacuna-menu '{}'
hyprctl layers
```

Runtime actions inside Lacuna should use Omarchy commands, for example
`omarchy restart shell`. Do not port standalone Lacuna process controls into
plugins.
