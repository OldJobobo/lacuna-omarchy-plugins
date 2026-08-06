# Lacuna Architecture Decomposition Plan

Status: proposed; design reviewed, implementation gated by Phase 0 preflight and per-slice approval

## Goal

Evolve Lacuna into a first-class, professionally structured Omarchy plugin suite
without changing its product identity, public plugin contracts, or runtime
behavior.

The target is not a generic framework and not a line-count exercise. It is a
**modular plugin monolith**:

- each supported plugin install unit remains runtime self-contained within its
  declared manifest dependencies;
- each public entry point remains a small, stable composition root;
- state and side effects have one authoritative owner;
- pure policy is separated from QML lifetime and compositor behavior;
- cross-plugin reuse is distributed at build time through verified vendoring;
- changes ship as small, behavior-preserving, independently revertible slices.

This plan refines Phase 7 of the active Reliability And Optimization plan and
Workstream 5 of Quattro P2. It does not replace the canonical roadmap.

## Why This Architecture Fits Omarchy

A conventional shared runtime library is the wrong default here. Omarchy
installs flat plugin directories and plugins may be installed or updated as
separate units. Runtime imports from the repository root or another optional
plugin can therefore break an otherwise valid installation.

The appropriate architecture is:

```text
Omarchy public contract
        │
        ▼
small plugin entry-point façade
        │
        ▼
plugin-local controllers and components
        │
        ├── pure policy modules
        ├── stateful QML controllers
        ├── lifetime-sensitive QML composition
        └── plugin-local scripts/workers

Cross-plugin source reuse
        │
        ▼
canonical build-time source → sync-vendored → verified plugin-local copies
```

This provides normal modularity inside each plugin while preserving Omarchy's
packaging model.

## Success Criteria

The program is complete when:

1. Public plugin IDs, manifests, entry points, IPC targets, settings keys, and
   user-visible behavior remain compatible or have explicit migration coverage.
2. `Service.qml`, `Menu.qml`, `Overlay.qml`, and other public entry points are
   composition roots and compatibility façades rather than multi-domain
   implementations.
3. Every mutable subsystem has one documented writer and one lifecycle owner.
4. Pure transformations are deterministic, side-effect free, and directly
   testable outside a live shell.
5. QML components that own `Timer`, `Loader`, `FileView`, `Connections`, media
   players, focus, or layer-shell windows retain cohesive lifetime ownership.
6. No new runtime cross-plugin import is introduced.
7. Repeated source is either deliberately independent or generated from a
   canonical source and checked for equality.
8. Idle and active resource budgets do not regress by more than 5% without an
   approved tradeoff.
9. Every implementation slice passes focused tests, the repository gate, live
   deployment of affected plugins, and the relevant compositor/runtime probe.
10. No implementation PR requires a coordinated big-bang rollout or prevents
    rollback to the immediately preceding slice.

File size may improve as a consequence, but no target line count is an
acceptance criterion.

## Non-Negotiable Constraints

### Omarchy plugin contract

- Keep installable plugin directories flat at repository root as `lacuna.*`.
- Never start a second Quickshell process.
- Keep runtime code, assets, and scripts inside the installed plugin directory.
- Preserve entry-point contracts:
  - bar widgets expose an `Item` and accept `bar`, `moduleName`, and `settings`;
  - attached bar widgets retain `open()`, `close()`, and `opened`;
  - menu/panel surfaces retain `open(payloadJson)` and `close()`;
  - persistent services retain their `Service.qml` entry points;
  - `lacuna.bar` remains a bar option selected through `bar.id`.
- Resolve plugin scripts through `manifest.__sourceDir` or another
  plugin-relative path.

### Dependency direction

Preserve the core dependency direction:

```text
lacuna.state
  └── lacuna.shell-settings
        └── lacuna.menu
              ├── lacuna.menu-button
              └── lacuna.bar
```

Rules:

