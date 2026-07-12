# Lacuna Surface Transition Pipeline Repair Plan

Status: proposed; ready for implementation

Purpose: repair the menu/sidebar/attached-flyout transition pipeline reviewed
on 2026-07-11. This is an execution specification, not an exploratory design
document. Follow the decisions below without redesigning the surface system.

This plan does **not** concern the desktop ambience plugins or the reverted
[`lacuna-animation-pipeline-plan.md`](./lacuna-animation-pipeline-plan.md).
Its scope is only the interactive `lacuna.menu` surface pipeline.

## 1. Required Outcome

Implement one deterministic transition pipeline with these properties:

1. A closed-menu flyout request opens the sidebar first. The flyout begins
   only after sidebar progress reaches `0.65`.
2. Flyout geometry opens from the attachment seam. Content remains fully
   hidden until flyout progress reaches `0.55`, then fades from `0` to `1`
   over the remaining geometry progress.
3. Closing uses the same mapping in reverse, so content is concealed before
   most of the flyout geometry collapses.
4. Switching between open flyouts keeps the one shared flyout shell open,
   crossfades old content to new content over `MotionTokens.quick`, and
   interpolates shell geometry instead of snapping between dimensions.
5. Stale animation completions cannot clear or overwrite newer state.
6. Reduced motion resolves menu, flyout, content, and switch geometry
   synchronously while preserving the same final state and attachment origin.
7. Input masks follow only visible sidebar, connector, and flyout geometry at
   every point in opening, closing, reversal, and content switching.
8. Focus is requested only after the active flyout is interactive. Focus loss
   closes the flyout, not the sidebar.

Do not change the public Omarchy contract: `Menu.qml` and `MenuWindow.qml`
must continue to expose `open(payloadJson)` and `close()`.

## 2. Existing Ownership — Preserve It

Do not replace the current architecture.

| Owner | Responsibility |
| --- | --- |
| `lacuna.menu/Menu.qml` | Route calls to the bar-hosted menu or fallback `MenuWindow`. |
| `lacuna.menu/menu/MenuWindow.qml` | Bind controller state to each output, content, focus, frame, and surface composition. |
| `lacuna.menu/services/PanelController.qml` | Own intent, transition state, progress, revision guards, and switch lifecycle. |
| `lacuna.menu/menu/LacunaPanelHost.qml` | Own sidebar/connector/flyout geometry and input-mask geometry. |
| `lacuna.menu/menu/LacunaPanelUnifiedSurface.qml` | Paint the combined silhouette and its single shadow. |
| `lacuna.menu/menu/MenuSurface.qml` | Render sidebar geometry from controller progress. |
| `lacuna.menu/menu/LacunaPanelConnector.qml` | Render the molding connector from flyout progress. |
| `lacuna.menu/menu/LacunaAttachedFlyout.qml` | Clip flyout geometry and apply controller-owned content opacity. |
| `lacuna.menu/services/MotionTokens.qml` | Own all visual transition durations and easing inputs. |

Keep the menu window at `WlrLayer.Overlay`. Do not add another layer-shell
surface. Do not change persistent frame mapping or the layer policy.

## 3. Fixed Transition Contract

### 3.1 Constants

Add these named, readonly properties to `PanelController.qml`:

```qml
readonly property real menuToFlyoutThreshold: 0.65
readonly property real flyoutContentThreshold: 0.55
```

Do not scatter either number through other files.

Compute content progress in the controller:

```qml
readonly property real contentProgress: Math.max(0, Math.min(1,
  (flyoutProgress - flyoutContentThreshold) /
  (1 - flyoutContentThreshold)))
```

`LacunaAttachedFlyout.qml` must consume this value and must not derive another
opacity curve.

### 3.2 Menu and queued flyout sequence

Add controller state:

```qml
property string pendingFlyout: ""
```

Implement `openFlyout(id)` as follows:

1. Reject an empty ID.
2. If the menu is closed or `menuProgress < menuToFlyoutThreshold`, store the
   ID in `pendingFlyout`, call `openMenu()`, and return without starting the
   flyout animation.
