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

This works from either a Git clone or a downloaded and extracted repository
archive. A clone uses the local checkout as its Omarchy plugin source; an
archive automatically registers the official GitHub repository as `lacuna`.

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

The installer performs a dependency preflight before staging. A non-dry-run
preserves the current `shell.json` and Lacuna `settings.json` under
`~/.config/omarchy/lacuna/backups/`, stages each plugin through a temporary
directory, and retains the previous installed copy as a hidden plugin backup.
If validation, rescan, or shell activation fails, the staged copies and shell
configuration are restored and the previous shell is reloaded.

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

Updates are transactional at the plugin-batch level. A failed rescan restores
all plugins touched by that update, while the state snapshots remain available
for manual recovery.

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

For a live checkout deploy during development, use the same verified workflow:

```bash
./scripts/dev deploy --all --only-changed --dry-run
./scripts/dev deploy --all --only-changed
```

The developer deploy also keeps prior plugin copies and restores them if the
rescan, shell restart, or installed-copy verification fails.