- lower layers never depend on menu or bar presentation;
- `requires` means a hard install/runtime dependency;
- `recommends` means optional enrichment and must degrade safely;
- no new dependency cycle or opportunistic cross-plugin QML import;
- `lacuna.bar` remains the frame/sidebar choreography owner;
- feature widgets do not gain frame, sidebar, or shell-wide state ownership.

The existing core-bundle import seam between `lacuna.bar` and `lacuna.menu` is
legacy compatibility, not a pattern to expand. Because `lacuna.bar/Bar.qml`
directly consumes menu types, properties, geometry methods, signals, and object
lifetimes, Phase 0 must inventory and pin that complete ABI. A bar and menu
built from adjacent supported revisions must either satisfy that tested ABI or
be rejected as an incompatible core-bundle combination.

### State and side effects

- `shell.json` remains Omarchy's composition and widget-setting interface.
- `~/.config/omarchy/lacuna/settings.json` remains Lacuna runtime/app state.
- `lacuna.state` remains the canonical Lacuna settings writer.
- Unknown recursively JSON-safe settings fields survive normalization and
  mutation.
- Omarchy services and commands remain preferred over duplicate orchestration.
- A refactor must not create a second poller, decoder, persistence writer,
  process supervisor, presentation deadline owner, or settings registry.

### QML lifetime and compositor behavior

Treat these as architecture, not implementation detail:

- `Variants`, `PanelWindow`, `Loader`, `Timer`, `Connections`, `FileView`,
  `IpcHandler`, focusable inputs, and `MediaPlayer` ownership determine object
  lifetime and callback order.
- Same-layer stacking is map order and cannot be repaired after mapping.
- Persistent surfaces remain mapped and gate paint/content rather than toggling
  visibility to restack.
- Mutually ordered paint, such as video plus black cover, stays in one window.
- Every layer assignment and namespace remains pinned by tests.
- Real fullscreen suppression must continue to gate paint, input, and exclusive
  zones per output.

### Geometry and design system

- Preserve one pixel-snapped effective geometry transaction for panel paint,
  connector, shadow, border, offsets, and compositor masks.
- Keep attachment edges square and use molding connectors.
- Use only the canonical vendored `curveKappa`.
- Round only exposed corners; never use `Rectangle.radius` on attached surfaces.
- Preserve fill-only attached shells and the explicit global frame-border
  exception.

### Compatibility-sensitive exclusions

Do not structurally refactor `lacuna.bar/OmarchyBar.qml` under this plan. It is
an upstream-derived, intentionally divergent compatibility surface. Changes to
it require a separate host-compatibility review.

## Architectural Standards

### 1. Stable façade, replaceable internals

Public entry points and widely consumed QML types remain stable façades. They
forward to internal collaborators and temporarily retain aliases while callers
migrate. Internal objects are not discovered directly through the shell.

### 2. One owner per state machine

A state machine moves as a cohesive unit. Do not distribute its timers,
revisions, callbacks, and cleanup across several objects merely to shorten a
file.

Examples:

- media handoff token, deadline, and recovery state belong together;
- inline video source generation, drift correction, and recovery timers belong
  together;
- settings write revisions, file-change suppression, retry, and permission
  repair belong together;
- installer lock, mutation record, staging, reload, and rollback remain one
  transaction boundary.

### 3. Commands in, events/snapshots out

Controllers communicate through explicit commands, signals, and immutable
replacement snapshots. A controller must not mutate a sibling controller's
internal object or retain undocumented access to its children.

### 4. Pure policy before QML composition

Extract deterministic transformations first. They accept complete explicit
inputs, return new data, do not mutate inputs, and do not read `shell`, QObjects,
files, processes, or globals.

Stateful QML controllers come next. Window/surface composition moves last.

### 5. Build-time reuse, runtime locality

Shared source exists only as an authoring source. Installed plugins receive
local copies. `scripts/sync-vendored --check` must be able both to detect and to
repair every declared copy.

