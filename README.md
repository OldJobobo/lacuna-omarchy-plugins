# Lacuna Omarchy Plugins

This repository is the Omarchy plugin integration path for Lacuna. It contains
standalone plugin directories that can be installed into
`~/.config/omarchy/plugins/` and loaded by Omarchy shell without starting a
second Quickshell process.

The older standalone Lacuna shell remains a source reference for behavior,
styling, and workflow ideas. New Omarchy work should happen here as plugins.

## Structure

- `plugins/omarchy.lacuna-menu/`: Lacuna menu/sidebar plugin, settings service,
  shared components, and menu assets.
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
- `plugins/omarchy.lacuna-system-stats/` and
  `plugins/omarchy.lacuna-temperature/`: system status bar widgets.
- `plugins/omarchy.lacuna-compact-pill/`: Lacuna UI density toggle.
- `plugins/omarchy.lacuna-bar-size-pill/`: Omarchy host bar compact/full
  toggle backed by Lacuna bar size mode.
- `config/`: example Omarchy shell and Lacuna settings files.
- `docs/omarchy-shell-refactor-plan.md`: implementation plan and phase status.

## Install

Symlink plugin directories into Omarchy's plugin directory:

```bash
mkdir -p ~/.config/omarchy/plugins
ln -sfn "$PWD/plugins/omarchy.lacuna-menu" ~/.config/omarchy/plugins/omarchy.lacuna-menu
ln -sfn "$PWD/plugins/omarchy.lacuna-menu-button" ~/.config/omarchy/plugins/omarchy.lacuna-menu-button
ln -sfn "$PWD/plugins/omarchy.lacuna-bar-size-pill" ~/.config/omarchy/plugins/omarchy.lacuna-bar-size-pill
ln -sfn "$PWD/plugins/omarchy.lacuna-desktop-clock" ~/.config/omarchy/plugins/omarchy.lacuna-desktop-clock
ln -sfn "$PWD/plugins/omarchy.lacuna-vhs-overlay" ~/.config/omarchy/plugins/omarchy.lacuna-vhs-overlay
```

Enable panel, overlay, and menu plugins in `~/.config/omarchy/shell.json`,
then reload:

```bash
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell rescanPlugins
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-desktop-clock true
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell setPluginEnabled omarchy.lacuna-vhs-overlay true
omarchy restart shell
```

Bar widgets are placed in `bar.layout`; menu surfaces are enabled in
`plugins`. Per-widget bar options belong in `shell.json` through Omarchy
Settings. Lacuna runtime state lives in
`~/.config/omarchy/lacuna/settings.json`, including the global
`colorProfile` setting, `customQuickLaunchApps`, and `preferredApps`. Use
`semantic` for the foreground-first profile or `colorful` to let Lacuna topbar
modules draw from the active Omarchy theme colors.

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
