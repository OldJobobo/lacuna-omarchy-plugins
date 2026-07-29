# Lacuna-Wide Theme Token System Plan

Status: proposed; architecture decision required before implementation

Purpose: establish a versioned, optional theme-extension contract for Lacuna
without misrepresenting Lacuna-specific behavior as native Omarchy theming.
The tooltip residue proposal below is the first vertical slice and acceptance
fixture, not the boundary of the system.

## 1. Originating Proposal

Record the initial proposal as the motivating example:

> `shell.toml` can theme the tooltip's color, border, and alpha, but residue
> behavior is not an Omarchy theme surface. Hard-coding it into Lacuna for
> Neuromancer would be the wrong abstraction.
>
> A clean approach is an optional Lacuna extension file:
>
> ```toml
> # lacuna.toml
>
> [tooltip.residue]
> enabled = true
> duration-ms = 160
> surface-alpha = 0.42
> drift-x = 1
> drift-y = 1
> border-decay-ms = 70
> ```
>
> Lacuna would continue inheriting standard colors from `shell.toml`, read
> optional behavioral tokens from `lacuna.toml`, use conservative defaults
> when the file is absent, and keep the tooltip surface alive briefly so
> Hyprland's existing noise appears as controlled residue.
>
> This establishes a real theme-extension contract without pretending these
> effects are native Omarchy capabilities.

The example token names and values above must remain the first end-to-end
fixture. They do not define the complete Lacuna token vocabulary.

## 2. Required Outcome

A theme may include this optional file at its root:

```text
<theme>/lacuna.toml
```

When the theme is applied:

1. Omarchy remains authoritative for its native palette and shell theme data.
2. THPM transports the active theme's optional `lacuna.toml` into Lacuna's
   stable runtime input path.
3. Lacuna parses, validates, normalizes, and publishes a versioned token
   snapshot.
4. Any Lacuna plugin can consume that snapshot without importing another
   plugin directory at runtime.
5. Missing, malformed, unsupported, or partial files safely resolve to Lacuna
   defaults and never retain tokens from the previous theme.
6. A valid change becomes visible without starting another Quickshell process
   or requiring a full desktop restart.
7. User accessibility and explicit user settings retain precedence over theme
   suggestions.

The system must support Lacuna-wide motion, geometry, typography,
presentation, surface, and ambience tokens while keeping operational state and
host-owned colors out of the extension contract.

## 3. Existing Ownership — Preserve It

| Owner | Existing responsibility | Theme-token relationship |
| --- | --- | --- |
| Omarchy `colors.toml` / `shell.toml` | Native colors, shell surfaces, and host theme values | Remains authoritative; do not duplicate its standard palette in `lacuna.toml`. |
| `lacuna.state` and `settings.json` | User and Lacuna runtime preferences | Remains writable user state; never overwrite it during a theme switch. |
| Manifest widget settings in `shell.json` | Per-widget user options | Continue to override theme suggestions where the same behavior is user-exposed. |
| Existing `LacunaTokens.qml` files | Build-time typography, spacing, and control constants | Keep their name and role; do not silently turn them into runtime theme readers. |
| Existing `MotionTokens.qml` files | Motion scale and named durations | Adopt validated theme values through explicit bindings, while honoring reduced motion. |
| `shared/qml/` and `scripts/sync-vendored` | Canonical source and plugin-local copies | Distribute the runtime token adapter so plugins remain self-contained. |
| THPM | Run Omarchy `theme-set.d` integrations | Transport and lifecycle only; THPM must not own Lacuna token semantics. |
| Lacuna token service/compiler | New responsibility | Own schema, defaults, validation, diagnostics, normalization, and published runtime snapshot. |

Do not fold theme tokens into `settings.json`. Theme defaults and user choices
have different lifecycles, ownership, and reset semantics.

## 4. Precedence Contract

Resolve every adopted value in this order, from lowest to highest precedence:

1. Lacuna built-in default.
2. Valid active-theme value from `lacuna.toml`.
3. Explicit Lacuna user setting from `settings.json`, where a setting exists.
4. Explicit per-plugin manifest setting from Omarchy `shell.json`, where a
   widget exposes an override.
5. Accessibility or safety override, including reduced motion, input safety,
   and hard geometry bounds.

Native Omarchy values are not another layer in this list. They remain the
source for native roles such as background, foreground, accent, border, and
urgent colors. A Lacuna component should combine those colors with Lacuna
behavioral tokens rather than copy the colors into `lacuna.toml`.