### 6. Ports at side-effect boundaries

Filesystem, process, host-shell, provider, and time behavior should be behind
small adapters. Production uses Quickshell/Omarchy implementations; tests use
fakes. Avoid a service-locator framework—construct dependencies explicitly in
the plugin composition root.

### 7. Observability without secret exposure

Use enumerated phases and sanitized reason codes. Status IPC and logs must not
contain signed URLs, credentials, raw provider errors, or secret-bearing argv.

## Target Source Layout

Names are proposed contracts, not a requirement to create every file at once.
Create a module only when its implementation slice is approved and tested.

### `lacuna.media-player`

```text
lacuna.media-player/
  Service.qml                         # public service façade/composition root
  components/
    MediaLibraryStore.qml             # plugin-local library/session state
    MediaCatalogController.qml        # search/cache/filter/provider results
    MediaWorkerClient.qml             # persistent JSONL worker transport
    MediaPlaybackSession.qml          # transport, queue progression, clock
    MediaPresentationCoordinator.qml  # intent/token/deadline/recovery
    LegacyMediaGateway.qml            # quarantined compatibility processes
  scripts/
    media-player-worker               # stable executable wrapper
    media_worker/
      __init__.py
      protocol.py
      jobs.py
      mpv.py
      providers.py
      youtube.py
      jellyfin.py
      worker.py
      cli.py
```

Ownership:

| Module | Sole ownership |
| --- | --- |
| `Service.qml` | public properties/methods, compatibility aliases, IPC façades, dependency wiring |
| `MediaLibraryStore` | plugin-local `media-player.json`: queue, history, favorites, volume, repeat, last query, and compatibility cache values |
| `MediaCatalogController` | query, provider states, result merging, filtering, cache, visible window |
| `MediaWorkerClient` | one worker process, wire codec, readiness, restart policy, correlation |
| `MediaPlaybackSession` | current track, transport, playback revision, authoritative smoothed clock, stop/failure normalization |
| `MediaPresentationCoordinator` | in-memory presentation intent/state, handoff phase/token, renderer deadline, recovery decision |
| `LegacyMediaGateway` | compatibility subprocess generations and cleanup only; removal target |

The extensionless worker path and protocol remain stable while implementation
moves behind the wrapper.

Persistence authority is intentionally split by data class, not duplicated:

- `lacuna.state` is the sole durable writer for user preferences in
  `settings.json`, including `mediaPlayer.presentationMode`, `videoQuality`, and
  `providerFilter` plus provider configuration;
- `MediaLibraryStore` owns the media plugin's operational library/session file,
  `media-player.json`;
- compatibility preference values may still be read from the local state file
  during migration, but the store cannot commit them to `settings.json`;
- `MediaPresentationCoordinator` owns only live intent and transition state and
  requests durable preference changes through the `lacuna.state` façade.

### Media UI inside `lacuna.menu`

```text
lacuna.menu/menu/media/
  MediaServiceAdapter.qml
  MediaSearchTab.qml
  MediaQueueTab.qml
  MediaFavoritesTab.qml
  MediaTrackRow.qml
  InlineVideoRenderer.qml
```

- `MediaServiceAdapter` narrows and normalizes the optional service API; it does
  not duplicate state.
- `FlyoutMediaPlayerContent.qml` retains routing, bounded focus, dismissal,
  styling inputs, `closeRequested()`, and `forceSearchFocus()`.
- Each tab owns only its local interaction state.
- `InlineVideoRenderer` owns its loader/player, source revision, handoff token,
  drift correction, retry, telemetry, and associated timers as one unit.
- `MediaPlayerTile.qml` remains the visual shell and maps renderer events to the
  service façade.

### `lacuna.media-player-video`

