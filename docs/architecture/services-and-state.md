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

Sidebar monitor targeting is part of the canonical `sidebar` object:

```json
{
  "monitorPolicy": "auto",
  "monitorNames": []
}
```

`monitorPolicy` accepts `auto`, `pinned`, and `all`. `monitorNames` stores
unique output names for `pinned` mode and can contain one or several names.
The sidebar may be mirrored to every selected output, but an open flyout is
kept on the active/focused selected output only.

Scripts that rewrite this file must preserve existing keys. The bar-size
helper routes live mutations through `lacuna.state`'s `lacuna-settings-state`
IPC target so updates serialize with the QML owner. When the shell is not
running, it takes the shared `settings.lock`, re-reads at commit time, overlays
only bar-size-owned keys, and uses an operation-owned atomic temporary file.

### Canonical settings shape

`lacuna.state/Service.qml` is the canonical settings implementation. The
menu's `LacunaSettings.qml` copy is kept identical by `scripts/sync-vendored`.
Both services normalize the same runtime shape:

```json
{
  "version": 2,
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

Settings schema v2 separates attached-flyout connectors from frame molding:
`sidebar.connectorPieces` controls only the molding bridge between the sidebar
and an attached flyout. `frame.moldingPieces` controls the curved upper/lower
frame joins and framed content radius, including the joins beside a visible
sidebar. Migration precedence is `frame.moldingPieces`, then the interim
`frame.roundedContentCorners` alias, then legacy `sidebar.cornerPieces`, then
the enabled default. For one release, normalized settings retain both interim
aliases for rollback. That downgrade is intentionally lossy once connector and
frame molding values diverge.

The unqualified term **corner pieces** is reserved for a future, separate
feature: black masks in the physical outer screen corners that make the outer
shell silhouette appear rounded, similar to Noctalia. Those masks are not part
of schema v2 and are not implemented by `frame.moldingPieces`.

When adding a settings key, update the canonical service first, run
`scripts/sync-vendored`, and extend the normalization contract tests before
changing the UI.

## Persistent Services

`lacuna.state` is the persistent shared state service for the core bundle.
Menu/bar/panel plugins can also consume Omarchy services through the injected
`shell` reference. Simple bar widgets do not receive `shell`; they read
appropriate `Quickshell.Services.*` APIs directly.
