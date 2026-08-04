# Uninstall

Status: user guide for the latest beta

Uninstalling Lacuna plugins and deleting Lacuna preferences are separate
choices. The default is to retain your user state.

## Remove all Lacuna plugins

Preview first:

```bash
lacuna-shell uninstall --all --dry-run
```

Then remove them:

```bash
lacuna-shell uninstall --all
```

Removing `lacuna.bar` restores Omarchy's packaged bar host **and packaged bar
layout**, replacing the current bar composition. This is intentionally broader
than `omarchy bar reset`, which preserves the current layout. Lacuna-owned
preferences are retained for a future reinstall.

A full uninstall also removes Lacuna-owned Hyprland toggle overrides for window
gaps, corner rounding, and single-window aspect ratio, then runs
`hyprctl reload` so the active Omarchy theme and host configuration take effect
immediately. Omarchy-owned toggle files are left untouched. If the Hyprland or
shell reload fails, the installer restores the removed overrides together with
the previous plugin and shell state.

## Remove plugins and saved Lacuna state

Only add `--purge-state` when you also want to delete the Lacuna state directory,
including saved settings and feature state covered by that directory:

```bash
lacuna-shell uninstall --all --purge-state
```

Read the confirmation carefully. Purging state is different from safe reset and
is intended to be destructive.

## Selective uninstall

Advanced users can remove selected plugins:

```bash
lacuna-shell uninstall --plugin lacuna.weather --dry-run
lacuna-shell uninstall --plugin lacuna.weather
```

The command refuses to break installed Lacuna dependencies. `--cascade`
includes installed dependents in the removal plan; use it only after reviewing
the entire printed closure.

## Remove the package payload

After uninstalling the user plugins, remove the `lacuna-shell` package through
your normal Omarchy/Arch package workflow if you no longer want the immutable
payload or `lacuna-shell` command. Package removal alone is not a substitute for
the user-level uninstall because the package transaction does not own your
active shell configuration.

## Source installations

Run the equivalent commands from the checkout:

```bash
./scripts/lacuna uninstall --all
```

After successful uninstall, you may remove the source checkout separately.
Keep it until status and the stock bar have been verified.