```text
lacuna.media-player-video/
  Overlay.qml
  components/
    BackgroundOutputRegistry.qml
    BackgroundVideoContent.qml
    BackgroundPresentationMachine.qml   # optional final extraction
```

`Overlay.qml` remains the only owner of background `PanelWindow` declarations,
layer, namespace, and per-output variants. `BackgroundVideoContent` is an
`Item` inside the existing window and contains both `VideoOutput` and its black
cover. Extract the presentation machine only after deterministic transition
tests exist.

### `lacuna.menu`

```text
lacuna.menu/menu/
  MenuWindow.qml                      # public façade/declaration-order owner
  controllers/
    MenuActionController.qml
    MenuFlyoutCoordinator.qml
    MenuMonitorCoordinator.qml
    MenuGeometryCoordinator.qml
  model/
    MenuSettingsPatches.js
    MenuEffectsCatalog.js
    MenuSectionModel.js
  surfaces/
    MenuScreenSurface.qml             # late, lifetime-sensitive extraction
    MenuReserveSurfaces.qml           # late, moved as one ordered group
  registry/
    MenuShellCatalog.qml
    MenuViewCatalog.qml
  content/
    QuickLaunchEditorOverlay.qml
    MenuGridSection.qml
    MenuContentFooter.qml
```

- `MenuWindow.qml` retains `open(payloadJson)`, `close()`, declaration order,
  service resolution, and temporary forwarding methods.
- Pure settings-patch and catalog functions return data or side-effect intents;
  they never save settings or invoke the shell.
- `MenuActionController` owns command dispatch, plugin changes, and settings
  mutation orchestration.
- Flyout and monitor coordinators are long-lived QML objects because they retain
  QML references and timing state.
- `MenuGeometryCoordinator` is the sole owner of per-screen published geometry
  records, revisions, newest-wins transaction inputs, and the adapters that feed
  paint, shadow, border, offsets, and input masks. Pure bounded geometry remains
  in `MenuFlyoutGeometry.js`; `LacunaPanelHost` retains interpolation of one
  effective geometry record. Consumers receive immutable snapshots and never
  reconstruct geometry from occupancy flags.
- Surface and reserve extraction occurs last and must preserve window count,
  namespaces, declaration order, sibling z-order, and map policy.

`MenuRegistry.qml` remains a stable façade over effects, shell, app, and view
catalogs. `MenuContent.qml` retains its root scrolling/loading/animation
lifecycle while pure section modeling and cohesive visual blocks move behind it.

### `lacuna.state`

```text
lacuna.state/
  Service.qml
  SettingsSchema.js
  SettingsPersistence.qml            # optional late extraction
```

- `SettingsSchema.js` owns schema version, defaults, migration, normalization,
  clamps, and recursive JSON-safe preservation.
- `Service.qml` remains the persistent service and public façade.
- The confirmed-latest-write persistence protocol moves only as one cohesive
  unit, after schema extraction has settled.

The menu fallback receives matching local files:

```text
lacuna.state/Service.qml
  → lacuna.menu/services/LacunaSettings.qml
lacuna.state/SettingsSchema.js
  → lacuna.menu/services/SettingsSchema.js
lacuna.state/SettingsPersistence.qml
  → lacuna.menu/services/SettingsPersistence.qml   # only if created
```

All pairs must be added atomically to `scripts/sync-vendored`.

### Installer CLI

```text
scripts/
  lacuna                              # thin executable and compatibility exports
  lacuna_cli/
    __init__.py
    catalog.py
    paths.py
    config.py
    host.py
    transaction.py
    operations.py
    ui.py
    cli.py
```

- Pure catalog/config transforms are separated from I/O first.
- `transaction.py` retains the mutation lock, snapshot, atomic staging, reload,
  rollback, and operation record boundary.
- `operations.py` orchestrates through explicit filesystem/host adapters.
- Existing command names, arguments, output, exit codes, dry-run behavior, and
  monkey-patched test seams remain compatible during migration.
