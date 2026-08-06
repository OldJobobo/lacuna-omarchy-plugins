# Lacuna Sidebar Autohide Plan

Status: implemented and live-verified on DP-1; extended multi-output matrix pending

Purpose: add an opt-in sidebar autohide mode that reveals the configured full
sidebar or icon rail from a left-edge hot zone without stealing focus, shifting
application windows, remapping Lacuna's Overlay surface, or weakening per-output
fullscreen suppression.

This is a pointer-state, input-mask, and geometry feature. It is not a second
menu implementation and must not create another layer-shell window.

## 1. Required Outcome

When autohide is enabled, each eligible output exposes a narrow hot zone along
the first usable pixel at its left edge. A deliberate pointer dwell reveals the
chosen `full` or `rail` presentation on that output. The sidebar remains visible
while the pointer is anywhere in the sidebar, connector, or attached flyout
interaction envelope, then conceals after a short grace period.

The implementation must satisfy these invariants:

1. Concealed autohide reserves no compositor space and captures input only in
   the hot zone.
2. Revealing and concealing never move or resize application windows.
3. The existing `PanelController.menuProgress` remains the only sidebar reveal
   animation progress.
4. The sidebar and flyouts remain pointer-first and do not take keyboard focus
   unless an existing explicitly keyboard-driven surface requires it.
5. Fullscreen disables paint, reserves, and hot-zone input on only the affected
   output.
6. Rail/full geometry is selected before the first reveal frame; a reveal may
   not resize from one presentation to the other mid-animation.
7. Flyout open, close, or switching cannot accidentally conceal the sidebar.
8. Explicit open and close requests remain deterministic and cannot bounce
   against a stationary pointer.
9. Existing behavior is unchanged when autohide is disabled.

## 2. Fixed Product Decisions

These decisions should be approved before implementation. They are the
recommended first-release contract.

### 2.1 Autohide is additive and disabled by default

Keep the current startup preference (`sidebar.defaultMode`) intact. Add a
separate autohide configuration with its own reveal presentation:

```json
"autoHide": {
  "enabled": false,
  "hotZoneWidth": 3,
  "revealDelayMs": 120,
  "hideDelayMs": 350
}
```

Autohide does not own a second presentation mode. The existing sidebar
full/rail state remains authoritative both while persistent and when revealed
from the edge. Turning autohide on or off must not rewrite `defaultMode`,
`collapsed`, or `exclusive` as a side effect.

### 2.2 Autohide always overlays

The effective exclusive zone is zero for the entire time autohide is enabled,
including while an explicit request holds the sidebar open. Repeatedly adding
and removing a docked exclusive zone on pointer hover would reflow application
windows and is not acceptable.

The stored Docked/Overlay preference remains unchanged and becomes effective
again when autohide is disabled. Lacuna Settings must explain that Window Mode
is temporarily overridden by autohide rather than silently changing it.

### 2.3 Reuse the existing sidebar window

Extend the existing `LacunaPanelWindow`; do not add a hot-zone window. Keep it
mapped while autohide is armed, preserve its layer assignment, and expose only a
small masked input region while concealed. This preserves map order and avoids
adding another namespace to the layer-stacking policy.

### 2.4 Hot-zone placement

The hot zone occupies the left edge of each eligible output's usable content
area:

- top/bottom bars are excluded vertically using the existing visual insets;
- when Omarchy's bar is on the left, the bar owns the physical edge and the hot
  zone begins at the first content pixel immediately beside it;
- fullscreen removes the hot-zone mask entirely;
- the configured width is in logical pixels and must be validated at fractional
  output scales.

Initial bounded defaults are 3 px width, 120 ms reveal dwell, and 350 ms hide
grace. The implementation should clamp width and delays to safe ranges rather
than trusting state-file input.

### 2.5 Per-output behavior

Monitor policy continues to determine eligible outputs:

- `auto`: arm the currently selected/focused sidebar output;
- `pinned`: arm every configured live output;
- `all`: arm every live output.

Only the output whose hot zone was activated reveals in autohide mode. If
multiple outputs are eligible, serialize handoff: fully settle the old output's
close before assigning visible paint and interaction to the new output. This
prevents a shared `menuState.open` value from revealing every mirrored variant.

