# TASK: Streamline the desktop ambience animation pipeline to cinematic quality

Status: fully reverted — T1/T2 optimizations and the T3/T4 ambience-host consolidation are all rolled back to the item-based standalone overlays (see 2026-07-02 and 2026-07-05 logs)

Executable plan for an LLM or developer. Findings were measured against the
actual overlay sources on 2026-07-02; do not re-derive them.

## SCOPE

The desktop background/foreground animation plugins: `lacuna.dust-motes-overlay`,
`lacuna.film-grain-overlay`, `lacuna.crt-overlay`, `lacuna.vhs-overlay`,
`lacuna.rainfall-overlay`, `lacuna.aurora-drift`, `lacuna.god-rays-overlay`,
`lacuna.cinematic-light-overlay`, `lacuna.background-vignette` (and the shared
patterns they vendor). Symptoms: stutter on first load/enable; intermittent
lag during steady state despite idle CPU/GPU.

## DIAGNOSED ROOT CAUSES (verified in source)

1. **CPU item-soup rendering.** Every effect is a Repeater of QML Rectangles:
   dust motes 72-180 items x 3 infinite SequentialAnimations each; film grain
   up to 520 items re-randomized by a 28-88ms Timer; CRT scanlines
   ~height/spacing items plus 34+90+more; god rays rayCount x 3 infinite
   animations + 0.7x rayCount secondary. Multiply by monitors (3 here):
   thousands of scene-graph nodes and 1000+ concurrent animations. There is
   no ShaderEffect, no ParticleSystem, and no FrameAnimation anywhere.
2. **Main-thread JS frame loops on wall-clock Timers.** 33ms/58ms/28ms Timers
   run physics/randomization in JS (`itemAt(i)` loops, per-mote math). 30Hz
   timers beat against the 60Hz render loop (judder), and they share the ONE
   QML thread with the whole shell — any bar/menu/service work (1s playback
   probes, FileView reloads, JSON parses) steals animation frames. This is
   the "lags despite plentiful resources" cause: it is thread contention,
   not resource exhaustion.
3. **Subprocess polling.** Dust motes forks `hyprctl cursorpos` up to 8x/sec
   per plugin for mouse reactivity — fork/exec jitter on the same thread.
4. **Delegate churn + GC.** Transient particles are ListModel rows appended/
   removed continuously; each spawns/destroys a Rectangle delegate ->
   allocation pressure -> GC pauses.
5. **First-load hitch.** Enabling an effect maps windows AND synchronously
   instantiates hundreds of delegates and starts all animations in a single
   frame, per monitor. Nothing is staggered, pooled, or pre-warmed.
6. **Compositor damage amplification.** Each effect is its own fullscreen
   alpha layer per monitor (4 layers x 3 monitors observed live). Every
   animated frame damages the full surface of every layer, forcing Hyprland
   to recomposite everything continuously.
7. **Duplicated watchers.** Each of the 9 overlay plugins runs its own 3
   FileViews (settings/colors/theme) + JSON parsing.

## IMPLEMENTATION TIERS (each independently shippable, in order)

### T0. Measurement baseline (do first; re-run after every tier)

Record with effects enabled/disabled: quickshell CPU (`pidstat -p <pid> 1 10`),
frame pacing (`QSG_RENDER_TIMING=1` on a dev shell instance), and a stopwatch
of enable-to-smooth time. Success budgets: <3% CPU per active effect per
monitor, no frame >20ms during steady state, enable hitch <1 frame.

### T1. Structural wins without rewrites

1. Replace every frame-driving Timer (33/58/28ms loops) with `FrameAnimation`
   using `frameTime`-based deltas — vsync-aligned, no beat frequency, auto-
   pauses when the window is not rendered.
2. Kill subprocess cursor polling: one shared query over Hyprland's IPC unix
   socket via Quickshell `Socket` (request `j/cursorpos`), owned by a single
   service and read by all overlays; poll only while the cursor moves
   (decay-gated), never fork.
