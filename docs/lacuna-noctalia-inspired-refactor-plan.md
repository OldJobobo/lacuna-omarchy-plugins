# Lacuna Noctalia-Inspired Refactor Plan

## Goal

Refactor the Lacuna Omarchy plugins so the sidebar, flyouts, and Lacuna-owned bar widgets behave more like Noctalia's Quickshell surfaces: coherent panel lifecycle, geometry-driven motion, centralized animation tokens, stable input masks, and reusable visual primitives.

The result should still be an Omarchy plugin integration. Do not turn Lacuna into a second standalone shell, do not start another Quickshell process, and do not replace Omarchy-owned services where Omarchy already provides the richer native surface.

## Progress

- 2026-05-19: Began Phase 1 by adding shared Lacuna menu motion tokens and routing the existing menu animation helpers plus panel progress duration through them. This preserves current timings while creating the timing owner needed for later geometry-driven panel animation.
- 2026-05-19: Began Phase 2 controller hardening by adding explicit menu/flyout state names, renderability aliases, outgoing flyout tracking, and revision fields to `PanelController.qml` while preserving the existing `MenuWindow`-facing API.
- 2026-05-19: Collapsed settings and app picker onto a single attached flyout shell and connector in `MenuWindow.qml`, then changed `LacunaAttachedFlyout.qml` to reveal by growing visible width from the sidebar edge with delayed content opacity. Added `LacunaShapeSurface.qml` as the first shared geometry-backed panel shell and made connector pieces fill-only.
- 2026-05-19: Ported the flyout shell to explicit per-corner state through `LacunaCornerHelper.qml`, keeping the sidebar attachment edge square while rounding only exposed right corners. Added `LacunaScrollView.qml` and moved the app picker list onto the shared smooth wheel scrolling primitive.
- 2026-05-19: Verified the current refactor checkpoint with full QML lint, Omarchy shell plugin rescan, `omarchy.lacuna-menu` summon, and live Quickshell log inspection. No Lacuna runtime load errors were present at this checkpoint.
- 2026-05-19: Added `LacunaPanelHost.qml` as the first non-visual geometry owner for sidebar, connector, flyout positions, and input masks. `MenuWindow.qml` now consumes host-owned mask geometry while keeping the existing visual children stable.
- 2026-05-19: Made Lacuna panel background ownership explicit with `Theme.panelBackground`, sourced from `colors.toml` base background and not from `shell.toml` popup/menu background roles. Switched panel progress animations to shared Noctalia-style bezier motion tokens and moved local scroll/view reveal timings onto `MotionTokens.qml`.
- 2026-05-19: Removed stale pre-host flyout mask aliases and the old `attachedFlyoutLeftX` property so mask ownership lives in `LacunaPanelHost.qml`. Re-verified with full QML lint, plugin rescan, menu summon, Quickshell log tail, and a compositor screenshot showing the sidebar rendered.
- 2026-05-19: Removed the remaining thin stroke from `MenuSurface.qml` so sidebar and flyout panel shells are fill-only; internal controls still retain their own borders and selected states.
- 2026-05-19: Extracted the app picker body into `FlyoutAppPickerContent.qml` so the single flyout shell now hosts dedicated settings and app-picker content components. The app picker owns its local search/filter state, and `SettingsWindow.qml` now uses the shared `LacunaScrollView.qml` primitive.
- 2026-05-19: Added short outgoing-content lifetime handling in `PanelController.qml`, allowing settings/app-picker content to crossfade during flyout switches while interactivity remains tied to the active flyout. Began the bar-widget pass by adding local `MotionTokens.qml` to the workspaces and MPRIS plugin component folders and routing their button animation constants through those tokens.
- 2026-05-19: Started the reusable control pass by moving hover/press reveal animation into `LacunaStateLayer.qml` and adding shared color animation to `LacunaTablerIcon.qml`. Menu rows, rail buttons, icon buttons, settings controls, and app-picker controls now get smoother Noctalia-style state transitions from the shared primitives.
- 2026-05-19: Tightened flyout focus ownership so `PanelController.flyoutInteractive` only becomes true after the flyout shell reaches the open end of its geometry animation. App-picker and settings focus requests are now queued and applied once the flyout is interactive, matching the renderability/interactivity split in the plan.
- 2026-05-19: Aligned the workspaces and MPRIS local `LacunaStateLayer.qml` copies with the menu state layer by giving them animated hover/press reveal. Their buttons now bind hover scale/glow to the state-layer reveal instead of running duplicate hover reveal animations locally.
- 2026-05-19: Routed settings rows, settings rail buttons, menu section headers, and app-picker row fills through the animated state-layer reveal instead of raw `containsMouse` checks. This keeps hover background, strip, and count-pill transitions on the shared motion path.
- 2026-05-19: Finished the first control-smoothing pass by moving shared icon button opacity and menu trailing-action fills/borders onto state-layer reveal. Direct hover checks now remain mainly for discrete text weight, tooltip, and drag behaviors.
- 2026-05-19: Made flyout content reveal an explicit controller-owned `contentProgress` value and passed it into `LacunaAttachedFlyout.qml`. The fade curve is unchanged, but renderability, interactivity, and content opacity now share the same controller state model.
- 2026-05-19: Added optional Noctalia-style top and bottom edge masks to `LacunaScrollView.qml`, then enabled them for settings and app-picker flyout lists. The masks fade with shared Lacuna animation tokens and use the Lacuna panel background color.
- 2026-05-19: Hardened controller animation completion with explicit targets and revision-checked completion helpers. `LacunaPanelHost.qml` now caches flyout geometry during transitions so mask rectangles, connector placement, and flyout attachment do not jump if content dimensions change mid-animation.
- 2026-05-19: Reaffirmed Lacuna as a left-owned sidebar independent of Omarchy bar placement. A right-side vertical Omarchy bar now keeps Lacuna's rail/sidebar on the left while still using vertical bar sizing for compact rail dimensions.
- 2026-05-19: Moved the sidebar body fill through `LacunaShapeSurface.qml` and kept molding connector pieces fill-only. Verified full QML lint plus Omarchy shell restart/summon against both top-bar and right-bar compositor geometry.
- 2026-05-19: Finished the first bar-widget cleanup checkpoint. Workspaces and MPRIS use local state-layer components, and the simpler Lacuna widgets now have self-contained motion tokens plus consistent hover reveal treatment without adding cross-plugin runtime imports.
- 2026-05-20: Closed the big refactor checkpoint. Controller-owned lifecycle, host-owned geometry/masks, single flyout shell, delayed content reveal, left-owned sidebar placement, hardened panel background color, shared menu primitives, and Lacuna-owned widget motion tokens are all in place and validated.