A theme token is a suggested theme default, not permission to override a user's
accessibility preference or alter persistent user state.

## 5. Contract Files And Runtime Paths

### 5.1 Theme-authored source

```text
$THPM_CURRENT_THEME_DIR/lacuna.toml
```

This is the only file theme authors edit and ship.

### 5.2 THPM-managed active input

```text
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/theme/lacuna.toml
```

This is an atomically replaced mirror of the active theme file. It is generated
integration state, not user configuration. THPM removes it when the newly
selected theme has no `lacuna.toml`.

### 5.3 Lacuna-published snapshot

```text
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/theme/tokens.json
```

Lacuna writes this atomically after parsing and validation. QML consumers read
JSON rather than parsing TOML independently. The snapshot must contain at least:

```json
{
  "schemaVersion": 1,
  "generation": 1,
  "valid": true,
  "sourcePresent": true,
  "tokens": {},
  "diagnostics": []
}
```

`generation` changes on every resolved source transition, including removal or
invalid input, so bindings can distinguish a new default snapshot from stale
state. Diagnostics must not include secret environment data or arbitrary file
contents.

Before implementation, confirm these paths against the installed Lacuna CLI
and packaging contract. If generated theme state is moved under
`XDG_STATE_HOME`, update both repositories and all documentation together; do
not leave two supported active paths.

## 6. Schema Design

### 6.1 Versioning

Version 1 accepts the unversioned originating example for compatibility. New
themes should declare:

```toml
[lacuna]
schema-version = 1
```

Rules:

- absent version means version 1;
- a supported version is normalized to the current runtime snapshot;
- a newer major schema is rejected to defaults with a clear diagnostic;
- unknown sections or keys are ignored with diagnostics, not promoted into
  arbitrary QML properties;
- deprecated keys require an explicit one-release alias and migration test.

### 6.2 Registry

Create one machine-readable Lacuna token registry. Each token definition must
record:

- canonical dotted key;
- TOML type;
- built-in default;
- minimum, maximum, or enum values;
- runtime output name;
- owning component or subsystem;
- whether user settings may override it;
- whether reduced motion or another safety rule suppresses it;
- reload class (`live`, `surface-recreate`, or `shell-restart`);
- documentation text;
- introduction and optional deprecation schema versions.

Generate or test documentation and parser behavior against this registry so
QML defaults, parser defaults, and theme-author documentation cannot drift.

### 6.3 Initial namespaces

The system must be capable of these namespaces. Only tokens adopted by a real
consumer should become public; do not publish speculative keys merely to fill
out the file.

| Namespace | Intended use | Example candidates |
| --- | --- | --- |
| `motion.*` | Global animation character and duration scaling | speed multiplier, reveal/settle scale, easing family from a bounded enum |
| `geometry.*` | Lacuna-specific exposed measurements | control radius, panel radius, connector scale, spacing scale within design-system bounds |
| `typography.*` | Lacuna display treatment | display/mono font preference, tracking scale, title scale with installed-font fallback |
| `surface.*` | Shared attached-surface behavior | opacity modifiers, shadow treatment, disclosure thresholds |
| `tooltip.*` | Tooltip presentation and lifecycle | the complete residue fixture |
| `bar.*` | Lacuna bar presentation not owned by Omarchy | recess depth, seam treatment, density suggestion |
| `sidebar.*` | Sidebar visual treatment | rail treatment, divider gaps, disclosure timing |
| `flyout.*` | Attached flyout behavior | reveal timing and content threshold within geometry invariants |
| `frame.*` | Lacuna frame paint treatment | shadow offsets/alpha and molding presentation within layer policy |
| `ambience.*` | Theme-led visual-effect defaults | intensity, speed, and blend suggestions for installed effects |
| `component.<id>.*` | Narrow component-specific extension | only when a shared semantic namespace would be misleading |

The originating example remains:

```toml
[tooltip.residue]
enabled = true
duration-ms = 160
surface-alpha = 0.42
drift-x = 1
drift-y = 1
border-decay-ms = 70
```

### 6.4 Explicitly forbidden token classes

Version 1 must reject or ignore attempts to theme:

- commands, executable code, QML, JavaScript, or shell fragments;
- arbitrary filesystem paths, URLs, or assets;
- media credentials, provider configuration, application defaults, or secrets;
- plugin enablement, bar layout membership, monitor selection, or workspace
  routing;