3. Replace ListModel transient particles with a fixed pre-allocated pool
   (create max items once, recycle via visible/opacity; zero churn, zero GC).
4. Stagger enable: ramp Repeater model counts over ~10 frames and fade the
   layer in; start looping animations with per-item randomized delays instead
   of all in frame one.
5. Gate everything hard: `running`/`visible` must be false whenever the
   effect is hidden, intensity is 0, or the output is fully covered by a
   fullscreen window (subscribe to Hyprland socket2 fullscreen events).

### T2. GPU migration (the cinematic fix)

1. Port per-pixel effects to a single fullscreen `ShaderEffect` each, with
   one time uniform driven by FrameAnimation: film-grain, crt, vhs,
   background-vignette, aurora-drift, god-rays, cinematic-light. One scene
   node replaces hundreds; per-frame CPU work becomes one uniform write.
   Precompile shaders with `qsb` and ship `.qsb` files in each plugin
   (eliminates first-use shader-compile hitch); add compilation to
   `./scripts/check.sh`.
2. Port particle effects (dust-motes, rainfall) to `QtQuick.Particles`
   (`ParticleSystem` + `ImageParticle`, GPU-batched single node); cursor wind
   becomes an `Affector`. RISK: verify QtQuick.Particles imports under
   Quickshell first; fallback is a point-sprite ShaderEffect with a particle
   state texture.
3. Define visual parity per effect before porting (screenshot A/B at fixed
   settings); tune until indistinguishable or better.

### T3. Architectural consolidation

1. One ambience host surface per monitor: a single always-mapped Bottom-layer
   window (plus an optional Overlay-layer twin for `foregroundOverlay`
   effects) that composites all active effects as child ShaderEffects/
   particle systems. Hyprland then composites 1 alpha layer instead of N.
   Follow `docs/architecture/layer-stacking.md` and update its policy table +
   `test_layer_stacking_policy` deliberately.
2. One shared ambience settings/theme service (single FileView set + parse,
   published to effects) replacing 9x3 watchers.
3. Keep per-effect plugins as thin manifests/settings surfaces so install
   granularity and `barWidget.schema` settings do not change for users.

### T4. Regression protection

1. Contract test: ban wall-clock frame loops in ambience plugins (no
   `Timer` with interval <100ms in `lacuna.*-overlay/`), require
   FrameAnimation-driven updates, require `.qsb` files referenced by
   ShaderEffects to exist on disk.
2. Perf smoke (opt-in, live): sample quickshell CPU with each effect toggled
   on for 10s; fail above budget. Pair with the pixel-probe harness from
   `lacuna-visual-regression-test-plan.md` T3 for visual parity.

## CONSTRAINTS

- Plugins stay self-contained (vendored shaders per plugin; canonical copies
  under `shared/` + sync-vendored pairs if duplicated).
- Never regress the layer-stacking policy; ambience host changes update the
  policy table and doc in the same change.
- Settings schemas (`barWidget.schema`, lacuna settings keys) are public
  contracts — visual internals may change, keys may not.
- Test with all three monitors; they differ in resolution and orientation.

## SUCCESS CRITERIA

- Enable/disable of any effect: no visible hitch (<1 dropped frame).
- All effects enabled on 3 monitors: quickshell CPU under ~10% total, no
  perceptible judder during simultaneous shell activity (menu open, track
  change, settings write).
- Motion is vsync-smooth ("cinematic"): no 30Hz beat, no GC stutter, no
  subprocess jitter.
- T0 measurements re-run and recorded in this file per tier.

## EXECUTION LOG

### 2026-07-02 T1 structural pass

- Replaced wall-clock frame-driving Timers with `FrameAnimation` in
  `lacuna.dust-motes-overlay`, `lacuna.film-grain-overlay`,
  `lacuna.crt-overlay`, and `lacuna.vhs-overlay`.