A pointer crossing an internal monitor seam may enter another output's left hot
zone. The dwell is intentional protection against accidental reveals; the
first release does not attempt compositor-specific pointer-pressure detection.

### 2.6 Explicit requests and rearming

A hot-zone reveal is passive and may hide after pointer exit. A public
`open(payloadJson)`, bar-menu action, or equivalent explicit request creates a
held-open session on the requested/focused output. That session remains open
until an explicit close or an existing action that deliberately closes the
whole menu.

After explicit close, disarm edge activation until the pointer leaves the hot
zone. Re-entering then starts a fresh dwell. This prevents close/reopen bounce
when the close action occurs while the pointer is still at the edge.

## 3. State And Ownership

Do not overload `PanelController` with pointer policy. Preserve the existing
owners and add one focused service.

| Owner | Responsibility |
| --- | --- |
| `SidebarState.qml` | Persist and expose autohide preferences without replacing unknown sidebar fields. |
| New `SidebarAutohideController.qml` | Own pointer intent, dwell/grace timers, holds, output assignment, rearm, and suppression. |
| `PanelController.qml` | Continue owning menu/flyout transition targets, progress, and revision safety. |
| `MenuWindow.qml` | Bind policy to monitor selection, content state, frame/bar geometry, and controller requests. |
| `LacunaPanelWindow.qml` | Own mapped window behavior and the exact hot-zone/sidebar/connector/flyout input regions. |
| `LacunaPanelHost.qml` | Continue owning visible sidebar/flyout geometry and masks; do not make it a timer owner. |
| `Bar.qml` | Consume actual per-screen reveal visibility for frame cutouts, outlines, and flyout avoidance. |

### 3.1 Autohide state machine

Use explicit semantic phases rather than loosely coupled booleans:

- `disabled`: ordinary current behavior;
- `concealed`: mapped and armed, with hot-zone input only;
- `revealPending`: pointer is in the zone and dwell is running;
- `revealing`: menu animation targets 1;
- `visible`: passively revealed and pointer envelope is active;
- `hidePending`: pointer left the envelope and grace is running;
- `hiding`: menu animation targets 0;
- `held`: explicit open or semantic content hold prevents pointer hide;
- `suppressed`: fullscreen, invalid output, disabled Lacuna, or monitor removal.

Track at minimum:

- candidate and active output names;
- hot-zone, sidebar, connector, and flyout hover state;
- explicit-open hold;
- flyout open/render/transition hold;
- keyboard-edit and modal-content holds;
- fullscreen suppression;
- edge rearm after explicit close;
- a monotonically increasing intent revision so stale timer callbacks cannot
  apply to newer pointer or output state.

The controller should emit semantic `revealRequested(screenName, reason)` and
`concealRequested(reason)` signals. `MenuWindow` routes those requests through
`PanelController.openMenu()` and `closeMenu()`.

### 3.2 Complete interaction envelope

The hide timer may run only when all of these are false:

- hot zone hovered;
- sidebar hovered;
- connector hovered;
- attached flyout hovered;
- flyout open or transitioning;
- explicitly held open;
- keyboard input active;
- rename/editor interaction active;
- restart confirmation or another modal sidebar interaction active.

Moving between sidebar, connector, and flyout may briefly clear one hover flag.
Evaluate the combined envelope on the next event-loop turn before starting the
hide grace so sibling handoff does not flicker.

## 4. Layer-Shell And Input-Mask Design

Extend `LacunaPanelWindow.qml` with explicit hot-zone inputs and signals:

- `hotZoneEnabled`;
- `hotZoneX`, `hotZoneY`, `hotZoneWidth`, `hotZoneHeight`;
- `hotZoneEntered()` and `hotZoneExited()`;
- a fourth `Region` in the existing mask;
- an invisible `HoverHandler` or hover-enabled target over the same geometry.

Separate `inputActive` into visible-surface input and hot-zone input. Current
`inputActive: panelVisible` cannot arm a concealed sidebar. While concealed:

- `visible` remains true through `keepMapped`;
- sidebar, connector, and flyout mask widths are zero;
- only the hot-zone region has non-zero input geometry;
- `WlrKeyboardFocus.None` remains effective;
- no invisible portion of the permanently reserved flyout lane accepts input.

During reveal, masks must follow the existing effective geometry. During
fullscreen, hot-zone input becomes zero immediately even if the mapped window
is retained for layer-order stability.

