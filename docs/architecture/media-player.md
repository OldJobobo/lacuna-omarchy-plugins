# Media Player Architecture

Status: current

Lacuna Media Player uses one authoritative, headless mpv instance for audio,
timing, transport, and queue progression. QML video surfaces are muted renderers
that follow mpv; they never become a second audio source.

## Runtime Components

- `lacuna.media-player/Service.qml` owns user-visible state, queue/history,
  provider merging, the smoothed playback clock, and presentation handoffs.
- `lacuna.media-player/scripts/media-player-worker` is a persistent JSONL
  worker. It keeps mpv JSON IPC connected, observes playback properties, runs
  provider searches concurrently, and resolves video candidates.
- `lacuna.menu/menu/MediaPlayerTile.qml` renders the inline video surface and
  reports availability, readiness, and failures to the service.
- `lacuna.media-player-video/Overlay.qml` renders the permanently mapped,
  content-gated background surface and owns its black-cover transitions.

The worker accepts `configure`, `play`, `command`, `search`, `resolve-video`,
`cancel`, and `shutdown`. It emits `ready`, `configured`, `playback`, provider
results, video candidates, command results, and scoped errors. Provider
credentials are loaded from the settings file and are not placed in worker or
mpv command arguments.

## Search

Editing the query only searches the 15-minute cache, favorites, history, and
queue. Submitting starts enabled providers concurrently. Each provider result
is published immediately and the ranked All view interleaves YouTube and
Jellyfin without waiting for the slower provider. Initial rendering is capped
at 18 rows and can expand to the configured maximum of 36 by default.

Explicit YouTube searches use public flat-playlist results without loading
browser cookies. Authentication remains scoped to personalized home
suggestions and playback, avoiding cookie startup cost on every cold query.

## Playback Clock

The worker samples mpv over its persistent IPC connection. The service
interpolates the latest sample every 100ms while playing. Muted QML surfaces
use this clock with three correction bands:

- below 400ms: play at normal rate;
- 400ms through 1500ms: correct at `0.97` or `1.03` playback rate;
- above 1500ms: seek, with a 1500ms hard-seek cooldown.

Two failed background seek corrections move an adaptive stream to the stable
progressive candidate. A terminal renderer failure falls back inline until a
new track, explicit presentation choice, or manual stream refresh retries it.

## Presentation

`presentationMode` is `inline`, `background`, or `auto`. Auto uses inline video
while an inline surface is available and promotes to the background otherwise.
The service transitions through `promoting`, `background`, `demoting`, and
`recovering`; the old surface remains alive until the destination reports
ready. Handoffs time out after five seconds.

Background source changes raise the black cover for 300ms, hold for 150ms,
then reveal over 750ms. Exit uses 350ms to black and 600ms back to the Lacuna
frame. Reduced motion uses 75ms transitions. The background layer remains
mapped to preserve layer-shell ordering and gates only its in-window paint.

Adaptive quality prefers a 720p-capable HLS candidate. A stable progressive
360p candidate is retained for readiness timeout, playback error, or repeated
drift failure.
