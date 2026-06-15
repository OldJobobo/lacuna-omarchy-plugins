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

> **Migration note.** The codebase currently hardcodes `JetBrains Mono` (`monoFont` in
> `lacuna.menu/components/LacunaTokens.qml`, default color/font in `LacunaText.qml`). Adopting
> **Hack Nerd Font** is a deliberate change; this spec defines the target, and
> [06-roadmap.md](06-roadmap.md) Phase E performs the swap (single token + re-vendor). Tektur is
> already in use for settings titles/headers and is unchanged.

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
