# Layer Stacking Policy

Status: reference

Every Lacuna plugin window is a wlr-layer-shell surface. The compositor gives
us exactly two stacking controls, and nothing else:

1. **Layer level** (`WlrLayershell.layer`): background < bottom < top < overlay.
2. **Map order within a level**: a surface mapped later stacks above surfaces
   mapped earlier in the same level, and cannot be restacked afterwards.

Map order is whatever the runtime happens to do — it changes with toggle
timing, restarts, and code motion. Two regressions came from relying on it:
the video fade cover rendering under the video (separate cover window), and
the full frame painting over the bar and sidebar (frame window mapped at
toggle time). Hence the rules below.

## Rules

1. **Pick the correct level first.** Never compensate for a wrong level with
   map-order tricks.
2. **Surfaces that must sit under later same-level UI stay mapped
   permanently** (`visible: true`) with content-gated paint (`isRenderable`
   or equivalent) and an empty input mask. Toggling `visible` on such a
   surface remaps it to the top of its level.
3. **Declaration order in the host is the intended order for Lacuna-owned
   surfaces, not a guarantee about the Omarchy bar.** In `lacuna.bar/Bar.qml`
   the frame surfaces are declared before `OmarchyBarAdapter`, which is
   declared before `MenuWindow`, and the layer-policy contract test pins this.
   Quattro maps the host-owned `omarchy-bar` on its own schedule; on the
   current build `hyprctl layers` reports `omarchy-bar` before
   `lacuna-bar-frame`. The frame therefore excludes the bar strip by geometry
   so correctness does not depend on controlling the host's map order.
4. **Compose within one window when elements must stack against each other**
   (deterministic sibling z-order) instead of using a second layer surface —
   e.g. the video wallpaper's black fade cover lives inside the video window.
5. **Prefer geometry over stacking against surfaces we do not control.** The
   vendored Omarchy bar maps on its own schedule, so the frame never paints
   the strip the bar occupies (`outerX/outerY/outerRight/outerBottom` in
   `LacunaFrameWindow.qml`); the bar itself is the frame edge on its side and
   the stacking between the two becomes irrelevant.
6. **Every `WlrLayershell.layer` assignment is pinned** by
   `test_layer_stacking_policy` in `tests/test_qml_contracts.py`. Adding a
   window or changing a layer must update the table there and this document.

## Level assignments

| Level | Surfaces | Notes |
| --- | --- | --- |
| background | `omarchy-background` (Omarchy), `lacuna-media-player-video`, `lacuna-background-vignette` (ignore-animations mode) | Video wallpaper carries its own fade cover internally. |
| bottom | Ambience overlays (`aurora-drift`, `cinematic-light`, `crt`, `dust-motes`, `film-grain`, `god-rays`, `rainfall`, `vhs`), `lacuna-desktop-clock`, `lacuna-background-vignette` (default) | Below windows, above wallpaper. |
| top | `omarchy-bar`, `lacuna-bar-frame` (always mapped), frame/sidebar reserve windows | Quattro currently maps the host bar before the frame; the frame's bar-strip exclusion makes the order safe. |
| overlay | `lacuna-bar-frame-border` (always mapped, maps first), `lacuna-menu` sidebar, transient panels (`audio`, `bluetooth`, `network`, `power`), `omarchy-bar-drag-ghost`, non-exclusive Lacuna panels, ambience overlays in `foregroundOverlay` mode | The sidebar is above the persistent Top-level frame surface on every output; its input mask still covers only the sidebar/flyout geometry. Border is 1px and click-through; transient panels map above it because they map later. |

## Verifying live

```bash
hyprctl layers
```

Within `Layer level 2 (top)` the current Quattro list is expected to show
`omarchy-bar` and `lacuna-bar-frame`; the open `lacuna-menu` sidebar appears in
`Layer level 3 (overlay)` above them. The exact bar/frame order is
host-controlled; verify that `LacunaFrameWindow.qml` still excludes the bar
strip. The frame surfaces appear even when frame mode is off — they are
intentionally always mapped (rule 2).