## Checkpoint Status

Current status: the major refactor work is complete for this checkpoint. The implementation is usable and lint-clean, with controller-owned lifecycle, host-owned geometry, stable masks, single flyout hosting, geometry-driven reveal, and consistent local motion tokens across Lacuna-owned widgets. Remaining work is optional polish and future consolidation, not required functionality.

Phase status:

- Phase 1 Motion tokens: complete for the menu and Lacuna-owned bar-widget groups in the current plugin boundary model.
- Phase 2 PanelController: complete for the current model. State names, renderability/interactivity, outgoing content, content progress, explicit targets, and revision-checked completion are in place.
- Phase 3 LacunaPanelHost: complete for current sidebar/flyout geometry. Host-owned masks and cached transition geometry are active.
- Phase 4 Single flyout host: complete for settings and app picker. They share one flyout shell and dedicated content components.
- Phase 5 Geometry-first animation: complete for the current shell behavior. Flyout width reveal, delayed content reveal, stable attachment, and cached transition geometry are in place.
- Phase 6 Shape surface layer: complete for the refactor scope. Sidebar and flyout bodies use shared shape primitives; connector molding remains a specialized component because its cubic transition is intentionally different from normal rounded panel corners.
- Phase 7 Reusable controls: complete for the current menu/sidebar surfaces. Rows, rails, icon buttons, settings rows, app picker rows, scroll masks, and local state layers use shared motion/state primitives.
- Phase 8 Bar widget pass: complete for the current checkpoint. Workspaces and MPRIS have local motion/state-layer components, and simpler script/status/theme/wallpaper/menu-button widgets now share the same token-driven hover reveal pattern within their own plugin boundary. A later polish pass can still extract richer pill components per plugin family if the widget set stays this broad.

