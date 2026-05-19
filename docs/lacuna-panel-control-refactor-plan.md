# Lacuna Panel Control Refactor Plan

## Goal

Refactor Lacuna's menu and attached flyout control so Omarchy/Quickshell behavior primitives handle lifecycle, focus, input regions, and outside-click dismissal while Lacuna keeps ownership of visual styling, connector geometry, and animation.

## Target Behavior

- The sidebar remains a click-through shell surface: only visible Lacuna regions receive input.
- Clicking outside an attached flyout dismisses that flyout and does not leave a stale input-blocking overlay.
- Only one attached flyout is active at a time.
- Lacuna visuals stay Lacuna-owned, including Carbon/Material/Omarchy style differences, molding connectors, panel radii, and `LacunaAnim` motion.
- The public Omarchy plugin lifecycle remains `open(payloadJson)` and `close()`.

## Implementation Outline

- Add a Lacuna-owned panel controller for menu-local state:
  - Track `panelVisible` and `activeFlyout`.
  - Provide `openMenu()`, `closeMenu()`, `toggleMenu()`, `openFlyout(id)`, `closeFlyout(id)`, `toggleFlyout(id)`, and `closeActiveFlyout()`.
  - Request `shell.hide(pluginId)` only when Lacuna closes itself rather than when the host is already closing it.
- Add a Lacuna-owned panel window wrapper:
  - Use `PanelWindow`, `Region`, `HyprlandFocusGrab`, and `WlrKeyboardFocus.OnDemand`.
  - Mask only the sidebar, active flyout, and active connector regions.
  - Keep the non-Lacuna desktop click-through.
- Add reusable attached-panel chrome:
  - `LacunaAttachedFlyout` owns slide/fade animation and the right-opening panel shell with a square attachment edge.
  - `LacunaPanelConnector` owns the molding connector shape between the sidebar and active flyout.
- Simplify `MenuWindow.qml`:
  - Replace independent `settingsPanelOpen` and `appPickerOpen` mutation with one active flyout id.
  - Opening settings closes app picker.
  - Opening app picker closes settings.
  - `flyoutLaneWidth` is the width of the active flyout only.

## Manual Test Checklist

- Run `qmllint` on changed QML files.
- Reload plugins with `omarchy-shell shell rescanPlugins`.
- Summon and hide `omarchy.lacuna-menu`.
- Open settings flyout, click outside it, and confirm the flyout slides closed while the sidebar remains open.
- Open app picker, then settings, and confirm only one flyout is visible.
- Toggle collapsed rail, corner pieces, and exclusive sidebar modes; confirm masks and connectors align.
- Confirm no direct dependency is added on Omarchy styled components such as `PopupCard.qml` or `KeyboardPanel.qml`.
