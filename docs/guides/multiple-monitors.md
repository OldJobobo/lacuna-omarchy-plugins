# Multiple monitors

Status: user guide for the latest beta

Lacuna treats each output independently for bars, frames, flyouts, fullscreen
suppression, and available space. The sidebar has one monitor policy that
chooses where its main surface belongs.

## Let Lacuna choose first

The default sidebar monitor policy is automatic. Use it until you have verified
that every connected output is named and arranged correctly in Hyprland.

To choose a monitor explicitly, open **Lacuna Settings → Layout** and select the
available monitor policy or monitor names shown there. Avoid hand-editing names
unless the settings interface cannot represent your arrangement.

## Portrait split bars

Portrait split is enabled by default. On a logical portrait output with a top
or bottom bar, selected status widgets move to a companion band on the opposite
edge. Landscape outputs and left/right bars stay on one surface.

The companion is derived from the same Omarchy bar layout. Edit widget order in
Omarchy Settings; do not try to maintain a second layout for the companion.

Advanced users can disable portrait split in the Lacuna settings state. See
[Advanced state files](../configuration/advanced-state-files.md) and make a
backup before manual editing.

## Sidebar and flyout space

An expanded sidebar reserves a lane for attached content on its monitor. Bar
flyouts move away when they would overlap that lane. A collapsed rail does not
reserve the same avoidance space.

Autohide arms a left-edge hot zone on every output selected by the monitor
policy, but reveals only the output whose edge was activated. Moving to another
eligible output closes the old reveal before opening the new one. Autohide is
overlay-only, so neither the concealed nor revealed state changes application
window reserves.

On an output too narrow to fit both surfaces, the flyout falls back to normal
screen clamping rather than opening off-screen.

## Fullscreen on one output

A real Hyprland fullscreen window suppresses Lacuna surfaces and exclusive
zones only on the output that owns that fullscreen workspace. Other monitors
keep their bars and sidebar behavior.

If one monitor changes unexpectedly when another enters fullscreen, record the
monitor names, active workspaces, and `lacuna-shell status` output for a bug
report.

## After changing displays

1. Confirm the Hyprland layout first.
2. Restart the Omarchy shell.
3. Open and close the sidebar on its chosen monitor.
4. Open a bar flyout on each output.
5. Test one real fullscreen window per output.
