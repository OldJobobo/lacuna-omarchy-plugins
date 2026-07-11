# Lacuna Media Player Rebrand Plan

Status: implemented; retained as the compatibility and validation record

## Goal

Rename the current YouTube Music surface into a generic Lacuna media player
without changing playback, search, queue, favorites, background-video, YouTube
auth, or Jellyfin behavior.

This is a compatibility-first rename. `Media Player` is the Lacuna surface name;
`YouTube`, `Jellyfin`, and future provider names remain visible wherever they
describe provider-specific auth, URLs, cookies, source labels, scripts, settings,
errors, or status text.

## Canonical Contracts

Public names:

```text
Lacuna Media Player
Lacuna Media Player Video
```

Plugin IDs and directories:

```text
lacuna.youtube-music/       -> lacuna.media-player/
lacuna.youtube-music-video/ -> lacuna.media-player-video/
```

IPC targets:

```text
lacuna-media-player
lacuna-media-player-video
```

Layer-shell namespace:

```text
lacuna-media-player-video
```

Menu flyout key:

```text
mediaPlayer
```

QML naming:

```text
mediaPlayerService
mediaPlayerOpen
mediaPlayerVisible
mediaPlayerWidth
mediaPlayerContent
openMediaPlayerPanel()
resolveMediaPlayerService()
```

Menu component renames:

```text
lacuna.menu/menu/YoutubeMusicTile.qml
  -> lacuna.menu/menu/MediaPlayerTile.qml

lacuna.menu/menu/FlyoutYoutubeMusicContent.qml
  -> lacuna.menu/menu/FlyoutMediaPlayerContent.qml
```

Do not keep `lacuna.youtube-music/` or `lacuna.youtube-music-video/` as checked-in
shim plugin directories. The old plugin IDs are replaced by the new plugin IDs;
compatibility is handled by state import and temporary IPC aliases.

## Implementation Changes

### Plugin Manifests

Update `lacuna.media-player/manifest.json`:

```json
{
  "id": "lacuna.media-player",
  "name": "Lacuna Media Player",
  "description": "Experimental Lacuna service for media search, queue, and mpv playback."
}
```

Keep `kinds`, `activation`, `keepLoaded`, `entryPoints`, defaults, schema, and
experimental standalone metadata equivalent to the current service plugin.
Replace its recommendation for `lacuna.youtube-music-video` with
`lacuna.media-player-video`; keep existing recommendations for `lacuna.menu` and
`lacuna.audio`.

Update `lacuna.media-player-video/manifest.json`:

```json
{
  "id": "lacuna.media-player-video",
  "name": "Lacuna Media Player Video",
  "description": "Wallpaper-layer video companion for Lacuna Media Player."
}
```

Keep the overlay entry point and `targetOutput` default. Recommend
`lacuna.media-player`.

Update `lacuna.menu/manifest.json` so `lacuna.menu` recommends
`lacuna.media-player` instead of `lacuna.youtube-music`.

### Service QML

Rename generic player concepts in `lacuna.media-player/Service.qml`:

```text
checkScript              -> scripts/media-player-check
searchScript             -> scripts/media-player-search
infoScript               -> scripts/media-player-info
refreshFavoritesScript   -> scripts/media-player-refresh-favorites
controlScript            -> scripts/media-player-control
previewScript            -> scripts/media-player-preview
backgroundScript         -> scripts/media-player-background
runtimeDir               -> $XDG_RUNTIME_DIR/lacuna-media-player
stateFile                -> ~/.config/omarchy/lacuna/media-player.json
IpcHandler.target        -> lacuna-media-player
```

Keep provider-specific names where they describe provider behavior:

```text
youtubeProviderSettings()
youtubeConfigValue()
youtubeLoginEnabled
youtubeAuthDir
youtubeCookiesFile
youtubeConfigJson
isYoutubeUrl()
normalizeYoutubeUrl()
videoIdFromUrl()
startYoutubeSuggestions()
refreshYoutubeResultsAfterLogin()
jellyfinProviderSettings()
jellyfinConfigValue()
jellyfinSearchScript
jellyfinStreamScript
```

