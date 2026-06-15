# 00 · Philosophy

## The name

*Lacuna* comes from Latin **lacuna** — "a pit, a hollow, a gap" — itself a diminutive of *lacus*,
a lake or basin. Its most evocative English sense is the one used of old manuscripts: **a lacuna
is the blank where text has been lost**, a hole in a document, a place where meaning is
*half-hidden* and the reader supplies the rest. The plural is *lacunae*.

That is the whole idea of this shell. A Lacuna interface is defined as much by **what is absent,
recessed, or withheld** as by what is present. Empty space is not the leftover around the design;
it *is* the design. Surfaces do not announce themselves — they disclose, partially and on cue.

This document is the root of the design language. Every later rule in this folder — color,
geometry, motion, type, components — must trace back to one of the four principles below. If a
proposed rule cannot, it does not belong in Lacuna.

## The four principles

### 1. Reveal, don't appear
Motion **discloses**; nothing pops into existence. A panel opens its geometry first and admits
its content only after it has opened far enough to hold it (the *threshold*). Frame pieces slide
in from the screen edge rather than fading on. The user should always feel that content was
*already there, behind the gap*, and is being uncovered — never that it was conjured.

> Practical consequence: animate the container's geometry from its attachment edge, then fade
> content in after a threshold. Never cross-fade a fully-formed panel into view.

### 2. Show the seam
Joins are **expressed, not smoothed away**. Where the sidebar meets a flyout, Lacuna keeps the
attachment edge square and bridges the gap with a *molding connector* — a deliberate piece of
trim, like architectural moulding — instead of melting the two shapes into one blob of corner
radius. The visible seam is a signature, not a defect. It tells the truth about how the surfaces
are assembled.

> Practical consequence: square attachment edges; molding connectors derived from one curve
> constant; round only the *exposed* corners of a surface, never the joined ones.

### 3. Absence has weight
**Void** and **recess** are first-class material with their own tokens. The deepest tone in a
Lacuna surface is not "the background showing through" — it is an intentional absence with a
named value. Interaction is rendered as a *recess* (a sinking-in) rather than a tint or a glow,
because pressing into a surface is a gesture about depth and space, not about adding light.

> Practical consequence: name the void and the recess; reach for negative space and depth before
> reaching for borders, fills, or color.

### 4. Theme owns hue, Lacuna owns form
Lacuna carries its identity in **structure and motion** so that it reads as itself under *any*
Omarchy theme. Every color in the system is **derived from the active theme**, never fixed.
There is no Lacuna brand color and no signature hue. What stays constant across themes is the
shape language, the negative space, the seams, and the reveal — the form.

> Practical consequence: no hard-coded hues in components; all color resolves through the theme
> service. See [01-color.md](01-color.md).

## What Lacuna owns vs. what it defers

Lacuna is an **Omarchy plugin set**, not a shell replacement, and that boundary is part of the
philosophy. Lacuna deliberately owns very little surface area and does it with conviction:

**Lacuna owns:**
- The command sidebar and its flyouts — the distinctive molding/seam/reveal surface.
- The negative-space and void language across every surface.
- The reveal choreography (how things disclose).
- Its experimental, non-native widgets where they prove a durable Lacuna workflow.

**Lacuna defers:**
- **All hue** — to the active Omarchy theme.
- **Rich system surfaces** (audio, network, Bluetooth, battery, tray, notifications, calendar)
  — to Omarchy-native services and widgets, which are already strong.
- **Process and runtime control** — to Omarchy commands (`omarchy restart shell`, etc.).

This restraint is itself a lacuna: Lacuna leaves gaps for the platform to fill, and is more
coherent for it.

## A note on lineage (and leaving it behind)

Lacuna's look was originally derived from, and inspired by, **Carbon** — and the code still shows
it: the internal style alias `carbon: lacuna` in `lacuna.menu/services/DesignTokens.qml`. This
design language **retires that lineage**. Carbon's debt is acknowledged with gratitude, but
Lacuna is now self-defined: the metaphor of the gap, not a borrowed grid, is the organizing
principle. The `omarchy` and `material` styles remain as selectable alternates; only the Carbon
alias is removed. See [06-roadmap.md](06-roadmap.md), Phase A.