## 5. Geometry And Reserve Policy

Introduce explicit effective policy in `MenuWindow.qml`:

- `effectiveSidebarExclusive = sidebarState.exclusive && !autoHideEnabled`;
- `sidebarReserveActive` and all sidebar-owned reserve windows remain false
  while autohide is enabled;
- `sidebarVisibleOnScreen(screen)` uses the active reveal output in autohide
  mode and retains current mirrored behavior otherwise;
- panel width is derived from the existing runtime `collapsed` state before
  opening;
- the active output remains assigned until `menuProgress` reaches zero, so the
  closing animation and frame cutout do not vanish early.

Update `Bar.qml` to use actual per-screen reveal state for:

- frame/sidebar occlusion;
- bar outline inset;
- bar flyout avoidance;
- frame geometry keys and snapshots.

The frame must close its left edge only after the sidebar finishes concealing.
Rapid reveal/hide reversal and output handoff must interpolate from the current
geometry rather than snap through a fully closed intermediate state.

## 6. Settings And Migration

Update:

- `lacuna.menu/services/LacunaSettings.qml`;
- `lacuna.menu/services/SidebarState.qml`;
- `config/settings.example.json`;
- `tests/fixtures/full-settings.json`.

Normalization requirements:

1. Missing `autoHide` means disabled, preserving existing behavior.
2. Drop the superseded `autoHide.revealMode` field during normalization; never
   auto-enable the feature.
3. Clamp width and timing fields to documented safe ranges.
4. Preserve unknown JSON-safe fields both in `sidebar` and nested `autoHide`.
5. Save owned fields by merge; do not replace the whole sidebar object.
7. Canonical reset disables autohide and restores defaults without deleting
   unrelated future sidebar state.

Add Lacuna Settings controls under Layout:

- **Autohide Sidebar** toggle;
- the existing **Sidebar Default** Full/Rail choice controls reveal presentation;
- advanced or concise controls for hot-zone width, reveal delay, and hide delay;
- a Window Mode hint explaining that autohide uses Overlay temporarily.

## 7. Test-First Implementation Phases

### Phase 0 — Approve interaction decisions

Approve Sections 2 and 3, especially effective Overlay behavior, single-active
output behavior under `pinned`/`all`, and explicit-open hold semantics. Do not
implement around unresolved alternatives.

### Phase 1 — Settings contract

Add failing migration and persistence probes, then implement normalization and
`SidebarState` mutations. Assert invalid-value clamping and unknown-field
preservation.

Primary tests:

- `tests/test_qml_behavior_lacuna_settings.py`;
- `tests/test_qml_contracts.py`;
- `tests/test_lacuna_installer.py`.

### Phase 2 — Pure autohide policy

Add `tests/test_qml_behavior_sidebar_autohide.py` and deterministic probes for:

- dwell completion and cancellation;
- hide grace and cancellation;
- pointer transfer across the full interaction envelope;
- full versus rail reveal;
- explicit-open hold and explicit-close rearm;
- flyout and keyboard/modal holds;
- close/reopen reversal;
- fullscreen suppression;
- monitor removal and serialized output handoff;
- reduced-motion settlement;
- stale timer/revision rejection.

Make timing inputs injectable so tests do not depend on wall-clock-scale waits.
Then add `SidebarAutohideController.qml`.

### Phase 3 — Mapped hot zone and masks

Extend `LacunaPanelWindow.qml` and bind it in `MenuWindow.qml`. Add geometry and
runtime assertions proving:

- concealed input equals only the hot-zone rectangle;
- adjacent application content is not intercepted;
- visible masks match sidebar/connector/flyout paint;
- fullscreen clears all input on the affected output;
- no new layer namespace or layer assignment appears.

### Phase 4 — Menu, frame, and bar integration

Wire semantic requests to `PanelController`, add per-output active visibility,
force effective Overlay behavior, and update frame/bar geometry. Test opening,
closing, reversal, rail/full, frame on/off, top/left bar placement, and monitor
handoff at animation start, midpoint, and endpoint.

Primary files:

- `lacuna.menu/menu/MenuWindow.qml`;
- `lacuna.menu/menu/LacunaPanelWindow.qml`;
- `lacuna.bar/Bar.qml`;
- `tests/test_qml_behavior_panels.py`;
- `tests/test_qml_geometry.py`;
- `tests/test_qml_contracts.py`.

