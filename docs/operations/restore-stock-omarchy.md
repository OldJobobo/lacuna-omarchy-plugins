# Restore stock Omarchy

Status: user guide for the latest beta

You can return to Omarchy's stock bar without deleting Lacuna preferences.
This is useful for diagnosis, comparison, or a temporary rollback.

## Reset only the bar host

```bash
omarchy bar reset
```

This clears the custom Lacuna bar choice while preserving the current bar
layout. It is the safer first recovery step when the custom host is the suspected
problem.

## Restore the full Omarchy bar defaults

```bash
omarchy bar defaults
```

This is broader: it restores Omarchy's packaged bar layout as well as its host.
Use it only when you intentionally want to discard the current bar composition.

## Keep or remove Lacuna

Changing the bar host does not remove installed Lacuna plugins or saved Lacuna
state. You can:

- keep Lacuna installed and switch back later;
- run `lacuna-shell reset` to restore the canonical Lacuna setup;
- follow [Uninstall](uninstall.md) to remove Lacuna completely.

## Verify recovery

1. Wait for the Omarchy shell to reload.
2. Confirm the stock bar appears on every output.
3. Open Omarchy Settings and inspect the bar layout.
4. Run `lacuna-shell status` if Lacuna remains installed.

If the shell does not return, diagnose the host independently before attempting
to reactivate Lacuna.
