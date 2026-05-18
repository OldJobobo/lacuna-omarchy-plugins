# Lacuna Panel UI Overhaul Plan

## Goal

Overhaul Lacuna's sidebar and attached flyout control so panel lifecycle, rendering, input masking, focus handling, and animation are driven by one coherent transition model. The public Omarchy plugin contract remains unchanged: `open(payloadJson)` and `close()`.

## Current Risks

- Flyout input masks can cover transparent space because `LacunaPanelWindow` masks the full flyout item while `LacunaAttachedFlyout` animates only an internal child.
- Connectors disappear immediately on flyout close while the flyout body continues sliding closed, causing visible gaps.
- Switching flyouts can leave old flyout visuals alive while mask/window geometry points at the new flyout.
- Closed flyouts can flash slivers when width, compact density, or geometry changes alter the derived closed offset.
- Close timing depends on magic delay values that can drift from actual animation duration.

## Target Behavior

- Only visible Lacuna regions receive input.
- The sidebar remains click-through outside visible sidebar, connector, and flyout regions.
- Clicking outside an attached flyout dismisses only the flyout unless the menu itself is explicitly closed.
- Only one attached flyout is active at a time.
- Switching between flyouts does not render overlapping stale panels.
- Connectors stay visually attached through open and close animations.
- Compact mode, rail/full mode, corner pieces, and docked/overlay mode can change while panels are open without graphical artifacts.

## Architecture

### Panel Controller State

Replace scattered lifecycle state with a controller-owned transition model in `plugins/omarchy.lacuna-menu/services/PanelController.qml`.

Track explicit state such as:

- `closed`
- `openingMenu`
- `menuOpen`
- `openingFlyout`
- `flyoutOpen`
- `closingFlyout`
- `closingMenu`

Expose render and input state separately:

- `menuRenderable`
- `menuInteractive`
- `flyoutRenderable`
- `flyoutInteractive`
- `activeFlyout`
- `outgoingFlyout`
- `menuProgress`
- `flyoutProgress`

Renderability should survive animations. Interactivity should turn off immediately when closing.

### Progress-Driven Animation

Move animation progress out of component geometry side effects.

- `MenuSurface` should accept `progress`.
- `LacunaAttachedFlyout` should accept `progress`, `renderable`, and `interactive`.
- `LacunaPanelConnector` should accept `progress` and `renderable`.
- `LacunaPanelWindow` should receive explicit mask rectangles derived from progress.

Derive visual positions from progress:

- Sidebar: `x = -width * (1 - menuProgress)`.
- Flyout: `x = openX - panelWidth * (1 - flyoutProgress)`.
- Connector: visible/renderable while the flyout is renderable, with opacity or width tied to `flyoutProgress`.

Do not use `panelBody.x` or child visibility as lifecycle truth.

### Reusable Flyout Host

Prefer a single `LacunaAttachedFlyout` host with content swapped by `Loader` or `StackLayout`.

Supported flyout kinds:

- `settings`
- `appPicker`

When opening a different flyout while one is already open, swap or crossfade the content inside the same shell instead of closing one shell and opening another. This avoids stale outgoing panels and mask mismatches.

### Connector Handling

`LacunaPanelConnector` should stay alive during flyout close.

Use:

- `renderable: flyoutRenderable && cornerPieces && connectorWidth > 0`
- `progress: flyoutProgress`
- `contentHeight: active flyout height`
- `y: active flyout y - connectorWidth`

The connector should use molding geometry with the existing `curveKappa` constant (`0.5522847498`). It should remain fill-first and avoid thin outer borders.

### Mask Geometry

`LacunaPanelWindow` should not inspect arbitrary child visibility to infer input regions. Instead, pass explicit rounded values:

- sidebar mask rectangle
- connector mask rectangle
- flyout visible-body mask rectangle

The flyout mask should track the visible body during animation, not the full flyout root. This prevents transparent areas from consuming outside clicks.

### Focus Handling

Focus should follow interactivity, not renderability.

- `WlrLayershell.keyboardFocus` should be enabled only for interactive flyouts.
- `HyprlandFocusGrab.active` should be based on menu open plus interactive flyout.
- Focus-clear should close the flyout first.
- Sidebar hide should only occur for explicit menu close or host close, not ordinary flyout dismissal.

### Timing And Race Safety

Remove magic lifecycle delays where practical.

- Use named animations with completion handlers.
- Add a transition revision token.
- Every delayed callback or animation completion should verify that its captured revision is still current before mutating state.

This prevents stale close completions from hiding a panel that has already reopened.

## Implementation Order

1. Refactor `PanelController.qml` into the explicit transition model.
2. Convert `MenuSurface.qml` to accept controller-owned `progress`.
3. Convert `LacunaAttachedFlyout.qml` to progress-driven root/body rendering.
4. Convert `LacunaPanelConnector.qml` to progress-driven renderability.
5. Update `LacunaPanelWindow.qml` to consume explicit mask rectangles.
6. Collapse duplicate flyout instances in `MenuWindow.qml` into one reusable flyout host.
7. Move settings and app picker content into loader components if needed.
8. Normalize shared geometry helpers in `MenuWindow.qml`.
9. Run QML lint.
10. Smoke-test inside Omarchy shell.

## Manual Test Matrix

- Open and close the sidebar normally.
- Rapidly toggle sidebar open and closed.
- Open settings, then close via close button, Escape, outside click, and focus loss.
- Open app picker, type a search, close, and reopen.
- Switch settings to app picker to settings rapidly.
- Toggle compact density while sidebar is open.
- Toggle icon rail/full sidebar while flyout is open.
- Toggle corner pieces while flyout is open.
- Toggle docked/overlay mode while flyout is open.
- Confirm outside clicks are not swallowed by transparent panel areas.
- Confirm no connector gap appears during flyout close.
- Confirm no closed flyout sliver appears when density or width changes.
- Confirm keyboard focus returns correctly after flyout close.

## Verification Commands

```sh
qmllint plugins/omarchy.lacuna-menu/services/PanelController.qml plugins/omarchy.lacuna-menu/menu/*.qml plugins/omarchy.lacuna-menu/settings/*.qml
```

```sh
omarchy-shell-ipc shell rescanPlugins
```

```sh
omarchy-shell-ipc shell summon omarchy.lacuna-menu "{}"
```
