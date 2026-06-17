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

## Persistent Services

`lacuna.state` is the persistent shared state service for the core bundle.
Menu/bar/panel plugins can also consume Omarchy services through the injected
`shell` reference. Simple bar widgets do not receive `shell`; they read
appropriate `Quickshell.Services.*` APIs directly.
