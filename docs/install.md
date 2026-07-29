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
- Update installed Lacuna plugins
- Reset Lacuna to omakase defaults
- Uninstall Lacuna
- Status

Full install is the canonical omakase path. Its checked inventory contains all
46 supported roots, including experimental plugins and both media plugins, and
excludes deprecated `lacuna.compact-pill`. It activates the Lacuna bar plus all
applicable menu, persistent service, and overlay entries, while the exact
canonical layout places only its curated bar widgets. Providers without
credentials remain disabled or visibly unavailable rather than breaking media
or the shell. Custom profiles remain an advanced development/recovery path.

## Scripted Installs

```bash
./scripts/lacuna install
./scripts/lacuna install --profile core
./scripts/lacuna install --profile native --activate
./scripts/lacuna install --plugin lacuna.clock,lacuna.weather
```

Preview the normal omakase install without changing the system:

```bash
./scripts/lacuna install --dry-run
```

The installer performs a dependency preflight before staging. A non-dry-run
preserves the current `shell.json` and Lacuna `settings.json` under
`${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/backups/`, stages each plugin through a temporary
directory, and retains the previous installed copy as a hidden plugin backup.
If validation, rescan, or shell activation fails, the staged copies and shell
configuration are restored and the previous shell is reloaded. Mutating
installer commands are serialized through a per-user transaction lock, and
configuration/plugin staging uses operation-owned temporary paths.

Stage a full install without enabling it:

```bash
./scripts/lacuna install --profile full --no-activate --keep-layout
```

## Arch Linux And AUR Packages

The repository maintains the `lacuna-omarchy-plugins` AUR recipe in
`packaging/aur/`. Approved beta, RC, and stable releases are published to the
same AUR package after their immutable GitHub release exists and the package
lifecycle gate passes. Upstream `0.1.0-beta.1` maps to Arch
`0.1.0beta.1`, which correctly upgrades through RC versions to stable `0.1.0`.
Install it with an AUR helper or build its `PKGBUILD` in a clean Arch
environment. The package requires an `omarchy` provider, Python, and Qt Multimedia, places
the versioned payload under `/usr/share/lacuna-omarchy-plugins` and provides
the `lacuna-omarchy` command; package installation itself never edits a user's
Omarchy configuration.

Choose a profile after installing the package:

```bash
lacuna-omarchy install --profile full
```

After a package upgrade, explicitly copy the new payload into the active
Omarchy plugin installation:

```bash
lacuna-omarchy update --yes
```

This explicit step preserves the installer's snapshots, validation, and
rollback behavior instead of mutating user state from a pacman transaction.
See `packaging/aur/README.md` for the maintainer publication procedure.

## Diagnostics

```bash
lacuna-omarchy status
```

Status reports Omarchy and Quickshell host versions, host/runtime paths, shell
and settings-schema health, sidebar monitor policy, the last installer failure
phase and recovery commands, and missing, disabled, or stale core plugins.

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

## Safe Reset

```bash
./scripts/lacuna reset --dry-run
./scripts/lacuna reset
```

Reset first requires all 46 canonical omakase plugin roots to be present in the
installed plugin directory; dry-run enforces the same preflight. If roots are
missing, install the complete profile with `./scripts/lacuna install --yes`
before resetting. Reset then snapshots `shell.json` and `settings.json`,
validates the checked profile and both inputs, atomically replaces each file,
and reloads exactly once. It is
transactional for handled write and reload failures: either failure restores
exact prior bytes and modes. An abrupt process or power loss between the two
file replacements can leave only one file updated; cross-file journaling is
outside this safe-reset scope. Reset owns
`bar.id`, `bar.layout`, `bar.centerAnchor`, `bar.transparent`, canonical Lacuna
plugin activation, and the presentation/runtime branches listed in
`config/omakase-profile.json`. It preserves credentials, provider settings,
media-player preferences, favorites, queue/history, auth and reminder files,
preferred/custom apps, unrelated plugin entries, other bar keys, and unknown
JSON-safe fields. Media-player preferences remain preserved because they are
mirrored into `media-player.json`; resetting only the settings copy would let
shell shutdown overwrite otherwise preserved media state. Reset
never changes installed plugin copies and deliberately has no purge mode.

## Uninstall

```bash
./scripts/lacuna uninstall --all
./scripts/lacuna uninstall --plugin lacuna.clock,lacuna.weather
./scripts/lacuna uninstall --all --purge-state
```

Selective uninstall refuses to remove a plugin while another installed Lacuna
plugin requires it. Review the printed reverse dependency closure and pass
`--cascade` only when those dependent plugins should be removed too.

## Manual Omarchy Source Install

If you prefer to use Omarchy's plugin commands directly, add this repository as
a trusted plugin source:

```bash
omarchy plugin source add <repo-url> --as lacuna
omarchy plugin available
omarchy plugin add lacuna.clock --from lacuna --enable --yes
```

Bar widgets are placed in `bar.layout`; use `omarchy bar plugin add <id>` or
copy `config/shell.lacuna-native-replacements.example.json` into
`~/.config/omarchy/shell.json` as a starting point.

`lacuna.bar` is a full Omarchy bar option rather than a bar widget. Activate it
with:

```bash
omarchy bar use lacuna.bar
```

Reset only the active bar host to Omarchy's stock bar with:

```bash
omarchy bar reset
```

That command preserves the current bar layout. Use `omarchy bar defaults` only
when you intentionally want the broader packaged default layout too.

For a live checkout deploy during development, use the same verified workflow:

```bash
./scripts/dev deploy --all --only-changed --dry-run
./scripts/dev deploy --all --only-changed
```

The developer deploy also keeps prior plugin copies and restores them if the
rescan, shell restart, or installed-copy verification fails.