Deferred polish:

- Extract richer per-family pill components only if the Lacuna widget set continues growing.
- Add automated smoke coverage when the repository gains a real build/test harness.
- Consider a settings-controlled animation disable/reduce-motion switch after the Omarchy plugin settings contract for Lacuna runtime state settles.

Validated at this checkpoint:

- `find plugins -name '*.qml' -print0 | xargs -0 qmllint`
- `omarchy restart shell`
- `omarchy-shell shell summon omarchy.lacuna-menu "{}"`
- Hyprland layer geometry with top bar: Omarchy bar at the top, Lacuna menu at the left below the bar.
- Hyprland layer geometry with right bar: Omarchy bar at the right, Lacuna menu at the left.

## Source Model

Use the local Noctalia shell as an implementation reference:

- `/home/oldjobobo/Projects/noctalia-shell/Modules/MainScreen/SmartPanel.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Services/UI/PanelService.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Modules/MainScreen/Backgrounds/PanelBackground.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Modules/MainScreen/Backgrounds/AllBackgrounds.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Modules/MainScreen/Backgrounds/ShapeCornerHelper.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Commons/Style.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Widgets/NButton.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Widgets/NIconButton.qml`
- `/home/oldjobobo/Projects/noctalia-shell/Widgets/NListView.qml`

Do not copy Noctalia's full plugin registry, settings system, Nix packaging, compositor abstraction, or standalone app ownership. Only copy patterns that fit Omarchy's plugin contract.

## Current Lacuna Problems

- `PanelController.qml` uses two generic progress values rather than an explicit transition state machine.
- `LacunaAttachedFlyout.qml` animates an internal child, so window masks and connector geometry must chase derived child geometry.
- Settings and app picker are separate attached flyout instances, which makes flyout switching vulnerable to stale visuals and stale masks.
- Connectors and flyout bodies do not share one lifecycle owner.
- Sidebar and flyout backgrounds are painted inside each surface instead of through one geometry-aware surface layer.
- Motion timing is split between local constants and component behavior.
- Current animation is mostly slide-based; Noctalia's better feel comes from geometry opening from a cached attachment edge plus delayed content fade-in.

## Target Principles

1. Keep the Omarchy plugin boundary.
2. Make panel lifecycle explicit.
3. Animate geometry from the attachment edge, not just child offsets.
4. Separate renderability from interactivity.
5. Separate surface background geometry from content.
6. Keep only visible regions in the input mask.
7. Cache animation direction when opening so geometry changes during animation do not flip direction.
8. Use one reusable flyout host and swap content inside it.
9. Centralize motion durations, easing, and disabled-animation behavior.
10. Prefer Omarchy-native services for system surfaces; Lacuna should own only its distinctive sidebar and experimental widgets.

## Target Architecture

### 1. Motion Tokens

Add a shared motion layer, either in `DesignTokens.qml` or a new `MotionTokens.qml`.

Required tokens:

- `animationFaster`: about 75 ms
- `animationFast`: about 150 ms
- `animationNormal`: about 300 ms
- `animationSlow`: about 450 ms
- `animationDisabled`: boolean
- `panelBezierCurve`: Noctalia-style `Easing.BezierSpline` curve
- `colorDuration`: about 150-180 ms
- `hoverDuration`: about 120-150 ms

The duration values should respect a Lacuna setting later if needed, but the first pass can hard-code sane values.

### 2. Explicit Panel Controller

Replace the current implicit progress controller in `plugins/omarchy.lacuna-menu/services/PanelController.qml` with a small state machine.

States:

- `closed`
- `openingMenu`
- `menuOpen`
- `openingFlyout`
- `flyoutOpen`
- `switchingFlyout`
- `closingFlyout`
- `closingMenu`

Controller-owned properties:

- `transitionRevision`
- `menuStateName`
- `flyoutStateName`
- `activeFlyout`
- `outgoingFlyout`
- `menuRenderable`
- `menuInteractive`
- `flyoutRenderable`
- `flyoutInteractive`
- `menuProgress`
- `flyoutProgress`
- `contentProgress`
- `panelGeometry`
- `flyoutGeometry`
- `connectorGeometry`

Rules:

- Renderability stays true until close animation completes.
- Interactivity turns off immediately when closing.
- Every animation completion checks a captured `transitionRevision` before mutating state.
- Switching flyouts should keep one shell host alive and swap or crossfade content.
- Closing the flyout should not close the sidebar unless explicitly requested.

### 3. Lacuna Panel Host

Create a new host component:

```text
plugins/omarchy.lacuna-menu/menu/LacunaPanelHost.qml
```

Responsibilities:

- Own sidebar, connector, flyout, and content geometry.
- Expose explicit mask rectangles to `LacunaPanelWindow`.
- Open and close from stable cached attachment directions.
- Keep left sidebar attachment fixed while flyouts grow or shrink.
- Delay content opacity until the shell geometry is at least halfway open.
- Flush stale state on immediate close paths where needed.

This is Lacuna's equivalent of Noctalia `SmartPanel`, but narrower. It should not become a general shell-wide panel manager.

### 4. Geometry-Driven Surface Animation

For the left sidebar:

- Sidebar opens from the left edge.
- Sidebar width animates or slides based on selected mode.
- Full sidebar content fades in after the shell is substantially open.
- Icon rail mode keeps stable dimensions and does not recalculate width mid-transition.

For right-opening flyouts attached to the sidebar:

- Left edge remains attached to the sidebar connector.
- Width grows from `0` to target width.
- Height can animate only when content-driven height changes.
- Content opacity starts after width progress crosses the configured threshold.
- Close fades content first, then shrinks shell geometry.

For app picker and settings:

- Use one flyout shell.
- Swap content using a `Loader`.
- When switching between settings and app picker, keep the shell open and crossfade content rather than closing and reopening the whole shell.

### 5. Shape Surface Layer

Introduce a reusable geometry-backed shape layer:

```text
plugins/omarchy.lacuna-menu/menu/LacunaShapeSurface.qml
plugins/omarchy.lacuna-menu/menu/LacunaCornerHelper.qml
```

Use Noctalia's corner-state idea:

- `-1`: flat/square corner
- `0`: normal inner rounded corner
- `1`: horizontal outer curve
- `2`: vertical outer curve

Adapt it to Lacuna:

- Sidebar attachment edge stays square.
- Right-opening flyouts round only exposed right corners.
- Connector pieces use molding transitions, not ordinary rounded rectangle corners.
- Shape paths should be fill-only for panel shells.
- Avoid degenerate zero-radius arcs by using a tiny minimum radius if `PathArc` is used.

Target outcome:

- Sidebar, connector, and flyout backgrounds are drawn from one coherent geometry model.
- The connector remains alive during both open and close.
- No thin outer borders on flyout shells.
- Internal controls can still use borders for focus, selection, and dividers.

### 6. Input Mask Ownership

`LacunaPanelWindow.qml` should consume explicit geometry from the host:

- sidebar visible mask rectangle
- connector visible mask rectangle
- flyout visible mask rectangle

Rules:

- Masks are derived from host-owned geometry, not child visibility.
- Transparent areas never consume clicks.
- During close, mask tracks the shrinking visible shell.
- During switch, mask stays attached to the active shell rather than the old outgoing content.

### 7. Focus And Keyboard Handling

Focus follows interactivity:

- `WlrLayershell.keyboardFocus` is enabled only while a flyout is interactive.
- `HyprlandFocusGrab.active` is true only when the menu is open and the active flyout is interactive.
- Focus clear closes the flyout first.
- Sidebar hide occurs only for explicit menu close or host close.
- Search fields should request focus after content load and after the shell reaches its interactive state.

Consider a short keyboard initialization period only if Hyprland focus remains flaky, using Noctalia's `isInitializingKeyboard` pattern as reference.

### 8. Reusable Content Primitives

After the panel host is stable, refactor Lacuna UI controls into a small widget set:

```text
plugins/omarchy.lacuna-menu/components/LacunaButton.qml
plugins/omarchy.lacuna-menu/components/LacunaIconButton.qml
plugins/omarchy.lacuna-menu/components/LacunaListView.qml
plugins/omarchy.lacuna-menu/components/LacunaSurfaceBox.qml
plugins/omarchy.lacuna-menu/components/LacunaScrollView.qml
```

