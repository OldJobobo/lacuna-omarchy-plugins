# Quattro P1 — Product Integration Plan

Status: proposed (updated 2026-07-10)

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

Acceptance:

- A settings inventory has no orphaned controls or undocumented keys.
- Every control can be changed, restarted, reloaded, and restored.
- Invalid values are clamped or rejected consistently.
- Settings UI and state services agree on nested objects and defaults.

## Workstream 3 — Accessibility and interaction quality

Tasks:

- Add accessible names and roles to core bar, sidebar, rail, flyout, and
  settings controls.
- Ensure keyboard focus can enter, move through, and leave every core surface.
- Make Escape, Tab, arrow keys, Enter, and Space behavior consistent.
- Preserve visible focus indicators in every design style.
- Verify tooltip targets and hover-only affordances have non-pointer paths.
- Ensure click-through frame and overlay surfaces do not steal input.

Primary files:

- `lacuna.bar/`
- `lacuna.menu/menu/`
- `lacuna.menu/settings/`
- `lacuna.shell-settings/`
- `tests/test_qml_contracts.py`

Acceptance:

- Core workflows can be completed without a pointer.
- Every interactive control has a meaningful accessible label.
- Focus state remains visible against both dark and light themes.
- Input masks and layer-shell focus behavior are covered by smoke tests.

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
- `docs/architecture/media-player.md`
- `tests/test_media_player_worker.py`
- `tests/test_qml_behavior_media_*.py`

Acceptance:

- Every handoff has success, timeout, cancellation, and failure behavior.
- Provider credentials never appear in command arguments or logs.
- Failed media surfaces fall back to an available presentation.
- Settings and queue state survive restart according to documented policy.

## Workstream 5 — Product bundles and catalog clarity

Tasks:

- Define `core`, `native`, and `advanced` bundle boundaries.
- Ensure each bundle has complete required companions and a safe default.
- Mark experimental or provider-dependent plugins clearly in the catalog.
- Keep standalone plugins installable without silently activating the full
  Lacuna bar.
- Make the custom bar host and its required core companions obvious in the
  installer and README.

Primary files:

- `scripts/lacuna`
- `docs/install.md`
- `docs/plugins/README.md`
- plugin `manifest.json` files

Acceptance:

- Each bundle can be installed, listed, updated, and removed independently.
- The catalog explains required companions and runtime ownership.
- Users can return to a minimal native configuration without deleting state.

## Workstream 6 — P1 validation

Required checks:

```bash
./scripts/check.sh
python3 -m pytest tests/test_qml_contracts.py tests/test_qml_behavior_*.py
python3 -m pytest tests/test_status_scripts.py tests/test_media_player_worker.py
./scripts/dev deploy --all --only-changed --dry-run
omarchy-shell shell listShellConfig
omarchy-shell shell summon lacuna.menu "{}"
```

P1 is complete when core workflows, native services, settings, accessibility,
and media recovery behave as one coherent product.
