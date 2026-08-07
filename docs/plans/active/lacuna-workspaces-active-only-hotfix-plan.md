# Lacuna Workspaces Active-Only Hotfix Plan

Status: implemented and live-deployed; interactive product validation pending

## Goal

Add an opt-in mode to `lacuna.workspaces` that renders exactly one workspace
button: the currently focused Hyprland workspace. Preserve the existing fixed
multi-workspace switcher as the default and avoid expanding this change into a
workspace-navigation redesign.

This is a hotfix-style delivery slice: one manifest option, one model-selection
branch, focused tests, an Unreleased changelog entry, and live deployment
validation.

## Product Contract

Introduce the bar-widget setting:

```json
{
  "activeWorkspaceOnly": false
}
```

Contract:

1. Missing or `false` keeps the current `workspaceCount` plus optional
   `showDynamicExtra` behavior byte-for-byte equivalent at the model level.
2. `true` makes the repeater model contain only `activeWorkspace()`.
3. Active-only mode takes precedence over `workspaceCount` and
   `showDynamicExtra` for rendering, but does not delete or rewrite either
   stored setting. Turning the option off restores the user's prior layout.
4. A focused positive workspace outside `workspaceCount` must still appear.
5. The existing `activeWorkspace()` fallback remains workspace `1` while
   Hyprland has not supplied a focused workspace.
6. Focus changes must replace the single model entry and allow the grid's
   implicit size to recompute without requiring a shell restart.
7. The single button retains the current style, active state, tooltip, hover,
   accessibility, and click dispatch behavior.

The first hotfix keeps the widget's existing global
`Hyprland.focusedWorkspace` semantics. Per-monitor active-workspace resolution,
special-workspace UX, scroll navigation, and changing the product default are
out of scope.

## Implementation

### 1. Manifest setting

Update `lacuna.workspaces/manifest.json`:

- Add `activeWorkspaceOnly: false` to `barWidget.defaults`.
- Add a boolean schema field named `activeWorkspaceOnly` with the label
  `Show only active workspace`, `defaultValue: false`, and a short description
  that explains `workspaceCount` and dynamic extras are temporarily ignored
  while enabled.
- Keep examples and the canonical omakase profile unchanged so existing and
  fresh installs continue to receive the multi-workspace layout.

The manifest remains the widget-level source of truth. Lacuna Settings also
exposes the option directly under **Settings → Bar** and writes the inline bar
widget setting through Omarchy's plugin registry.

### 2. Workspace model selection

Update `lacuna.workspaces/Widget.qml`:

- Add a readonly boolean derived through the existing `setting()` helper:
  `setting("activeWorkspaceOnly", false) === true`.
- At the start of `workspaceIds()`, return `[activeWorkspace()]` when the option
  is enabled.
- Leave the existing fixed and dynamic ID construction untouched in the false
  branch.

Using `workspaceIds()` as the sole branch point keeps `Grid`, `Repeater`, button
state, tooltip generation, and focus-change invalidation on their current code
paths. It also ensures an active workspace above the configured fixed count is
not filtered out.

### 3. Regression coverage

Extend `tests/test_qml_behavior_workspace_bar_style.py` with a non-window QML
probe that instantiates `lacuna.workspaces/Widget.qml` and verifies:

1. With the option omitted, `workspaceIds()` still returns the configured fixed
   range (use a small deterministic `workspaceCount` in the probe).
2. With `activeWorkspaceOnly: true`, the model has length one and its only value
   equals `activeWorkspace()`.
3. Toggling the settings object back to false restores the configured fixed
   range, proving the ignored settings were not lost.

Add a narrow manifest assertion in `tests/test_manifest_contracts.py` for the
new boolean default/schema pair. This protects both backward compatibility and
Settings discoverability without relying only on string pins in a contract
file.

If direct widget construction exposes an unavailable Hyprland/session behavior
in the harness, keep the runtime probe session-gated like the existing workspace
style test and add a static contract assertion as CI fallback. Do not replace
the runtime probe with only a source-string assertion.

### 4. Release note

Add one item under `CHANGELOG.md` → `Unreleased` → `Added` describing the opt-in
active-workspace-only mode and explicitly noting that multi-workspace display
remains the default.

Do not bump `VERSION` or individual manifests during implementation. If this
slice is selected for publication, release it on the next approved beta line
(for example `0.1.0-beta.4`) through `scripts/release-version`; do not republish
`0.1.0-beta.3` with changed contents. Regenerate the release inventory during
normal release preparation if required by the release workflow.

## Validation

Repository checks:

```bash
python3 -m json.tool lacuna.workspaces/manifest.json
python3 -m pytest tests/test_manifest_contracts.py \
  tests/test_qml_behavior_workspace_bar_style.py
./scripts/check.sh
scripts/release-inventory --check
git diff --check
```

Live Omarchy validation is required before calling the user-visible behavior
fixed or shipped:

```bash
./scripts/dev deploy lacuna.workspaces
```

Then verify in Omarchy Settings and the running shell:

1. Existing or omitted settings still show the current multi-workspace group.
2. Enabling the option immediately collapses the widget to one active button.
3. Switching workspaces by keyboard replaces the displayed number, including a
   workspace above `workspaceCount`.
4. Disabling the option restores the previous count and dynamic-extra behavior.
5. Horizontal and vertical bars recompute their occupied dimensions correctly.
6. The setting survives an Omarchy shell restart.
7. The deploy helper confirms the installed plugin matches the checkout after
   rescan and restart.

## Acceptance Criteria

- `activeWorkspaceOnly` is discoverable in Omarchy Settings and defaults to
  `false`.
- Default rendering remains the existing multi-workspace display.
- Enabled rendering contains exactly the currently focused workspace.
- Existing count and dynamic-extra preferences return unchanged when the mode
  is disabled.
- Automated behavior and manifest tests pass.
- The changed plugin is deployed and validated in the live shell before the
  feature is reported as shipped.

## Product-Test Follow-up

Collect feedback on discoverability, bar-space savings, multi-monitor behavior,
and whether a single active button remains useful as a clickable control. A
default flip is a separate product decision and must not be bundled into this
hotfix.
