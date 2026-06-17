# Lacuna Omarchy Plugins

Current suite version: `0.1.0`.

This repository is the Omarchy plugin integration path for Lacuna. It contains
standalone plugin directories that can be installed into
`~/.config/omarchy/plugins/` and loaded by Omarchy shell without starting a
second Quickshell process.

The older standalone Lacuna shell remains a source reference for behavior,
styling, and workflow ideas. New Omarchy work should happen here as plugins.

## Structure

Plugin directories live at the repository root as `lacuna.*` directories. This
is intentional: Omarchy's repo-source installer scans only top-level folders
that contain a `manifest.json`.

- `lacuna.bar/`: Lacuna's Omarchy bar-option host. It owns the Lacuna frame
  surfaces and applies a Lacuna module layout instead of the stock Omarchy bar
  plugin set.
- `lacuna.menu/`, `lacuna.state/`, `lacuna.shell-settings/`, and
  `lacuna.menu-button/`: the core Lacuna sidebar/menu bundle.
- `lacuna.theme/`, `lacuna.wallpaper/`, and `lacuna.theme-preloader/`: theme
  and wallpaper controls plus the optional preview/background helper service.
- `lacuna.*-overlay/`, `lacuna.desktop-clock/`, and
  `lacuna.background-vignette/`: desktop ambience overlays.
- `lacuna.audio/`, `lacuna.network/`, `lacuna.bluetooth/`,
  `lacuna.notifications/`, `lacuna.indicators/`, and other `lacuna.*`
  topbar widgets: a-la-carte bar widgets.
- `lacuna.bar-size-pill/`: Omarchy host bar compact/full toggle.
- `lacuna.compact-pill/`: legacy companion for `lacuna.bar-size-pill`; prefer
  `lacuna.bar-size-pill` for new layouts.
- `shared/qml/simple-bar/`: canonical vendored helper templates for simple
  Lacuna topbar widgets.
- `config/`: example Omarchy shell and Lacuna settings files.
- `docs/`: current project documentation. Plan/tracker material is separated
  under `docs/plans/`.
- `docs/plugin-dependencies.md`: standalone and bundle classification.

## Install

Run the Lacuna installer for a menu-driven setup:

```bash
./scripts/lacuna
```

The first screen offers:

- Full Lacuna install
- Custom install
- Uninstall Lacuna
- Status

Full install stages the safe Lacuna suite disabled, leaving native Omarchy
bar-widget replacements opt-in. Custom install lets you pick groups or
individual standalone plugins, then automatically includes required companions
such as `lacuna.state` and `lacuna.shell-settings`.

Scripted installs are supported too:

```bash
./scripts/lacuna install --profile full
./scripts/lacuna install --profile core
./scripts/lacuna install --profile native --activate
./scripts/lacuna install --profile full --include-replacements
./scripts/lacuna install --plugin lacuna.clock,lacuna.weather
```

Preview any install without changing the system:

```bash
./scripts/lacuna install --profile full --dry-run
```

Update already-installed Lacuna plugins from this checkout:

```bash
./scripts/lacuna update --dry-run
./scripts/lacuna update --yes
./scripts/lacuna update --plugin lacuna.menu,lacuna.state --yes
```

Uninstall is handled by the same helper:

```bash
./scripts/lacuna uninstall --all
./scripts/lacuna uninstall --plugin lacuna.clock,lacuna.weather
./scripts/lacuna uninstall --all --purge-state
```

The installer uses Omarchy's public plugin commands. If you prefer to do the
steps manually, add this repository as a trusted Omarchy plugin source:

```bash
omarchy plugin source add <repo-url> --as lacuna
omarchy plugin available
omarchy plugin add lacuna.clock --from lacuna --enable --yes
```

Bar widgets are placed in `bar.layout`; use `omarchy plugin bar add <id>` or
copy `config/shell.lacuna-native-replacements.example.json` into
`~/.config/omarchy/shell.json` as a starting point. Activating `lacuna.bar`
through the installer applies the Lacuna-owned host layout automatically and
removes stock `omarchy.*` bar modules from that layout. Per-widget bar options belong in `shell.json` through Omarchy
Settings. Lacuna runtime state lives in
`~/.config/omarchy/lacuna/settings.json`, including the global
`colorProfile` setting, `customQuickLaunchApps`, and `preferredApps`. Use
`semantic` for the foreground-first profile or `colorful` to let Lacuna topbar
modules draw from the active Omarchy theme colors.

`config/shell.lacuna-native-replacements.example.json` shows the current
recommended topbar layout with Lacuna replacements for Clock, SystemUpdate,
Weather, NotificationCenter, Indicators, Audio, Network, Bluetooth, and Power.

`lacuna.bar` is a full Omarchy bar option rather than a bar widget. Activate it
with `omarchy plugin bar use lacuna.bar` after staging the core or native
bundle. Reset to the stock Omarchy bar with `omarchy plugin bar reset`.

The Lacuna menu uses a unified color model: normal entries share the active
theme accent, while destructive actions keep the danger/urgent color. See
`docs/lacuna-design-system/01-color.md` for the rationale (part of the
[Lacuna Design Language](docs/lacuna-design-system/)).

`lacuna.bar` is the target owner for Lacuna frame/sidebar choreography. The
`lacuna.menu` plugin remains a compatibility summon target and delegates to the
bar-hosted menu when Lacuna Bar is active. Specialized widgets own their own
interaction animation, while simple topbar widgets use vendored helper
templates under `shared/qml/simple-bar/` to keep hover/color timing consistent
without cross-plugin imports.

The desktop clock uses ImageMagick's `magick` command for adaptive wallpaper
contrast sampling. Without it, the clock still renders with theme colors.

## Development

Run the full local check before publishing changes:

```bash
./scripts/check.sh
```

It validates example JSON, plugin manifests, vendored-file equality, pytest,
and runs `qmllint`/`shellcheck` when those tools are installed. Smoke test
loaded plugins with:

```bash
omarchy plugin list
OMARCHY_PATH="$HOME/.local/share/omarchy" omarchy shell shell toggle lacuna.menu '{}'
hyprctl layers
```

Runtime actions inside Lacuna should use Omarchy commands, for example
`omarchy restart shell`. Do not port standalone Lacuna process controls into
plugins.

## License

Lacuna Omarchy Plugins is released under the MIT License. See `LICENSE`.
