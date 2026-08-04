# Upgrading

Status: user guide for the latest beta

Updating the package and applying the new Lacuna payload are separate steps.
This keeps package transactions from silently changing your live shell state.

## AUR installation

Before a host update, compare its planned Omarchy and Quickshell versions with
the [reviewed compatibility environment](../help/compatibility.md). Do not update
the host solely for Lacuna. When you choose to update packages, stage the new
Lacuna payload afterward:

```bash
omarchy update
lacuna-shell update --dry-run
lacuna-shell update --yes
```

The dry run shows what is stale. The real update stages and verifies changed
installed plugin copies, then asks Omarchy to rescan plugins. If the operation
fails during its handled phases, it restores the touched plugin copies. It does
not mutate or roll back `shell.json`.

If a persistent surface does not pick up the rescanned payload, run:

```bash
omarchy restart shell
```

## Source bootstrap installation

Rerun the same bootstrap command used for installation. It fast-forwards its
verified checkout and reinstalls the complete profile:

```bash
( f="$(mktemp)" && trap 'rm -f "$f"' EXIT && curl -fsSL https://raw.githubusercontent.com/OldJobobo/lacuna-shell/refs/heads/master/install.sh -o "$f" && bash "$f" )
```

The bootstrap refuses dirty or divergent checkouts rather than overwriting
local work.

## Manually cloned source

```bash
cd "$HOME/lacuna-shell"
git pull --ff-only
./scripts/lacuna update --dry-run
./scripts/lacuna update --yes
```

Use your actual clone location if it differs.

## Before and after an update

1. Read the [release notes](../releases/index.md) and
   [migration notes](../releases/migration-notes.md).
2. Preview the operation.
3. Let the plugin rescan complete; restart the shell if a persistent surface
   still shows the old payload.
4. Run `lacuna-shell status` or `./scripts/lacuna status`.
5. Check the bar, sidebar, theme, and any configured media provider.

If a host update changes Omarchy or Quickshell behavior, compare it with the
[reviewed compatibility environment](../help/compatibility.md).
