# Lacuna Suite Polish Review

Status: strategic review

Date: 2026-07-17

## Executive Verdict

Lacuna already has the foundations of a first-class Omarchy Quattro extension
suite. Its strongest assets are unusually defensible:

- A recognizable design language built around seams, gaps, connectors, and
  attached geometry.
- A custom bar–frame–sidebar composition that no ordinary widget pack offers.
- Strong multi-monitor, layer-order, state, rollback, and geometry engineering.
- A serious test suite: `./scripts/check.sh` passes with 310 tests passed and 3
  opt-in visual tests skipped.
- Transactional installation and recovery inside Omarchy's existing Quickshell
  process.

The primary risk is no longer lack of capability. It is insufficient curation
and product hardening. Lacuna should temporarily stop expanding and turn what
exists into one focused, trustworthy experience.

## Product Position

Position Lacuna as:

> A cinematic but dependable desktop layer for Omarchy—not a collection of 45
> widgets.

Lead with three qualities:

1. The integrated frame, bar, sidebar, and attached-surface choreography.
2. Safe maximalism: expressive visuals with measured resource use and reliable
   teardown.
3. Best-in-class installation, compatibility reporting, diagnostics, and
   recovery.

Everything else should reinforce those pillars.

## Highest-Priority Work

### 1. Freeze A Curated Omakase Installation

`scripts/lacuna` currently defines Full as essentially every non-legacy
manifest. The dry run selects about 45 plugins, including experimental, beta,
provider-dependent, and persistent ambience surfaces. Adding a manifest can
therefore silently change the flagship product.

Create a machine-readable, explicitly reviewed omakase inventory containing:

- Exact plugin IDs and stability requirements
- Canonical bar layout
- Default Lacuna settings
- Enabled ambience preset
- Optional capability groups
- Reset ownership

Suggested grouping:

- **Lacuna Core:** bar, frame, menu, state, settings, workspaces, clock, tray,
  and essential system surfaces.
- **Lacuna Plus:** theme, wallpaper, weather, notifications, and resource
  widgets.
- **Media:** explicit opt-in until beta reliability and credential work is
  complete.
- **Ambience:** enabled through named presets rather than every persistent
  effect by default.
- **Developer Lab:** script pill and experimental components.

The normal installer should offer one excellent default, not an architectural
profile decision.

### 2. Resolve The Focus-Policy Contradiction

The P1 plan defines the persistent sidebar as pointer-first and prohibits
general keyboard navigation. The current implementation still includes
focus-on-open, directional navigation, and keyboard activation in shared
controls.

Choose one contract and make code, tests, and documentation agree. The roadmap's
current direction is appropriate:

- The passive sidebar never steals application focus.
- Flyouts take bounded focus only for dismissal and direct text entry.
- Escape, unconsumed Backspace, click-away, and explicit close restore prior
  focus.
- Accessibility names and roles remain even without general keyboard traversal.

Prove this in a live compositor session before beta.

### 3. Close Concrete Security Gaps

Two issues should block a stable security claim:

- The media fallback can place a Jellyfin API key inside process arguments
  through `lacuna.media-player/Service.qml` and `media-player-control`.
- Corrupt settings backups may initially be created with permissive file modes
  before delayed permission correction in `lacuna.state/Service.qml`.

Required changes:

- Never pass credential-bearing URLs through argv. Keep playback inside the
  worker or use protected stdin/IPC.
- Create the Lacuna state directory as `0700`; create settings, backups,
  sockets, and PID files with restrictive modes immediately.
- Add forced-fallback tests asserting that credentials never appear in argv,
  logs, diagnostics, or errors.
- Publish a capability and privacy disclosure per plugin: commands executed,
  network services contacted, files read, and credentials used.

### 4. Make Settings Visibly Trustworthy

The settings architecture is sound, but the UI does not yet prove persistence.
Add a standard state model:

- `idle`
- `saving`
- `saved`
- `failed`
- `retrying`

Keep the last confirmed revision and implement latest-write-wins serialization.
A failed write should produce a concise inline message and Retry action rather
than looking successful.

Generate a complete settings inventory containing:

- Key and persistence owner
- Default and valid range
- Units
- UI location
- Reset behavior
- Migration behavior
- Whether restart or reload is required

This is particularly important for ambience settings that currently lack
bounds.

### 5. Fix Release Machinery Before `0.1.0-beta.1`

Concrete blockers include:

- `tests/test_manifest_contracts.py` accepts only `X.Y.Z`, so the planned beta
  and RC SemVer versions would fail the project gate.
- Selective uninstall does not protect reverse dependencies.
- CI pins an older Omarchy revision than the compatibility ledger and does not
  run the repository compatibility checker.
- The release archive has many top-level roots instead of one versioned
  directory and does not undergo a clean extraction/install rehearsal.
- The changelog says CI reports coverage, but the workflow currently runs plain
  pytest.

Before beta:

1. Support full SemVer prereleases everywhere.
2. Validate one stability vocabulary, including the currently used `beta`.
3. Block or cascade dependency-breaking uninstall operations.
4. Build a versioned archive from committed files with generated inventory.
5. Extract it into a clean directory and run package/install smoke checks.
6. Record install → restart → settings round trip → forced update failure →
   rollback → uninstall → stock-bar recovery.
7. Mark GitHub beta and RC releases as prereleases.

### 6. Ship `lacuna doctor`

The current status command reports installed/enabled versions. A first-class
diagnostic should also report:

