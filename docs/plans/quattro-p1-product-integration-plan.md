# Quattro P1 — Product Integration Plan

Status: in progress; beta product-readiness track (reviewed 2026-07-16)

P1 builds on the P0 core foundation and makes Lacuna feel like a complete,
native Quattro desktop layer while preserving its custom bar and frame.

## Goal

Every core interaction should have a clear owner, a reliable setting path, a
native Omarchy integration boundary, and a predictable failure mode.

## Dependencies

- P0 state and layout schema
- P0 custom-bar compatibility record
- P0 geometry and monitor policy
- P0 installer/recovery workflow

## Progress Summary

| Workstream | Status | Current evidence | Remaining beta boundary |
| --- | --- | --- | --- |
| Native service integration | Mostly complete | Ownership policy, service implementations, and capability-aware Codex/Claude quota states exist. | Finish the complete owner/action/failure matrix and coexistence checks. |
| Settings and subsettings | In progress | Versioned state, migration, corrupt-state recovery, and nested helpers exist. | Inventory every control/key and close deterministic round-trip gaps. |
| Interaction and focus safety | In progress; general keyboard navigation removed from scope | Pointer interaction, semantic labels, Media Search text entry, Escape dismissal, and click-away dismissal exist. | Keep passive sidebar use pointer-driven, scope keyboard focus to intentional text entry, and prove focus restoration and dismissal without turning the sidebar into a keyboard-navigated surface. |
| Media reliability | In progress | Playback services, provider scripts, video transition behavior, and failure tests exist. | Document ownership; cover provider cancellation, redaction, restart, and fallback. |
| Omakase setup and customization | In progress | The installer already has a full default, manifest metadata, and catalog grouping. | Define one canonical designed setup and prove safe customization and reset behavior. |
| P1 validation | Pending | Repository and P0 checks pass. | Complete the beta product matrix and live smoke record. |

## Workstream 1 — Native service integration matrix

Tasks:

- Document the owner of state, commands, notifications, and presentation for
  battery, media, idle, audio, Bluetooth, network, temperature, tray,
  notifications, updates, and system statistics.
- Use Omarchy services where they already provide authoritative state.
- Keep Lacuna presentation where the custom layout or visual treatment is the
  product value.
- Prevent duplicate low-battery notifications, idle orchestration, media
  state, and other user-visible side effects.
- Verify simple bar widgets use the correct injected properties and direct
  Quickshell service access.
- Treat optional provider quota windows as capabilities: suppress absent windows
  in the bar, retain a clearly unavailable flyout row, and restore the window
  automatically if the provider reports it again.
- Distinguish an explicitly absent provider window from an unknown state caused
  by expired authentication, unavailable endpoints, or local probe failures.

Primary files:

- `docs/architecture/omarchy-integration.md`
- `lacuna.audio/`
- `lacuna.bluetooth/`
- `lacuna.network/`
- `lacuna.power/`
- `lacuna.mpris/`
- `lacuna.notifications/`
- `lacuna.tray/`
- `lacuna.system-stats/`

Acceptance:

- Every rich system surface has one documented state owner.
- Actions use the correct Omarchy command or service boundary.
- Native widgets can coexist with the Lacuna bar without duplicate output.
- Service failures degrade to a clear unavailable state rather than breaking
  the bar or menu.
- Provider-dependent usage widgets never present stale historical windows as
  current limits and never claim suppression when provider capability is merely
  unknown.

## Workstream 2 — Settings and subsetting UX

Tasks:

- Inventory every core and bundled setting exposed by manifests, menu controls,
  shell settings, and runtime state.
- Ensure every setting has a visible default, valid range, persistence path,
  reset behavior, and migration rule.
- Remove controls that write a different shape than the state service reads.
- Make settings changes transactional and report failed writes clearly.
- Preserve unknown JSON-safe fields during read-modify-write operations.
- Add round-trip tests for nested settings and provider-specific settings.

Primary files:

- `lacuna.menu/settings/SettingsWindow.qml`
- `lacuna.shell-settings/settings/`
- `lacuna.menu/services/LacunaSettings.qml`
- `lacuna.state/Service.qml`
- `docs/configuration.md`

Required artifact:

- A checked settings inventory in `docs/configuration.md` or a linked generated
  inventory. It must name the default, valid values, persistence owner, reset
  behavior, and migration behavior for every beta-supported setting.

Acceptance:

- A settings inventory has no orphaned controls or undocumented keys.
- Every control can be changed, restarted, reloaded, and restored.
- Invalid values are clamped or rejected consistently.
- Settings UI and state services agree on nested objects and defaults.

## Workstream 3 — Pointer interaction and focus safety

Product decision: the Lacuna sidebar is a semi-persistent desktop surface, not
a modal application window. General keyboard navigation and Tab traversal
inside the sidebar or its attached flyouts are out of scope. Intentional text
entry remains supported: the Media Search field may receive keyboard input,
Escape may close an active flyout, and clicking outside may dismiss it. The
surface must not take keyboard focus merely because it or a flyout is visible.

Tasks:

- Keep passive sidebar and flyout use at `WlrKeyboardFocus.None`.
- Allow a scoped keyboard-focus state for an explicitly activated text-entry
  control such as Media Search; end that state immediately when the flyout is
  dismissed or the search interaction ends.
