# 05 · Components

> Every component is an expression of the four principles in the token families. This catalog
> re-states the existing primitives in the language of the system and fixes the **state laws**
> that keep them consistent.

## The state law (read first)

Interaction in Lacuna is **recess** — a sinking-in — not a tint or a glow (Principle 3). The
recess is an alpha layer over a surface, never a new hue, and its values are the design-style
`hoverOpacity` / `activeOpacity` from `DesignTokens.qml`:

| State | `lacuna` alpha | Rendered as |
|---|---|---|
| rest | 0 | nothing — the surface as-is |
| hover | `0.06` | a faint recess (`stateColor` over surface) |
| pressed / active | `0.11` | a deeper recess |
| selected | — | a `seam` edge or accent strip, not a fill flood |

`stateColor` is `accent` for Lacuna (it is `ink` only in the `material` alternate). State changes
animate with `quick` (150ms) / `color` (160ms), `OutCubic`. This single law governs every
interactive primitive below — a component should never invent its own hover treatment.

## Primitives (`lacuna.menu/components/`)

| Component | Role | Key properties / state law |
|---|---|---|
| `LacunaText` | baseline text | `ink` default, `monoFont`, `body` (12px), native render, elide right, single line; color animates (`color`, OutCubic). See [04-typography.md](04-typography.md). |
| `LacunaRect` | animated base rectangle | transparent by default; color animates `color`(160), opacity animates `quick`(120→150). The substrate most surfaces are built from. |
| `LacunaStateLayer` | the recess | hover `0.06` / press `0.11` over `stateColor`; the canonical implementation of the state law. Every clickable surface composes this rather than rolling its own. |
| `LacunaIconButton` | icon button | `controlRadius: 0` (square), size 30, icon 15; icon `whisper` at rest → `accent` on hover; recess via `LacunaStateLayer`. Accepts SVG source or inline Tabler path. |
| `LacunaTablerIcon` | vector icon | Tabler paths (24×24 base), `strokeWidth: 2`, scale-independent; color from role tokens. |
| `LacunaScrollView` | scroll container | Flickable-based, smooth wheel; **edge masks fade content at top/bottom** — a literal reveal/conceal at the scroll boundary (Principle 1). |
| `LacunaDropShadow` | depth | `MultiEffect` blur; offset X2/Y3. **One shadow on the combined silhouette**, never per-piece (see geometry/motion). |
| `LacunaAnim` / `LacunaColorAnim` | motion helpers | consume the [03-motion.md](03-motion.md) tokens; components use these, never raw `NumberAnimation` durations. |
| `LacunaGeometry` | curve constant | the single `curveKappa`. See [02-geometry.md](02-geometry.md). |
| `LacunaTokens` | token registry | spacing, type, control sizes. Components reference these, never literals. |

## Surfaces (`lacuna.menu/menu/`)

These compose into the sidebar→connector→flyout assembly that *is* Lacuna's signature. The
disclosure of this assembly follows the reveal choreography in [03-motion.md](03-motion.md).

| Surface | Role |
|---|---|
| `MenuWindow` | root: panel state machine, theme binding, layout, focus. |
| `LacunaPanelUnifiedSurface` | composes sidebar + connector + flyout under **one** shadow, enabling seamless sidebar-only → sidebar+flyout → flyout-only transitions. |
| `MenuSurface` | the sidebar: animated geometry + `LacunaShapeSurface` backdrop + the molding join shapes. |
| `LacunaShapeSurface` | per-corner rounded surface (`Shape`/`PathArc`), fill-only, `panelRadius` 14. The corner-state renderer. |
| `LacunaPanelConnector` | the molding connector strip (straight body + two `curveKappa` caps) bridging sidebar and flyout. |
| `LacunaAttachedFlyout` | the disclosed panel: geometry opens from the seam, content fades after the threshold; left edge square, right corners rounded. |
| `LacunaFrameOverlay` | optional decorative frame; pieces slide in from screen edges; sits *behind* real surfaces; zero input participation. |
| `LacunaCornerHelper` | corner-state math (`multX`/`multY`/`arcDirection`/`flattenedRadius`). |

**Composition law:** content is hosted *inside* a surface, separate from the surface's background
geometry; only visible regions go in the input mask; reuse the one flyout host and swap content
inside it rather than spawning bespoke panels.

## Controls (`lacuna.menu/settings/`)

| Control | Pattern under the system |
|---|---|
| `SettingsRow` | icon + label + hint + control; background is a faint `LacunaRect` (recess on hover); **optional left `accent` strip** marks a row instead of a fill flood. Title = Tektur `primary`; hint = mono `small` `whisper`. |
| `SettingsSelectRow` | row + expandable option list; selection shown by a `seam`/accent edge, not a colored fill. |
| `SettingsSearchableSelectRow` | the above + a filter input. |
| `SettingsHeader` | Tektur `title` + mono `small` subtitle + `LacunaIconButton` close. |
| `SettingsRail` / `SettingsSection` | linework rail navigation (`railTreatment: "linework"`) and grouped content. |
| toggle | compact pill knob (`switchStyle: "compact"`); track uses `seam`/`accent`, no heavy fill. |

Selected/active is communicated with **edge and accent strip** (`seam`, `accent`) — Lacuna draws
a line at the seam, it does not flood a tile with color. This keeps the unified color model
(01-color) intact even in dense settings views.

## The bar-widget "pill" vocabulary

Simple bar widgets (`lacuna.script-pill`, `lacuna.bar-size-pill`, `lacuna.compact-pill`, the
status widgets) share one shape: a square cell (`barSize`, ~26px), a centered glyph or short mono
label, recess on hover (`0.06`), and color from the **vendored** `ColorProfile.qml`
(`semantic` by default, `colorful` opt-in per [01-color.md](01-color.md)). They each carry their
own vendored `ColorProfile.qml` + `MotionTokens.qml`, synced from `shared/qml/simple-bar/` via
`scripts/sync-vendored`. A pill is a single cell of the manuscript grid: filled or empty.

## Rules

1. **Interaction = recess**, via `LacunaStateLayer`. Never a bespoke hover hue.
2. **Selection = edge/strip** (`seam`/`accent`), not a flooded fill.
3. **Compose primitives**; do not re-implement text, recess, icons, or motion locally.
4. **One shadow per silhouette.** Depth is composed at the assembly, not per piece.
5. **Reference tokens** (`LacunaTokens`, role colors, motion tokens) — never literals.
