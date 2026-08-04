# Compatibility

Status: reviewed environment for the latest beta

Lacuna is developed against Omarchy's Quattro-era shell contracts. The project
records exact reviewed host files because bar, layer-shell, plugin, and settings
behavior can change between Omarchy revisions.

## Reviewed environment

The current checked review records:

| Component | Reviewed version |
| --- | --- |
| Omarchy | `4.0.0.r1438.g9b693cc-1` |
| Quickshell | `0.3.0.r18.g10b439f-3` |

This is a tested pair, **not a declared minimum-version range**. The beta may
work on nearby revisions, but the project has not yet promised every older or
newer build.

## What is supported

- The exact reviewed Omarchy/Quickshell pair shown above
- Omarchy's single Quickshell process and plugin host
- Hyprland outputs, including multi-monitor and portrait arrangements covered
  by the current test and live-validation matrix
- AUR package installation and the official source workflows

## What is not a supported promise

- Other compositors or desktop environments
- A second standalone Quickshell process
- Arbitrary older Omarchy plugin contracts
- Every downstream Quickshell development snapshot
- Hand-edited combinations that remove required core plugins

## After an Omarchy update

1. Update normally and restart the shell.
2. Run `lacuna-shell status`.
3. Apply the latest Lacuna payload.
4. Test the bar, sidebar, one flyout, and true fullscreen on each output.
5. Check the current release notes for compatibility changes.

If the host is newer than the reviewed environment and a regression appears,
report both exact versions. Do not describe the reviewed pair as a minimum.

Maintainers can consult the detailed
[Quattro compatibility ledger](../architecture/quattro-compatibility.md) for
file digests and port decisions.
