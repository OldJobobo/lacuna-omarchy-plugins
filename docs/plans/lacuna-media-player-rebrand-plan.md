# Lacuna Media Player Rebrand Plan

Status: planned

## Goal

Rename the YouTube Music player surface into a generic Lacuna media player
without changing playback behavior yet.

This plan covers naming, labels, plugin IDs, file names, directories, and
compatibility aliases. Provider-specific behavior remains provider-specific:
YouTube login, YouTube URL parsing, YouTube cookies, Jellyfin search, and
provider settings should keep their precise provider names.

## Naming Model

Use `Media Player` for the Lacuna surface and reserve `YouTube`, `Jellyfin`, or
other provider names for provider-specific settings, scripts, status messages,
and error text.

Canonical public names:

```text
Lacuna Media Player
Lacuna Media Player Video
```

Canonical plugin IDs:

```text
lacuna.media-player
lacuna.media-player-video
```

Preferred internal QML naming:

```text
mediaPlayerService
mediaPlayerOpen
mediaPlayerVisible
mediaPlayerWidth
mediaPlayerContent
openMediaPlayerPanel()
resolveMediaPlayerService()
```

Preferred flyout key:

```text
mediaPlayer
```

Preferred IPC target:

```text
lacuna-media-player
```

## Plugin Directory Renames

Rename the current plugin directories:

```text
lacuna.youtube-music/       -> lacuna.media-player/
lacuna.youtube-music-video/ -> lacuna.media-player-video/
```

Update each renamed plugin's `manifest.json`:

```json
{
  "id": "lacuna.media-player",
  "name": "Lacuna Media Player",
  "description": "Experimental Lacuna service for media search, queue, and mpv playback."
}
```

```json
{
  "id": "lacuna.media-player-video",
  "name": "Lacuna Media Player Video",
  "description": "Wallpaper-layer video companion for Lacuna Media Player."
}
```

Update manifest relationships:

1. `lacuna.media-player` should recommend `lacuna.media-player-video`.
2. `lacuna.media-player-video` should recommend or resolve
   `lacuna.media-player`.
3. `lacuna.menu` should recommend `lacuna.media-player`.

## QML File Renames

Rename menu components:

```text
lacuna.menu/menu/YoutubeMusicTile.qml
  -> lacuna.menu/menu/MediaPlayerTile.qml

lacuna.menu/menu/FlyoutYoutubeMusicContent.qml
  -> lacuna.menu/menu/FlyoutMediaPlayerContent.qml
```

Update references in:

```text
lacuna.menu/menu/MenuWindow.qml
lacuna.menu/menu/MenuContent.qml
lacuna.menu/menu/MenuRail.qml
tests/test_qml_contracts.py
```

Public labels inside these files should say `Media` or `Media Player` unless
the control is specifically for YouTube account login or a YouTube URL.

## Service Naming

Rename broad service concepts:

```text
youtubeMusicService       -> mediaPlayerService
openYoutubeMusicPanel()   -> openMediaPlayerPanel()
resolveYoutubeMusicService() -> resolveMediaPlayerService()
openYoutubeMusicLogin()   -> openYoutubeLogin()
```

Keep provider-specific names where they describe YouTube behavior:

```text
youtubeProviderSettings()
youtubeConfigValue()
youtubeLoginEnabled
youtubeAuthDir
youtubeCookiesFile
youtubeConfigJson
isYoutubeUrl()
videoIdFromUrl()
```

The login button can call a generic media-player service method if that method
dispatches to provider-specific auth internally, but the provider setting should
remain `mediaProviders.youtube`.

## Script Renames

Rename scripts that belong to the generic player surface:

```text
youtube-music-check             -> media-player-check
youtube-music-control           -> media-player-control
youtube-music-search            -> media-player-search
youtube-music-info              -> media-player-info
youtube-music-preview           -> media-player-preview
youtube-music-background        -> media-player-background
youtube-music-refresh-favorites -> media-player-refresh-favorites
```

Rename provider-specific scripts by provider, not by player surface:

```text
youtube-music-auth            -> youtube-auth
youtube-music-jellyfin-search -> jellyfin-search
youtube-music-jellyfin-stream -> jellyfin-stream
```

Update `Service.qml` script path properties after the file renames.

## State And Runtime Paths

Rename the generic player state and runtime paths:

```text
~/.config/omarchy/lacuna/youtube-music.json
  -> ~/.config/omarchy/lacuna/media-player.json

$XDG_RUNTIME_DIR/lacuna-youtube-music
  -> $XDG_RUNTIME_DIR/lacuna-media-player
```

Keep provider-specific auth paths:

```text
~/.config/omarchy/lacuna/youtube/
mediaProviders.youtube
```

Add a one-time compatibility read path:

1. Prefer `media-player.json`.
2. If it does not exist and `youtube-music.json` exists, load the legacy file.
3. Save future writes to `media-player.json`.
4. Do not delete the legacy file automatically in the rename pass.

## Compatibility Strategy

Implement this as a compatibility-first rename.

First implementation pass:

1. Add the new plugin IDs and directory names.
2. Update menu and video companion lookups to the new service ID.
3. Keep legacy state import from `youtube-music.json`.
4. Consider a short-lived legacy IPC alias for `lacuna-youtube-music` if live
   scripts or debugging habits still depend on it.
5. Update tests to assert the new names while still covering the state migration.

Later cleanup pass:

1. Remove legacy QML function aliases once live configs no longer reference
   them.
2. Remove legacy IPC alias if it was added.
3. Remove tests that only exist for the temporary alias.
4. Leave provider-specific YouTube settings and auth names in place.

## User-Facing Label Rules

Use generic labels for the player:

```text
Media
Media Player
Search media
Favorites
Queue
Playback
Stream volume
Audio-only playback
```

Keep YouTube labels when the user action is specifically YouTube-bound:

```text
Paste a YouTube URL
Connect YouTube
YouTube login
YouTube cookies
YouTube Home
YouTube Home Music
```

Do not replace provider result source labels such as `YouTube`, `YouTube Home`,
`YouTube Home Music`, or `Jellyfin`.

## Documentation Updates

Update naming in:

```text
README.md
CHANGELOG.md
AGENTS.md
CLAUDE.md
docs/
docs/plugins/
docs/plans/lacuna-youtube-video-transition-plan.md
```

Keep existing YouTube-specific lifecycle guidance accurate, but rewrite it as
the media-player video companion with YouTube-backed video as the current
provider implementation.

## Test Updates

Update static tests and smoke tests:

```text
tests/test_manifest_contracts.py
tests/test_plugin_kind_contracts.py
tests/test_plugin_load_smoke.py
tests/test_qml_contracts.py
tests/test_status_scripts.py
```

Expected contract changes:

1. Plugin IDs become `lacuna.media-player` and `lacuna.media-player-video`.
2. QML component names become `MediaPlayerTile` and
   `FlyoutMediaPlayerContent`.
3. IPC target becomes `lacuna-media-player`.
4. Script paths use the new script file names.
5. State persistence test covers `media-player.json` and legacy import from
   `youtube-music.json`.
6. Provider tests continue to assert `mediaProviders.youtube`, YouTube URL
   handling, cookies, and YouTube source labels.

## Validation

Repository validation:

```bash
./scripts/check.sh
python3 -m pytest tests/test_qml_contracts.py tests/test_status_scripts.py -q
```

Live validation after implementation:

```bash
./scripts/dev deploy lacuna.media-player
./scripts/dev deploy lacuna.media-player-video
./scripts/dev deploy lacuna.menu
omarchy-shell shell listPlugins
omarchy-shell shell summon lacuna.menu "{}"
```

Manual checks:

1. The menu tile appears as Media or Media Player.
2. The flyout opens under the media-player flyout key.
3. Existing favorites and queue state survive from the old
   `youtube-music.json` state file.
4. YouTube login still uses the existing provider settings.
5. YouTube URL paste still works and remains labeled as YouTube-specific.
6. The background video companion follows the renamed media-player service.