- layer-shell levels, namespaces, anchors, exclusive zones, or map policy;
- input masks, focus policy, permissions, persistence behavior, or safety
  timeouts;
- native Omarchy palette roles already supplied by `colors.toml` or
  `shell.toml`;
- unbounded geometry or durations that can leave invisible mapped surfaces.

Themeability must not weaken the layer-stacking, flyout-geometry, background
video, or accessibility contracts.

## 7. Lacuna Architecture

### 7.1 New token service

Add a persistent core plugin:

```text
lacuna.theme-tokens/
  manifest.json
  Service.qml
  scripts/
    compile-theme-tokens.py
```

Responsibilities:

1. Watch the THPM-managed active input.
2. Invoke the plugin-local Python compiler without launching another
   Quickshell process.
3. Parse TOML with the standard library `tomllib`.
4. Validate against the canonical registry.
5. Clamp bounded values only where the contract says clamping is safe;
   otherwise reject the individual value to its default.
6. Publish the complete normalized JSON snapshot atomically.
7. Publish a default snapshot when input is absent or invalid.
8. Retain the last known-good snapshot only for a transient read/write race on
   the same generation; never retain the previous theme after a confirmed
   source removal or invalid new theme.
9. Expose status and refresh IPC for THPM and diagnostics.
10. Coalesce rapid theme changes and guard stale compiler completions by
    generation number.

Suggested IPC contract:

```bash
omarchy-shell lacuna-theme-tokens refresh
omarchy-shell lacuna-theme-tokens status
```

`status` should report source presence, validity, schema version, generation,
active token count, diagnostics count, and snapshot path.

### 7.2 Plugin-local runtime adapter

Add a canonical adapter under `shared/qml/`, for example:

```text
shared/qml/LacunaThemeTokens.qml
```

Extend `scripts/sync-vendored` to copy it into consuming plugins. This preserves
the existing rule that installed plugins do not import repository-root or
sibling-plugin paths.

The adapter must:

- watch `tokens.json` with `FileView`;
- expose a monotonically changing revision;
- retain a last known-good in-memory snapshot during an atomic replacement;
- fall back to built-in values when the snapshot is missing or malformed;
- provide typed accessors or explicit properties, not unchecked dynamic QML
  evaluation;
- expose source validity for diagnostics without making consumers responsible
  for error handling;
- avoid one subprocess per widget.

Do not rename the existing `LacunaTokens.qml`; the new name must make the
runtime/theme distinction obvious.

### 7.3 Consumption model

Consumers should bind theme values into their existing local token objects:

```qml
LacunaThemeTokens { id: themeTokens }
MotionTokens {
  animationDisabled: userState.reduceMotion
  animationSpeed: themeTokens.motionSpeed
}
```

This preserves local component contracts and makes precedence visible at the
binding site. Core services may share a loaded snapshot when the host provides
one, but every standalone plugin must still work through its vendored adapter
and defaults.

Adoption is incremental. A plugin not yet migrated continues using current
behavior even when `lacuna.toml` exists.

## 8. THPM Integration

Implement the cross-repository integration in:

```text
/home/oldjobobo/Projects/theme-hook-plugin-manager
```

Add a bundled hook, provisionally:

```text
theme-set.d/10-lacuna.sh
```

Add it to `THPM_PLUGIN_FILES` in `lib/plugin-registry.sh`. It should be enabled
by default because it is a safe no-op when no Lacuna extension is present and
the contract should work when a theme opts in.

The hook must:

1. Source `THPM_THEME_ENV` and use `THPM_CURRENT_THEME_DIR`.
2. Resolve the target using `XDG_CONFIG_HOME` consistently with Lacuna.
3. If the active theme contains `lacuna.toml`, create the destination directory
   and atomically install the file without interpreting Lacuna keys.
4. If it does not, atomically remove the previous active mirror.
5. Ask the running Lacuna token service to refresh when available.
6. Exit successfully when Lacuna or `omarchy-shell` is unavailable.
7. Never modify the source theme, `settings.json`, `shell.json`, or
   `tokens.json`.
8. Avoid restart notifications because the normal path is live reload.
9. Support cleanup on disable/uninstall so stale theme input cannot survive
   removal of the integration.

THPM owns transport, atomic replacement, cleanup, and hook lifecycle. It must
not duplicate the Lacuna registry, validate individual tokens, convert key
names, or invent defaults.

