# Lacuna Settings Panel Plan

## Goal

Move Lacuna settings out of the main sidebar item flow and into a dedicated
floating settings panel opened from the bottom gear button.

The main Lacuna sidebar should stay focused on launchers, system actions, and
workflow commands. Settings should feel like a modern app preferences surface:
separate, persistent while open, easy to scan, and reachable from a small gear
control anchored at the bottom of the sidebar or collapsed rail.

## Interaction Model

The bottom gear button opens a floating `LacunaSettingsWindow`.

Flyout and subpanel rule:

1. Opening a flyout must not resize, move, collapse, expand, or reroute the
   sidebar.
2. The sidebar `PanelWindow` keeps a stable width while open by reserving a
   constant flyout lane; opening and closing panels only changes child
   visibility, not the sidebar window geometry.
3. Flyouts should attach directly to the sidebar edge or to the topbar join
   line, never float with a decorative gap.
4. When sidebar corner pieces are enabled, flyouts should participate in that
   connection by aligning to the same join line and using connected corner-piece
   geometry rather than detached popup placement.

The settings panel should:

1. Open beside the sidebar instead of pushing a normal sidebar route.
2. Toggle closed when the gear is pressed again.
3. Close from an explicit close button.
4. Close on Escape.
5. Prefer closing on outside click if the Omarchy shell/window model supports
   it cleanly.
6. Stay independent from `menuState.currentView`.
7. Keep the sidebar usable as a launcher surface.

The existing settings-oriented views should move out of normal sidebar
navigation:

1. `lacuna`
2. `lacuna-preferences`
3. `lacuna-clock`
4. `lacuna-preferred-apps`
5. `lacuna-shell`

These should become settings-panel sections or be replaced by equivalent
settings-panel content.

## Window Shape

Use a dedicated floating window-like surface from `MenuWindow.qml`.

Recommended first implementation:

```qml
property bool settingsPanelOpen: false
property string settingsSection: "overview"
property var settingsStack: ["overview"]
```

The panel should be positioned beside the sidebar and stay attached to it:

```qml
property int settingsConnectorWidth: sidebarState.cornerPieces ? joinRadius : 0
property int attachedFlyoutLeftX: panelWidth + settingsConnectorWidth

x: root.settingsPanelOpen
  ? root.attachedFlyoutLeftX
  : root.attachedFlyoutLeftX - Math.min(root.settingsPanelWidth, 72)
y: root.settingsFlyoutY(targetHeight)
```

Suggested sizing:

1. Width: `360` to `420` px.
2. Height: `Math.min(menuWindow.height - y - designTokens.bottomInset, 620)`.
3. Collapsed rail mode should use the same panel and open beside the rail.
4. The panel should use the same Lacuna design tokens as the sidebar.
5. It should use a subtle border or accent treatment, not nested cards.

Keyboard focus should become exclusive while the settings panel is open only if
needed for Escape handling, search inputs, or keyboard navigation.

### Corner Pieces And Rounding

Flyout panels that attach to the Lacuna sidebar must treat the left and right
edges differently:

1. The left edge is the attachment edge. Keep it square so it can sit flush
   against the connector molding.
2. The exposed right edge may use normal panel rounding. Round only the
   top-right and bottom-right corners.
3. Do not use normal rounded corners for the connector pieces. Connector pieces
   are molding transitions, matching the sidebar/topbar connection in
   `MenuSurface.qml`.
4. When `sidebarState.cornerPieces` is false, omit the connector width and let
   the panel attach directly at `panelWidth`.

The connector lives between the sidebar and the flyout panel:

```qml
property int settingsConnectorWidth: sidebarState.cornerPieces ? joinRadius : 0
property int attachedFlyoutLeftX: panelWidth + settingsConnectorWidth
```

Place the connector at the sidebar edge, not inside the panel:

```qml
x: root.panelWidth
y: settingsPanel.y - root.settingsConnectorWidth
width: root.settingsConnectorWidth
height: settingsPanel.height + root.settingsConnectorWidth * 2
```

The connector is three pieces:

1. A straight body from `settingsConnectorWidth` below the panel top to the
   panel bottom.
2. A top molding piece above the panel.
3. A bottom molding piece below the panel, vertically flipped from the top.

The straight body is just the shared panel color:

```qml
LacunaRect {
  y: root.settingsConnectorWidth
  width: parent.width + 1
  height: settingsPanel.height
  color: root.panelColor
}
```

The molding pieces should use `ShapePath` cubic curves and the same
`curveKappa` constant as `MenuSurface.qml`:

```qml
readonly property real curveKappa: 0.5522847498
```

Top molding path:

```qml
ShapePath {
  fillColor: root.panelColor
  strokeColor: root.panelColor
  strokeWidth: 1
  startX: 0
  startY: root.settingsConnectorWidth

  PathLine { x: root.settingsConnectorWidth; y: root.settingsConnectorWidth }
  PathCubic {
    x: 0
    y: 0
    control1X: root.settingsConnectorWidth * (1 - settingsConnector.curveKappa)
    control1Y: root.settingsConnectorWidth
    control2X: 0
    control2Y: root.settingsConnectorWidth * settingsConnector.curveKappa
  }
  PathLine { x: 0; y: root.settingsConnectorWidth }
}
```

Bottom molding path:

```qml
ShapePath {
  fillColor: root.panelColor
  strokeColor: root.panelColor
  strokeWidth: 1
  startX: 0
  startY: 0

  PathLine { x: root.settingsConnectorWidth; y: 0 }
  PathCubic {
    x: 0
    y: root.settingsConnectorWidth
    control1X: root.settingsConnectorWidth * (1 - settingsConnector.curveKappa)
    control1Y: 0
    control2X: 0
    control2Y: root.settingsConnectorWidth * (1 - settingsConnector.curveKappa)
  }
  PathLine { x: 0; y: 0 }
}
```

The flyout panel itself should draw a custom shape rather than using a
rectangle radius, because rectangle radius rounds all four corners. Use a
square left edge and cubic curves only on the right edge:

```qml
PathLine { x: root.width - root.panelRadius; y: 0 }
PathCubic {
  x: root.width
  y: root.panelRadius
  control1X: root.width - root.panelRadius * (1 - root.curveKappa)
  control1Y: 0
  control2X: root.width
  control2Y: root.panelRadius * (1 - root.curveKappa)
}
PathLine { x: root.width; y: root.height - root.panelRadius }
PathCubic {
  x: root.width - root.panelRadius
  y: root.height
  control1X: root.width
  control1Y: root.height - root.panelRadius * (1 - root.curveKappa)
  control2X: root.width - root.panelRadius * (1 - root.curveKappa)
  control2Y: root.height
}
PathLine { x: 0; y: root.height }
PathLine { x: 0; y: 0 }
```

## Visual Structure

The settings panel should use a compact app-preferences layout:

```text
settings/
  SettingsWindow.qml
  SettingsHeader.qml
  SettingsRail.qml
  SettingsSection.qml
  SettingsRow.qml
  SettingsToggleRow.qml
  SettingsOptionRow.qml
```

Recommended layout:

1. Header with section title, optional back button, and close button.
2. Left icon rail for settings sections.
3. Scrollable section content area.
4. Dense rows with clear labels and current values.
5. Toggle, segmented, and button controls where appropriate.

Do not put the primary settings experience inside decorative cards. Use full
panel rows, dividers, and constrained content.

## Sections

### Overview

Purpose: quick status and shortcuts into deeper sections.

Content:

1. Current design style.
2. Current density.
3. Current sidebar mode.
4. Preferred apps summary.
5. Desktop clock status.
6. Lacuna version.

### Appearance

Purpose: visual style and color behavior.

Content:

1. Design style: `Lacuna`, `Omarchy`, `Material`.
2. Color profile: `Semantic`, `Colorful`.
3. Theme shortcut.
4. Background shortcut.
5. Wallpaper catalog shortcut.

### Layout

Purpose: sidebar and density behavior.

Content:

1. Density: `Normal`, `Compact`.
2. Sidebar display: `Full`, `Icon Rail`.
3. Sidebar mode: `Overlay`, `Docked`.
4. Corner pieces: enabled/disabled.

### Preferred Apps

Purpose: configure role-based app launch targets.

Content:

1. Files.
2. Editor.
3. Email.
4. Discord.

Each row should show the current resolved app or system fallback. Selecting a
row should open the existing shared app picker in `preferredApp` mode. The
picker should keep its reset-to-system option.

### Desktop Clock

Purpose: configure the desktop-layer Lacuna clock plugin.

Content:

1. Enable/disable desktop clock.
2. Horizontal anchor: `Left`, `Center`, `Right`.
3. Vertical anchor: `Top`, `Center`, `Bottom`.
4. Nudge left/right/up/down.
5. Reset position.
6. Future-ready scale or style controls if needed.

### Runtime

Purpose: operational tools and diagnostics.

Content:

1. Restart shell.
2. Open log.
3. Reload app catalog.
4. Open plugin source.

### About

Purpose: low-noise metadata.

Content:

1. Lacuna version.
2. Active theme title.
3. Plugin path.
4. Basic shell/plugin diagnostic metadata.

## State And Data

The settings panel should not introduce a separate runtime config file.

Continue using:

```text
~/.config/omarchy/lacuna/settings.json
```

Current user-facing Lacuna runtime settings:

1. `designStyle`
2. `colorProfile`
3. `compact`
4. `customQuickLaunchApps`
5. `preferredApps`
6. `sidebar`

Desktop clock plugin settings still belong in Omarchy shell plugin state because
the clock is its own plugin entry.

## Registry And Routing

`MenuRegistry.qml` should stop owning settings panel composition over time.

Recommended final shape:

```text
settings/SettingsRegistry.qml
```

It should expose:

```qml
function titleFor(section)
function sections()
function itemsFor(section)
```

For the first implementation pass, settings section composition can live in
`SettingsWindow.qml` if that keeps the change smaller. Move it into
`SettingsRegistry.qml` once it becomes more than a few sections.

The bottom gear should no longer activate a normal menu route:

```qml
settingsPanelOpen = !settingsPanelOpen
```

Do not expand the collapsed rail just to show settings.

## Shared Behavior

Avoid duplicating state mutation logic. Reuse or pass callbacks from
`MenuWindow.qml` into `SettingsWindow.qml`.

Shared behaviors needed by the settings panel:

1. `setDesignStyle(style)`
2. Toggle color profile.
3. Toggle compact density.
4. Toggle sidebar rail.
5. Toggle sidebar overlay/docked mode.
6. Toggle corner pieces.
7. Open preferred app picker.
8. Set preferred app.
9. Desktop clock enable/settings controls.
10. Reload app catalog.
11. Restart shell.
12. Open log.
13. Open plugin source.

## App Picker Integration

Keep one shared app picker surface.

The settings panel should call:

```qml
openPreferredAppPicker(role)
```

When the app picker is open:

1. Keep the settings panel visible.
2. Show the picker beside or above the settings panel without unreadable
   overlap.
3. Use titles like `Set Files App`.
4. Return to the settings panel after selection or close.

## Implementation Phases

### Current Implementation Progress

Completed so far:

1. Bottom sidebar gear toggles a dedicated floating settings panel.
2. Settings panel stays independent from the normal sidebar route stack.
3. Full sidebar and collapsed rail can open the same settings panel.
4. Settings content has been moved into a purpose-built preferences surface with
   a header, icon rail, section labels, rows, toggles, segmented controls, and
   command buttons.
5. Preferred app rows call the shared app picker.
6. Runtime, layout, appearance, preferred app, desktop clock, and about sections
   are wired to the existing Lacuna action path.

Remaining polish:

1. Tune exact panel width/height after live use.
2. Add better hover labels/tooltips for the settings icon rail if needed.
3. Replace the four desktop-clock nudge rows with a more compact directional
   control if the section feels too tall.
4. Do another live pass on text clipping and app-picker collision.

### Phase 1: Floating Shell

1. Add `settingsPanelOpen` to `MenuWindow.qml`.
2. Change the bottom gear action to toggle `settingsPanelOpen`.
3. Add a blank floating settings panel beside the sidebar.
4. Add close and Escape behavior.
5. Validate full sidebar and collapsed rail mode.

### Phase 2: Basic Settings Content

1. Add `settings/SettingsWindow.qml`.
2. Add header and close control.
3. Add the initial sections rail.
4. Move `Runtime`, `Layout`, `Preferred Apps`, and `Desktop Clock` content into
   the panel.
5. Remove normal sidebar settings routes after parity.

### Phase 3: Wire Controls

1. Wire design style segmented control.
2. Wire color profile toggle.
3. Wire sidebar and density toggles.
4. Wire preferred app picker rows.
5. Wire desktop clock controls.
6. Wire runtime commands.

### Phase 4: Polish

1. Tune panel dimensions for compact and normal density.
2. Tune rail icons and hover states.
3. Add empty/loading states where app catalog data is unavailable.
4. Check text overflow at narrow widths.
5. Verify the settings panel and app picker do not collide badly.

### Phase 5: Cleanup

1. Move settings row composition into `SettingsRegistry.qml` if needed.
2. Remove dead settings routes from `MenuRegistry.qml`.
3. Remove any stale action names.
4. Update docs if the implementation diverges.

## Validation

Run:

```bash
qmllint plugins/omarchy.lacuna-menu/menu/MenuWindow.qml
qmllint plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml
python3 -m json.tool config/settings.example.json
```

Manual smoke tests:

1. Gear opens and closes settings panel in full sidebar mode.
2. Gear opens and closes settings panel in collapsed rail mode.
3. Main sidebar launch items still work.
4. Preferred app picker still works.
5. Desktop clock controls update plugin settings.
6. Escape closes the settings panel.
7. Close button closes the settings panel.
8. Panel sizing works in compact and normal density.
9. Settings panel does not obscure the app picker in a broken way.
10. Shell restart preserves Lacuna settings.