Model them after Noctalia's widgets, but use Lacuna/Omarchy tokens:

- hover and press colors animate through shared motion tokens
- icon and text colors animate consistently
- scroll lists support smooth wheel movement and gradient edge masks where useful
- controls expose stable implicit sizes
- controls do not resize on hover

### 9. Bar Widget Cleanup

Apply the same primitives to Lacuna bar widgets after the menu refactor:

- `omarchy.lacuna-menu-button`
- `omarchy.lacuna-script-pill`
- `omarchy.lacuna-compact-pill`
- `omarchy.lacuna-system-stats`
- `omarchy.lacuna-temperature`
- `omarchy.lacuna-codex-usage`
- `omarchy.lacuna-claude-usage`
- `omarchy.lacuna-theme`
- `omarchy.lacuna-wallpaper`
- `omarchy.lacuna-workspaces`
- `omarchy.lacuna-mpris`

Goals:

- shared pill geometry
- shared hover/press state layer
- shared color profile adapter
- consistent `Behavior` use
- no per-widget animation constants unless a widget has a real reason

Do not duplicate Omarchy-native widgets unless Lacuna adds a distinct workflow or visual treatment.

## Implementation Phases

### Phase 1: Record Motion And State Contracts

1. Add `MotionTokens.qml` or extend `DesignTokens.qml`.
2. Replace `LacunaAnim.qml` and `LacunaColorAnim.qml` internals to read shared motion tokens where possible.
3. Document the panel lifecycle states in `PanelController.qml`.
4. Add no visual behavior changes yet.

Success criteria:

- Existing menu behavior is unchanged.
- `qmllint` passes for changed files.
- Motion constants have one owner.

### Phase 2: Refactor PanelController

1. Add explicit state names.
2. Add `transitionRevision`.
3. Split renderability and interactivity.
4. Replace `onStopped` mutation with revision-checked completion helpers.
5. Preserve the public functions used by `MenuWindow.qml`: `openMenu`, `closeMenu`, `toggleMenu`, `openFlyout`, `closeFlyout`, `toggleFlyout`.

Success criteria:

- Sidebar opens and closes as before.
- Settings flyout opens and closes as before.
- Rapid toggles do not leave stale renderable state.

### Phase 3: Build LacunaPanelHost

1. Add `LacunaPanelHost.qml`.
2. Move sidebar/flyout/connector geometry ownership into it.
3. Keep existing `MenuSurface`, `LacunaAttachedFlyout`, and `LacunaPanelConnector` working under the host first.
4. Route `LacunaPanelWindow` mask rectangles from host-owned properties.

Success criteria:

- No input mask regression.
- No connector disappearance during close.
- Existing visual shell remains recognizable.

### Phase 4: Single Flyout Host

1. Replace duplicate `settingsFlyout` and `appPicker` shell instances with one reusable flyout host.
2. Move settings content into a loader component.
3. Move app picker content into a loader component.
4. Support crossfade or instant content swap while shell remains open.

Success criteria:

- Switching settings to app picker does not show overlapping panels.
- Search focus still works in app picker.
- Settings close button still closes only the flyout.

### Phase 5: Geometry-First Animation

1. Animate flyout width from `0` to target width.
2. Keep the flyout's left edge fixed against the sidebar connector.
3. Fade content in after shell progress crosses the threshold.
4. On close, fade content first, then shrink shell.
5. Cache animation direction and target geometry when opening.

Success criteria:

- Motion feels like Noctalia's panel open/close.
- Flyout close does not flash slivers.
- Compact/full/sidebar mode changes do not flip animation direction mid-flight.

### Phase 6: Shape Surface Layer

1. Add `LacunaCornerHelper.qml`.
2. Add `LacunaShapeSurface.qml`.
3. Port sidebar body shape.
4. Port flyout shape.
5. Port connector shape.
6. Remove one-off duplicated connector path code where practical.

Success criteria:

- Exposed flyout corners are rounded.
- Attached edge is square.
- Connector pieces are molding transitions.
- Shell shapes are fill-only.

### Phase 7: Reusable Controls

1. Create shared Lacuna controls inspired by Noctalia widgets.
2. Replace repeated button/list/pill behavior in the menu.
3. Keep all visual states stable under hover and press.
4. Add smooth scroll behavior where useful.