- AUR packaging must install `lacuna_cli/` with the executable.

### Canonical rich flyout shell

Create `shared/qml/BarFlyoutSurface.qml` as the build-time source for every
non-excluded `lacuna.*/BarFlyoutSurface.qml`. Preserve plugin-local runtime
copies and current public QML properties. This is canonicalization only, not a
geometry redesign.

## Public Contract Characterization

Before moving implementation, add tests that inventory the current contracts.

### Media service v1

Retain flat compatibility fields and methods while internals move. Add an
`apiVersion`/capability marker without removing existing members.

Contract groups:

- availability and dependency capabilities;
- search, provider state, result windows, queue, history, and favorites;
- playback track, position, duration, revisions, transport, volume, repeat;
- presentation mode/state/phase, candidates, revisions, and renderer callbacks;
- separate provider, worker, playback, and presentation error domains.

Arrays and object snapshots are replace-on-write. Consumers must not mutate
them.

### Renderer callback contract

Keep URL-free handoff tokens with:

```json
{
  "surface": "inline|background",
  "playbackRevision": 1,
  "presentationRevision": 1,
  "requestRevision": 1,
  "sourceRevision": 1
}
```

Callbacks are accepted only when all service-owned revisions and the surface
match. Duplicate loading for one token is idempotent. Loading starts the sole
generic renderer deadline.

### Worker protocol v1

- one JSON object per stdin/stdout line;
- stdout is protocol-only and stderr is sanitized diagnostics;
- preserve `configure`, `play`, `command`, `search`, `resolve-video`, `cancel`,
  and `shutdown`;
- cancelled or superseded work emits no effective late result;
- shutdown cancels/reaps provider children and owned mpv;
- credentials never enter public IPC, logs, diagnostics, or argv.

### Menu and settings contracts

- retain menu `open(payloadJson)`/`close()` behavior and summon target;
- retain pointer-first passive sidebar and bounded focus for interactive
  flyouts/text entry;
- retain settings schema version, unknown-field preservation, migration aliases,
  IPC targets, and latest-write-wins persistence behavior;
- retain all current `MenuRegistry` and `MenuWindow` forwarding methods until
  callers and tests have migrated;
- inventory and pin the complete `lacuna.bar/Bar.qml` → `lacuna.menu` ABI:
  imported types, required properties, methods, signals, geometry snapshot
  shape/revision semantics, controller references, construction order, and
  lifetime assumptions. Test both source compatibility and a staged core-bundle
  load before changing either side.

## Delivery Program

Each phase is independently shippable. Each numbered extraction should normally
be one PR or one small sequence of revertible commits.

### Phase 0 — Unblock and baseline

1. Review the installed Omarchy host against the compatibility ledger. The
   current environment reports host drift in `Bar.qml`, `BarModel.js`, and
   `shell.qml`; resolve or explicitly pin it before using the full gate as proof.
2. Record current plugin IDs, entry points, IPC surfaces, layer namespaces,
   window/player/process counts, and public media/menu/settings APIs.
3. Inventory and test the complete `lacuna.bar` → `lacuna.menu` core ABI,
   including geometry records and object-lifetime assumptions.
4. Capture live screenshots and `hyprctl layers` for representative bar,
   sidebar, flyout, fullscreen, inline media, and background media states.
5. Add missing contract tests before moving code.
6. Land a separate security correction that removes or disables the legacy
   Jellyfin credential-bearing argv path. This is a correctness prerequisite,
   not part of structural extraction.
7. Land a separate installer correctness fix so status derives the expected
   Lacuna settings schema (`2`) from one authoritative source. Update the
   baseline output contract before CLI extraction rather than preserving the
   known incorrect value.

Exit gate: a green reviewed-host baseline; pinned core bar/menu ABI; no
credential-bearing media argv path; correct schema status; and an artifact that
can distinguish architectural regressions from pre-existing host drift.

