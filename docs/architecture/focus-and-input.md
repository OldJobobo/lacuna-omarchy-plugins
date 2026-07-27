# Focus And Input Contract

Status: reference

Lacuna's persistent sidebar is pointer-first. Merely mapping, revealing, or
updating the sidebar must not acquire keyboard focus from the active
application. Sidebar rows and shared pointer buttons retain accessibility
roles, names, descriptions, states, and press actions, but are not part of a
Tab/arrow/Enter traversal model.

## Bounded flyout focus

An interactive flyout may create one bounded `HyprlandFocusGrab` session for:

- click-away dismissal;
- Escape dismissal;
- unconsumed Backspace dismissal; and
- intentional text entry, such as Media search, app search, or quick-launch
  rename.

The grab is armed only while `flyoutInteractive` is true and is released when
that state ends. Switching flyout content does not destroy and recreate the
grab, so an interrupted transition retains the original pre-Lacuna focus
owner. `WlrKeyboardFocus.Exclusive` is reserved for direct text surfaces;
other interactive flyouts use `OnDemand`, while the passive sidebar uses
`None`.

Backspace is disabled as a window dismissal shortcut while the active focus
item is a `TextInput`/`TextEdit`. Escape remains the explicit flyout dismissal
key; text-specific popovers may consume it locally first.

## Restoration paths

`LacunaPanelWindow` records a focus-session revision and releases the
compositor grab for every close path:

- `escape`;
- `backspace`;
- `click-away`;
- `explicit-close` (close button, selected action, or API close);
- `transition` settlement; and
- `shell-rescan`/component destruction.

Hyprland restores the client focused before the grab when the grab is released
or destroyed. Lacuna never focuses another application by title, PID, or
window address; restoration ownership stays with the compositor.

## Input masks

The layer-shell input region is the union of the currently painted sidebar,
connector, and visible flyout body. Connector and flyout regions become zero
when the flyout is not renderable. During geometry transitions their bounds
come from `LacunaPanelHost.effectivePanelGeometry`, matching paint and border
snapshots rather than requested endpoints.

## Verification

Source and runtime behavior tests cover passive-focus removal, direct text
focus, dismissal reasons, latest effective input masks, and empty masks. The
opt-in live visual/focus probe must confirm that the active application before
opening a flyout is active again after each dismissal path and after shell
rescan.
