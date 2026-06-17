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
- `docs/`: project documentation, architecture references, plugin catalog,
  design system, screenshots, and historical plans.

## Install

Run the Lacuna installer for a menu-driven setup:

```bash
./scripts/lacuna
```

Common scripted installs:

```bash
./scripts/lacuna install --profile full
./scripts/lacuna install --profile core
./scripts/lacuna install --profile native --activate
```

See [docs/install.md](docs/install.md) for install, update, uninstall, and
manual Omarchy source workflows.

## Development

Run the full local check before publishing changes:

```bash
./scripts/check.sh
```

See [docs/development/testing.md](docs/development/testing.md) for validation
and Omarchy smoke-test commands.

## Documentation

- [docs/README.md](docs/README.md): documentation map and reading paths.
- [docs/architecture/overview.md](docs/architecture/overview.md): current
  architecture.
- [docs/plugins/README.md](docs/plugins/README.md): plugin catalog and install
  grouping.
- [docs/configuration.md](docs/configuration.md): shell and Lacuna runtime
  settings.
- [docs/lacuna-design-system/](docs/lacuna-design-system/): Lacuna design
  language.

## License

Lacuna Omarchy Plugins is released under the MIT License. See `LICENSE`.