Success criteria:

- Menu rows, rail buttons, settings rows, and app picker rows use the same state model.
- Hover/press animations feel consistent.
- Text and icons do not shift on hover.

### Phase 8: Bar Widget Pass

1. Extract shared pill/button primitives usable outside `omarchy.lacuna-menu`.
2. Update Lacuna bar widgets one group at a time.
3. Preserve existing manifest schemas and Omarchy Settings behavior.
4. Keep plugin-relative script path handling intact.

Success criteria:

- Widgets appear in Omarchy Settings.
- Widgets survive shell restart.
- Widgets use shared animation and state-layer behavior.
- No widget starts a separate Quickshell process.

## File Map

Likely new files:

- `plugins/omarchy.lacuna-menu/services/MotionTokens.qml`
- `plugins/omarchy.lacuna-menu/menu/LacunaPanelHost.qml`
- `plugins/omarchy.lacuna-menu/menu/LacunaShapeSurface.qml`
- `plugins/omarchy.lacuna-menu/menu/LacunaCornerHelper.qml`
- `plugins/omarchy.lacuna-menu/components/LacunaScrollView.qml`
- `plugins/omarchy.lacuna-menu/menu/FlyoutAppPickerContent.qml`

Likely major edits:

- `plugins/omarchy.lacuna-menu/services/PanelController.qml`
- `plugins/omarchy.lacuna-menu/services/DesignTokens.qml`
- `plugins/omarchy.lacuna-menu/menu/MenuWindow.qml`
- `plugins/omarchy.lacuna-menu/menu/LacunaPanelWindow.qml`
- `plugins/omarchy.lacuna-menu/menu/MenuSurface.qml`
- `plugins/omarchy.lacuna-menu/menu/LacunaAttachedFlyout.qml`
- `plugins/omarchy.lacuna-menu/menu/LacunaPanelConnector.qml`
- `plugins/omarchy.lacuna-menu/components/LacunaAnim.qml`
- `plugins/omarchy.lacuna-menu/components/LacunaColorAnim.qml`

## Manual Test Matrix

- Open and close the sidebar.
- Rapidly toggle the sidebar.
- Open settings, close settings.
- Open app picker, type search, close app picker.
- Switch settings to app picker and back repeatedly.
- Toggle compact mode while the menu is open.
- Toggle full sidebar/icon rail while the menu is open.
- Toggle corner pieces while a flyout is open.
- Toggle docked/overlay mode while a flyout is open.
- Click transparent space around the sidebar and flyout.
- Confirm outside clicks do not get swallowed by invisible regions.
- Confirm search focus works after flyout animation.
- Confirm no connector gap appears during close.
- Confirm no stale old flyout remains visible during switch.
- Confirm current theme changes do not recolor Lacuna panel shell from popup/menu background roles.

## Verification Commands

```sh
qmllint plugins/omarchy.lacuna-menu/services/*.qml plugins/omarchy.lacuna-menu/menu/*.qml plugins/omarchy.lacuna-menu/components/*.qml plugins/omarchy.lacuna-menu/settings/*.qml
```

```sh
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell rescanPlugins
```

```sh
OMARCHY_PATH="$HOME/.local/share/omarchy" ~/.local/share/omarchy/bin/omarchy-shell shell summon omarchy.lacuna-menu "{}"
```

## Non-Goals

- Do not port Noctalia wholesale.
- Do not introduce a second plugin registry.
- Do not replace Omarchy's native settings, notifications, tray, audio, network, or media services.
- Do not move Lacuna settings into Omarchy theme files.
- Do not require root-level runtime imports from this repository.
- Do not change the public Omarchy menu plugin contract.

## Open Questions

1. Should Lacuna expose a user setting for animation speed, or keep motion tuned and fixed?
2. Should the sidebar itself slide, grow from the edge, or support both as design styles?
3. Should the app picker preview panel become a second attached flyout lane later?
4. Should shared Lacuna controls live inside `omarchy.lacuna-menu` first, then be copied to bar widgets, or should they become a tiny shared component package per plugin?
5. Should Lacuna continue maintaining separate bar widgets where Omarchy has strong native widgets, or should the refactor reduce the widget set to only distinct Lacuna workflows?