### Phase 5 — Settings UI and documentation

Add registry actions and Layout controls. Update:

- `docs/configuration/lacuna-settings.md`;
- `docs/guides/sidebar-and-launchers.md`;
- `docs/guides/multiple-monitors.md`;
- `docs/architecture/layer-stacking.md`;
- `config/release-inventory.json`.

The layer document should record that autohide keeps the existing Overlay menu
surface mapped and adds no new level assignment. Overlay keeps the complete
sidebar/flyout assembly above the persistent Top frame regardless of map order;
foreground ambience shares Overlay under the documented resource-first mapping
semantics.

### Phase 6 — Live validation

Add an opt-in `LACUNA_LIVE_VISUAL=1` probe that records active output, menu
progress, panel width, masks, reserve, frame occlusion, and hover phase through
reveal, conceal, and reversal. Restore every modified setting in cleanup.

Run:

```bash
python3 -m pytest tests/test_qml_behavior_sidebar_autohide.py
python3 -m pytest tests/test_qml_behavior_panels.py tests/test_qml_behavior_lacuna_settings.py
python3 -m pytest tests/test_qml_geometry.py tests/test_qml_contracts.py
python3 -m pytest tests/test_lacuna_installer.py tests/test_docs_contracts.py
./scripts/check.sh
./scripts/dev deploy lacuna.menu
./scripts/dev deploy lacuna.bar
```

Manually verify:

- slow and fast edge passes;
- full and rail reveal;
- sidebar-to-flyout traversal;
- explicit bar/menu open and close;
- top and left bars;
- 1x and fractional output scales;
- `auto`, multi-output `pinned`, and `all` monitor policies;
- output disconnect during dwell and while visible;
- real fullscreen independently on each output.

## 8. Completion Criteria

The plan is complete only when:

- the approved settings survive migration, save, reset, and restart;
- edge dwell and hide grace are deterministic under rapid reversal;
- hidden state captures no input outside the hot zone;
- fullscreen captures no hot-zone input at all;
- rail/full geometry is correct from the first reveal frame;
- flyouts and modal/keyboard interactions cannot trigger accidental conceal;
- explicit close cannot bounce open under a stationary pointer;
- autohide never creates an exclusive zone or application reflow;
- monitor handoff never paints two autohide sidebars simultaneously;
- frame/bar seams remain correct throughout transition endpoints and reversal;
- layer assignments and namespaces remain unchanged;
- repository checks pass;
- both changed plugins are deployed, verified against the checkout, and tested
  in the running Omarchy shell.

## 9. Principal Risks

- A mask bug in a permanently mapped layer-shell window can intercept invisible
  screen content; runtime mask probes and live pointer testing are mandatory.
- A 1 px logical strip may be unreliable at fractional scale; keep the default
  bounded to 2–4 px until scale testing proves otherwise.
- Shared `menuState.open` currently maps naturally to mirrored sidebars; the
  active-output gate must be authoritative in autohide mode.
- Left-positioned bars own the physical edge and must not be covered by the hot
  zone.
- Tooltips, rename controls, restart confirmation, and keyboard-enabled media
  or app-picker content outlive simple hover and require semantic holds.
- Frame and menu transitions have different owners; releasing active-output
  state before close settlement can create a temporary border gap.
- This repository already contains unrelated plan-index edits. Preserve them
  when adding this plan to `docs/plans/README.md`.

## 10. Implementation Checkpoint

Implemented in the repository with a dedicated autohide policy controller,
additive settings migration, mapped hot-zone input, per-output visibility,
Overlay-only reserve policy, settings controls, documentation, and behavior
coverage.

Live DP-1 validation confirmed:

- the concealed 3 px hot zone reveals the full sidebar after dwell;
- leaving the complete sidebar area conceals it after the grace period;
- the existing Rail sidebar state reveals the icon rail from the same hot zone;
- real fullscreen suppresses edge activation and sidebar paint;
- installed `lacuna.state`, `lacuna.menu`, and `lacuna.bar` copies match this
  checkout after shell restart.

The remaining release boundary is the extended matrix across pinned/all
multi-output handoff, fractional scaling, and left-positioned bars.