Rename the login method exposed to generic UI from `openYoutubeMusicLogin()` to
`openYoutubeLogin()`, and keep `openYoutubeMusicLogin()` only as a temporary
alias that calls `openYoutubeLogin()`.

Add two IPC handlers during the transition:

1. Canonical handler target `lacuna-media-player`.
2. Legacy handler target `lacuna-youtube-music` exposing the same methods and
   status payload.

The legacy IPC handler is a temporary compatibility shim and should be removed in
the later cleanup pass after live scripts and debugging habits have moved.

### State And Runtime Paths

Use the new state path:

```text
~/.config/omarchy/lacuna/media-player.json
```

Keep provider auth paths unchanged:

```text
~/.config/omarchy/lacuna/youtube/
mediaProviders.youtube
```

State load behavior:

1. Prefer `media-player.json` when it exists.
2. If `media-player.json` is absent and `youtube-music.json` exists, load the
   legacy file.
3. After legacy import, save future writes only to `media-player.json`.
4. Do not delete `youtube-music.json` automatically.

Implementation detail: `FileView.path` must point at the canonical new state
file. Legacy import should be a separate one-time read path, not a permanent
watch on the old file.

Use the new runtime directory:

```text
$XDG_RUNTIME_DIR/lacuna-media-player
```

Do not migrate or reuse the old mpv socket path. A running old instance should be
stopped by normal shell/plugin restart during deploy.

### Scripts

Rename generic player scripts:

```text
youtube-music-check             -> media-player-check
youtube-music-control           -> media-player-control
youtube-music-search            -> media-player-search
youtube-music-info              -> media-player-info
youtube-music-preview           -> media-player-preview
youtube-music-background        -> media-player-background
youtube-music-refresh-favorites -> media-player-refresh-favorites
```

Rename provider-specific scripts by provider, not by the old surface name:

```text
youtube-music-auth            -> youtube-auth
youtube-music-jellyfin-search -> jellyfin-search
youtube-music-jellyfin-stream -> jellyfin-stream
```

Keep Python module/function names that are genuinely provider-specific, such as
`youtube_home_results`, `filtered_home_music_rows`, YouTube auth helpers, and
Jellyfin request helpers. Update CLI usage strings so generic commands say
`media-player-*` and provider commands say `youtube-*` or `jellyfin-*`.

### Menu And Flyout QML

Rename broad menu concepts:

```text
youtubeMusicService       -> mediaPlayerService
youtubeMusicOpen          -> mediaPlayerOpen
youtubeMusicVisible       -> mediaPlayerVisible
youtubeMusicWidth         -> mediaPlayerWidth
youtubeMusicContent       -> mediaPlayerContent
youtubeMusicRequested     -> mediaPlayerRequested
youtubeMusicReserveHeight -> mediaPlayerReserveHeight
openYoutubeMusicPanel()   -> openMediaPlayerPanel()
resolveYoutubeMusicService() -> resolveMediaPlayerService()
```

Resolve the canonical service ID:

```qml
root.shell.ensureService("lacuna.media-player")
root.shell.serviceFor("lacuna.media-player")
```

Do not fall back to `lacuna.youtube-music` in normal service resolution. Old
plugin IDs are not part of the supported post-rename live graph.

Use `panelController.openFlyout("mediaPlayer")` and
`panelController.closeFlyout("mediaPlayer")`. Keep no `youtubeMusic` flyout key
unless a later cleanup task discovers a specific live config dependency.

Update `MenuContent.qml`, `MenuRail.qml`, and `MenuWindow.qml` to pass
`mediaPlayerService` into `MediaPlayerTile` and `FlyoutMediaPlayerContent`.
Rail/tooltips should use `Media Player` when there is no current track title.

### Video Companion

In `lacuna.media-player-video/Overlay.qml`:

```text
ensureService("lacuna.media-player")
serviceFor("lacuna.media-player")
WlrLayershell.namespace: "lacuna-media-player-video"
IpcHandler.target: "lacuna-media-player-video"
```

