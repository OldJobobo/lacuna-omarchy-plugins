# Services And State

Status: reference

Lacuna keeps user-visible Omarchy plugin settings separate from Lacuna runtime
state.

## Omarchy Settings

Per-widget bar options belong in each plugin manifest's `barWidget.schema`.
Omarchy Settings writes those options into:

```text
~/.config/omarchy/shell.json
```

Bar layout placement also lives in `shell.json`.

## Lacuna Runtime Settings

Lacuna runtime/app state lives in:

```text
~/.config/omarchy/lacuna/settings.json
```

This includes shared Lacuna preferences such as:

- `colorProfile`
- `customQuickLaunchApps`
- `preferredApps`
- sidebar/frame settings

Scripts that rewrite this file must preserve existing keys.

### Canonical settings shape

`lacuna.state/Service.qml` is the canonical settings implementation. The
menu's `LacunaSettings.qml` copy is kept identical by `scripts/sync-vendored`.
Both services normalize the same runtime shape:

```json
{
  "version": 1,
  "designStyle": "lacuna",
  "designStyles": {
    "lacuna": {
      "bar": {
        "centerAnchor": "lacuna.clock",
        "layout": {
          "left": [],
          "center": [],
          "right": []
        }
      }
    },
    "omarchy": {},
    "material": {}
  }
}
```

The `designStyles.<style>.bar` object is optional and persists a style's bar
layout independently of the active `designStyle`. Layout entries may be
objects or strings; strings normalize to `{ "id": "..." }`. Object entries
require a non-empty `id` and preserve recursively JSON-safe metadata (strings,
booleans, finite numbers, nulls, arrays, and objects). Unsupported values are
discarded. `migrateSettings()` owns version handling and always emits the
current `settingsSchemaVersion`.

When adding a settings key, update the canonical service first, run
`scripts/sync-vendored`, and extend the normalization contract tests before
changing the UI.

## Persistent Services

`lacuna.state` is the persistent shared state service for the core bundle.
Menu/bar/panel plugins can also consume Omarchy services through the injected
`shell` reference. Simple bar widgets do not receive `shell`; they read
appropriate `Quickshell.Services.*` APIs directly.
