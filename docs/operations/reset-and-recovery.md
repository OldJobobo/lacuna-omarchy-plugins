# Reset and recovery

Status: user guide for the latest beta

Use health reporting before reset. Reset is designed to restore Lacuna's
canonical presentation and activation, not to repair missing plugin files or
delete personal state.

## Start with the health report

Package installation:

```bash
lacuna-shell status
```

Source installation:

```bash
./scripts/lacuna status
```

Read the reported host versions, configuration health, missing/disabled/stale
plugins, sidebar monitor policy, and any previous failure phase. Follow a
printed recovery command before attempting unrelated manual edits.

## Restart the shell

For a transient visual or service problem:

```bash
omarchy restart shell
```

Wait for the shell to return, then run status again. Repeated restarts do not
repair stale payloads or malformed configuration.

## Preview a safe reset

```bash
lacuna-shell reset --dry-run
```

Reset requires the complete normal Lacuna plugin set to be installed. If status
reports missing roots, repair the installation first:

```bash
lacuna-shell install --dry-run
lacuna-shell install --profile full --reinstall --yes
```

## Perform a safe reset

```bash
lacuna-shell reset
```

Reset restores Lacuna's canonical activation, bar layout, and owned
presentation/runtime defaults. It snapshots relevant state, validates inputs,
replaces the handled configuration files, and reloads once.

Safe reset preserves user-owned data including:

- provider credentials and configuration;
- Media Player preferences, queue, history, and favorites;
- preferred and custom applications;
- reminders and authentication files;
- unrelated Omarchy entries;
- unknown JSON-safe fields outside the reset-owned contract.

Reset does not replace installed plugin payloads and has no purge mode.

## If reset is interrupted

Each handled configuration file is replaced atomically, but a sudden process or
power loss between replacing `shell.json` and `settings.json` can leave a
cross-file partial state. Use the operation backup and status-reported recovery
path rather than trying to reconstruct both files manually.

See [Advanced state files](../configuration/advanced-state-files.md) for backup
locations and safe inspection.

## When to stop

Stop and collect evidence if:

- status reports a malformed settings or shell file;
- a reinstall cannot stage or verify a plugin;
- the shell health ping does not recover;
- restoring the exact backup changes the failure.

Continue with [Support](../help/support.md).