Add a temporary legacy IPC handler target `lacuna-youtube-music-video` with the
same status payload as the canonical handler.

Preserve the existing two-phase background video lifecycle:

1. Raise the black cover before assigning a new active source.
2. Keep the last active source alive while the cover fades to black on exit.
3. Clear the source only after the cover is opaque.
4. Keep the fade cover inside the video window above `VideoOutput`.
5. Keep the layer assignment at `WlrLayer.Background`.

Do not change fade timings, source resolution behavior, watchdog behavior, or
player controls as part of the rebrand.

### Settings Services

Keep `mediaProviders.youtube` and `mediaProviders.jellyfin` as the settings
schema. Keep the existing legacy normalization of `mediaProviders.youtubeMusic`
into `mediaProviders.youtube` in both `lacuna.state/Service.qml` and
`lacuna.menu/services/LacunaSettings.qml`.

Do not introduce `mediaProviders.mediaPlayer`; the player is the surface, not a
provider.

## Compatibility And Cleanup

First implementation pass:

1. Rename directories, manifests, QML components, scripts, IDs, IPC targets,
   runtime dir, state path, docs, and tests.
2. Add legacy state import from `youtube-music.json`.
3. Add legacy IPC aliases for `lacuna-youtube-music` and
   `lacuna-youtube-music-video`.
4. Keep temporary QML function aliases only where needed to preserve existing
   internal call sites during the rename.
5. Update tests to assert new names and temporary aliases.

Later cleanup pass:

1. Remove `openYoutubeMusicLogin()` after all UI/tests use `openYoutubeLogin()`.
2. Remove legacy IPC aliases.
3. Remove tests that only assert temporary legacy IPC compatibility.
4. Keep provider-specific YouTube and Jellyfin names permanently.

## Label Rules

Use generic labels for the player surface:

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

Keep YouTube labels when the user action or data is YouTube-bound:

```text
Paste a YouTube URL
Connect YouTube
YouTube login
YouTube cookies
YouTube Home
YouTube Home Music
```

Keep provider result source labels:

```text
YouTube
YouTube Home
YouTube Home Music
Jellyfin
```

Keep provider-specific error text when it names the failing provider, for
example `yt-dlp is not installed`, `Paste a YouTube URL`, and Jellyfin
connection/search errors.

## Source Inventory

Update at least these source areas:

```text
lacuna.youtube-music/ -> lacuna.media-player/
lacuna.youtube-music-video/ -> lacuna.media-player-video/
lacuna.media-player/Service.qml
lacuna.media-player/scripts/*
lacuna.media-player-video/Overlay.qml
lacuna.menu/manifest.json
lacuna.menu/menu/MenuWindow.qml
lacuna.menu/menu/MenuContent.qml
lacuna.menu/menu/MenuRail.qml
lacuna.menu/menu/YoutubeMusicTile.qml -> MediaPlayerTile.qml
lacuna.menu/menu/FlyoutYoutubeMusicContent.qml -> FlyoutMediaPlayerContent.qml
lacuna.state/Service.qml
lacuna.menu/services/LacunaSettings.qml
```

Update docs:

```text
README.md
CHANGELOG.md
AGENTS.md
CLAUDE.md
docs/
docs/plugins/
docs/architecture/layer-stacking.md
docs/plans/lacuna-youtube-video-transition-plan.md
docs/plans/lacuna-visual-regression-test-plan.md
```

The transition-plan docs may still explain YouTube-backed implementation
details, but their top-level subject should become the media-player video
companion.

## Test Updates

Update static contract tests:

```text
tests/test_manifest_contracts.py
tests/test_plugin_kind_contracts.py
tests/test_plugin_load_smoke.py
tests/test_qml_contracts.py
```

Expected contract changes:

1. Standalone plugin IDs become `lacuna.media-player` and
   `lacuna.media-player-video`.
2. Layer policy references `lacuna.media-player-video/Overlay.qml`.
3. The video layer namespace becomes `lacuna-media-player-video`.
4. Canonical IPC targets are `lacuna-media-player` and
   `lacuna-media-player-video`.