### Phase 1 — Canonicalize repeated rich flyout source

1. Add the canonical `shared/qml/BarFlyoutSurface.qml`.
2. Update `scripts/sync-vendored` to discover every non-excluded plugin copy.
3. Re-vendor all copies and strengthen equality/inventory tests.
4. Make no visual or API change.

Exit gate: `--check` detects drift and `--fix` repairs every copy; all four-edge
geometry and live representative flyouts remain unchanged.

### Phase 2 — Extract pure menu and settings policy

In separate slices:

1. `MenuSectionModel.js`.
2. `MenuEffectsCatalog.js`.
3. `MenuSettingsPatches.js`.
4. `SettingsSchema.js`, vendored atomically with the canonical/fallback services.

Use explicit inputs, immutable outputs, and table-driven Node tests. Keep QML
adapter methods so bindings read explicit QML properties/revision counters.

Exit gate: parity against the old behavior, unknown-field preservation, no lost
reactivity, and identical canonical/fallback settings results.

### Phase 3 — Decompose media flyout views

1. Add `MediaServiceAdapter.qml`.
2. Extract Search, Queue, and Favorites tabs one at a time.
3. Extract shared track-row presentation only after tab behavior is stable.
4. Keep root focus, dismissal, tab routing, and sizing in
   `FlyoutMediaPlayerContent.qml`.

Exit gate: provider races, debounce, pagination, queue edits, favorites
filter/sort, accessibility, and focus behavior pass with a fake service and live
interaction.

### Phase 4 — Split the persistent media worker

1. Keep `scripts/media-player-worker` as an executable compatibility wrapper.
2. Move protocol/emitter code.
3. Move jobs/cancellation/reaping.
4. Move mpv supervision.
5. Move providers one at a time.
6. Move coordinator and CLI loop last.

Do not change the wire protocol during this phase.

Exit gate: worker tests pass after each move; a copied installed plugin can start
the wrapper; concurrent search, cancellation, crash recovery, shutdown, and
secret redaction remain correct.

### Phase 5 — Decompose installer pure logic

1. Extract manifest/catalog/profile logic.
2. Extract path/config transforms.
3. Introduce explicit host/filesystem adapters without moving mutation
   ownership.
4. Keep command parser/output and compatibility exports in `scripts/lacuna`.
5. Update AUR/release packaging and add staged-package import coverage.

Exit gate: existing installer tests, dry runs, output/exit-code parity, archive
inventory, and installed CLI imports pass.

### Phase 6 — Split menu catalogs and content components

1. Move effect catalog use behind `MenuRegistry.qml`.
2. Add QML shell and view catalogs while retaining the registry façade.
3. Extract quick-launch editor overlay.
4. Extract grid section and footer one at a time.
5. Keep root flickable/loader/animation lifecycle in `MenuContent.qml`.

Exit gate: asynchronous catalog arrival, reopen, rename focus/Escape, drag/drop,
context removal, media footer, and reactive updates pass.

### Phase 7 — Extract media worker client and quarantine legacy paths

1. Move persistent worker `Process`, JSONL codec, readiness, restart, and
   correlation into `MediaWorkerClient`.
2. Move the already-sanitized fallback processes and generations into
   `LegacyMediaGateway` without changing policy.
3. Verify that the Phase 0 credential-bearing argv path cannot recur through
   either worker or fallback adapters.
4. Keep typed events identical between worker and fallback paths.

Exit gate: worker failure/restart, in-flight search, stop, stale-result rejection,
and no-secret diagnostics/argv checks pass.

### Phase 8 — Extract media state and catalog controllers

1. Move plugin-local library/session normalization, load, save, and migration
   into `MediaLibraryStore`; leave durable `settings.json` preferences owned by
   `lacuna.state`.
2. Move provider state, merge/rank/filter/cache, and result-window behavior.
3. Preserve flat aliases in `Service.qml`.
4. Migrate the menu adapter to the new capability marker without discovering
   controllers directly.