Update THPM's plugin guide, registry tests, installer/update preservation tests,
doctor behavior, and uninstaller cleanup tests. `thpm doctor lacuna` should
check the hook, source/destination relationship, and optional Lacuna refresh
command without treating an absent `lacuna.toml` as an error.

## 9. First Vertical Slice: Tooltip Residue

Use tooltip residue to prove the complete path before broad adoption:

1. Add the six originating keys to the registry with documented bounds.
2. Apply a theme through THPM and verify the active mirror changes.
3. Compile and publish the normalized snapshot.
4. Read the values through the vendored adapter in the tooltip owner.
5. Keep the existing tooltip surface mapped only for the bounded residue
   duration.
6. Disable input immediately when normal tooltip dismissal begins.
7. Apply surface alpha, drift, and border decay while allowing Hyprland's
   existing noise to show through.
8. Cancel or restart residue deterministically when the tooltip reopens.
9. Bypass the residue lifecycle when reduced motion is enabled unless the
   accessibility contract explicitly permits a non-moving fade-only fallback.
10. Return to defaults immediately when switching to a theme without
    `lacuna.toml`.

Read and preserve the layer-stacking policy before changing surface lifetime.
Do not add a second tooltip layer-shell surface merely to implement residue.

The exact value bounds must be fixed by tests before implementation. Initial
safe ranges to evaluate are:

| Token | Type | Default | Candidate bound |
| --- | --- | --- | --- |
| `tooltip.residue.enabled` | boolean | `false` | — |
| `tooltip.residue.duration-ms` | integer | `0` | `0..500` |
| `tooltip.residue.surface-alpha` | real | `0` | `0..1` |
| `tooltip.residue.drift-x` | real | `0` | `-8..8` |
| `tooltip.residue.drift-y` | real | `0` | `-8..8` |
| `tooltip.residue.border-decay-ms` | integer | `0` | `0..duration-ms` |

These are review candidates, not final public guarantees.

## 10. Implementation Phases

### Phase 0 — Contract decision

- Confirm runtime paths and schema-version syntax.
- Identify the canonical tooltip owner and current tooltip surface lifecycle.
- Decide whether reduced motion disables residue entirely or retains a
  stationary alpha decay.
- Approve the first registry entries and bounds.
- Confirm THPM hook name, default state, and cleanup action.

No implementation should begin until these decisions are recorded.

### Phase 1 — Parser and registry

- Add the machine-readable registry.
- Implement TOML parsing, normalization, diagnostics, and snapshot generation.
- Add fixtures for absent, partial, valid, invalid, unsupported, and oversized
  files.
- Ensure output is deterministic and atomically written.

### Phase 2 — Persistent service and adapter

- Add `lacuna.theme-tokens` and IPC.
- Add the canonical `LacunaThemeTokens.qml` adapter.
- Extend vendoring and manifest metadata.
- Add the service to the core bundle while preserving standalone-plugin
  fallback behavior.

### Phase 3 — THPM hook

- Add the bundled Lacuna hook and registry entry.
- Add atomic copy, removal, cleanup, refresh, doctor, installer, update, and
  uninstall coverage.
- Verify a theme without the extension clears the previous theme input.

### Phase 4 — Tooltip residue proof

- Add behavior tests before changing the tooltip.
- Implement the six originating tokens end to end.
- Add runtime and opt-in live visual coverage for dismissal, reopen,
  reduced-motion, invalid input, and theme removal.

### Phase 5 — Shared token adoption

Adopt tokens by subsystem, not through a repository-wide replacement:

1. motion scale and named duration modifiers;
2. shared surface and flyout presentation;
3. geometry and density values that do not violate attachment invariants;
4. typography with installed-font fallback;
5. frame and ambience presentation;
6. component-specific extensions only when justified by a shipped theme.

Each adopted namespace requires a consumer, tests, documentation, and a
fallback demonstration.

### Phase 6 — Theme authoring and diagnostics

- Publish a complete `lacuna.toml` reference and minimal example.
- Add a `lacuna theme-tokens validate <path>` or equivalent non-mutating
  validation command.
- Surface active schema version, source, token count, and diagnostics in Lacuna
  settings or CLI status.
- Add Neuromancer's residue configuration only after the contract is released.

## 11. Test Plan

### 11.1 Lacuna parser tests

Cover:

- missing source produces defaults;
- empty file and unversioned v1 file;
- complete and partial sections;
- unknown keys and sections;
- wrong scalar types, arrays, and tables;
- out-of-range numbers and non-finite values;
- unsupported schema versions;
- deterministic normalized output;
- source removal after a valid theme;
- invalid new theme after a valid theme;
- rapid generation changes cannot publish stale compiler output;
- input size and nesting limits.

### 11.2 QML adapter tests

Cover:

- missing and malformed snapshots;
- atomic replacement without a transient default flash;
- generation and revision changes;
- typed fallback behavior;
- reduced-motion and user-setting precedence;
- vendored copies match the canonical adapter;
- standalone widget operation without `lacuna.theme-tokens` installed.

### 11.3 Consumer tests

For every adopted token, test built-in default, theme value, user override,
safety override, live change, and source removal. Visual/stateful changes need
runtime behavior or deterministic geometry tests; string-contract pins alone
are insufficient.

Tooltip residue additionally requires:

- disabled path preserves current dismissal;
- mapped lifetime ends at the bounded deadline;
- residual surface captures no input;
- reopen cancels stale dismissal completion;
- drift and border decay settle correctly;
- reduced motion follows the approved policy;
- no new layer or window is introduced.

### 11.4 THPM tests

In THPM's isolated fake-home harness, cover:

- install and default enablement;
- theme with `lacuna.toml`;
- theme without it;
- configured-to-unconfigured theme switch;
- invalid TOML is transported unchanged for Lacuna-owned diagnostics;
- atomic replacement and permissions;
- unavailable Lacuna service;
- refresh invocation when available;
- disable and uninstall cleanup;
- update preserves user-selected enabled/disabled state;
- doctor treats an absent theme extension as healthy.

### 11.5 Integration matrix

Verify all four transitions:

| Previous theme | New theme | Required snapshot |
| --- | --- | --- |
| no extension | no extension | defaults |
| no extension | valid extension | new normalized tokens |
| valid extension | valid extension | only the new theme's tokens |
| valid extension | no/invalid extension | defaults, never previous tokens |

Also verify shell startup while a valid mirrored file already exists and shell
startup after THPM removed it while the shell was stopped.

## 12. Documentation Deliverables

In Lacuna:

- add a theme-token architecture reference;
- add a generated or registry-checked token reference;
- update `docs/configuration.md` to distinguish user state from generated theme
  input and snapshots;
- update plugin contracts for the vendored runtime adapter;
- document precedence, versioning, diagnostics, reload classes, and forbidden
  token categories;
- provide minimal and full `lacuna.toml` examples;
- retain this plan as the rationale and rollout record.

In THPM:

- document `lacuna.toml` theme discovery;
- document the active mirror and cleanup semantics;
- add the plugin to the bundled registry documentation;
- state clearly that Lacuna owns validation and token semantics.

## 13. Validation Commands

Lacuna repository:

```bash
python3 -m pytest tests/test_docs_contracts.py
python3 -m pytest tests/test_vendored_files.py
./scripts/check.sh
git diff --check
```

For each user-visible consuming plugin:

```bash
./scripts/dev deploy <plugin-id> --dry-run
./scripts/dev deploy <plugin-id>
```

Deploy `lacuna.theme-tokens` first, then consumers. Run any new opt-in live
visual test with `LACUNA_LIVE_VISUAL=1` and restore every setting or theme it
changes.

THPM repository:

```bash
bash -n thpm install.sh uninstall.sh lib/*.sh theme-set theme-set.d/*.sh
bash tests/run.sh
git diff --check
```

Perform a live switch from Neuromancer to a theme without `lacuna.toml`, then
back, and inspect both token-service status and shell logs.

## 14. Acceptance Criteria

The plan is complete only when:

- `lacuna.toml` is an optional, versioned, documented theme-root contract;
- standard colors and native shell styling still come from Omarchy;
- theme tokens never mutate `settings.json` or `shell.json`;
- THPM atomically installs and removes the active source mirror;
- Lacuna alone owns schema validation, defaults, and normalized output;
- every plugin can consume tokens without sibling-plugin runtime imports;
- missing or invalid input resolves to conservative defaults;
- switching away from an extended theme cannot retain stale tokens;
- accessibility, safety, geometry, and layer policies override theme requests;
- tooltip residue works as the first end-to-end fixture without
  Neuromancer-specific code;
- runtime behavior tests and live visual verification cover stateful changes;
- both repositories' full checks pass;
- the installed Lacuna plugins and active THPM hook match their checked-out
  implementations before the feature is reported as live-fixed.