5. Temporary legacy IPC targets remain asserted until cleanup.
6. Menu component names become `MediaPlayerTile` and
   `FlyoutMediaPlayerContent`.
7. Menu service lookup uses `lacuna.media-player`.
8. Manifest recommendations use the new plugin IDs.

Update behavior tests:

```text
tests/test_qml_behavior_video.py
tests/test_qml_behavior_panels.py
```

Expected behavior changes:

1. Runtime QML tests load `lacuna.media-player/Service.qml`.
2. Stub script names use the new script filenames.
3. Panel/tile tests load `MediaPlayerTile.qml`.
4. Existing playback probe, EOF, background-video, and preview-suppression
   behavior remains unchanged.

Update script tests:

```text
tests/test_status_scripts.py
```

Expected script-test changes:

1. Test class/file constants point at `lacuna.media-player/scripts/media-player-*`.
2. Provider script constants point at `youtube-auth`, `jellyfin-search`, and
   `jellyfin-stream`.
3. State tests use `media-player.json` for canonical writes and a separate
   legacy-import test for `youtube-music.json`.
4. Provider assertions still check YouTube URL handling, cookies, source labels,
   Jellyfin results, and YouTube Home/Home Music behavior.

Add or extend an allowlist check for old terms after implementation. The check
should fail unexpected occurrences of:

```text
YoutubeMusic
youtubeMusic
youtube-music
lacuna.youtube-music
lacuna-youtube-music
YouTube Music
```

Allowed occurrences must be provider-specific, legacy compatibility assertions,
or historical docs explicitly marked as legacy.

## Validation

Repository validation:

```bash
./scripts/check.sh
python3 -m pytest tests/test_qml_contracts.py tests/test_qml_behavior_video.py tests/test_qml_behavior_panels.py tests/test_status_scripts.py -q
rg -n --glob '!graphify-out/**' 'YoutubeMusic|youtubeMusic|youtube-music|lacuna\.youtube-music|lacuna-youtube-music|YouTube Music' .
```

The final `rg` command is an audit, not automatically a failure. Every hit must
be either provider-specific, a temporary legacy alias/test, or historical docs
marked as legacy.

Live validation after implementation:

```bash
./scripts/dev deploy lacuna.media-player
./scripts/dev deploy lacuna.media-player-video
./scripts/dev deploy lacuna.menu
omarchy-shell shell listPlugins
omarchy-shell shell summon lacuna.menu "{}"
```

Manual checks:

1. `listPlugins` shows `lacuna.media-player` and `lacuna.media-player-video`.
2. The menu tile appears as `Media` or `Media Player`.
3. The rail fallback tooltip says `Media Player` when no track title is active.
4. The flyout opens under the `mediaPlayer` key.
5. Existing favorites and queue state import from `youtube-music.json` when no
   `media-player.json` exists.
6. Future state writes go to `media-player.json`.
7. YouTube login still uses `mediaProviders.youtube` and the existing auth dir.
8. YouTube URL paste still works and remains YouTube-labeled.
9. Jellyfin search and stream playback still work when Jellyfin is configured.
10. The background video companion follows the renamed media-player service and
    preserves the black-cover transition behavior.
11. Canonical IPC targets answer `status`; legacy IPC targets still answer
    during the compatibility pass.

Live install cleanup:

1. Deploy and verify the new plugin directories first.
2. Check `~/.config/omarchy/plugins/` for stale `lacuna.youtube-music` and
   `lacuna.youtube-music-video` installs.
3. Move stale old install directories aside only after the new deployed copies
   are verified and `listPlugins` shows the new IDs.
4. Restart Omarchy shell after stale old installs are moved aside, then rerun
   `listPlugins`.

## Out Of Scope

Do not change:

```text
Playback controls
mpv command behavior
yt-dlp extraction behavior
Search ranking/filter behavior
Queue/history/favorites schema beyond state-file migration
Background-video fade timing or lifecycle
Provider settings schema
YouTube auth directory
Jellyfin API behavior
Audio volume model
MPRIS widget behavior
```
