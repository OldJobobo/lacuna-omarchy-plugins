# Widget Plugins

Status: reference

Lacuna widgets are a-la-carte bar widgets unless the plugin catalog marks them
as bundle-only or deprecated.

## Native-Replacement Widgets

These mirror common Omarchy/system surfaces with Lacuna styling:

- `lacuna.audio`
- `lacuna.bluetooth`
- `lacuna.indicators`
- `lacuna.network`
- `lacuna.notifications`
- `lacuna.power`
- `lacuna.system-stats`
- `lacuna.system-update`
- `lacuna.weather`

Prefer Omarchy-native services and widgets for rich behavior that Lacuna does
not need to own visually. Lacuna widgets should fill real visual/workflow gaps,
not fork Omarchy orchestration.

## Local Status Widgets

- `lacuna.claude-usage`
- `lacuna.codex-usage`
- `lacuna.temperature`
- `lacuna.voxtype`
- `lacuna.idle-inhibitor`
- `lacuna.screen-recording`

## Experiment Path

`lacuna.script-pill` is the script-backed widget experiment path. Promote a
script-backed widget only when it proves a durable non-native workflow.
