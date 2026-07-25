# Lacuna Design Language

> *Lacuna* (Latin: a gap, a hollow, a missing portion of a manuscript) — the half-hidden.
> An interface defined as much by what is absent, recessed, or withheld as by what is present.

This is the authored design language for the Lacuna Omarchy/Quickshell shell. It graduates
Lacuna from a Carbon-derived look into a first-class system of its own, organized around a single
metaphor: **the gap**.

## What Lacuna owns, and what it defers

Lacuna owns **form** — geometry, negative space, and reveal motion. The active Omarchy theme owns
**all hue**. This split is deliberate and load-bearing: it is what lets Lacuna read as *itself*
under any theme the user installs. There is no Lacuna brand color.

## The four principles

1. **Reveal, don't appear.** Motion discloses; nothing pops into existence.
2. **Show the seam.** Joins are expressed, not smoothed away.
3. **Absence has weight.** Void and recess are first-class material, not leftover background.
4. **Theme owns hue, Lacuna owns form.** Identity rides on structure and motion.

## Token families

| Family | Meaning |
|---|---|
| `field` | the page — deepest present background |
| `void` | absence/recess tone, deeper than field |
| `plate` | a present, raised surface |
| `ink` / `whisper` | foreground / muted foreground |
| `accent` / `danger` | the single theme accent + the destructive accent |
| `seam` | the expressed edge or join |
| `recess` | sunken interaction state (hover/press) |
| `threshold` | the boundary at which content discloses |
| `reveal` | the disclosure motion family |

## Documents

| File | Subject |
|---|---|
| [00-philosophy.md](00-philosophy.md) | The name, the metaphor, the four principles, ownership boundaries |
| [01-color.md](01-color.md) | Theme-derived color roles, profiles, the unified color model |
| [02-geometry.md](02-geometry.md) | The seam language: kappa, molding connectors, corners, radius |
| [03-motion.md](03-motion.md) | The unified reveal system: timing, easing, choreography |
| [04-typography.md](04-typography.md) | Mono-first identity, the type scale, the manuscript tie-in |
| [05-components.md](05-components.md) | Primitives and controls re-expressed in the token families |
| [06-roadmap.md](06-roadmap.md) | The phased migration from today's QML onto this language |

## Interaction scope

Lacuna is intentionally pointer-first. Broad keyboard navigation, complete
focus traversal, and screen-reader coverage are deferred because they require a
design-wide interaction model rather than piecemeal shortcuts. Existing bounded
focus behavior remains supported: intentional text entry, Escape and click-away
dismissal, and already-shipped semantic metadata must not regress. This matches
the beta boundary in [`../roadmap.md`](../roadmap.md).

## How this lives in the code

Plugins are self-contained and **vendor** shared build-time sources, reconciled
by `scripts/sync-vendored`. `shared/qml/LacunaGeometry.qml` owns curve geometry;
`shared/qml/simple-bar/` owns simple-widget color and motion templates. Runtime
imports remain plugin-local. This spec is the source of truth for intent, while
those shared templates are the source of truth for duplicated code.
