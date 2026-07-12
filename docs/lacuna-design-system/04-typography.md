# 04 · Typography

> Principle 1: **Reveal, don't appear.** Principle 4: **Theme owns hue, Lacuna owns form** —
> and type is form.

## Two faces

Lacuna is **mono-first**. A monospace text face is the body and chrome of the entire shell; a
display face is reserved for titles.

| Role | Face | Why |
|---|---|---|
| **Mono** (body, chrome, data) | **Hack Nerd Font** | Even rhythm, excellent legibility at small sizes, and a Nerd Font glyph set that complements the inline Tabler icon paths. The mono grid *is* the manuscript. |
| **Display** (titles) | **Tektur** | Wide, technical, architectural. Used sparingly for headers and section titles to mark the seams of the layout. |

> **Migration note (done, Phase E).** The codebase previously hardcoded `JetBrains Mono`
> throughout; every literal — the `monoFont` token plus the per-component `bodyFontFamily`
> defaults — was swapped to **Hack Nerd Font** (the exact resolvable fontconfig family). Tektur
> remains the display/title face, and the Omarchy `bar.fontFamily` inheritance is untouched, so a
> user's configured bar font still wins for bar widgets.

### The manuscript tie-in
The name *lacuna* is a term from textual scholarship — the gap in a manuscript. A monospace face
is the closest a screen comes to a *set text*: a fixed grid of cells, each either filled or
empty. Choosing mono-first is the metaphor made literal — the interface is a page of text with
deliberate gaps in it. Display type (Tektur) marks where one passage ends and the next begins.

## The size scale

A single scale of named roles (px), from `LacunaTokens.qml`. Sizes do not vary by theme; they
flow through density `mix()` only where a layout demands it.

| Role | Size | Face | Use |
|---|---|---|---|
| `hint` | 9 | mono | captions, secondary hints under a row |
| `small` | 10 | mono | dense labels, metadata, subtitles |
| `body` | 12 | mono | default text — the workhorse (`LacunaText` default) |
| `primary` | 13 | mono | emphasized row labels, settings titles |
| `title` | 16 | Tektur | section / panel headers |
| `icon` | 15 | — | inline icon sizing baseline |
| `glyph` | 20 | — | large feature glyphs |

Control heights pair with the scale: `controlSmall 30`, `controlNormal 34`.

## Color, weight, and rendering

- **Color** comes from the role tokens in [01-color.md](01-color.md): primary text is `ink`,
  secondary is `whisper`, de-emphasized-but-legible is `soft`. Never a literal.
- **Weight** carries hierarchy sparingly: regular mono for body; Tektur (bold) for titles. Avoid
  using many weights of the mono face to signal hierarchy — use size and the `ink`/`whisper`
  ladder instead, so the page stays calm.
- **Rendering** follows the existing `LacunaText` contract: `Text.NativeRendering`,
  `Text.PlainText`, `elide: Text.ElideRight`, `maximumLineCount: 1` for chrome labels. Color
  transitions animate with `color` (160ms, `OutCubic`) — type re-colors as a reveal, never a snap.

## Tracking roles

Letter spacing is part of the type role and comes from `LacunaTokens`, not
component-local literals. Title tracking follows the sidebar `LACUNA`
wordmark; menu items retain a quieter rhythm so repeated navigation rows do not
read like competing headers.

| Role | Full | Compact | Use |
|---|---:|---:|---|
| `trackingTitle` | `2.0px` | `1.4px` | Tektur panel titles and wordmarks |
| `trackingMenuItem` | `0.9px` | `0.6px` | Tektur sidebar/menu item labels |
| `trackingSection` | `0px` | `0px` | dense uppercase section labels |
| `trackingBody` | `0px` | `0px` | mono body text, metadata, hints, and values |

Capitalization remains contextual: wordmarks and section labels may uppercase;
content-derived titles such as theme or wallpaper names preserve their normal
title casing while using the title tracking role.

## Behavior, true to the metaphor

- **Elision is a lacuna.** When text overflows, Lacuna *elides* (a trailing gap) rather than
  wrapping or shrinking. The missing tail is the half-hidden — consistent, never a reflow.
- **Single line for chrome.** Menu and bar labels stay one line. Multi-line is for content
  bodies, not chrome.
- **No font hard-coding in components.** Reference `tokens.monoFont` and the title face token,
  never a string literal, so the migration in Phase E is a one-line change.

## Rules

1. **Mono-first: Hack Nerd Font for body/chrome, Tektur for titles.**
2. **Use the named size roles**; do not introduce off-scale sizes.
3. **Hierarchy via size + `ink`/`whisper`/`soft`**, not a stack of weights.
4. **Elide, don't wrap or shrink, in chrome** — the trailing gap is intentional.
5. **Reference font tokens, never literals.**
6. **Reference tracking tokens, never literals.** Title, menu-item, section,
   and body tracking are distinct roles.
