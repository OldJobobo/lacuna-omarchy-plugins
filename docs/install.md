# Install and update

Status: compatibility entry point

The user installation documentation has moved into task-oriented guides:

- [Requirements](getting-started/requirements.md)
- [Install Lacuna](getting-started/installation.md)
- [First-run tour](getting-started/first-run.md)
- [Upgrade Lacuna](getting-started/upgrading.md)
- [Reset and recovery](operations/reset-and-recovery.md)
- [Uninstall](operations/uninstall.md)

The recommended package path is:

```bash
omarchy pkg aur add lacuna-shell
lacuna-shell
```

Choose **Full Lacuna install** for the normal, canonical setup. The package
places the versioned payload on disk; the guided installer previews, snapshots,
stages, validates, activates, and reloads the user shell.

Inspect the plan without changing anything:

```bash
lacuna-shell install --dry-run
```

Advanced profile, individual-plugin, manual source, and recovery options are
listed by the executable itself:

```bash
lacuna-shell install --help
lacuna-shell uninstall --help
```

Maintainers should use the [release workflow](development/release.md) and
[AUR packaging runbook](https://github.com/OldJobobo/lacuna-shell/tree/master/packaging/aur)
rather than this user entry point.