Exit gate: migration, secure permissions, queue/favorites persistence, provider
ordering, cache bounds, stale search rejection, and result window limits pass.

### Phase 9 — Extract playback and presentation state machines

1. Move playback transport, queue progression, stop/failure reset, playback
   revision, and smoothed clock as one `MediaPlaybackSession` unit.
2. After playback settles, move presentation intent, handoff token validation,
   generic renderer deadline, compatibility-state projection, and recovery as
   one `MediaPresentationCoordinator` unit.
3. Do not move renderer-specific timers into the coordinator.

Exit gate: EOF/repeat/next, same-source replay, pause/stop, worker restart, rapid
presentation toggles, stale callbacks/timers, forced inline without a surface,
and error-domain separation pass.

### Phase 10 — Extract inline and background renderer internals

1. Move the complete inline loader/player/token/drift/retry/telemetry lifecycle
   into `InlineVideoRenderer.qml`.
2. Extract background output registry.
3. Extract per-output content inside the existing background windows.
4. Leave background fade/source choreography in `Overlay.qml` initially.
5. Optionally extract `BackgroundPresentationMachine` only after deterministic
   timed transition coverage is complete.

Exit gate: no new window or namespace, permanent background mapping, in-window
black cover, player-count budgets, multi-output readiness, source-generation
races, drift bands, and two-phase entry/exit pass live.

### Phase 11 — Decompose menu orchestration

In this order:

1. `MenuActionController.qml` with temporary forwarding methods.
2. `MenuFlyoutCoordinator.qml` as one long-lived child.
3. `MenuMonitorCoordinator.qml`, retaining pure monitor policy separately.
4. `MenuGeometryCoordinator.qml`, first behind forwarding adapters and then as
   sole publisher of immutable per-screen geometry records/revisions. Preserve
   `LacunaPanelHost` as the effective-geometry interpolator.
5. Only after those settle, `MenuScreenSurface.qml` as one complete existing
   window delegate.
6. Move all reserve surfaces together and preserve declaration order.

Exit gate after each slice: rapid A→B→A flyout swaps, close during blend,
reduced-motion atomicity, focus restore, monitor handoff, fullscreen suppression,
geometry transaction parity, unchanged window count/namespaces, and live layer
inspection.

### Phase 12 — Move transaction machinery last

1. Move CLI transaction code by existing rollback unit, not by helper category.
2. Preserve one lock around mutation record, staging, shell edit, reload, and
   rollback.
3. Move settings persistence only if still beneficial, and only as the complete
   revision/FileView/retry/permission protocol.
4. Remove compatibility forwarding methods only after at least one release and
   migration/usage validation.

Exit gate: failure injection proves exact restoration of files, modes, plugin
copies, shell config, Hyprland overrides, and operation records.

## Validation Contract

### Every slice

Run the narrowest relevant tests first, then:

```bash
scripts/sync-vendored --check
python3 -m pytest
./scripts/check.sh
scripts/quattro-compatibility --check
```

Also verify:

- manifests and plugin-load contracts;
- no unexpected release-inventory change;
- no new runtime cross-plugin import;
- no new writer/poller/player/process authority;
- no public API, settings, IPC, output, or exit-code drift unless explicitly
  planned and migrated.

### Geometry, focus, or surface slices

Require:

- deterministic geometry and panel behavior tests;
- layer policy contracts;
- focus/input behavior tests;
- `./scripts/dev deploy <plugin-id>` for every changed installed plugin;
- rapid interaction and reduced-motion probes;
- multi-monitor and real-fullscreen checks;
- `hyprctl layers` and namespace/window-count comparison;
- opt-in live visual coverage with settings restored in cleanup.

### Media slices

Require the focused worker/service/UI/overlay/video suites plus:

