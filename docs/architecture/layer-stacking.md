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
3. **Declaration order in the host is mapping order.** In `lacuna.bar/Bar.qml`
   the frame surfaces are declared before `OmarchyBarAdapter`, which is
   declared before `MenuWindow`. The layer-policy contract test pins this.
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
| background | `omarchy-background` (Omarchy), `lacuna-youtube-music-video`, `lacuna-background-vignette` (ignore-animations mode) | Video wallpaper carries its own fade cover internally. |
| bottom | Ambience overlays (`aurora-drift`, `cinematic-light`, `crt`, `dust-motes`, `film-grain`, `god-rays`, `rainfall`, `vhs`), `lacuna-desktop-clock`, `lacuna-background-vignette` (default) | Below windows, above wallpaper. |
| top | `lacuna-bar-frame` (always mapped, maps first), `omarchy-bar`, frame/sidebar reserve windows, `lacuna-menu` sidebar (exclusive panels) | Required map order: frame → bar → sidebar. |
| overlay | `lacuna-bar-frame-border` (always mapped, maps first), transient panels (`audio`, `bluetooth`, `network`, `power`), `omarchy-bar-drag-ghost`, non-exclusive Lacuna panels, ambience overlays in `foregroundOverlay` mode | Border is 1px and click-through; transient panels map above it because they map later. |

## Verifying live

```bash
hyprctl layers
```

Within `Layer level 2 (top)` the list is bottom-to-top and must read
`lacuna-bar-frame` before `omarchy-bar` before `lacuna-menu`. The frame
surfaces appear even when frame mode is off — they are intentionally
always mapped (rule 2).
