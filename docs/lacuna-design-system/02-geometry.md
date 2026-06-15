# 02 · Geometry — the seam language

> Principle 2: **Show the seam.** Principle 3: **Absence has weight.**
> This document absorbs and supersedes the "Flyout Surface Geometry" section of `AGENTS.md`,
> which should link here.

Geometry is where Lacuna's identity lives most visibly. The signature is a deliberate tension:
**sharp, square interior geometry** joined by **curved molding connectors**. Surfaces are honest
rectangles; the only curves in the system are the trim pieces that bridge a gap between two
surfaces, plus the rounding of a surface's *exposed* outer corners.

## The one curve constant

Every curve in Lacuna — every molding connector and every rounded corner — is a quarter-circle
approximated by one cubic Bézier, controlled by a single number:

```qml
// lacuna.menu/components/LacunaGeometry.qml
readonly property real curveKappa: 0.5522847498   // = 4/3 * (sqrt(2) - 1)
```

`curveKappa` is the cubic-Bézier control-point multiplier that makes a quarter turn approximate a
circular arc. **It must stay defined in exactly one place** and be referenced everywhere. A second
copy is a bug: it is how two surfaces drift out of optical agreement.

Control points for a quarter arc of radius `r` are placed at `r * (1 - curveKappa)` from the
corner. This is the canonical pattern used by `MenuSurface.qml`'s join shapes; reuse it.

## The molding connector

When a flyout attaches to the sidebar, Lacuna does **not** round the meeting corners. Instead:

- The attachment edge (the side that touches) stays **square**.
- A **connector** bridges the gap: a straight body between the panel's top and bottom, plus two
  `ShapePath` cubic pieces *outside* the panel bounds — one above, one a vertical mirror below.
- The connector uses the **same `curveKappa`** as the sidebar/topbar join, so the trim reads as
  one continuous piece of moulding around the whole assembly.

This is the Carbon-era join, re-grounded in the gap metaphor: the connector is *trim over a seam*,
not a corner radius that hides the seam exists.

### Attachment geometry

From `lacuna.menu/menu/MenuSurface.qml` and the corner system:

```
                 connectorWidth = joinRadius
                 ┌──┐
   ┌─────────────┤  ╲────────────────┐
   │   sidebar   │   │   flyout       │   flyout placed at x = panelWidth + connectorWidth
   │  (square    │   │  (square left, │   connector drawn at x = panelWidth
   │   right edge│   │   rounded      │
   │   here)     │   │   right edge)  │
   └─────────────┤   ╱────────────────┘
                 └──┘
```

- If `sidebarState.cornerPieces` is **enabled**: reserve `connectorWidth = joinRadius`, place the
  flyout at `panelWidth + connectorWidth`, and draw the connector at `x: panelWidth` so it sits
  *between* sidebar and flyout.
- If corner pieces are **disabled**: attach the flyout directly at `panelWidth`.

## Corner states

Selective corner rounding is encoded per corner, not via `Rectangle.radius`. From
`lacuna.menu/menu/LacunaShapeSurface.qml` and `LacunaCornerHelper.qml`:

| State | Meaning |
|---|---|
| `-1` | **square** — an attachment or interior edge; no rounding |
| `0` | **rounded inward** — a normal exposed corner |
| `1` / `2` | **outer / molding curves** — connector trim that bows away from the body |

`LacunaCornerHelper` provides the math: `multX(state)`, `multY(state)`, `arcDirection(mx, my)`
(Clockwise vs Counterclockwise), and `flattenedRadius(dimension, requested)` which clamps a
radius to half the available dimension so curves never overrun.

**For a right-opening flyout attached to the sidebar:** keep the left edge square
(`topLeft`/`bottomLeft = -1`) and round only the top-right and bottom-right corners
(`= 0`). Never `Rectangle.radius` — it rounds all four corners and breaks the seam.

## Fill-only surfaces

> Principle 2 again: the seam, not a frame, defines an edge.

Lacuna surface shells are **fill-only** (`strokeWidth: 0`). Do **not** draw thin outer borders
around a flyout or panel shell. Edges are expressed by the `seam` color used on *internal*
dividers, controls, and explicit selected states — never as a hairline outlining the whole
surface. A bordered shell reads as a card; Lacuna wants a recess in space.

## The radius scale

Lacuna's interior is square; its *joins and exposed corners* carry the only radii. Values are
density-aware via `mix(full, compact)` (see [03-motion.md](03-motion.md) and the density note
below). Current `lacuna`-style values in `DesignTokens.qml`:

| Token | Full | Compact | Role |
|---|---|---|---|
| `radius` | `0` | `0` | interior surfaces / item backgrounds — **always square** |
| `controlRadius` | `0` | `0` | controls (buttons, toggles) — **always square** |
| `panelRadius` | `14` | — | exposed outer corners of a surface |
| `joinRadius` | `18` | `14` | connector trim radius (also the connector width) |
| `connectorOverlap` | `33` | `25` | how far the connector overlaps for a seamless join |
| `borderWidth` | `0` | `0` | **no shell borders** (Principle 2 / fill-only) |

The contrast is the point: **`radius: 0` everywhere inside, real curves only at joins and exposed
corners.** That sharp/curved tension is more Lacuna than any single value.

## Density

Lacuna interpolates between a full and a compact layout with a single progress value, so the shell
can shrink continuously rather than snapping between two states:

```qml
function mix(fullValue, compactValue) {
  var p = Math.max(0, Math.min(1, compactProgress))   // 0 = full, 1 = compact
  return fullValue + (compactValue - fullValue) * p
}
```

Spacing, insets, item heights, `joinRadius`, and `connectorOverlap` all flow through `mix()`.
Representative spacing scale (`LacunaTokens.qml`): `tiny 2 · small 4 · normal 8 · large 10 ·
xLarge 14`. Representative item heights (`DesignTokens.qml`, full→compact): `item 38→32 ·
primary 40→34 · featured 48→42 · compact 32→28`.

## Alternate styles

`DesignTokens.qml` keeps two non-Lacuna styles selectable. They exist for users who want a more
conventional look; they are **not** the Lacuna language:

| | `lacuna` | `omarchy` | `material` |
|---|---|---|---|
| `radius` | 0 | 2 | 8 |
| `controlRadius` | 0 | 2 | 9 |
| `borderWidth` | 0 | 1 | 1 |
| `joinRadius` | 18 | 0 | 16 |
| `headerTreatment` | accent-line | body-border | tonal |
| `railTreatment` | linework | contained | tonal |

The Carbon alias that previously made `lacuna === carbon` is **removed** (see
[06-roadmap.md](06-roadmap.md), Phase A). `lacuna` is now original.

## Rules

1. **One `curveKappa`, referenced everywhere.** Never copy the constant.
2. **Square interior, curves only at joins and exposed corners.**
3. **Molding connectors over rounded join corners.** Show the seam.
4. **No `Rectangle.radius` on attached surfaces** — use per-corner `Shape` states.
5. **Fill-only shells (`strokeWidth: 0`).** Borders belong to internal controls, not surfaces.
