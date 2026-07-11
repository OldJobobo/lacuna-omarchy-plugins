# TASK: Fix slow/black-screen background-video transitions in Lacuna Media Player

Status: implemented; retained as the background-video lifecycle and validation record

Executable plan for an LLM or developer. Diagnosis was performed and measured on
2026-07-01; timing/format claims below were verified empirically — do not re-litigate them.

## REPO CONTEXT

- Repo: lacuna-omarchy-plugins (Omarchy/Quickshell plugins, QML + Python/shell scripts)
- Key files:
  - `lacuna.media-player/Service.qml` — playback service (state, yt-dlp resolution procs)
  - `lacuna.media-player/scripts/media-player-background` — resolves background stream URL (yt-dlp)
  - `lacuna.media-player/scripts/media-player-preview` — resolves preview stream URL (yt-dlp)
  - `lacuna.media-player-video/Overlay.qml` — desktop video wallpaper + black fade cover
  - `tests/test_qml_contracts.py` — string-contract tests that PIN the fade lifecycle; update deliberately, never delete the two-phase contract
- Contract that MUST survive (CLAUDE.md): startup = raise black cover first, assign video
  source behind black, fade in; shutdown = fade to black, clear source only when opaque,
  fade cover out. Never stop backgroundPlayer directly from wallpaperDesired changes.
- Verify with: `./scripts/check.sh` (runs json validation, qmllint, pytest; 185 tests currently pass)

## DIAGNOSED ROOT CAUSES

1. SERIALIZED LOAD: Overlay gates `activeSource` assignment behind the FULL 7000ms fade
   (`fadeInDuration`, Overlay.qml ~line 32; gate at `syncWallpaper()` ~lines 159-171).
   Media starts loading ~7.3s after the URL is already known (~3s resolve, measured 3.1s).
   Reveal is a fixed-timer 7000ms fade, not readiness-driven. Total: ~8s to first frames,
   ~15s to full brightness.
2. BLACK-FOREVER #1: resolve failure (`backgroundProc.onExited` exit!=0 or empty url in
   Service.qml) leaves `backgroundStreamUrl=""` → Overlay `waitingForHighRes` stays true →
   `holdFadeCover()` holds opaque cover indefinitely; `clearWallpaperNow()` refuses release
   while waitingForHighRes (Overlay.qml ~line 209). No retry, no give-up, no error surfaced.
   Systematic trigger: all yt-dlp calls use `player_client=web_embedded`; embed-restricted
   videos always fail on that client. No fallback client exists.
3. BLACK-FOREVER #2: Overlay `MediaPlayer` has NO onErrorOccurred, NO mediaStatus handling,
   NO watchdog. Expired/IP-bound googlevideo URLs fail silently (playbackState stays Stopped).
   Properties `restartAttempts`, `lastExitCode`, `backgroundReadyProbeAttempts`, `usingHighRes`
   and Overlay's `onPreviewStreamUrlChanged` hook are dead vestiges of the removed mpv design.
4. DUPLICATE WORK: the only progressive YouTube format today is itag 18 (360p); format 22 no
   longer exists (verified via `yt-dlp -F`). Preview script (`-f 18/best[height<=360]...`) and
   background script (`-f 22/18/best[height<=720]...`) resolve the SAME URL — two ~3s yt-dlp
   runs per track. No URL cache (URLs valid ~6h, IP-bound, `expire=` param in URL). No queue
   prefetch.

## IMPLEMENTATION TASKS (in order)

### T1. Overlay: decouple media loading from the fade (biggest win)

- On track switch (activeSource != videoSource), dip to black FAST: reuse
  `exitFadeToBlackDuration` (900ms) for the cover rise instead of the 7000ms `fadeInDuration`.
- Assign `activeSource` as soon as (new URL known) AND (cover opacity has reached opaque),
  NOT after a fixed 7s. Let the player buffer behind the opaque cover.