3. When menu progress first reaches `menuToFlyoutThreshold`, consume and clear
   `pendingFlyout`, then run the normal flyout-open path.
4. `closeMenu()` clears `pendingFlyout` before closing active flyout state.
5. A later queued request replaces an earlier queued request; only the latest
   ID may open.
6. With reduced motion enabled, `openMenu()` settles at progress `1`
   synchronously and the pending flyout opens synchronously in the same turn.

Use a helper such as `openFlyoutNow(id)` so queue handling and normal opening
do not duplicate state mutations.

### 3.3 Reversal and completion safety

Keep the existing revision-token pattern. Every menu, flyout, and switch
animation must:

1. invalidate its old revision before `stop()`;
2. allocate a new revision before `start()`;
3. verify the captured revision in its completion handler;
4. mutate terminal state only when progress matches the requested endpoint.

Add an endpoint fast path to `animateFlyout(to)` equivalent to the existing
`animateMenu(to)` fast path. Starting a `0 -> 0` or `1 -> 1` animation is not
allowed.

### 3.4 Flyout switching policy

The chosen policy is **same-shell crossfade plus geometry interpolation**.
Do not close and reopen the shell and do not snap directly to new dimensions.

Add controller state:

```qml
property real contentSwitchProgress: 1
property int contentSwitchRevision: -1
property string incomingFlyout: ""
```

When flyout A is fully or partially visible and B is requested:

1. Keep `visibleFlyout` and `outgoingFlyout` set to A.
2. Set `incomingFlyout` and `activeFlyout` to B.
3. Keep `flyoutProgress` moving toward or fixed at `1`; never collapse the
   shared shell solely to switch content.
4. Capture A's current effective geometry in `LacunaPanelHost`.
5. Set B's dimensions as the target geometry.
6. Animate `contentSwitchProgress` from `0` to `1` using
   `MotionTokens.quick` and `Easing.OutCubic`.
7. Render A opacity as `1 - contentSwitchProgress` and B opacity as
   `contentSwitchProgress`, both multiplied by the shell's
   `contentProgress`.
8. Interpolate flyout `x`, `y`, width, height, connector width, connector
   height, border geometry, and input-mask geometry from the captured A
   geometry to B geometry using the same `contentSwitchProgress`.
9. Keep only B interactive, and only after both shell content progress and
   switch progress exceed `0.98`.
10. On completion, set `visibleFlyout = B`; clear `incomingFlyout` and
    `outgoingFlyout`; normalize `contentSwitchProgress = 1`.

Remove `contentSwitchTimer`. Lifetime must be controlled by the named switch
animation completion, not an independent delay.

If a third flyout is requested mid-switch, capture the currently interpolated
geometry and visible opacity state as the new outgoing state, invalidate the
old switch revision, and transition to the newest request. The newest request
always wins.

### 3.5 Geometry API changes

Extend `LacunaPanelHost.qml` with explicit transition inputs rather than
having it infer a switch from content IDs:

```qml
property bool geometrySwitchActive: false
property real geometrySwitchProgress: 1
property real fromFlyoutY: 0
property real fromFlyoutWidth: 0
property real fromFlyoutHeight: 0
property real fromConnectorWidth: 0
property bool fromAnchorRight: false
```

The existing `flyoutY`, `flyoutWidth`, `flyoutHeight`, `connectorWidth`, and
`anchorRight` values are the target geometry. Calculate every effective value
with linear interpolation while `geometrySwitchActive` is true. Continue to
use the existing cached geometry for ordinary open/close transitions.

All paint and mask consumers in `MenuWindow.qml` must read the same effective
geometry from `LacunaPanelHost`. There must not be one interpolation for paint
and another for input masks.

### 3.6 Reduced motion

`MotionTokens.animationDisabled` currently produces duration `0`. Make the
controller explicitly settle state instead of relying on the runtime behavior
of zero-duration `NumberAnimation`:

