# Sidebar And Settings Flyout Stability Plan

Status: completed and user-verified (2026-07-11)

Purpose: eliminate the residual sidebar displacement/hide-pop visible when
opening or closing the Lacuna Settings and Omarchy Shell Settings flyouts.
This is a state/geometry correctness fix, not optional animation work.

Current diagnosis: the sidebar and flyout share a layer-shell window whose
implicit width previously grew only while a flyout was renderable. Hyprland
briefly scaled the existing sidebar buffer during that resize, compressing the
sidebar background and all child content before the replacement buffer arrived.
The final fix reserves the maximum flyout lane for the lifetime of every
mapped sidebar surface, so opening and closing a flyout cannot resize it.

## Reported Behavior

- Closing either settings flyout makes the sidebar begin hiding, then pop back
  into place after the flyout closes.
- Opening either settings flyout makes the sidebar hide or retract briefly,
  then the sidebar and flyout reveal again.
- The first mitigation, `retainMenuOnExternalClose`, reduced the displacement
  but did not remove it. It must remain a hypothesis under test, not be treated
  as proof that the host-close path is the only cause.

## Required Invariant

When a persistent sidebar is already open in `rail` or `full` mode, opening,
closing, switching, or focus-clearing an attached settings flyout may change
only flyout, connector, focus, and flyout-mask state.

Throughout that operation:

- `menuProgress` remains `1`;
- `panelVisible` and `sidebarSurfaceVisible` remain `true`;
- sidebar width, x position, screen assignment, reserve, and input mask remain
  stable;
- `menuState.open` must not cause a sidebar close/reopen cycle;
- flyout close ends with `activeFlyout`, `visibleFlyout`, and incoming/outgoing
  content cleared while the sidebar remains interactive;
- flyout open must not replay the sidebar reveal.

`defaultMode: off` and an explicit whole-menu close retain their existing
ability to close the sidebar.

## Scope

Primary runtime files:

- `lacuna.menu/services/PanelController.qml`
- `lacuna.menu/menu/MenuWindow.qml`
- `lacuna.menu/menu/LacunaPanelWindow.qml`
- `lacuna.menu/menu/LacunaPanelHost.qml`
- `lacuna.menu/menu/MenuSurface.qml`
- `lacuna.bar/Bar.qml`

Primary tests:

- `tests/test_qml_behavior_panels.py`
- `tests/test_qml_geometry.py`
- `tests/test_qml_contracts.py`
- `tests/test_live_visual.py`

Do not change layer assignments, public plugin IDs, settings schemas, flyout
visual design, motion tokens, or ambience/video plugins.

## Phase 1 — Capture The Actual Transition

Add one opt-in transition trace owned by `PanelController` and exposed through
`MenuWindow`. Each state-changing event must emit one structured record with a
monotonic sequence number and event name.

Capture:

- `menuState.open`, `hostClosing`, and `retainMenuOnExternalClose`;
- `menuStateName`, `menuProgress`, `menuAnimationTarget`, and revision;
- `activeFlyout`, `visibleFlyout`, `incomingFlyout`, `outgoingFlyout`, and
  `closingFlyout`;
- `flyoutStateName`, `flyoutProgress`, target, and revision;
- focus-grab active/cleared and pending flyout focus;
- `panelVisible`, `sidebarSurfaceVisible`, sidebar mode, width, and reserve;
- effective sidebar x, flyout x/width, connector width, and all three input
  mask widths;
- focused monitor, sidebar screen, and flyout screen.

The trace must be disabled by default and must never include credentials,
commands, or provider payloads.

Record all of these live cases for both `settings` and `shellSettings`:

1. open from a persistent full sidebar;
2. close with the header close button;
3. close with Escape;
4. close after focus moves outside the flyout;
5. switch directly from one settings flyout to the other;
6. repeat in rail mode;
7. repeat with reduced motion enabled.

Do not choose the production fix until the first frame in which a sidebar
invariant changes is identified.

## Phase 2 — Pin Failing Tests

Before production changes, add deterministic tests for the observed owner.

### Controller behavior

Add runtime probes asserting that a persistent open menu:

- never targets menu animation `0` during flyout open or close;
- never drops `menuProgress` below `1` during an external focus/host handoff;
- settles flyout close without changing sidebar intent;
- handles a close/open or focus-clear callback in the same event-loop turn;
- preserves the invariant with normal and reduced motion.

Keep the existing `retainMenuOnExternalClose` regression test, but expand it
to cover a complete settings flyout lifecycle rather than a single external
`menuState.open = false` assignment.

### Geometry behavior

