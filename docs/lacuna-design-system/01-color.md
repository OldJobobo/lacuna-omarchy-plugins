# 01 · Color

> Principle 4: **Theme owns hue, Lacuna owns form.**

Lacuna does not have a palette. It has a set of **roles** and the **relationships** between them.
Every role resolves from the active Omarchy theme at runtime through `lacuna.menu/services/Theme.qml`
(and, for vendored bar widgets, `shared/qml/simple-bar/ColorProfile.qml`). The fallback values
below exist only so the shell degrades gracefully when no theme is loaded — they are *not* the
Lacuna palette, because there is no Lacuna palette.

## Source of truth

Color enters from two theme files Omarchy maintains:

- `~/.config/omarchy/current/theme/colors.toml` — the palette (`foreground`, `background`,
  `accent`, `color1`–`color15`).
- `~/.config/omarchy/current/theme/shell.toml` — shell-layer overrides (`menu.text`,
  `menu.selected`, `bar.background`, …), read via `shellColor()` / `shellSurfaceColor()`.

Shell overrides win where present; palette is the base; the fallback constants are the floor.

## The role tokens

Each role is named from the gap metaphor and defined as a **derivation**, never a literal.

| Role | Derivation | Fallback | Used for |
|---|---|---|---|
| `field` | `color("background")` | `#101315` | the page, deepest present background |
| `void` | `withAlpha(field, 0.18)` | — | intentional absence: insets, wells, scrim behind reveals |
| `plate` | `shellSurfaceColor("bar.background", field)` | `#101315` | a present, raised surface (bar, sidebar, flyout) |
| `ink` | `shellColor("menu.text", color("foreground"))` | `#d8dee9` | primary foreground / text |
| `whisper` | `withAlpha(ink, 0.48)` | — | muted foreground: hints, secondary labels, idle icons |
| `soft` | `withAlpha(ink, 0.78)` | — | de-emphasized but legible foreground |
| `seam` | `withAlpha(ink, 0.18)` | — | expressed edges, dividers, connector strokes, linework |
| `accent` | `shellColor("menu.selected", color("accent"))` | `#88c0d0` | the single theme accent (see unified model) |
| `danger` | `color("color9")` | `#bf616a` | destructive/high-impact actions only |
| `warning` | `color("color11")` | `#ebcb8b` | warm/low/warning status |
| `urgent` | `bar.urgent` → `color("color9")` | `#d42b5b` | critical/over-threshold status |

`withAlpha(c, a)` and the color-format parsing (hex `#RRGGBB[AA]`, `rgba()`, hyprland
`0xAARRGGBB`) already live in `Theme.qml`; reuse them rather than re-deriving.

### Why `recess` is not a color
`recess` (interaction depth) is defined in [05-components.md](05-components.md) as an **alpha
state over a surface**, not a hue, because Principle 3 renders interaction as sinking-in, not as
added light. Its values come from the design-style table below (`hoverOpacity`, `activeOpacity`).

## The unified color model

> Folds in and supersedes `docs/plans/lacuna-menu-unified-color-model.md`.

The menu must read as **one designed surface, not a set of unrelated semantic color chips.**
Therefore the rendered palette for chrome is intentionally narrow:

- `field` / `void` (background and absence)
- `ink` / `whisper` / `soft` (foreground ladder)
- `accent` (one theme accent for *all* non-destructive chrome)
- `danger` (reserved for destructive actions only)
- `seam` (edges)

**One accent for everything non-destructive.** Section headers, rail hovers, row hover/selected
states, tooltip strips, non-danger tile accents, and both the Lacuna-settings and Omarchy-shell-
settings flyouts all use the single `accent`. Only **destructive or high-impact actions**
(restart, shutdown, dangerous confirmations) use `danger`.

The implementation rule is unchanged and load-bearing:

```qml
function toneAccent(tone) {
  return tone === "danger" ? danger : accent
}
```

Tone metadata stays on menu entries (Lacuna / shell / session / neutral / danger) — it remains
useful for filtering, labels, and optional modes — but only `danger` changes the rendered hue.
Everything else collapses to `accent`. This keeps the active theme visible without turning every
category into a competing color.

## Color profiles: `semantic` vs `colorful`

A user (or per-widget setting) selects a `colorProfile`, stored in
`~/.config/omarchy/lacuna/settings.json` and read by `ColorProfile.qml`:

- **`semantic`** (default) — the unified model above. Non-danger elements use `ink`/`accent`
  only. Calm, cohesive, theme-forward. This is the canonical Lacuna feel.
- **`colorful`** — bar widgets may map their role to a distinct palette hue for at-a-glance
  identification. The role→palette map is:

  | role | palette key | role | palette key |
  |---|---|---|---|
  | `menu` | `accent` | `disk` | `color12` |
  | `codex` | `color6` | `memory` | `color10` |
  | `claude` | `color13` | `cpu` | `color11` |
  | `script` | `color14` | `temperature` | `color9` |
  | `density` | `color5` | | |

`colorful` is an **opt-in affordance for status widgets**, not the default and never the menu
chrome. The menu always obeys the unified model. Even in `colorful` mode, hues come from the
theme palette — Principle 4 still holds.

## Status semantics

Status colors are also theme-derived and carry fixed meaning across the shell:

- `warning` (`color11`) — warm / low / caution.
- `urgent` (`color9`, or `bar.urgent`) — critical / hot / over-threshold / alert.
- `danger` (`color9`) — destructive intent (a *user action*, distinct from a *system state*).

## Rules

1. **Never hard-code a hue in a component.** Resolve every color through a role token.
2. **`danger` is for destructive actions only.** A red system *state* is `urgent`/`warning`.
3. **One accent for non-destructive chrome.** Do not reintroduce per-category tones into the menu.
4. **Reach for `void`/`seam`/`recess` before reaching for new color.** Depth and edge first.
5. **Fallbacks are a floor, not a palette.** Never design *to* the fallback hexes.