- `animateMenu(to)`: stop, assign endpoint, call the validated completion path.
- `animateFlyout(to)`: stop, assign endpoint, call the validated completion path.
- content switch: assign progress `1`, then finalize the incoming flyout.
- queued flyout: consume immediately once menu progress becomes `1`.

Add `readonly property bool animationDisabled` to the controller as a binding
to `motionTokens.animationDisabled` if that makes these branches clearer.

### 3.7 Focus guard

The existing `900ms` settings-activation guard is semantic debounce, not a
visual animation. Preserve its behavior but remove the unexplained literal:

```qml
readonly property int flyoutActivationFocusGuardMs: 900
```

Bind `flyoutFocusClearHold.interval` to that property and add a comment saying
it deliberately does not scale with reduced-motion or animation-speed
settings. Do not move it into `MotionTokens`.

## 4. Files to Modify

Required production changes:

1. `lacuna.menu/services/PanelController.qml`
   - thresholded content progress;
   - queued flyout state and sidebar-first sequencing;
   - flyout endpoint fast path;
   - revision-guarded content-switch animation;
   - explicit reduced-motion settlement;
   - remove `contentSwitchTimer`.
2. `lacuna.menu/menu/LacunaPanelHost.qml`
   - capture current effective geometry;
   - interpolate switch geometry;
   - expose one effective geometry set for paint and masks.
3. `lacuna.menu/menu/MenuWindow.qml`
   - bind controller switch state to the host;
   - crossfade outgoing/incoming content;
   - keep interactivity on the incoming active content only;
   - use effective geometry everywhere;
   - name and document the focus guard interval.
4. `lacuna.menu/menu/LacunaAttachedFlyout.qml`
   - continue consuming controller-owned `contentProgress`;
   - do not add local animation or threshold state.
5. `lacuna.menu/menu/LacunaPanelUnifiedSurface.qml`
   - only update bindings necessary to consume effective interpolated geometry.
6. `docs/lacuna-design-system/03-motion.md`
   - record the numeric sidebar/flyout and content thresholds;
   - document same-shell switch crossfade and geometry interpolation.

Required test changes:

7. `tests/test_qml_behavior_panels.py`
8. `tests/test_qml_geometry.py`
9. `tests/test_qml_contracts.py`
10. `tests/test_live_visual.py`

Do not edit ambience overlay plugins, video transition code, frame layer
assignments, plugin manifests, or public settings schemas.

## 5. Test-First Implementation Order

Complete these steps in order. Do not combine them into an unreviewable QML
rewrite.

### Step 1 — Pin the controller contract

Add failing runtime behavior tests for:

- content progress equals `0` below `0.55`;
- content progress is approximately `0.5` at flyout progress `0.775`;
- content progress equals `1` at flyout progress `1`;
- requesting a flyout on a closed menu queues it;
- queued flyout remains closed below menu progress `0.65`;
- queued flyout opens after the menu crosses `0.65`;
- closing the menu cancels a queued flyout;
- reverse open/close/open sequences settle on the newest intent;
- reduced-motion open, close, and switch settle synchronously;
- a third request during a switch leaves only the third flyout active and
  visible after settlement.

Then implement only the controller changes required to pass them.

### Step 2 — Pin geometry interpolation

Add deterministic tests that instantiate or evaluate `LacunaPanelHost` and
assert, at switch progress `0`, `0.5`, and `1`:

- effective width, height, and Y;
- connector position and dimensions;
- flyout visible-body mask;
- left- and right-opening behavior;
- capture of current interpolated geometry during an interrupted switch.

Then implement the host interpolation.

### Step 3 — Wire content and surface composition

Update `MenuWindow.qml` so all four content kinds—`settings`,
`shellSettings`, `appPicker`, and `mediaPlayer`—use the same switch-opacity
contract. Do not special-case one flyout.

Add contract assertions that:

