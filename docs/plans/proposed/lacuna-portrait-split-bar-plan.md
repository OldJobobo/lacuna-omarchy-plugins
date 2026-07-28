# Lacuna Portrait Split Bar

Status: proposed; ready for implementation

## Summary

Restore the portrait-monitor bar composition from standalone Lacuna as an
optional Lacuna plugin feature. On a portrait output, a horizontal Lacuna bar
is split across the configured edge and the opposite edge instead of forcing
the complete desktop layout into one narrow row.

The feature is per output and automatic:

- Landscape outputs keep the current single-bar composition.
- Portrait outputs use the split composition when enabled.
- A top bar gains a portrait-only bottom companion; a bottom bar gains a
  portrait-only top companion.
- Left and right bar positions remain unchanged because they already use the
  vertical bar implementation.

The standalone source reference is `~/Projects/lacuna/LacunaBar.qml`. Its
load-bearing behavior is the logical `height > width` portrait test, dedicated
portrait clusters, and an opposite-edge bar for usage, telemetry, theme, and
wallpaper controls. The plugin implementation must preserve Omarchy's
`shell.json` layout as the canonical widget list rather than copying the
standalone hard-coded widget tree.

## Current Gap

`lacuna.bar/OmarchyBar.qml` creates the same normalized `bar.layout` on every
valid screen. It has no portrait predicate and no second bar surface. Its
compact overflow path is based on bar height (`barSize <= 26`), not output
shape, so full-size portrait bars can collide or lose the deliberate standalone
composition.

On the current three-output setup, `DP-3` is logically portrait. Live layer
state shows one top `omarchy-bar` plus the bottom frame reserve; there is no
portrait companion bar. This confirms that the feature is absent rather than
merely disabled.

## Product Contract

### Activation

Add an additive Lacuna runtime setting:

```json
{
  "barPresentation": {
    "portraitSplit": true
  }
}
```

- Default `portraitSplit` to `true` to restore established Lacuna behavior.
- Normalize it in both `lacuna.state/Service.qml` and
  `lacuna.menu/services/LacunaSettings.qml`.
- Preserve unknown keys under `barPresentation`.
- Add a `Portrait split bar` toggle to the Lacuna Layout settings section.
- Do not rewrite `shell.json` when the toggle, monitor orientation, or monitor
  set changes.

The effective split state for a screen is:

```text
portraitSplit setting is enabled
AND logical screen height > logical screen width
AND bar.position is top or bottom
```

Use logical Quickshell screen dimensions after output transforms. Do not bind
the feature to connector names such as `DP-3` or to Hyprland transform numbers.
Zero-sized and transient screens remain filtered by `ScreenModel.validScreens`.

### Widget routing

Derive both bands from the one normalized `shell.json` layout. Every layout
entry, including its widget-specific settings and JSON-safe metadata, must be
instantiated exactly once per output.

Use this built-in portrait route table, matching the standalone composition:

| Widget IDs | Portrait band | Target region |
| --- | --- | --- |
| `lacuna.codex-usage`, `lacuna.claude-usage` | companion | left |
| `lacuna.system-stats`, `lacuna.temperature` | companion | center |
| `lacuna.theme`, `lacuna.wallpaper` | companion | right |
| all other known and unknown entries | primary | original region |

Rules:

- Canonicalize IDs before routing so supported aliases behave consistently.
- Preserve source order within each routed group.
- Preserve settings objects unchanged.
- Unknown/custom modules stay in their original region on the primary bar;
  they must never disappear merely because the output is portrait.
- Do not add `portraitBand` metadata or a second persisted layout in the MVP.
  User-authored routing and drag-to-move-between-bands are follow-up work.
- The configured `centerAnchor` remains active only on the primary bar. The
  companion center region is centered as a normal module list.

This gives the current layout the intended distribution without owning the
layout twice:

- Primary: menu/workspaces/media; voice/clock/weather/status indicators;
  tray/connectivity/audio/power/bar-size control.
- Companion: Codex/Claude usage; system telemetry/temperature;
  theme/wallpaper controls.

### Surface behavior

Add one Lacuna-owned companion `PanelWindow` per valid screen inside the bar
host.

- Namespace: `lacuna-bar-portrait-companion`.
- Layer: `WlrLayer.Top`.
- Edge: opposite the configured horizontal bar edge.
- Thickness: the same horizontal `barSize` as the primary bar.
- Exclusive zone: `barSize` only while split mode is effective for that
  screen; otherwise `0`.
- Keyboard focus: none.
- Background and theme transitions: identical to the primary Lacuna bar.

Keep the companion window permanently mapped for every valid screen. Gate its
paint, input mask, and exclusive zone when inactive instead of toggling window
`visible`. This avoids same-layer remapping and follows
`docs/architecture/layer-stacking.md`.

The primary bar also switches to its filtered portrait layout without remapping
its window. Rotating an output at runtime must update both bands, reserves,
paint, and input atomically enough that no stale empty work-area strip remains.

