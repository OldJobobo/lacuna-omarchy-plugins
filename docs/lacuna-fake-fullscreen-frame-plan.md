# Lacuna Fake Fullscreen Frame Plan

## Goal

Add a Lacuna-owned visual frame mode that can make the Omarchy bar, Lacuna
sidebar, sidebar corner pieces, flyout connector, and attached flyouts read as
one cohesive framed surface without changing Omarchy shell ownership.

This is intentionally a visual overlay. It must not start a second Quickshell
process, replace the Omarchy bar, or steal input outside Lacuna's existing
sidebar/flyout masks.

## Settings

Store the feature in Lacuna runtime settings:

```json
{
  "frame": {
    "mode": "off",
    "shadow": false,
    "thickness": 8,
    "radius": 14,
    "shadowDirection": "bottom_right",
    "shadowOffsetX": 2,
    "shadowOffsetY": 3
  }
}
```

Frame modes:

- `off`: current Lacuna behavior.
- `sidebar`: draw only the Lacuna-owned sidebar/flyout silhouette and a fake
  bar-adjacent shadow strip.
- `fullFrame`: add perimeter pieces around the screen so the frame reads as a
  continuous shell border.

The `shadow` toggle controls whether the frame silhouette gets a shadow. It is
separate from the mode so users can keep the filled frame pieces without the
extra effect pass.

## Rendering Model

Add a visual-only overlay inside the Lacuna menu window:

- `menu/LacunaFrameOverlay.qml`: receives screen, bar, sidebar, connector, and
  flyout geometry and draws the frame pieces.
- `components/LacunaDropShadow.qml`: small `MultiEffect` wrapper for settings
  backed shadows.

The overlay should sit behind Lacuna's real sidebar and flyout surfaces. It
should never participate in the `PanelWindow.mask`; the existing
`LacunaPanelHost.qml` masks remain the input source of truth.

## Cohesive Shadow Strategy

The ideal shadow path is one flattened silhouette:

1. Omarchy bar strip or bar-adjacent fake shadow region.
2. Lacuna sidebar body.
3. Sidebar/bar corner molding piece.
4. Active flyout connector.
5. Active flyout body.
6. Extra perimeter strips when `mode === "fullFrame"`.

Apply the shadow once to that combined layer. Do not add independent shadows to
each visible piece, because that creates stacked internal shadows around
connectors and corner pieces.

## Bar Limitation

Omarchy's current bar background is the `PanelWindow.color` inside the host bar
plugin. Lacuna plugins can read `shell.bar` geometry and colors, but they do
not have a supported hook for applying a real `MultiEffect` to the bar
background.

Therefore Lacuna must not draw an opaque fake bar over the actual Omarchy bar.
The first implementation should use one of these safer approximations:

- draw only the bar-adjacent shadow strip outside the bar's occupied edge;
- include the fake bar silhouette only when layer ordering proves it cannot
  cover bar widgets;
- leave the real bar fill to Omarchy and let the Lacuna frame pieces connect to
  its edge visually.

## Implementation Phases

1. Add normalized frame settings and settings-panel controls.
2. Add `LacunaDropShadow.qml`.
3. Add `LacunaFrameOverlay.qml` with `sidebar` mode.
4. Wire the overlay behind `MenuSurface`, `LacunaPanelConnector`, and
   `LacunaAttachedFlyout`.
5. Add `fullFrame` perimeter pieces.
6. Validate with shadows on/off, corner pieces on/off, collapsed/full sidebar,
   flyout open/closed, top/right bar positions, and overlay/exclusive sidebar
   modes.

## Implementation Checkpoint

2026-05-20:

- Added normalized `frame` runtime settings to `LacunaSettings.qml` and
  `config/settings.example.json`.
- Added Settings panel controls for `off`, `sidebar`, and `fullframe` frame
  modes plus an independent frame-shadow toggle.
- Added `LacunaDropShadow.qml` as the local `MultiEffect` wrapper.
- Added `LacunaFrameOverlay.qml` as a visual-only overlay that flattens frame,
  sidebar, connector, and flyout pieces before applying the optional shadow.
- Full-frame perimeter pieces are drawn only on screen edges that are not
  already occupied by the real Omarchy bar or the Lacuna sidebar.
- Expanded `LacunaPanelWindow` with a `visualWidth` property so frame rendering
  can span the screen while the existing input mask remains sidebar/flyout
  only.
- Wired the overlay behind `MenuSurface`, `LacunaPanelConnector`, and
  `LacunaAttachedFlyout` in `MenuWindow.qml`.

2026-05-20 follow-up:

- Expanded the sidebar exclusive reservation to include the visible molding
  inset.
- Added reserve-only frame edge windows using `ExclusionMode.Auto` so visible
  frame pieces can reserve compositor workarea without adding input regions.
- Added a matching reserve-only topbar shadow caster window so the top workarea
  includes the Lacuna-owned shadow strip below Omarchy's real top bar.
- Moved the visible Lacuna panel window to `ExclusionMode.Ignore` and added a
  separate sidebar reserve window so frame/shadow workarea reservations do not
  push Lacuna's own surfaces away from the bar edge.
- Tuned reserve widths so the left sidebar reserve excludes the decorative
  molding inset and the right full-frame reserve includes rightward shadow
  offset.
- Added a 4px uniform reserve padding around active Lacuna frame edges so
  tiled clients keep a consistent gap from the visual frame/shadow.
- Increased the single flattened frame shadow pass so full-frame mode reads
  with stronger depth without adding stacked internal shadows.
- Tightened and darkened the flattened frame shadow so it reads more opaque
  and less diffuse around full-frame edges.
- Replaced the bar-edge shadow caster's `MultiEffect` strip with a directional
  gradient shadow so it no longer reads as a hard offset line.
- Decoupled the bar-edge shadow caster height from corner placement so stronger
  topbar shadow treatment does not create a second, lower upper-left corner or
  push the upper-right full-frame corner down.
- Increased only the topbar caster gradient opacity to make the bar shadow read
  stronger without changing reserve geometry or other frame-edge shadows.

Validated:

- `find plugins -name '*.qml' -print0 | xargs -0 qmllint`
- `omarchy-shell shell rescanPlugins`
- `omarchy-shell shell summon omarchy.lacuna-menu "{}"`

## Performance Rules

- Use one overlay window/layer, not one window per edge.
- Prefer rectangles for straight pieces.
- Use shapes only for molded corner pieces and rounded frame joins.
- Keep panel shells fill-only; no thin outer borders.
- Keep shadows optional and off by default.
- Avoid fullscreen blur. Drop shadow is acceptable only as a single flattened
  source pass.