- Active bar host
- Exact Omarchy and Quickshell versions
- Supported, unreviewed, or incompatible host status
- Missing, staged, disabled, failed, stale, and version-mismatched plugins
- Dependency closure
- Current monitor/sidebar policy
- Settings schema and migration status
- Missing optional commands
- Redacted provider state
- Relevant log locations
- An exact recovery action for every failure

Provide calm human output, `--json`, and an optional redacted support bundle.

## Visual And Interaction Polish

### Replace Public Screenshots

The README hero and reference captures expose personal/session information and
show stale alpha version text. Recapture a sanitized release gallery with:

- A deliberately composed hero desktop
- Current version
- No personal identifiers or implementation transcripts
- Sidebar default and collapsed states
- Representative attached flyouts
- Loading, empty, unavailable, and error states
- Two contrasting themes
- Compact and comfortable density
- 100% and 150% scaling
- Multi-monitor composition
- Reduced-motion behavior

Keep concept art clearly separated from shipping screenshots.

### Improve Legibility Without Losing The Aesthetic

The current UI has a coherent silhouette but relies heavily on small, faint
text. Recommended changes:

- Introduce Comfortable and Compact density modes.
- Increase secondary text size and contrast.
- Remove low-value metadata from default views.
- Use progressive disclosure for technical details.
- Test scale factors through 200%.
- Add automated contrast checks for representative themes.

Preserve the mono grid and geometry; improve hierarchy through spacing and
information density rather than smaller typography.

### Standardize State Presentation

Define a shared state anatomy:

1. Icon
2. Concise title
3. One explanatory sentence
4. Optional status detail
5. Primary recovery action
6. Optional diagnostics action

Use it consistently for empty, loading, offline, permission denied, missing
service, provider unconfigured, stale data, failed write, and retry-exhausted
states.

### Complete The Accessibility Contract

Audit every interactive element for:

- Accessible role, name, state, and description
- Minimum pointer target
- Reliable hit region
- Intentional focus behavior
- Visible focus where focus is supported
- Reduced-motion behavior
- Screen-scale behavior
- Contrast

Expose the existing reduced-motion preference directly in settings and document
it.

## Performance And Reliability

### Establish A Performance Budget

Compare stock Omarchy, Lacuna Core, canonical omakase, each ambience preset,
menu open/closed, and media playback. Measure:

- Shell CPU and RSS
- Child-process launches and wakeups
- Frame timing
- Startup time
- One hundred open/close cycles

Areas deserving attention include high-frequency cursor subprocess polling,
power helper polling, duplicate network refresh ownership, persistent effects
across multiple monitors, and duplicate resource collection.

Publish thresholds and fail RC promotion when they regress materially.

### Standardize Subprocess Lifecycle

Build a common bounded runner with:

- Timeout
- Terminate/kill/reap behavior
- Output-size cap
- Queue recovery
- Redacted errors
- User-visible timeout state

Apply it first to shell settings and settings persistence, following the
watchdog pattern already present in `lacuna.shell-settings/Service.qml`.

### Retire Duplicate Media Paths

`lacuna.media-player/Service.qml` currently maintains worker orchestration and a
large fallback stack. Once worker reliability is proven, reduce the fallback to
a safe degraded state rather than retaining a second feature-complete playback
architecture.

## Documentation And Ecosystem Polish

### Generate The Catalog

Generate these artifacts from manifests and canonical inventory data:

- Plugin catalog
- Stability table
- Omakase membership
- Dependencies and recommendations
- Runtime command and network requirements
- Configuration option tables
- Release inventory

This will prevent current drift such as missing catalog entries, incomplete
stability documentation, mismatched weather copy, and stale reduced-motion
status.

### Clarify The Ownership Principle

Use this product principle:

> Omarchy owns authoritative state and orchestration. Lacuna may own
> presentation where it adds a distinctive suite-level workflow without
> duplicating side effects.

Require every replacement surface to justify itself through a unique workflow,
meaningful sidebar/frame integration, better failure-state communication,
strong visual value, and no competing orchestration.

### Publish A Lacuna-Native Extension Recipe

After the core is stable, document how third parties can create a surface that
feels native to Lacuna:

- Token usage
- Connector geometry
- Motion choreography
- State anatomy
- Accessibility contract
- Service ownership
- Manifest metadata
- Required tests

This would turn Lacuna from a closed suite into a small design and plugin
ecosystem.

## Recommended Delivery Sequence

### Beta Blockers

1. Curated omakase inventory and safe reset.
2. Screenshot and privacy replacement.
3. Focus-policy reconciliation and live focus-restoration tests.
4. Credential and settings-permission fixes.
5. Confirmed settings persistence with visible failures.
6. SemVer prerelease support and dependency-safe uninstall.
7. Compatibility-aligned CI and clean release-artifact rehearsal.
8. Complete settings and accessibility inventory.

### Release Candidate Quality

9. `lacuna doctor` and redacted support bundle.
10. Performance baseline and subprocess hardening.
11. Runtime Quickshell promotion gate, not only static hosted CI.
12. Generated catalog, configuration, and release inventory.
13. Sanitized visual matrix across themes, scaling, and failure states.

### Post-1.0 Differentiation

14. Live settings preview with a timed Revert action.
15. First-run seam-based walkthrough.
16. Context-aware calm for fullscreen, battery saver, presentation, and idle.
17. Public Lacuna-native plugin authoring guide.

## Bottom Line

Lacuna does not need another widget to become first in class. It needs:

- A smaller, intentional flagship experience
- Zero ambiguity around focus, credentials, and persistence
- Measured performance
- Exceptional diagnostics and recovery
- Release-quality visual presentation

If those are completed while preserving the existing geometry and shell-safety
work, Lacuna can credibly become the reference example of an ambitious Omarchy
Quattro extension suite.
