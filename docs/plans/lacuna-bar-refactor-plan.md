# Lacuna Bar Refactor Plan

Status: complete

## Summary

Refactor Lacuna around the existing `lacuna.bar` plugin as the dedicated
Lacuna Bar. It remains an Omarchy bar option selected through
`bar.id = "lacuna.bar"` and composes modules from Omarchy's existing
`bar.layout` plus `barWidgetRegistry`.

The goal is a cleaner host/container architecture where `lacuna.bar` owns the
bar frame, embedded sidebar choreography, and module layout while individual
features remain modular bar-widget, service, panel, menu, or overlay plugins.

## Decisions

- Keep `lacuna.bar` as the Lacuna Bar plugin ID; do not create a second bar
  plugin.
- Keep `shell.json` as the public composition interface; do not introduce a
  private Lacuna module registry.
- Keep `lacuna.menu` as a compatibility summon target that delegates to the
  bar-hosted menu when `shell.bar.lacunaFrameHost === true`.
- Use Noctalia as an architectural reference for host-owned geometry, stable
  widget models, open/closing render slots, and unified shape backgrounds, but
  do not copy Noctalia's registry, settings system, packaging, compositor
  abstraction, or standalone shell ownership.
- Keep reusable plugin extraction evaluative for this refactor. Classify
  candidates now; only extract them later after boundaries are proven.
- Required pre-refactor baseline is static/unit coverage. Live Omarchy smoke
  testing is recommended after runtime changes, but not required before
  structural work begins.

## Implementation Checklist

- [x] Pin current `lacuna.bar` host behavior with tests.
- [x] Pin `BarModel.js` layout normalization and helper behavior with pure
  JavaScript-backed tests.
- [x] Document reusable extraction candidates for theme, wallpaper, Claude,
  and Codex modules.
- [x] Keep installer activation aligned with `bar.id = "lacuna.bar"` and the
  Lacuna host layout.
- [x] Move any remaining frame/sidebar ownership assumptions from
  `lacuna.menu` fallback behavior into `lacuna.bar` where practical.
- [x] Preserve flyout geometry rules: square attachment edge, molding
  connectors, fill-only shells, and `curveKappa = 0.5522847498`.
- [x] Run `python3 -m pytest` after each meaningful slice.
- [x] Run `./scripts/check.sh` before publishing the refactor.

## Progress

- 2026-06-14: Added this active plan, documented reusable extraction
  candidates, added `BarModel.js` unit coverage, and verified the baseline with
  `python3 -m pytest` and `./scripts/check.sh`.
- 2026-06-14: Added installer coverage for Lacuna Bar host layout filtering,
  `centerAnchor`, and preserved entry settings. Updated hosted menu frame
  ownership so `hostManaged` suppresses fallback frame/reserve behavior even
  before `shell.bar` is assigned. Verified with `python3 -m pytest` and
  `./scripts/check.sh`.
- 2026-06-14: Added explicit contract coverage for Lacuna flyout geometry:
  square attachment edges, molding connectors, fill-only shell paths, and the
  shared `curveKappa` constant. Completed the active checklist and verified
  with `python3 -m pytest` and `./scripts/check.sh`.
- 2026-06-14: Fixed bar-owned full-frame corner spacing by separating the
  hosted sidebar's frame occlusion width from its molding/input surface width.
  The full-frame strips and shadows now align to the sidebar body edge instead
  of starting after the connector inset.
- 2026-06-14: Fixed the remaining left end gap on the top bar by disabling the
  bar-owned left/right frame reserve on any edge already occupied by the hosted
  sidebar. The sidebar reserve now owns that workarea while it is visible.
- 2026-06-14: Matched collapsed rail geometry to the active top bar height:
  the rail panel and its buttons now use the same width as the rendered
  top-bar height for the current size mode, with no extra side padding.
- 2026-06-14: Fixed the hosted rail's stale size fallback. `lacuna.bar` now
  passes its resolved `Style.bar` size into the hosted menu, so themes with
  full-size `size-horizontal = 32` do not collapse the rail back to the old
  26px default.

## Test Targets

- `lacuna.bar` public host API and injected-property compatibility.
- `lacuna.menu` delegation and fallback behavior when a Lacuna bar host is
  present or absent.
- Installer activation behavior: selected bar ID, layout replacement, preserved
  Lacuna widget settings, and restart/rescan command choice.
- Manifest metadata and docs classification for standalone, bundle-only, and
  reusable-candidate plugins.
- `BarModel.js` helpers: position normalization, entry settings, tray pinning,
  entry lookup, path expansion, custom module type inference, and safe custom
  module paths.

## Reusable Candidate Policy

The first refactor pass keeps all current plugin IDs. The following plugins
should be treated as extraction candidates and kept free of unnecessary Lacuna
frame/sidebar coupling:

- `lacuna.theme`
- `lacuna.wallpaper`
- `lacuna.claude-usage`
- `lacuna.codex-usage`

Extraction is a later phase, not part of the first host-architecture pass.
