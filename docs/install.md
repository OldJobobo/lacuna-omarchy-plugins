# Install And Update

Status: reference

Lacuna Omarchy Plugins installs into Omarchy's normal plugin system. The repo
contains top-level `lacuna.*` plugin directories because Omarchy's repo-source
installer scans only top-level folders that contain a `manifest.json`.

## Installer

Run the Lacuna helper for a menu-driven setup:

```bash
./scripts/lacuna
```

The first screen offers:

- Full Lacuna install
- Custom install
- Uninstall Lacuna
- Status

Full install stages and activates the Lacuna Bar setup, including the native
Lacuna bar-widget replacements used by the Lacuna layout. Custom install lets
you pick groups or individual standalone plugins, then automatically includes
required companions such as `lacuna.state` and `lacuna.shell-settings`.

## Scripted Installs

```bash
./scripts/lacuna install --profile full
./scripts/lacuna install --profile core
./scripts/lacuna install --profile native --activate
./scripts/lacuna install --plugin lacuna.clock,lacuna.weather
```

Preview any install without changing the system:

```bash
./scripts/lacuna install --profile full --dry-run
```

Stage a full install without enabling it:

```bash
./scripts/lacuna install --profile full --no-activate --keep-layout
```

## Update

Update already-installed Lacuna plugins from this checkout:

```bash
./scripts/lacuna update --dry-run
./scripts/lacuna update --yes
./scripts/lacuna update --plugin lacuna.menu,lacuna.state --yes
```

## Uninstall

```bash
./scripts/lacuna uninstall --all
./scripts/lacuna uninstall --plugin lacuna.clock,lacuna.weather
./scripts/lacuna uninstall --all --purge-state
```

## Manual Omarchy Source Install

If you prefer to use Omarchy's plugin commands directly, add this repository as
a trusted plugin source:

```bash
omarchy plugin source add <repo-url> --as lacuna
omarchy plugin available
omarchy plugin add lacuna.clock --from lacuna --enable --yes
```

Bar widgets are placed in `bar.layout`; use `omarchy plugin bar add <id>` or
copy `config/shell.lacuna-native-replacements.example.json` into
`~/.config/omarchy/shell.json` as a starting point.

`lacuna.bar` is a full Omarchy bar option rather than a bar widget. Activate it
with:

```bash
omarchy plugin bar use lacuna.bar
```

Reset to the stock Omarchy bar with:

```bash
omarchy plugin bar reset
```
