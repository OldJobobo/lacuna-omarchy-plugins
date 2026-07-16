# Bar Plugins

Status: reference

Lacuna has one bar-option plugin and several bar-widget plugins. The distinction
matters because Omarchy activates them through different configuration paths.

## Bar Option

`lacuna.bar` is selected through `bar.id`:

```bash
omarchy plugin bar use lacuna.bar
```

It owns the Lacuna frame/sidebar choreography and applies a Lacuna module layout
instead of the stock Omarchy bar plugin set. It is not placed in `bar.layout`.

The Lacuna bar is deliberately opaque so its bar, frame, sidebar, connectors,
and attached flyouts read as one unified surface. Activating `lacuna.bar`
normalizes `bar.transparent` to `false`; the stock bar's double-click
transparency gesture is not part of the Lacuna bar contract.

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
