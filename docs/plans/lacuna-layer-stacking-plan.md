# TASK: Deterministic layer stacking for all Lacuna surfaces

Status: complete

Implemented and live-verified 2026-07-02. Kept as the executable record of the
layering rework so an LLM or developer can extend it without re-deriving the
constraints. The living policy is `docs/architecture/layer-stacking.md`; this
plan explains why it exists and what was changed.

## REPO CONTEXT

- Repo: lacuna-omarchy-plugins (Omarchy/Quickshell plugins; every window is a
  wlr-layer-shell surface).
- Key files:
  - `lacuna.bar/Bar.qml` — bar host; creates frame surfaces, bar adapter, hosted menu
  - `lacuna.bar/LacunaFrameWindow.qml` — full-frame paint surface (Top layer)
  - `lacuna.bar/LacunaFrameBorderWindow.qml` — frame border hairline (Overlay layer)
  - `lacuna.media-player-video/Overlay.qml` — video wallpaper + in-window fade cover
  - `tests/test_qml_contracts.py::test_layer_stacking_policy` — enforcement
  - `docs/architecture/layer-stacking.md` — the policy document
- Verify with: `./scripts/check.sh`; live truth: `hyprctl layers`.

## THE INVARIANT THAT DRIVES EVERYTHING

wlr-layer-shell gives exactly two stacking controls and nothing else:

1. Layer level: background < bottom < top < overlay.
2. Map order within a level: later-mapped stacks higher, and surfaces can
   NEVER be restacked afterwards. Toggling `visible` on a window unmaps and
   remaps it — to the top of its level.

Any design that needs surface A under surface B in the same level, where A
can map after B, is a latent regression. Two shipped bugs came from this:

- BUG 1: the video wallpaper's black fade cover was a second Background-layer
  window; sessions where it mapped under the video made every fade invisible
  and transitions popped in abruptly.
- BUG 2: the full-frame surface (Top layer) mapped only when the user enabled
  frame mode, so it mapped last and painted its opaque surround OVER the bar
  and sidebar ("UI elements missing or underneath").

## IMPLEMENTED FIXES

### F1. In-window composition for the video fade cover (BUG 1)

`lacuna.media-player-video/Overlay.qml`: the cover is a `Rectangle` inside
the video window above the `VideoOutput` (`id: fadeCover`, `z: 10`); the
separate `lacuna-media-player-video-fade` surface was deleted and the
contract test asserts it never returns (`assertNotIn`). Sibling z-order is
deterministic; cross-window order is not.

### F2. Always-mapped frame surfaces (BUG 2, sidebar/panels half)

`LacunaFrameWindow.qml` and `LacunaFrameBorderWindow.qml` are `visible: true`
permanently, with all paint gated by `isRenderable` (content transparent and
click-through while frame mode is off). Toggling frame mode changes paint
only — mapping, and therefore stacking, never changes at runtime. The frame
Variants are declared before `OmarchyBarAdapter` (before `MenuWindow`) in
`Bar.qml`, so the sidebar maps after the frame and stacks above it.

### F3. Geometry instead of stacking against the bar (BUG 2, bar half)

Empirical finding: the vendored Omarchy bar window maps on its own schedule —
declaration order could NOT get the frame under it (`hyprctl layers` showed
`omarchy-bar` before `lacuna-bar-frame` regardless). Fix: the frame never
paints the strip the bar occupies. `LacunaFrameWindow.qml` gained
`outerX/outerY/outerRight/outerBottom` — the outer path boundary starts at
the bar's inner edge on the bar's side, so the bar itself is the frame edge
there and bar-vs-frame stacking is irrelevant. Do not "fix" this back to
full-screen outer bounds.

## LEVEL ASSIGNMENTS (summary; full table in docs/architecture/layer-stacking.md)

- background: omarchy wallpaper, `lacuna-media-player-video` (carries its own
  fade cover), vignette in ignore-animations mode.
- bottom: ambience overlays, desktop clock, vignette default.
- top: `lacuna-bar-frame` (always mapped), `omarchy-bar`, reserve windows.
- overlay: `lacuna-menu` sidebar, above the persistent frame surface on every
  output, plus `lacuna-bar-frame-border` (always mapped, maps first), transient
  panels (audio/bluetooth/network/power), drag ghost, non-exclusive panels,
  and ambience in foregroundOverlay mode. The sidebar input mask remains
  limited to the sidebar and flyout geometry.

## REGRESSION PROTECTION (already in place — keep it working)

- `test_layer_stacking_policy` pins: every `WlrLayershell.layer` assignment in
  the repo against a policy table; `visible: true` + `assertNotIn("visible:
  active")` on both frame windows; `Bar.qml` declaration order via
  `assertLess(bar.index(...))`; the no-paint-under-bar outer geometry strings.
- Any new window, layer change, or visibility-gating change MUST update the
  policy table, `docs/architecture/layer-stacking.md`, and this awareness —
  the test failing is the intended tripwire, not an obstacle.

## RULES FOR FUTURE SURFACES (apply in order)

1. Pick the correct level first; never simulate a level with map-order tricks.
2. If a surface must sit UNDER later same-level UI: keep it permanently mapped
   (`visible: true`), gate content instead, give it an empty input mask.
3. If two elements must stack against each other: one window, sibling z-order.
4. If the other surface is not ours (vendored bar): solve with geometry —
   don't paint where it lives.
5. Never toggle `visible` on a window whose stacking matters.
6. Add the new `WlrLayershell.layer` line to the policy test table and the
   policy doc in the same change.

## VERIFICATION RECIPE

```bash
./scripts/check.sh                       # policy test + suite
hyprctl layers                           # live truth, bottom-to-top per level
```

Expected in `Layer level 2 (top)`: `lacuna-bar-frame` present even with frame
mode off (always mapped), `lacuna-menu` listed after it. Toggling
`frame.mode` in `~/.config/omarchy/lacuna/settings.json` between `off` and
`fullframe` must not change the layer list at all. Deploy via
`./scripts/dev deploy lacuna.bar lacuna.media-player-video` (restarts shell).

## KNOWN TRADE-OFFS / OPEN FOLLOW-UPS

- Translucent bar: the frame no longer paints behind the bar strip, so a
  translucent bar shows wallpaper there instead of frame color. Revisit only
  if it reads wrong visually (would need the bar to paint its own frame-color
  backdrop, not a stacking change).
- `barHidden` + fullframe: the bar strip becomes a wallpaper gap since the
  frame does not reclaim it. Cosmetic, unusual combo; fix by binding the
  outer edge to `barHidden` if it ever matters.
- Frame border is Overlay and 1px click-through; transient panels stack above
  it because they map later. If a persistent Overlay surface is ever added,
  it must follow rule 2.
