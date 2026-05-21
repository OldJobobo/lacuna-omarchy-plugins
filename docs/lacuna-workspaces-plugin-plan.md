# Lacuna Workspaces Plugin Plan

## Goal

Add an Omarchy bar-widget plugin that recreates the original Lacuna workspace
switcher design inside the Omarchy shell plugin model.

The plugin exists because Lacuna's original workspace module has a specific
visual and interaction treatment that the native Omarchy workspace module does
not provide: numbered rectangular controls, muted empty
states, occupied workspace color, urgent override, and hover pulse.

## Plugin

```text
plugins/omarchy.lacuna-workspaces/
  manifest.json
  Widget.qml
  ColorProfile.qml
  components/
    LacunaAnim.qml
    LacunaStateLayer.qml
    LacunaWorkspaceButton.qml
```

Type: `bar-widget`

Entry point: `Widget.qml`

Runtime imports stay plugin-local. The plugin must not import from the
repository root or another Lacuna plugin directory.

## Source Reference

Original standalone Lacuna files:

```text
../lacuna/modules/Workspaces.qml
../lacuna/modules/LacunaButton.qml
```

The implementation should preserve the useful behavior from those files while
adapting the root to Omarchy's bar-widget contract:

```qml
property var bar
property string moduleName
property var settings
```

## Behavior

First pass:

1. Show fixed numeric workspaces `1` through `7`.
2. Use the focused Hyprland workspace as the active state.
3. Mark a workspace occupied when its Hyprland workspace reports windows or
   toplevels.
4. Mark urgent workspaces with the urgent color.
5. Dispatch left-clicks through `Hyprland.dispatch`.
6. Refresh workspace state on Hyprland workspace/window/focused-monitor/urgent
   events with a short debounce.
7. Keep Lacuna hover pulse treatment while selected state stays text-only.

Optional behavior exposed through settings:

1. `workspaceCount`: number of persistent buttons, default `7`.
2. `showDynamicExtra`: include additional positive workspaces beyond the fixed
   count when Hyprland reports them.
3. `colorProfile`: use Lacuna semantic colors or active Omarchy theme colors.

The widget also follows Lacuna's global `designStyle` setting from
`~/.config/omarchy/lacuna/settings.json`:

1. `lacuna`: original Lacuna workspace design with numbered rectangular
   buttons, hover pulse, occupied color, and dim empty text.
2. `omarchy`: native Omarchy workspace treatment with fixed-width minimal
   buttons, focused workspace glyph, and opacity-based empty state.
3. `material`: stable rounded state chips with a filled tonal selected state,
   outlined tonal occupied state, muted empty text, wider spacing, and calm
   Material-style hover motion.

## Styling

The visual target is the original Lacuna topbar workspace group:

1. Rectangular buttons, radius `0`.
2. Compact size follows `bar.barSize`, with a minimum width close to the old
   `24` compact / `32` regular rhythm.
3. Active workspace uses accent color and heavier label weight.
4. Active workspace is selected through accent text and weight, without a fill
   or underline.
5. Occupied inactive workspace uses a secondary alive color.
6. Empty workspace uses a semantic muted foreground color with an opaque
   contrast-safe mix, not a decorative palette accent.
7. Hover reveals a subtle fill and pulse/glow around the label.

## Omarchy Layout

Use this widget in `bar.layout` where native `workspaces` would normally sit:

```json
{ "id": "omarchy.lacuna-workspaces", "workspaceCount": 7 }
```

The plugin should appear in Omarchy Settings under the `Lacuna` category.

## Validation

Manual validation target:

1. Symlink the plugin into `~/.config/omarchy/plugins/`.
2. Run `omarchy-shell shell rescanPlugins`.
3. Place the widget in `~/.config/omarchy/shell.json`.
4. Confirm workspace focus, occupied, empty, urgent, hover, and restart
   behavior inside Omarchy shell.

Static validation:

```bash
python3 -m json.tool plugins/omarchy.lacuna-workspaces/manifest.json
qmllint plugins/omarchy.lacuna-workspaces/Widget.qml
qmllint plugins/omarchy.lacuna-workspaces/components/LacunaWorkspaceButton.qml
```
