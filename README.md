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
- `plugins/omarchy.lacuna-*-usage/`: Codex and Claude usage bar widgets.
- `plugins/omarchy.lacuna-theme/` and
  `plugins/omarchy.lacuna-wallpaper/`: active Omarchy theme/background widgets.
- `plugins/omarchy.lacuna-system-stats/` and
  `plugins/omarchy.lacuna-temperature/`: system status bar widgets.
- `plugins/omarchy.lacuna-compact-pill/`: Lacuna UI density toggle.
- `config/`: example Omarchy shell and Lacuna settings files.
- `docs/omarchy-shell-refactor-plan.md`: implementation plan and phase status.

## Install

Symlink plugin directories into Omarchy's plugin directory:

```bash
mkdir -p ~/.config/omarchy/plugins
ln -sfn "$PWD/plugins/omarchy.lacuna-menu" ~/.config/omarchy/plugins/omarchy.lacuna-menu
ln -sfn "$PWD/plugins/omarchy.lacuna-menu-button" ~/.config/omarchy/plugins/omarchy.lacuna-menu-button
```

Enable menu plugins in `~/.config/omarchy/shell.json`, then reload:

```bash
omarchy-shell-ipc shell rescanPlugins
omarchy restart shell
```

Bar widgets are placed in `bar.layout`; menu surfaces are enabled in
`plugins`. Per-widget bar options belong in `shell.json` through Omarchy
Settings. Lacuna runtime state lives in
`~/.config/omarchy/lacuna/settings.json`, including the global
`colorProfile` setting. Use `semantic` for the foreground-first profile or
`colorful` to let Lacuna topbar modules draw from the active Omarchy theme
colors.

## Development

Use `qmllint` for changed QML and validate manifests with
`python3 -m json.tool`. Smoke test loaded plugins with:

```bash
omarchy-shell-ipc shell listPlugins
omarchy-shell-ipc shell toggle omarchy.lacuna-menu '{}'
hyprctl layers
```

Runtime actions inside Lacuna should use Omarchy commands, for example
`omarchy restart shell`. Do not port standalone Lacuna process controls into
plugins.
