# Lacuna Theme Preloader Plugin Plan

## Goal

Reduce the perceived startup delay of the stock Omarchy theme switcher by keeping the caches it already uses warm before the user opens it.

The plugin must not replace the Omarchy theme switcher. It should prepare the same preview and thumbnail cache paths so the existing `omarchy theme switcher` path remains the UI and selection authority.

## Current Omarchy Theme Switcher Flow

The stock theme switcher script performs three expensive steps before the picker is useful:

1. Scan user themes in `~/.config/omarchy/themes`.
2. Scan stock themes in `~/.local/share/omarchy/themes`.
3. Build preview symlinks in `~/.cache/omarchy/theme-selector/previews`, then delegate to `omarchy menu images`.

`omarchy menu images` then prepares image-selector rows and thumbnails under `~/.cache/omarchy/image-selector`.

## Plugin Shape

Add a persistent headless plugin:

```text
lacuna.theme-preloader/
  manifest.json
  Service.qml
  scripts/
    preload-theme-switcher.sh
```

The plugin is headless and runs inside the existing Omarchy shell process. It does not create a second Quickshell process.

Current Omarchy shell only instantiates generic `service` entries for first-party plugins. For third-party Lacuna code, the preloader should therefore declare a `panel` entry with `keepLoaded: true` and use an `Item` root that renders no window. This makes it behave like a persistent service while using the supported third-party loader path.

## Runtime Behavior

`Service.qml` should:

- run a warmup shortly after shell startup
- rerun on a conservative interval while the shell is alive
- expose IPC for manual warmup and status checks
- avoid overlapping runs

`preload-theme-switcher.sh` should:

- mirror the stock theme-switcher preview-index logic
- write only regeneratable cache files under `~/.cache/omarchy`
- warm the image-selector cache with `omarchy menu images --cache-only`
- never edit files in `~/.local/share/omarchy`
- exit successfully when another preload is already running

## Cache Paths

The plugin may write:

```text
~/.cache/omarchy/theme-selector/previews
~/.cache/omarchy/theme-selector/signature
~/.cache/omarchy/theme-selector/preloader-status.json
~/.cache/omarchy/image-selector
```

The plugin may read:

```text
~/.config/omarchy/themes
~/.config/omarchy/current/theme.name
~/.local/share/omarchy/themes
```

## IPC

Expose:

```bash
omarchy-shell lacuna-theme-preloader warm
omarchy-shell lacuna-theme-preloader status
omarchy-shell lacuna-theme-preloader ping
```

`warm` starts a preload if one is not already running. `status` returns a small JSON object describing whether the service is running and the last exit code.

## Validation

Use:

```bash
qmllint lacuna.theme-preloader/Service.qml
bash -n lacuna.theme-preloader/scripts/preload-theme-switcher.sh
lacuna.theme-preloader/scripts/preload-theme-switcher.sh
omarchy plugin rescan
omarchy restart shell
quickshell log --path ~/.local/share/omarchy/shell --tail 100 --newest
```

Success criteria:

- no UI opens during preload
- cache paths are created or refreshed
- repeated warm runs are cheap
- shell log contains no Lacuna QML errors
- stock theme switcher still owns actual selection and theme application