- `contentSwitchTimer` no longer exists;
- the controller owns `flyoutContentThreshold` and `contentSwitchProgress`;
- `LacunaAttachedFlyout` receives controller-owned `contentProgress`;
- the host receives controller-owned switch progress;
- paint, border, connector, and mask bindings use effective host geometry;
- no new `PanelWindow` or `WlrLayershell.layer` assignment was added.

### Step 4 — Add live visual coverage

Extend the opt-in `tests/test_live_visual.py` suite. The test must remain
gated by `LACUNA_LIVE_VISUAL=1` and restore every changed setting in
`finally` or `tearDown`.

Capture or probe these states:

1. menu opening before flyout disclosure;
2. flyout below and above content threshold;
3. settings-to-media-player switch with different dimensions;
4. mid-switch third-flyout interruption;
5. flyout closing with connector still attached;
6. reduced-motion final state;
7. click-through immediately outside the animated mask.

The visual test must fail for content appearing below threshold, a geometry
snap, connector separation, stale outgoing content, or an oversized input
mask.

### Step 5 — Update the motion specification

Update `03-motion.md` only after implementation behavior and tests agree.
Keep `02-geometry.md` unchanged unless an actual attachment invariant changes;
this plan is not authorization to redesign connector geometry.

## 6. Required Validation

Run all of the following from the repository root:

```bash
python3 -m pytest -q tests/test_qml_behavior_panels.py
python3 -m pytest -q tests/test_qml_geometry.py
python3 -m pytest -q tests/test_qml_contracts.py
./scripts/check.sh
git diff --check
```

Then preview and perform the live deployment:

```bash
./scripts/dev deploy lacuna.menu --dry-run
./scripts/dev deploy lacuna.menu
```

The deploy helper must report that the installed copy matches the checkout
and must restart/rescan the Omarchy shell successfully.

Run the opt-in visual suite in the live session:

```bash
LACUNA_LIVE_VISUAL=1 python3 -m pytest -q tests/test_live_visual.py
```

Finally summon the menu with a flyout payload and inspect shell logs:

```bash
OMARCHY_PATH="$HOME/.local/share/omarchy" \
  omarchy-shell shell summon lacuna.menu '{"flyout":"settings"}'
journalctl --user -b --no-pager | rg 'quickshell|lacuna' | tail -200
```

There must be no new QML binding-loop, animation, loader, focus, or layer-shell
errors.

## 7. Manual Acceptance Matrix

Verify every row. A single failure keeps the plan incomplete.

| Scenario | Required result |
| --- | --- |
| Open menu only | Sidebar grows from its hidden edge; no flyout exists. |
| Summon settings from closed | Sidebar reaches `0.65`, then connector and flyout begin. |
| Observe early flyout reveal | No content is visible below progress `0.55`. |
| Close flyout | Content conceals first; geometry and connector close together. |
| Reverse close by reopening | Motion reverses from current progress without a flash or stale completion. |
| Settings → media player | Content crossfades; shell and mask interpolate to new dimensions. |
| Settings → media → app picker rapidly | App picker wins; no stale panel or mask survives. |
| Outside click during transition | Only visible geometry consumes input; flyout dismisses, sidebar stays open. |
| Toggle rail/full during flyout | Attachment and mask stay coherent. |
| Toggle corner pieces during flyout | No connector gap, detached cap, or input hole. |
| Change focused output | No duplicate interactive flyout; transition remains on the selected output. |
| Reduced motion enabled | Every operation reaches the correct final state immediately with no flash. |
| Shell restart | Menu and flyout remain usable; no stale focus grab or invisible input surface. |

## 8. Completion Gate

Mark this plan `complete` only when all of the following are true:

- production and test changes are implemented;
- the full repository check passes;
- the live `lacuna.menu` copy matches the checkout;
- Omarchy shell has been restarted or rescanned by the deploy helper;
- the opt-in live visual suite passes;
- every manual acceptance row passes;
- `03-motion.md` describes the implemented thresholds and switch behavior;
- no unrelated plugin or ambience animation changes are included.

If live visual validation cannot run, report the work as **implemented in the
repository but not live-verified**. Do not call the user-visible issue fixed.
