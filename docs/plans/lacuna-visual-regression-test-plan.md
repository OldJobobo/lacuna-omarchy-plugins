# TASK: Close the visual/UI regression test gaps

Status: executed

Executable plan for an LLM or developer. Gap analysis performed 2026-07-02
against the real regressions that shipped that week; do not re-derive it.

## WHY THE CURRENT SUITE MISSES VISUAL REGRESSIONS

Current coverage (189 tests): `test_qml_contracts.py` pins source *text*;
script/installer tests exercise Python/shell behavior; the two load-smoke
suites verify imports resolve and QML *compiles*; `test_live_behavior.py`
createObjects exactly one non-visual service (`lacuna.state`).

Nothing executes QML behavior, computes geometry, or looks at pixels. Every
recent visual regression lived in exactly those blind spots:

- fade cover stacked under the video window (map-order stacking) — invisible
  to text pins, compile checks, and script tests;
- frame painted over the bar/sidebar on mode toggle — same;
- bar shadow missing/misaligned in both frame modes — same;
- sidebar preview suppression race, black-screen-forever watchdog holes —
  runtime state-machine bugs in QML that no test executes.

String pins freeze today's code text; they cannot catch a bug whose code
"looks right". The gaps below add the three missing layers. Build them in
tier order — each tier is independently shippable.

## T1. Runtime QML behavior harness + state-machine tests (highest value)

Generalize the harness in `tests/test_live_behavior.py` into
`tests/qml_harness.py`: run quickshell with a generated ShellRoot that
createObjects a target QML file, injects a stub service/bar (plain QtObject
with the properties/signals the target reads), drives scripted property
changes on a timer, and prints `BEHAVE <json>` lines the test asserts on.
Skip without quickshell + Wayland session (existing pattern).

Targets and the regressions they would have caught:

1. `lacuna.menu/services/PanelController.qml` (plain Item, fully headless):
   open/close/toggle menu and flyout sequences; assert state names,
   progress endpoints, revision-guarded completion (no stuck
   `openingMenu`/`closingFlyout` states after rapid toggles).
2. `lacuna.menu/menu/YoutubeMusicTile.qml` preview state machine (stub
   service; MediaPlayer never gets a real URL): desktop→sidebar handoff must
   clear `previewSuppressed`, re-seek, and never suppress while
   `previewPositionPending`/settling; drift strikes reach suppression only
   after repeated misses. (Would have caught the suppression race.)
3. `lacuna.youtube-music-video/Overlay.qml` choreography (stub service;
   `activeSource` kept empty or file:// stub so windows stay transparent):
   assert ordering — cover opaque BEFORE `activeSource` assigned on switch;
   reveal only after player-ready or watchdog; `waitingForHighRes` +
   resolve-failure releases the cover (no black-forever); exit clears source
   only under opaque cover. (Would have caught pop-in and black-forever.)
4. `lacuna.youtube-music/Service.qml` beyond load: track-end probe payloads
   drive `handlePlaybackEnded` (feed fake `probe` JSON via a stub
   controlScript on PATH), stale `playbackSessionRevision` results discarded.

Constraint: never assert wall-clock durations (7000ms fades); assert state
*ordering* and gating conditions. Timers may be shortened by setting the
timing properties on the object under test.

## T2. Geometry math tests (cheap, deterministic)

Same harness, `createObject` with `visible: false` — property math needs no
mapped window:

1. `lacuna.bar/LacunaFrameWindow.qml`: matrix over barPosition ×
   barSize × thickness × radius × sidebar occlusion — assert `hole*`,
   `outer*` (never under the bar), and `casterHole*` (collapses to bar edge
   when inactive; equals paint hole when active). (Would have caught the
   missing shadow caster.)
2. `lacuna.bar/Bar.qml` `lacunaFrameContentRect(screen)` with fake screen
   objects: framed/unframed rects, bleed, inner rect, sidebar occlusion —
   the video wallpaper's placement depends entirely on this.
3. `lacuna.menu/menu/LacunaFrameBorderWindow.qml`: border path endpoints and
   attachment-gap math (gap only when flyout attached and renderable).
4. Flyout anchor clamps in `lacuna.notifications/NotificationsFlyout.qml`
   and `lacuna.claude-usage` (popup x clamped to window, join geometry).

## T3. Live desktop probes (opt-in; encode the manual verification already proven)

New `tests/test_live_visual.py`, skipped unless quickshell + Wayland + grim +
magick + hyprctl AND `LACUNA_LIVE_VISUAL=1` (they read the user's real
screen). Each probe is a pixel-relationship assertion, robust to theme
changes — never golden-image diffs:

1. Layer order: `hyprctl layers` shows `lacuna-bar-frame` and
   `lacuna-bar-frame-border` mapped with frame mode off; toggling
   `frame.mode` off↔fullframe leaves the layer list byte-identical.
2. Bar shadow: sample a mid-span column; rows 0-3 below the bar are darker
   than rows 15-20 (shadow present, flush, fading) in BOTH frame modes; bar
   rows themselves identical before/after toggling (nothing draws over the
   bar).
3. Frame paint: with fullframe on, rail-region pixels differ from wallpaper;
   with frame off they match wallpaper (no stray paint).
4. Restore all toggled settings in `finally` blocks; preserve unknown keys
   (reuse the settings read-modify-write already used in dev verification).

## T4. Enforcement glue

1. `./scripts/check.sh`: T1/T2 run whenever quickshell + session exist; T3
   only with `LACUNA_LIVE_VISUAL=1`.
2. `AGENTS.md` testing section: a UI behavior fix is not protected by string
   pins alone — add or extend a T1/T2 behavior test in the same change.
3. Keep the existing string-pin suites; they remain the cheap first line.

## FILES TO CREATE

- `tests/qml_harness.py` (T1/T2 shared runner + stub-service builders)
- `tests/test_qml_behavior_panels.py` (T1 items 1-2)
- `tests/test_qml_behavior_video.py` (T1 items 3-4)
- `tests/test_qml_geometry.py` (T2)
- `tests/test_live_visual.py` (T3)

## SUCCESS CRITERIA

- Each of the four shipped regressions above, if reintroduced, fails at
  least one new test (re-verify by temporarily reverting each fix locally).
- Full suite still passes headless/CI (all new suites skip cleanly without
  quickshell/session/tools).
- No test depends on theme colors, wallpaper content, or absolute durations.