- Removed dust-mote `hyprctl cursorpos` subprocess polling. Cursor reactivity
  now requests `j/cursorpos` through Quickshell's `Socket` and Hyprland's
  `requestSocketPath`.
- Replaced dust transient mote `ListModel` append/remove churn with a fixed
  preallocated Repeater pool. Expired motes are hidden and reused.
- Added a contract test banning `Timer {` from the ambience overlay set and
  requiring `FrameAnimation` in the currently frame-driven overlays.
- Validation: `python3 -m pytest tests/test_qml_contracts.py -q` passed.
  `./scripts/check.sh` passed with `200 passed, 2 skipped`.
- Live deploy: `./scripts/dev deploy` verified installed copies for
  `lacuna.dust-motes-overlay`, `lacuna.film-grain-overlay`,
  `lacuna.crt-overlay`, and `lacuna.vhs-overlay`.
- Runtime smoke: `omarchy-shell <plugin-id> status` returned JSON for all four
  changed overlays after shell restart. Dust was visible under current
  settings; film grain, CRT, and VHS were loaded but not visible because the
  active Lacuna background selection did not include them.
- Measurement limitation: `pidstat` was not installed, and QSG frame timing was
  not captured from a separate dev shell instance in this pass. `top` sampling
  of the running Omarchy shell process (`quickshell -n -p /usr/share/omarchy/shell`)
  still showed roughly 75-85% CPU with the current active ambience stack, so
  the full success budget is not met yet. Continue with T2/T3 GPU/layer
  consolidation before treating this plan as complete.

### 2026-07-02 T2 GPU migration slice

- Added precompiled shader assets for `lacuna.film-grain-overlay` and
  `lacuna.background-vignette`. Source `.frag` files live beside the baked
  `.frag.qsb` packs under each plugin's `shaders/` directory.
- Ported film grain from a fullscreen Repeater of grain rectangles to one
  fullscreen `ShaderEffect` with a `FrameAnimation` time uniform.
- Ported background vignette from a stretched SVG image to one clipped
  fullscreen `ShaderEffect`, keeping the existing frame-rect/radius clipping
  contract.
- Added `qsb` validation to `./scripts/check.sh`: every checked-in
  `lacuna.*/shaders/*.frag` must have a matching baked `.qsb`, and the baked
  pack must compare cleanly against a fresh `qsb --qt6 -O` build.
- Ported rainfall's actual falling drop fields from three animated Rectangle
  Repeater groups to one `QtQuick.Particles` `ParticleSystem` with shared
  `ImageParticle`, three emitters, and a small plugin-local `assets/raindrop.svg`
  sprite. Mist, splash, and vignette support geometry remain item-based.
- Added tests requiring shader `.qsb` references to exist, requiring the new
  film/vignette shader paths, and requiring rainfall's particle system import
  and raindrop asset.
- Validation: `python3 -m pytest tests/test_qml_contracts.py tests/test_live_load_smoke.py -q`
  passed. `./scripts/check.sh` passed with `206 passed, 2 skipped`.
- Live deploy: `./scripts/dev deploy` verified installed copies for
  `lacuna.film-grain-overlay`, `lacuna.background-vignette`, and
  `lacuna.rainfall-overlay`.
- Runtime smoke: `omarchy-shell <plugin-id> status` returned JSON for all three
  changed overlays after shell restart. Background vignette was visible under
  current settings; film grain and rainfall were loaded but not visible because
  the current active background effects did not include them. Recent quickshell
  logs showed no shader/qsb/particle errors.
- Completion update: `lacuna.ambience-host` now provides hosted GPU/particle
  render paths for the rest of the ambience set. Aurora drift, god rays,
  cinematic light, CRT, and VHS render through a shared baked
  `ambience_effect.frag.qsb` ShaderEffect path in the host. Dust motes render
  through a hosted `QtQuick.Particles` path with a plugin-local dust sprite.
  The standalone plugins keep their legacy renderers only as host-disabled
  fallbacks.

