# Repository Guidelines

## Project Structure & Module Organization

This repository is the Omarchy plugin target for Lacuna, with the standalone Lacuna project treated as the source reference. The current structure is intentionally small:

- `docs/`: current project documentation, design-system specs, screenshots, and reference docs.
- `docs/plans/`: implementation plans, migration notes, historical trackers, and superseded design notes.
- `lacuna.*/`: one top-level Omarchy plugin directory per Lacuna surface or widget. This flattened layout is required for `omarchy plugin source add` repo installs.
- `lacuna.menu/`: menu/sidebar plugin, with `menu/`, `components/`, `services/`, and `assets/`.
- `config/`: example configuration should live here, such as `settings.example.json`.

Keep plugin code self-contained under its plugin directory. Do not depend on the repository root as a runtime import path.

## Build, Test, and Development Commands

Use the repository check script for local validation:

- `./scripts/check.sh`: validate example JSON, manifests, vendored-file equality, optional `qmllint`/`shellcheck`, and the Python test suite.
- `python3 -m pytest`: run the test suite directly.
- `rg --files`: list tracked source-like files quickly.
- `find . -maxdepth 2 -path './lacuna.*' -print`: inspect plugin layout.
- `omarchy plugin rescan`: ask Omarchy shell to reload installed plugins.
- `OMARCHY_PATH="$HOME/.local/share/omarchy" omarchy-shell shell summon lacuna.menu "{}"`: smoke-test the menu plugin once implemented.

For local testing, copy or symlink a plugin directory into `~/.config/omarchy/plugins/<plugin-id>/`, then rescan or restart Omarchy shell. No plugin should start a second Quickshell process.

## Coding Style & Naming Conventions

Use QML for plugin entry points and keep roots compatible with Omarchy plugin contracts: bar widgets expose an `Item`; menu/panel surfaces implement `open(payloadJson)` and `close()`. Name plugin directories with full IDs, for example `lacuna.script-pill`. Prefer `Widget.qml` for bar-widget entry points and `Menu.qml` for the menu entry point.

Use 2-space indentation for JSON and QML unless a copied source file already has a consistent style. Store bar-widget user options in the plugin manifest schema so Omarchy Settings writes them inline to `~/.config/omarchy/shell.json`. Keep `~/.config/omarchy/lacuna/settings.json` for Lacuna runtime/app state only.

## Flyout Surface Geometry

The authoritative spec for Lacuna's seam/connector geometry is
[`docs/lacuna-design-system/02-geometry.md`](docs/lacuna-design-system/02-geometry.md).
Read it before touching any attached flyout. The load-bearing invariants:

- Keep the attachment edge **square** and bridge the gap with an Omarchy-style molding connector — a straight body between the panel's top and bottom plus two `ShapePath` cubic pieces outside the panel bounds — not rounded connector corners. With `sidebarState.cornerPieces` enabled, reserve a connector width of `joinRadius`, place the flyout at `panelWidth + connectorWidth`, and draw the connector at `x: panelWidth`; otherwise attach directly at `panelWidth`.
- Use the single `curveKappa` (`0.5522847498`) from `lacuna.menu/components/LacunaGeometry.qml` for every curve; never copy the constant.
- Round only **exposed** corners with a custom `Shape`; never use `Rectangle.radius` on an attached surface (it rounds all four corners and breaks the connector edge).
- Flyout shells are **fill-only** (`strokeWidth: 0`); reserve borders for internal controls, dividers, or explicit selected states.

## Testing Guidelines

Until automated tests exist, validate changes inside Omarchy shell. Confirm that each widget appears in Omarchy Settings, can be placed in `bar.layout`, survives shell restart, and uses injected `bar`, `moduleName`, and `settings` properties. Test script paths through `manifest.__sourceDir` or another plugin-relative path.

## Commit & Pull Request Guidelines

This checkout has no readable Git history. Use concise, imperative commits such as `Add script pill manifest` or `Port temperature widget shell contract`. Pull requests should describe the plugin affected, list manual Omarchy smoke tests, include screenshots for visible UI changes, and call out any remaining standalone Lacuna dependencies.

## Architecture Notes

Prefer Omarchy-native services and widgets for audio, media, network, Bluetooth, battery, tray, calendar, notifications, idle/update indicators, and other already-rich system surfaces. Keep `script-pill` as the experiment path; promote a script-backed widget only when it proves a durable non-native Lacuna workflow, visual treatment, or sidebar behavior.
