# 03 · Motion — the reveal system

> Principle 1: **Reveal, don't appear.**

Motion is not decoration in Lacuna; it is how the gap is bridged. A surface does not fade into
existence — it **opens its geometry from an attachment edge**, and its content is **disclosed
after a threshold**. The feeling to protect: *content was already there, behind the gap, and is
being uncovered.*

## One scale (the consolidation)

Today the code carries **two** unreconciled timing scales — a legacy Lacuna set and a noctalia-
style set. The design language defines **one** `reveal` scale. The legacy set is retired in favor
of these names (migration in [06-roadmap.md](06-roadmap.md), Phase D):

| Token | ms | Use |
|---|---|---|
| `instant` | 75 | micro-feedback; state that should feel immediate |
| `quick` | 150 | hover/press recess, small reveals, icon swaps |
| `color` | 160 | color transitions specifically (`ColorAnimation`) |
| `reveal` | 300 | the standard panel/flyout disclosure |
| `settle` | 450 | large geometry changes, layout reflow |
| `ambient` | 750 | slow, background, decorative drift |
| `pulse` | 900 | attention loops |
| `sweep` | 2400 | long decorative sweeps (overlays) |

Mapping from the old names: legacy `fast 120 → quick`, `normal 180 → ` use `quick`/`reveal` by
context, `slow 260 → reveal`, `legacyColor 160 → color`; noctalia `faster 75 → instant`,
`fast 150 → quick`, `normal 300 → reveal`, `slow 450 → settle`, `slowest 750 → ambient`.

## Easing

- **`OutCubic`** — the default. Reveals decelerate into place; they arrive softly, never bounce.
  Used for opacity, position, and most geometry.
- **`InOutSine`** — symmetric, gentle. Hovers, header transitions, anything that both opens and
  closes within a single gesture.
- **Reveal Bézier `[0.20, 0, 0.32, 1]`** — the signature panel-open curve. A quick commit out of
  the closed state, a long graceful settle. Reserve it for the primary surface disclosure.

Lacuna motion **does not overshoot or bounce.** Disclosure is calm and certain; a lacuna is
uncovered, not sprung open.

## The reveal choreography

The core sequence, true to Principle 1, is **geometry first, content after a threshold**:

```
t0 ─────────────── threshold ─────────────── t1
│   geometry opens from attachment edge       │
│   (width 0 → target, OutCubic / reveal-béz)  │
│                    │                          │
│                    └─ content opacity 0 → 1   │
│                       begins only here        │
└── surface is a thin seam ──► fully open ──────┘
```

Rules that make this read correctly:

1. **Animate geometry from the attachment edge**, not just a child offset. The surface should
   look like it is *growing out of the seam*, not sliding in pre-formed. (See the panel-lifecycle
   notes in `docs/plans/lacuna-noctalia-inspired-refactor-plan.md`.)
2. **Withhold content until the `threshold`.** Content opacity stays 0 until the surface is
   "substantially open," then fades in. Never show content over a half-width container.
3. **Cache the open direction.** Capture which way a panel is opening at the start of the gesture
   so a mid-flight geometry change cannot flip it. Disclosure must feel decided.
4. **Frame and overlay pieces slide in from their screen edge**, they do not fade on. Depth comes
   from a single combined shadow on the flattened silhouette, never stacked per-piece shadows.

### Interactive menu pipeline

`lacuna.menu` uses one controller-owned transition pipeline. A flyout requested
while the menu is closed is queued until sidebar progress reaches **0.65**.
The attached shell opens from its seam immediately after that point, while its
content remains fully concealed through flyout progress **0.55** and then uses
the remaining progress range for opacity. Closing follows the same mapping in
reverse.

Changing between flyouts keeps the shared shell open: the old and new content
crossfade over `quick` (150 ms), while the shell, connector, border, and input
mask interpolate over that same progress. The incoming content alone becomes
interactive after both progress values settle. Reduced motion settles all of
these states synchronously; it does not change the attachment origin or final
geometry.

## Closing

Closing is the reveal **in reverse and slightly faster**: content fades first (drops below the
threshold), then the geometry collapses back into the seam. The surface returns to being a
half-hidden edge — it does not vanish, it *re-conceals*.

## Reduced motion

Honor a reduced-motion preference by collapsing durations toward `instant` and dropping the
threshold delay (content and geometry resolve together). The *structure* of the reveal stays —
geometry still originates at the attachment edge — only the time is removed. Centralize this
switch alongside the tokens so every consumer obeys it; no component should special-case it.

## Where motion is owned

- `lacuna.menu/services/MotionTokens.qml` — canonical token home for the menu.
- `shared/qml/simple-bar/MotionTokens.qml` — canonical template for vendored bar widgets;
  re-vendor with `scripts/sync-vendored` after any change so every widget copy matches.
- Animation primitives (`LacunaAnim`, `LacunaColorAnim`, `LacunaStateLayer`) consume the tokens;
  components consume the primitives. No component should hand-write a duration.

## Rules

1. **Geometry first, content after the threshold.** Always.
2. **Open from the attachment edge**, never as a pre-formed slide.
3. **No bounce, no overshoot.** `OutCubic` / the reveal Bézier; calm arrivals.
4. **One scale, one place.** Use the named tokens; never inline a millisecond literal.
5. **Reduced motion removes time, not structure.**