### 2026-07-02 T3 architectural consolidation slice

- Added `lacuna.ambience-host`, a persistent overlay plugin that consolidates
  every Lacuna ambience effect into shared host surfaces.
- The host maps three explicit surfaces: `lacuna-ambience-host-background`
  for vignette ignore-animations mode, `lacuna-ambience-host-bottom` for
  normal below-window ambience, and `lacuna-ambience-host-overlay` for
  foreground-overlay film/rain mode.
- Reused the T2 GPU/particle assets inside the host: film grain and vignette
  render as `ShaderEffect`s with baked `.qsb` shaders; rainfall renders with
  `QtQuick.Particles` and the shared raindrop sprite. Added a shared hosted
  ambience shader for aurora drift, god rays, cinematic light, CRT, and VHS,
  plus a hosted particle dust path.
- Kept the per-effect plugins as public settings/install surfaces. When
  `lacuna.ambience-host` is enabled in shell config, all standalone ambience
  windows report `hostedByAmbienceHost` and suppress their own painting.
- Updated the native-replacements example config to load the host before the
  migrated standalone ambience plugins.
- Updated `docs/architecture/layer-stacking.md`,
  `test_layer_stacking_policy`, and overlay-kind contracts for the new host
  surfaces.
- Validation: `./scripts/check.sh` passed with `206 passed, 2 skipped`.
- Live deploy: `./scripts/dev deploy` verified installed copies for
  `lacuna.ambience-host`, `lacuna.film-grain-overlay`,
  `lacuna.rainfall-overlay`, and `lacuna.background-vignette`.
- Runtime smoke: `omarchy plugin enable lacuna.ambience-host` enabled the
  host in the live shell config. `omarchy-shell lacuna-ambience-host status`
  reported `bottomVisible: true` with the current vignette settings, and
  `hyprctl -j layers` showed `lacuna-ambience-host-bottom` mapped on all
  three monitors. The migrated standalone plugins reported
  `hostedByAmbienceHost: true` and `visible: false`.
- Completion update: the host now owns all ambience rendering when enabled,
  replacing the duplicated watcher/render paths with one FileView set inside
  the host plus fallback-only standalone plugins.

### 2026-07-02 T4 regression protection

- Replaced the broad ambience-overlay Timer string check with a targeted QML
  object scan. Ambience overlays may not contain any `Timer` with an explicit
  interval below 100ms, which protects against wall-clock animation loops
  without blocking slower debounce or lifecycle timers.
- Kept the `FrameAnimation` requirement pinned for the ambience effects that
  currently drive per-frame state: ambience host, dust motes, film grain, CRT,
  and VHS.
- Kept shader reference coverage in the normal contract suite: every
  `ShaderEffect` `.qsb` reference must exist, and `./scripts/check.sh` still
  validates checked-in `.frag` sources against freshly baked `.qsb` output.
- Added an opt-in live CPU smoke to `tests/test_live_visual.py`. It is skipped
  unless both `LACUNA_LIVE_VISUAL=1` and `LACUNA_LIVE_PERF=1` are set, restores
  Lacuna settings in `tearDown`, toggles each ambience effect one at a time,
  samples the mapped Omarchy shell PID from `hyprctl -j layers`, and enforces
  a configurable CPU budget.
- Validation: focused T4 tests passed with `2 passed, 3 skipped`.
  `./scripts/check.sh` passed with `207 passed, 3 skipped`.

### 2026-07-02 visual parity correction

- Live feedback showed that the hosted shader approximations preserved the
  architecture but changed the look too much. Several effects became more
  saturated and obvious than the legacy ambience renderers.
- Captured a legacy-vs-hosted screenshot set under `/tmp/lacuna-ambience-parity`
  by toggling `lacuna.ambience-host` and activating each background effect
  one at a time, then restored the original live shell/settings state.