- Support Escape dismissal while a flyout owns scoped keyboard focus.
- Preserve click-away dismissal for interactive flyouts, with any focus grab
  limited to that dismissal lifecycle and never activated solely because the
  persistent sidebar is mapped.
- Restore focus to the previously active application after Escape, click-away,
  or explicit close.
- Retain meaningful accessible names and roles where they do not make controls
  keyboard-focusable or change compositor focus policy.
- Keep tooltip targets and hover affordances understandable through visible
  labels or pointer-accessible controls.
- Move workflows requiring broader keyboard navigation than direct text entry
  into a separate transient/modal surface with an explicit focus lifecycle; do
  not turn the persistent sidebar host into a Tab-navigated surface.
- Ensure click-through frame and overlay surfaces do not steal input.

Primary files:

- `lacuna.bar/`
- `lacuna.menu/menu/`
- `lacuna.menu/settings/`
- `lacuna.shell-settings/`
- `tests/test_qml_contracts.py`

Testing boundary:

- Extend focused runtime behavior tests under `tests/test_qml_behavior_*.py`;
  string-presence contracts alone do not satisfy this workstream.

Acceptance:

- Opening the sidebar or a non-text flyout does not steal keyboard focus from
  the active application.
- Activating Media Search accepts typing; Escape, click-away, and explicit
  close dismiss the flyout and restore application focus.
- Layer-shell keyboard focus changes only for the bounded text-entry lifecycle,
  not for passive pointer interaction or general flyout visibility.
- Pointer-operated controls have meaningful labels and reliable hit regions.
- Input masks, outside-click behavior, and layer-shell focus policy are covered
  by runtime smoke tests.

## Workstream 4 — Media lifecycle and provider reliability

Tasks:

- Validate inline, background, and automatic presentation handoffs.
- Keep one authoritative playback owner and make secondary surfaces recoverable.
- Test provider search cancellation, result merging, queue progression, and
  renderer failure fallback.
- Verify Jellyfin and YouTube settings migration and credential redaction.
- Ensure shell restart, plugin rescan, and provider failure do not leave stale
  UI state or broken controls.
- Keep the media feature separable from the core shell release.

Primary files:

- `lacuna.media-player/Service.qml`
- `lacuna.media-player/scripts/`
- `lacuna.media-player-video/Overlay.qml`
- `lacuna.menu/menu/MediaPlayerTile.qml`
- a new `docs/architecture/media-player.md`
- existing `tests/test_qml_behavior_video.py`
- existing media/provider coverage in `tests/test_status_scripts.py`
- new focused provider tests where the existing suites do not cover the
  acceptance cases below

Acceptance:

- Every handoff has success, timeout, cancellation, and failure behavior.
- Provider credentials never appear in command arguments or logs.
- Failed media surfaces fall back to an available presentation.
- Settings and queue state survive restart according to documented policy.

## Workstream 5 — Omakase setup and customization

Tasks:

- Define one canonical omakase installation: the designed Lacuna bar, sidebar,
  layout, settings baseline, and supported plugin collection.
- Make the normal install path activate that setup without asking the user to
  choose between architectural profiles.
- Keep the result customizable after installation without weakening the
  quality or coherence of the default experience.
- Provide a safe reset path back to the canonical layout and settings baseline.
- Mark optional, experimental, or provider-dependent plugins clearly without
  turning them into competing beta installation profiles.
- Keep lower-level selective installation available only where useful for
  development, recovery, or advanced manual customization.

Primary files:

- `scripts/lacuna`
- `docs/install.md`
- `docs/plugins/README.md`
- plugin `manifest.json` files

Acceptance:

- A clean normal install produces the complete designed Lacuna experience.
- The installer, README, catalog, default layout, and settings baseline agree
  on what the omakase setup contains.
- Users can customize the installed setup and safely reset it to the canonical
  default without deleting unrelated state.
- Selective installation mechanisms do not appear as required product choices
  in the beta onboarding path.

## Workstream 6 — P1 validation

Required checks:

```bash
./scripts/check.sh
python3 -m pytest tests/test_qml_contracts.py tests/test_qml_behavior_*.py
python3 -m pytest tests/test_status_scripts.py tests/test_qml_behavior_video.py
./scripts/dev deploy --all --only-changed --dry-run
omarchy-shell shell listShellConfig
omarchy-shell shell summon lacuna.menu "{}"
```

P1 is complete when core workflows, native services, settings, pointer/focus
safety, and media recovery behave as one coherent product.

## Delivered Checkpoint — 2026-07-16

- `lacuna.codex-usage` now rejects stale historical 5-hour windows, switches the
  bar to weekly-only when the current provider payload omits the session window,
  and dims the retained flyout row as suppressed.
- `lacuna.claude-usage` now reads the authenticated provider usage endpoint when
  available, distinguishes explicit window absence from probe uncertainty, and
  falls back to calibrated local estimates without making a false suppression
  claim.
- Both widgets automatically restore normal session/weekly rotation when the
  provider reports the session window again.
- Runtime behavior, QML contracts, script fixtures, live deployment, and
  installed-copy verification cover the transition in both directions.
- This closes the usage-widget capability-state slice of Workstream 1. It does
  not close the remaining native integration matrix or the P1 beta exit gate.

## Beta Exit Record

Do not mark P1 complete from repository tests alone. Record the supported
environment, packaged artifact, clean-install result, shell restart result,
settings round trip, sidebar focus-safety smoke, and media failure fallback in
this section when the beta gate is actually run.