Add deterministic geometry tests sampling the start, midpoint, and endpoint
of settings flyout open and close. Assert that sidebar x, width, reserve, and
sidebar mask are identical at every sample while flyout and connector geometry
change.

### Live visual behavior

Add an opt-in `LACUNA_LIVE_VISUAL=1` probe that records the relevant geometry
at short intervals through both flyout lifecycles. It must restore the prior
sidebar mode, reduced-motion value, section, and open state in `finally` or
`tearDown` cleanup.

## Phase 3 — Correct Ownership

Apply the smallest correction indicated by the trace, following these fixed
ownership rules:

1. Persistent sidebar visibility is durable product intent. Flyout focus and
   host popup state cannot own it.
2. `PanelController` alone owns menu and flyout transition targets/revisions.
3. `LacunaPanelHost` alone owns effective sidebar/flyout/connector and mask
   geometry. Paint and input consumers use the same effective values.
4. `HyprlandFocusGrab` may request flyout close. Its activation or teardown
   must not mutate persistent sidebar intent or start menu animation.
5. `MenuWindow.applySidebarDefaultState()` is startup/reconfiguration logic,
   not a transition-completion callback. Do not use it to repair a sidebar
   after a flyout handoff.
6. A persistent sidebar must not be fixed by closing and immediately reopening
   `menuState`; keep it continuously open/renderable instead.

Expected correction shape:

- separate durable sidebar intent from transient hosted-menu/flyout focus;
- classify explicit whole-menu closes separately from external focus/host
  clears;
- leave menu animation untouched for flyout-only operations;
- keep stable sidebar geometry cached independently of active flyout width and
  render lifetime;
- remove any redundant reopen/default reapplication exposed by the trace.

Do not add another timeout, debounce, delayed reopen, opacity patch, or second
animation. Those approaches can hide the race but cannot satisfy the invariant.

## Phase 4 — Validate Live

Run:

```bash
python3 -m pytest tests/test_qml_behavior_panels.py tests/test_qml_geometry.py
python3 -m pytest tests/test_qml_contracts.py
./scripts/check.sh
./scripts/dev deploy lacuna.menu
```

If the trace shows that `lacuna.bar/Bar.qml` participates, deploy
`lacuna.bar` in the same operation.

After deployment, manually exercise both settings flyouts with header close,
Escape, focus loss, direct switching, full mode, and rail mode. Inspect the
structured trace and confirm no sidebar invariant changes. Only then report
the visual issue fixed.

## Completion Criteria

This plan is complete when:

- the first incorrect state/geometry mutation is documented;
- controller, geometry, and opt-in live tests reproduce the old glitch;
- the fix removes the close/reopen or geometry discontinuity rather than
  masking it;
- both settings flyouts pass every lifecycle case in full and rail modes;
- reduced motion reaches the same stable states;
- repository checks pass;
- installed plugin copies match the repository;
- the running Omarchy shell has been restarted and manually verified;
- temporary transition tracing is removed or retained only as a documented,
  disabled diagnostic facility.

## Completion Record

The controller trace established that `menuProgress` remained `1` through the
flyout lifecycle. A 120 FPS frame-by-frame crop then exposed the real failure:
the background and every sidebar child compressed horizontally and rebounded
while the flyout opened. The shared `LacunaPanelWindow` changed implicit width
from sidebar-only to sidebar-plus-flyout when `flyoutVisibleOnScreen()` became
true. During that layer-shell buffer resize, Hyprland briefly scaled the old
buffer before presenting the replacement.

Final correction:

- `flyoutLaneWidthFor(screen)` now reserves the maximum flyout lane for every
  mapped sidebar surface, so flyout open/close cannot resize its layer-shell
  window;
- the persistent sidebar/flyout surface remains pointer-driven with
  `WlrKeyboardFocus.None` and no `HyprlandFocusGrab` activation;
- `retainMenuOnExternalClose` remains as the controller guard against a
  separate transient host-close path;
- nested settings opacity behaviors remain removed so the controller owns the
  flyout transition;
- the disabled-by-default `LACUNA_TRANSITION_TRACE=1` diagnostic remains
  available for future state-machine investigations.

Verification:

- 110 focused controller, geometry, monitor-policy, and QML contract tests
  passed;
- `lacuna.menu` was deployed, the shell restarted, and the installed copy was
  verified against the checkout;
- a settled 120 FPS opening capture measured the complete sidebar content
  region frame by frame and found no squeeze, slide, blanking, or redraw while
  the settings flyout opened;
- the user visually confirmed the sidebar and its elements no longer twitch.
