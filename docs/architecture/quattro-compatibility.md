# Quattro Compatibility Ledger

Status: reference (updated 2026-07-10)

This is the compatibility record for the Lacuna core bundle on Omarchy
Quattro. It is intentionally a ledger, not a promise that every future
Omarchy development build is supported.

## Current tested host

| Component | Observed value |
| --- | --- |
| Omarchy package | `omarchy-dev 4.0.0.r1034.gaf82848-1` |
| Quickshell package | `quickshell 0.3.0-2` |
| Omarchy path | `/usr/share/omarchy` |
| Upstream bar source | `/usr/share/omarchy/shell/plugins/bar/` |
| Bar source revision | package revision `af82848` (encoded in the Omarchy package version) |
| Target date | 2026-07-10 |

The current upstream bar source is package-managed rather than a Git checkout,
so the package version and source hashes are the authoritative revision record
on this machine:

| File | SHA-256 |
| --- | --- |
| `shell/plugins/bar/Bar.qml` | `9202417d6201cc05a80f74ba6e07d1f60d3aff7b42793151c01eacdec3404852` |
| `shell/plugins/bar/BarModel.js` | `729f86bc475ad3b6383bfff4b44a64132da2a5cd36e5470ca4d6bec9ee3712c0` |

`lacuna.bar/BarModel.js` matches the upstream `BarModel.js`. The copied
`lacuna.bar/OmarchyBar.qml` is intentionally Lacuna-owned and diverges from
the upstream `Bar.qml`; that divergence is declared in
`lacuna.bar/manifest.json` and must not be silently synchronized.

## Compatibility check

Run the read-only checker from the repository root:

```bash
scripts/quattro-compatibility --check
```

It records the live Omarchy and Quickshell package versions, verifies the
upstream bar files exist, checks the declared vendored pairs, and validates the
core plugin folders. For CI or a machine without a live Omarchy installation,
use the repository-only mode:

```bash
scripts/quattro-compatibility --repo-only --check
```

When the Omarchy bar source changes, run the checker and then review the
following contract-sensitive areas before accepting the new revision:

1. `Bar.qml` injection properties, layout normalization, slot measurement,
   overflow, drag behavior, and per-screen variants.
2. `BarModel.js` entry shape, string-entry handling, tray pinning, and custom
   module paths.
3. `PluginRegistry` discovery, `shell.json` bar selection, plugin rescan, and
   shell restart behavior.
4. Bar position, size, orientation, transparency, theme/color access, and
   widget registry APIs.
5. `lacuna.bar` frame/sidebar ownership, `lacuna.menu` summon compatibility,
   and the layer/geometry contract.

Required source and runtime checks after an upgrade:

```bash
./scripts/check.sh
scripts/sync-vendored --check
scripts/quattro-p0-smoke
./scripts/dev deploy lacuna.bar lacuna.menu lacuna.state --dry-run
omarchy plugin list
omarchy-shell shell listPlugins
omarchy-shell shell debugBarGeometry
hyprctl layers
```

`quattro-p0-smoke` is read-only. It combines the compatibility report with
core plugin enablement, bar geometry registration, and per-output frame-layer
checks; it requires a live Wayland/Omarchy session.

The stock recovery path remains:

```bash
omarchy plugin bar reset
```

This resets the active bar choice while leaving Lacuna runtime state in
`~/.config/omarchy/lacuna/settings.json`.

## Multi-monitor policy

`lacuna.menu` resolves the focused monitor name from the Omarchy shell-settings
state and selects the matching `Quickshell.screens` entry. The persisted
`sidebar.monitorPolicy` setting controls the target set:

- `auto` (default): the focused output, with the first live output as a
  deterministic fallback when focus data is unavailable or stale.
- `pinned`: the live outputs named by `sidebar.monitorNames`; selecting one or
  several outputs is supported. If no pinned name is currently present, the
  focused-output fallback is used until a valid output is selected.
- `all`: every live output.

Focus and monitor add/remove events recalculate the target set. The sidebar,
frame cutout, border attachment, and reserve surfaces are instantiated for
every selected output. The interactive flyout is different: it is rendered
only on the active/focused selected output, including when the sidebar policy
is `all`; its connector, input mask, and attached frame-border gap follow that
same output. In `pinned` mode, if the focused output is not pinned, the
flyout falls back to the first valid pinned output. Monitor names are output
names such as `DP-1`, not Hyprland workspace IDs; the policy therefore pins
the surface to a physical/logical output while that output's active workspace
can continue to change normally. The menu does not persist an open state, so a
restart cannot resurrect it on a stale output.

For the 2026-07-10 live smoke, the outputs were `DP-1`, `DP-2`, and `DP-3`,
with `DP-3` focused; `auto` therefore selected `DP-3` rather than the previous
`Quickshell.screens[0]` (`DP-1`).

## Layer-order reconciliation

The source declaration in `lacuna.bar/Bar.qml` keeps frame surfaces before the
bar adapter and the hosted menu. On the current Quattro build, `hyprctl layers`
reports the mapped top-layer order as `omarchy-bar`, `lacuna-bar-frame`, then
`lacuna-menu` on the sidebar output. The Omarchy bar maps on its own host
schedule, so its runtime map order is not controlled by the Lacuna declaration.

Correctness therefore comes from both constraints: the source declaration is
kept deterministic for Lacuna-owned surfaces, and `LacunaFrameWindow.qml`
excludes the bar strip from frame paint so the custom frame cannot cover the
bar even when Quattro maps `omarchy-bar` first. The frame, border, and reserve
surfaces remain pinned by `tests/test_qml_contracts.py` and the geometry tests.
