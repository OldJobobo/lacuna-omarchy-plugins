# Lacuna Menu Unified Color Model

Status: done

## Goal

Keep Lacuna menu surfaces cohesive while still using the active Omarchy theme
well. The menu should read as one designed surface, not as a set of unrelated
semantic color chips.

## Chosen Model

Use one primary theme accent for normal menu chrome:

- section headers
- rail hover states
- row hover and selected states
- tooltip strips and borders
- non-danger tile accents
- Lacuna settings and Omarchy shell settings flyouts

Reserve a separate danger accent only for destructive or high-impact actions,
such as restart and shutdown confirmations.

## Rationale

Older Lacuna menu entries carried separate tone colors for Lacuna, shell,
session, danger, and neutral navigation. That made the menu scannable by
consequence, but it also made mixed views feel visually noisy. The unified
model keeps the same metadata and grouping in the registry while reducing the
rendered palette to:

- active theme background
- active theme foreground and muted foreground
- active theme primary accent
- urgent/danger accent

This keeps theme colors visible without turning every category into a competing
hue.

## Implementation Rule

`toneAccent(tone)` should return the theme danger color only when
`tone === "danger"`. Every other tone should return the primary Lacuna/theme
accent. Do not remove tone metadata from menu entries; it remains useful for
future filtering, labels, and optional visual modes.