- Trigger cover reveal from player readiness (`mediaStatus === MediaPlayer.BufferedMedia` or
  playbackState playing), not a fixed timer. Keep a minimum-hold (e.g. 500ms) to avoid flicker.
- Keep long 7000ms fades ONLY for cold start (no video playing yet) and shutdown, preserving
  the documented two-phase contract.
- Keep distinct timing properties; do not collapse them (tests reference them).

### T2. Service: eliminate duplicate resolution + add cache + prefetch

- Add session cache in Service.qml: map videoId -> {url, resolvedAtMs}; TTL ~4h; consult in
  `resolveBackground()`/`resolvePreview()` before spawning procs; populate from proc results.
- When preview resolves first and the background format would be identical (itag 18 reality),
  satisfy `backgroundStreamUrl` from the preview result instead of a second yt-dlp run.
  (Alternative: single shared "resolve stream" path used by both.)
- Prefetch: after playback stabilizes (e.g. first successful position probe), pre-resolve the
  background URL of queue[0] into the cache.

### T3. Failure handling: kill both black-forever holes

- Scripts (`media-player-background`, `media-player-preview`): on failure with
  web_embedded, retry once WITHOUT `player_client=web_embedded` (default web client) before
  reporting error. Keep JSON output shape {url, error}.
- Service.qml `backgroundProc.onExited`: on final failure set a new property
  `backgroundResolveFailed: true` (cleared on next resolve/track) and put message in errorText.
- Overlay.qml: add give-up watchdog Timer (~12s): if cover held (waitingForHighRes OR
  activeSource assigned but player never left StoppedState/never buffered), release cover
  (fade out via exitFadeFromBlackDuration), clear activeSource, keep audio playing.
  Also react to `backgroundResolveFailed` from service.
- Overlay MediaPlayer: add `onErrorOccurred`: first occurrence → request one re-resolve from
  service (handles expired URLs; add e.g. `service.refreshBackgroundStream()`), second → give
  up gracefully (same path as watchdog). Wire the existing vestigial `restartAttempts`
  property into this, or remove it and its IPC status fields.

### T4. Cleanup

- Remove or wire in: `lastExitCode`, `backgroundReadyProbeAttempts`, `usingHighRes`,
  Overlay's dead `onPreviewStreamUrlChanged` connection.
- Simplify background format string to `18/best[ext=mp4][vcodec!=none][acodec!=none]`
  (720p progressive no longer exists). OPTIONAL follow-up (separate commit, needs manual
  testing): HLS via `player_client=ios` for >360p muxed playback in QtMultimedia.

## TEST REQUIREMENTS

- Update `tests/test_qml_contracts.py` string pins for every renamed/added function, property,
  and timing constant; keep asserting: startup fade gate exists, source assigned behind
  opaque cover, delayed exit clear, new watchdog + error handler exist.
- Add/extend script tests in `tests/test_status_scripts.py`: fallback-client retry emits the
  retried command (stub yt-dlp records argv), failure JSON shape unchanged.
- All existing 185 tests must pass: run `./scripts/check.sh`.

## DEPLOY NOTE

Repo changes are NOT live. Deploy with
`./scripts/dev deploy lacuna.media-player lacuna.media-player-video`
(restarts Omarchy shell). Do not claim fixed until deployed + verified via
`OMARCHY_PATH="$HOME/.local/share/omarchy" omarchy shell` IPC status
(`lacuna-media-player` and `lacuna-media-player-video` targets expose full state JSON).

## SUCCESS CRITERIA

- Track switch with background video: new video visible in ≤6s on normal network.
- Resolve failure or bad URL: cover releases within ~12s, audio continues, error surfaced
  in service errorText/IPC status — never an indefinite black screen.
- Replaying a cached track starts its video with no yt-dlp delay.
- Two-phase fade contract (behind-black source swaps, hidden teardown) still holds.