### Per-surface bar context

A companion widget must see its actual edge, not the globally configured edge.
Introduce a small per-surface bar-context proxy and inject it into widgets from
`ModuleSlot`:

- Forward the existing bar API and shared properties used by widgets.
- Override `position`, `vertical`, and edge-sensitive popup context for the
  owning surface.
- Keep `barSize`, colors, font, shell access, popout ownership, tooltip routing,
  and menu routing shared with the root bar.
- Audit every `bar.*` use before finalizing the proxy contract; pin the required
  forwarding surface in a contract test.

This is required so open indicators, meters, flyouts, and popup payloads treat
a bottom companion as bottom-attached rather than top-attached.

### Interaction and editing

- Tooltips and flyouts anchor to the actual primary or companion window.
- Bar-originated menu payloads report the invoking screen and actual bar edge.
- Global popout ownership remains singular: opening a widget on either band
  closes the previously active popout.
- Screen removal clears tooltip, popout, and drag state exactly as it does now.
- Disable drag reordering on the companion band in the MVP. Its placement is a
  derived view over the canonical layout and cannot be persisted honestly by
  the existing three-region editor.
- Primary-band drag operations continue to edit canonical `shell.json`; tests
  must cover filtered entries so hidden companion entries are not dropped or
  reordered accidentally.
- The existing bar configuration panel remains the only layout editor and
  should explain that selected widgets are redistributed automatically on
  portrait outputs.

## Frame, Border, and Reserve Geometry

The companion bar becomes a real second frame edge on its portrait output.
Update geometry per screen rather than introducing a global second-bar flag.

### Frame paint and shadow

Extend `LacunaFrameWindow.qml` and `LacunaFrameBorderWindow.qml` with an
opposite-edge occupancy input for the portrait companion.

- Exclude both bar strips from frame paint and shadow clipping.
- Use `barSize` for both horizontal bar insets on an active portrait split.
- Keep landscape and vertical-bar geometry byte-for-byte equivalent in the
  inactive path.
- Keep the frame and border windows permanently mapped.
- Do not rely on map order between `omarchy-bar`, the companion, and frame
  surfaces; geometry must make overlap impossible.

Update `Bar.qml` helpers such as `lacunaFrameContentRect(screen)` to compute the
companion state from that specific screen. Include the effective split state in
`lacunaFrameGeometryKey` so runtime rotations and setting changes invalidate
geometry deterministically.

### Exclusive reserves

The existing full-frame reserve on the companion edge must not coexist with the
companion bar.

- Suppress `LacunaFrameReserveWindow` only for the effective companion edge on
  the effective portrait screen.
- Let the companion bar own that edge's exclusive zone.
- Keep frame reserves unchanged on all other screens and edges.
- When split mode deactivates, clear the companion exclusive zone before or in
  the same update that re-enables the frame reserve to prevent a doubled or
  missing work-area inset.

Sidebar edge ownership remains unchanged because the portrait companion uses
only top/bottom edges.

## Implementation Phases

### Phase 1 — Pure screen and routing model

1. Add `ScreenModel.isPortrait(screen)` using finite positive logical geometry.
2. Add pure routing helpers in a new `lacuna.bar/PortraitBarModel.js` rather
   than embedding route mutation in QML.
3. Return primary and companion `{ left, center, right }` layouts from one
   normalized source layout.
4. Prove canonical ID matching, ordering, metadata preservation, unknown-entry
   fallback, and exactly-once membership with Node-backed unit tests.

### Phase 2 — Settings contract

1. Add and normalize `barPresentation.portraitSplit` in both settings services.
2. Update `config/settings.example.json` and settings fixtures.
3. Add the Layout settings toggle and explanatory copy.
4. Verify old settings files migrate additively with the feature enabled and
   unknown settings preserved.

### Phase 3 — Per-surface composition

1. Refactor `LeftModules`, `CenterModules`, `RightModules`, `ModuleList`, and
   `ModuleSlot` to accept a routed layout/band and an owning surface context.
2. Keep the existing primary `BarPanel` mapped and switch its entries between
   full and portrait-primary layouts per screen.
3. Add the permanently mapped companion panel and render the companion layout
   on the opposite edge only when effective.
4. Add the per-surface bar-context proxy and edge-aware popup context.
5. Gate companion dragging while preserving primary and landscape editing.

### Phase 4 — Frame and work-area integration

1. Thread per-screen companion occupancy through `Bar.qml` into frame and border
   windows.
2. Exclude the companion strip from frame paint, border, and shadow geometry.
3. Suppress the redundant frame reserve and let the companion own exclusion.
4. Update the layer assignment table and the layer-policy contract for the new
   namespace/surface.

### Phase 5 — Runtime hardening

1. Handle live output rotation, add/remove, bar top/bottom changes, theme
   changes, bar-size changes, and setting toggles without remapping protected
   surfaces.
