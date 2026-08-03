# Bar Plugins

Status: reference

Lacuna has one bar-option plugin and several bar-widget plugins. The distinction
matters because Omarchy activates them through different configuration paths.

## Bar Option

`lacuna.bar` is selected through `bar.id`:

```bash
omarchy bar use lacuna.bar
```

It owns the Lacuna frame/sidebar choreography and applies a Lacuna module layout
instead of the stock Omarchy bar plugin set. It is not placed in `bar.layout`.

The Lacuna bar is deliberately opaque so its bar, frame, sidebar, connectors,
and attached flyouts read as one unified surface. Activating `lacuna.bar`
normalizes `bar.transparent` to `false`; the stock bar's double-click
transparency gesture is not part of the Lacuna bar contract. When the optional
Frame Border is enabled, Lacuna-owned bar flyouts continue that same solid
theme border around their exposed edges and leave the bar attachment edge open,
matching sidebar-attached flyouts. The border toggle is independent of Full
Frame: with Full Frame off, the bar and sidebar share one exposed seam rather
than boxing either surface. The bar rail stops at the sidebar molding tangent,
and the sidebar owns the curve plus its vertical content edge. Open bar flyouts
report their connector span to the owning bar window so this rail also stops at
both connector tangents and returns only after the attachment opening.

## Portrait Split

With `barPresentation.portraitSplit` enabled (the default), a logical portrait
output using a top or bottom bar also receives a companion on the opposite
edge. Landscape outputs and left/right bars retain the normal single surface.

Both bands derive from the one canonical `shell.json` layout. Codex/Claude
usage route to companion-left, system stats/temperature to companion-center,
and theme/wallpaper to companion-right. All other modules—including unknown
custom modules—stay in their original primary region. Order, per-widget
settings, and JSON-safe metadata are preserved, and every entry is instantiated
once per output.

The companion is a derived view, so dragging is disabled there. Primary-bar
editing continues to mutate the canonical three-region layout in Omarchy
Settings; there is no second persisted layout. Flyouts, tooltips, indicators,
and menu payloads receive the actual edge and screen of the band that invoked
them.

## Responsive Scaling

Compact and full are density choices; they do not directly decide which
modules are visible. Each horizontal bar instead uses the output's logical
width after Hyprland monitor scaling. Lacuna keeps the center anchor at the
exact output midpoint, gives the left and right sections equal non-overlapping
corridors, and hides lower-priority whole modules whenever their measured
widths exceed a corridor. Full mode uses the same protection as compact mode.

The width classes exposed to widgets and live diagnostics are `wide` (1680+),
`standard` (1200–1679), `constrained` (800–1199), and `minimal` (below 800)
logical pixels. Display scale is never applied a second time inside the bar.
Vertical bars retain their existing flow behavior.

## Bar Widgets

Bar widgets are placed in `bar.layout` and receive `bar`, `moduleName`, and
`settings` from Omarchy. Examples include:

- `lacuna.audio`
- `lacuna.bluetooth`
- `lacuna.clock`
- `lacuna.network`
- `lacuna.power`
- `lacuna.system-stats`
- `lacuna.weather`

Use `config/shell.lacuna-native-replacements.example.json` as the current
reference layout for Lacuna replacements.

## Size Controls

- `lacuna.bar-size-pill`: preferred compact/full Omarchy host bar toggle.
- `lacuna.compact-pill`: legacy companion; keep only for compatibility.