- stopped: one control worker, zero mpv/provider children, zero Qt media players;
- inline: one mpv and at most one inline muted renderer;
- background: one mpv, zero inline renderer, one background renderer per matched
  output;
- cancelled search: zero surviving provider processes and no accepted late
  results;
- repeated stop/replay and worker shutdown: zero zombies/orphans;
- provider resolution time measured separately from renderer readiness;
- status/log/argv inspection for credential leakage.

### Installer slices

Require existing installer failure tests plus staged-package tests for:

- thin entry-point imports;
- install/update/reset/uninstall dry-run parity;
- failed batch rescan and activation rollback;
- exact bytes/modes restoration;
- lock serialization;
- deterministic archive and AUR payload contents.

### Performance gate

Use `scripts/lacuna-performance-benchmark` with the same monitor/layout and
configuration before and after a phase. Quick runs validate the harness only;
promotion evidence uses the documented warmup and sample durations.

Reject a slice that causes unexplained growth in shell CPU, RSS, wakeups,
descendants, players, process launches, open windows, or transition p95.

## Pull Request and Rollback Policy

- One architectural seam per PR where practical.
- No PR combines extraction with visual redesign, schema redesign, new feature,
  provider behavior change, or unrelated optimization.
- Keep public façades and forwarding aliases until consumers have migrated.
- Every PR names its rollback unit and proves the prior state can be restored.
- Generated/vendored copies belong in the same commit as their canonical source.
- If a live gate fails, revert the current slice; do not stack compensating
  refactors on an unproven boundary.
- Update architecture docs when ownership moves, and update source-contract
  tests to pin contracts in their new owner rather than pinning obsolete file
  placement.

## Decision Gates

Human approval is required before:

1. changing a public plugin ID, IPC target, settings key, command output, or
   worker protocol;
2. adding a hard plugin dependency;
3. creating or removing a layer-shell window;
4. changing persistent mapping/resource policy;
5. removing a compatibility alias or fallback path;
6. accepting a measured performance regression;
7. merging the optional background presentation-machine or settings-persistence
   extractions if the cohesive files are already maintainable after earlier
   work.

## Explicit Non-Goals

- Replacing Lacuna's custom bar/frame architecture with the stock Omarchy bar.
- Refactoring `OmarchyBar.qml` for aesthetics or line count.
- Building a general dependency-injection or plugin framework.
- Introducing runtime imports from `shared/` or optional plugins.
- Renaming public APIs while moving implementation.
- Combining this program with a visual redesign or settings-schema redesign.
- Splitting cohesive state machines into many tiny files.
- Treating source-contract string tests as sufficient runtime proof.

## Known Preflight Issues

These are not caused by decomposition but must be resolved or explicitly
bounded before implementation claims a green baseline:

- the installed Omarchy host is newer than the reviewed compatibility ledger
  and currently reports review-required changes in host bar/shell files;
- live vendored parity therefore prevents a clean full compatibility gate;
- the direct bar/menu core ABI is not yet completely inventoried or pinned;
- `scripts/lacuna` reports an outdated expected settings schema value in status;
- the legacy Jellyfin fallback can place a credential-bearing URL in process
  arguments;
- repeated `BarFlyoutSurface.qml` files are equal but not all are repairable by
  `scripts/sync-vendored --fix`.

Host compatibility, the core bar/menu ABI, the schema-status correction, and
the credential-bearing argv correction are Phase 0 blockers. They must land as
separate correctness/characterization changes before structural media or CLI
work. Flyout canonicalization remains the isolated Phase 1 repair.

## Definition of Done

The program is done when ownership documentation matches source, public façades
are stable and small, pure policy has direct tests, lifetime-sensitive state
machines remain cohesive, vendoring is canonical and repairable, packaged
installs contain every required module, runtime and compositor behavior are
live-verified, performance budgets hold, and all temporary compatibility aliases
have either completed their documented release window or remain intentionally
supported.