2. Confirm popout, tooltip, menu, and screen fallback behavior from both bands.
3. Verify that fullframe, frame shadow, frame border, sidebar auto/pinned/all,
   and corner-piece settings remain coherent on mixed-orientation outputs.

## Test Plan

### Deterministic/unit tests

- Extend `tests/test_bar_screens.py` for landscape, portrait, square,
  zero-sized, and transformed logical geometry.
- Add `tests/test_portrait_bar_model.py` for:
  - route-table membership;
  - alias canonicalization;
  - source-order preservation;
  - settings/metadata preservation;
  - unknown/custom module fallback;
  - exactly-once membership across both bands.
- Extend settings normalization tests in `tests/test_qml_contracts.py` and
  fixtures for missing, true, false, malformed, and unknown sibling values.

### QML behavior and geometry tests

- Add a runtime behavior test under `tests/test_qml_behavior_*.py` proving that
  a landscape and portrait screen can coexist with different effective bands.
- Test top-primary/bottom-companion and bottom-primary/top-companion contexts.
- Test that companion widgets receive the companion edge and remain registered
  with valid implicit geometry.
- Test primary drag mutation with companion-filtered entries and confirm no
  canonical entries are lost.
- Extend `tests/test_qml_geometry.py` for dual horizontal insets, companion-edge
  reserve suppression, frame/sidebar occlusion, and runtime activation changes.
- Update `test_layer_stacking_policy` for
  `lacuna-bar-portrait-companion: WlrLayer.Top` and permanent mapping.
- Add string-contract pins only for structural invariants; do not treat them as
  substitutes for behavior or geometry tests.

### Repository validation

Run:

```bash
./scripts/check.sh
scripts/quattro-compatibility --check
scripts/quattro-p0-smoke
```

The compatibility review must confirm that the per-surface context proxy does
not break Omarchy bar widget injection, popout ownership, registry routing, or
layout mutation contracts.

### Live validation

Deploy the changed installed plugins before reporting the feature fixed:

```bash
./scripts/dev deploy lacuna.state
./scripts/dev deploy lacuna.menu
./scripts/dev deploy lacuna.bar
```

Then verify on the current mixed setup:

1. `DP-1` and `DP-2` retain one top bar and their current layout.
2. Portrait `DP-3` shows the primary top bar and populated companion bottom bar.
3. `hyprctl layers` shows one permanently mapped companion surface per valid
   output, with inactive landscape instances transparent and non-exclusive.
4. `hyprctl monitors` reserved areas show one bar-sized inset on each active
   portrait horizontal edge, without the old bottom frame reserve doubling it.
5. Every configured layout entry appears exactly once on each output.
6. Tooltips, flyouts, open indicators, menu invocation, and bar-size control
   use the correct edge on both bands.
7. Toggle portrait split off/on, rotate `DP-3`, switch top/bottom bar position,
   restart Omarchy shell, and disconnect/reconnect the output.
8. Re-run with frame off, sidebar frame, fullframe, frame border/shadow, and
   sidebar monitor policies `auto`, `pinned`, and `all`.

Add an opt-in `LACUNA_LIVE_VISUAL=1` probe if deterministic screenshots can
assert the two populated bands and restored work area; it must restore every
setting and bar position in cleanup.

## Documentation

- Update `docs/configuration.md` with activation and routing behavior.
- Update `docs/plugins/bar.md` or the current bar plugin reference with the
  per-screen split contract and editing limitation.
- Update `docs/architecture/layer-stacking.md` with the companion surface.
- Update `docs/architecture/quattro-compatibility.md` multi-monitor policy.
- Record that this restores the standalone behavior while preserving Omarchy
  `shell.json` ownership.

## Rollback and Recovery

- User rollback: set `barPresentation.portraitSplit` to `false`; this must
  restore the current single-bar behavior without changing `shell.json`.
- Code rollback: remove the companion composition and dual-edge geometry while
  retaining additive settings data as an ignored, preserved key.
- Host recovery remains `omarchy plugin bar reset`.
- If live geometry fails, deploy the previous `lacuna.bar` and restart Omarchy
  shell; no layout migration or destructive config rewrite should need undoing.

## Acceptance Criteria

The feature is complete when a portrait and landscape output can run
simultaneously, the portrait output has two populated horizontal Lacuna bands,
landscape output behavior is unchanged, every canonical layout entry appears
exactly once per output, frame/work-area geometry has no doubled reserve or
paint overlap, all edge-sensitive interactions use the owning surface edge,
and repository plus live validation pass after deployment.

## Non-Goals

- Independent user-authored layouts per monitor.
- Persisted primary/companion routing metadata.
- Dragging widgets between portrait bands.
- Split bars for left/right bar positions.
- Recreating standalone script-backed widgets instead of using current Lacuna
  plugin widgets.
- Folding this feature into the broader Shell Layout Presets proposal.