- Fixed the immediate foreground blowout by premultiplying RGB by alpha in
  the hosted ambience and film-grain shaders, then rebaked the `.qsb` packs.
- Made a conservative first refinement pass: lowered hosted generic shader
  opacity, reduced warm/color-shift saturation, and made hosted dust smaller
  and fainter.
- Validation: `./scripts/check.sh` passed with `207 passed, 3 skipped`.
  Live screenshot sanity after deployment reported low near-white coverage.
- Remaining visual work: tune each hosted effect against its legacy reference
  individually. Do not treat generic shader similarity as parity.

### 2026-07-02 rollback to standalone visuals

- Disabled `lacuna.ambience-host` in the live shell after feedback that hosted
  effects were not visually equivalent and did not preserve per-effect
  subsettings well enough.
- Removed `lacuna.ambience-host` from the native-replacements example config
  and the `scripts/lacuna` ambience profile so the host is no longer enabled
  by default.
- Current user-facing behavior should come from the standalone ambience
  plugins. The host remains in the repo only as an experimental consolidation
  path until each effect has real parity against the captured legacy reference.

### 2026-07-02 repo revert of the ambience-host experiment

- Removed `lacuna.ambience-host/` from the repo and reverted the
  `hostedByAmbienceHost` suppression gates in all eight standalone ambience
  overlays, plus the host-specific test and layer-stacking doc changes. The
  working tree is back to the committed T1/T2 state; the disabled live copy
  was uninstalled from `~/.config/omarchy/plugins/`.
- Postmortem: the shared mode-switched `ambience_effect.frag` could not
  reproduce the bespoke per-effect compositions, and its generic uniform
  block (time/intensity/speed/density/accentBlend/2 colors) silently dropped
  most per-effect settings (CRT static/bloom/distortion, cinematic
  stylePreset/slowDrift/sweeps/shimmer, god-ray rayCount/origin/shimmer, VHS
  trackingBands/noise/glitch, dust mouse reactivity, aurora blurSoftness).
  Hosted effects also filled the whole screen instead of clipping to the
  Lacuna frame content rect, and the first shader pack emitted
  non-premultiplied alpha, causing the blowout.
- Any future T3/T4 consolidation must port one effect at a time: a dedicated
  shader per effect carrying that effect's full settings schema as uniforms,
  clipped to the frame rect, and verified side-by-side against the legacy
  reference captures before moving to the next effect.

### 2026-07-05 full revert of the remaining T1/T2 optimizations

- Film grain and rainfall had already been reverted to item-based rendering
  after live review. This pass reverts the rest of the T1/T2 work, restoring
  the remaining optimized overlays to their exact pre-pipeline sources:
  - `lacuna.dust-motes-overlay`: back to wall-clock Timers, `hyprctl
    cursorpos` subprocess polling for cursor reactivity, and `ListModel`
    append/remove transient motes (drops FrameAnimation, the Hyprland IPC
    cursor socket, and the fixed recycled mote pool).
  - `lacuna.crt-overlay` / `lacuna.vhs-overlay`: back to Timer-driven
    animation instead of FrameAnimation.
  - `lacuna.background-vignette`: back to the stretched `assets/vignette.svg`
    image; deleted `shaders/background_vignette.frag(.qsb)`.
  - `scripts/check.sh`: removed the qsb bake-validation block (no `.frag`
    sources remain in the repo).
- The item-based designs are authoritative. The film-grain overlay keeps the
  FrameAnimation driver its item-based revert shipped with; every other
  ambience overlay is back to its original renderer.
- Updated `tests/test_qml_contracts.py` to assert the restored contracts
  (Timer-based dust/CRT/VHS allowed again, SVG vignette, no shader assets).
- Validation: `./scripts/check.sh` passed with `206 passed, 2 skipped`.
