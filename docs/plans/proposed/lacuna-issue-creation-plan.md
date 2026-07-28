# Lacuna Omarchy Plugins Issue Creation Plan

Status: draft

## Creation Method

Once execution is requested, create one GitHub issue per fixable behavior using `gh issue create`:

```bash
gh issue create --repo OldJobobo/lacuna-omarchy-plugins --title "<title>" --label bug --body-file "<temp-body-file>"
```

Use one unique temporary body file per issue, for example:

```bash
/tmp/lacuna-issue-<short-slug>.md
```

After each issue is created, capture the URL printed by `gh issue create` and report the final title-to-URL mapping.

## Issue Drafts

### Issue 1: Persist per-style bar layout settings in Lacuna settings state

```md
**Plugin(s):**
lacuna.menu, lacuna.state, lacuna.bar

**Suite version:** 0.1.0

**Omarchy / Quickshell version:** not captured during static validation

## What happened

Static validation found that the Lacuna settings schema tracks the active `designStyle`, but does not consistently persist per-style bar layout settings. This affects the settings services in `lacuna.menu/services/LacunaSettings.qml` and `lacuna.state/Service.qml`, where normalized settings should retain style-specific configuration such as Lacuna, Omarchy, and Material bar presets.

Without a persisted `designStyles` object, changing design styles can lose or ignore the layout configuration associated with each style.

## What you expected

Settings state should include and normalize per-style design settings so each supported design style can retain its own bar layout and related preset data.

Expected behavior:

- `designStyles` exists in default settings data.
- Supported styles such as `lacuna`, `omarchy`, and `material` have stable normalized entries.
- Existing aliases such as `stylePresets` or `designStylePresets`, if supported, are normalized into the canonical settings shape.
- Switching design styles does not discard or ignore saved per-style bar layout data.

## Steps to reproduce

1. Inspect `lacuna.menu/services/LacunaSettings.qml` and `lacuna.state/Service.qml`.
2. Check the default settings object and normalization path for per-style bar layout state.
3. Observe that static validation expects style-specific bar layout persistence but the settings contract does not consistently represent it.

## Shell logs / QML errors

Static validation finding; no shell logs captured.
```

### Issue 2: Normalize per-style bar layout entries consistently across menu and state services

```md
**Plugin(s):**
lacuna.menu, lacuna.state, lacuna.bar

**Suite version:** 0.1.0

**Omarchy / Quickshell version:** not captured during static validation

## What happened

Static validation found that per-style bar layout data needs a canonical normalization path in both `lacuna.menu/services/LacunaSettings.qml` and `lacuna.state/Service.qml`. The affected configuration shape includes nested style presets with bar layout sections such as `left`, `center`, and `right`, plus optional bar metadata such as `centerAnchor`.

If these paths do not normalize the same way in both services, persisted settings can drift between the menu settings UI and the state service.

## What you expected

Both services should normalize the same per-style bar layout shape into one canonical representation.

Expected behavior:

- The menu settings service and state service expose matching normalization behavior.
- Bar layout sections are normalized as arrays for `left`, `center`, and `right`.
- Entries with valid IDs are preserved.
- Unsupported or invalid values are ignored or rejected consistently.
- Optional fields such as `centerAnchor` are preserved when valid.

## Steps to reproduce

1. Inspect `lacuna.menu/services/LacunaSettings.qml`.
2. Inspect `lacuna.state/Service.qml`.
3. Compare how each service handles per-style bar layout settings.
4. Observe any missing or inconsistent normalization paths for nested design-style bar layout data.

## Shell logs / QML errors

Static validation finding; no shell logs captured.
```

### Issue 3: Preserve JSON-safe metadata on bar layout entries instead of dropping valid fields

```md
**Plugin(s):**
lacuna.menu, lacuna.state, lacuna.bar

**Suite version:** 0.1.0

**Omarchy / Quickshell version:** not captured during static validation

## What happened

Static validation found that bar layout entry normalization needs to preserve valid JSON-safe entry metadata, not only the entry ID. Bar layout entries may need additional fields for plugin configuration, display behavior, or future layout metadata.

If normalization keeps only `id`, valid entry-level configuration can be silently dropped when settings are loaded, saved, or migrated.

## What you expected

Bar layout entry normalization should preserve JSON-safe metadata fields while still rejecting unsupported values.

Expected behavior:

- `id` remains required for object-form layout entries.
- Additional string, boolean, finite number, null, array, and object values are preserved recursively.
- Non-JSON-safe values such as functions, undefined values, or non-finite numbers are omitted or rejected consistently.
- Persisted settings do not silently lose valid entry-level configuration.

## Steps to reproduce

1. Inspect the bar layout entry normalization path in `lacuna.menu/services/LacunaSettings.qml` and `lacuna.state/Service.qml`.
2. Provide or inspect an object-form layout entry with an `id` and additional JSON-safe metadata fields.
3. Observe whether normalization preserves the additional metadata or drops it.

## Shell logs / QML errors

Static validation finding; no shell logs captured.
```

### Issue 4: Handle string-form bar layout entries consistently or reject them explicitly

```md
**Plugin(s):**
lacuna.menu, lacuna.state, lacuna.bar

**Suite version:** 0.1.0

**Omarchy / Quickshell version:** not captured during static validation

## What happened

Static validation found inconsistent handling of string-form bar layout entries. Existing tests did not prove that string-form entries are intended to be supported, so this should not be phrased as a confirmed runtime failure.

The affected behavior is the normalization contract for bar layout entries in per-style bar settings. Object-form entries with an `id` can be normalized, but string-form entries need a clear policy.

## What you expected

The settings contract should either normalize and support string-form entries consistently, or reject them explicitly with a clear validation error.

Expected behavior should be one of:

- String-form entries such as `"lacuna.clock"` are normalized into object-form entries such as `{ "id": "lacuna.clock" }`; or
- String-form entries are rejected explicitly and documented as unsupported.

Either outcome is acceptable as long as the behavior is consistent across services and tests.

## Steps to reproduce

1. Inspect the bar layout entry normalization path in `lacuna.menu/services/LacunaSettings.qml` and `lacuna.state/Service.qml`.
2. Check how entries in `left`, `center`, or `right` sections behave when represented as strings instead of objects.
3. Observe that the expected contract for string-form entries is not explicit or consistently normalized.

## Shell logs / QML errors

Static validation finding; no shell logs captured.
```

### Issue 5: Do not collapse active bar items solely because the loaded item reports visible false

```md
**Plugin(s):**
lacuna.bar

**Suite version:** 0.1.0

**Omarchy / Quickshell version:** not captured during static validation

## What happened

Static validation found that `lacuna.bar/OmarchyBar.qml` can treat a loaded bar item as not visible solely because `activeItem.visible` is false. The affected logic is the bar slot content visibility and natural-size calculation around the active loaded item.

Some loaded QML items can still expose meaningful implicit dimensions even when their `visible` property is false or managed indirectly by a loader, wrapper, animation, or parent. If the slot depends only on `activeItem.visible`, it can collapse the item to zero width or height even though the item has valid implicit size.

## What you expected

A bar slot should remain measurable when the loaded active item has valid implicit dimensions, unless the item is explicitly absent or has no meaningful size.

Expected behavior:

- The slot checks the active item's implicit width and height.
- The slot does not collapse solely because `activeItem.visible` is false when implicit dimensions are present.
- Natural width and height use numeric implicit dimensions safely.
- Overflow and slot sizing remain stable for loaded widgets.

## Steps to reproduce

1. Inspect `lacuna.bar/OmarchyBar.qml`.
2. Find the active-item content visibility and natural-size calculations.
3. Load or inspect a bar item whose `visible` property may be false while implicit dimensions are still present.
4. Observe that static validation flags the slot as collapsible under that condition.

## Shell logs / QML errors

Static validation finding; no shell logs captured.

This issue also covers the related static-validation finding where the same root cause appears to produce collapsed or missing overflow/slot content when the active item has measurable implicit size but is treated as invisible.
```

### Issue 6: Add contract tests for bar slot measurement and settings normalization regressions

```md
**Plugin(s):**
lacuna.bar, lacuna.menu, lacuna.state

**Suite version:** 0.1.0

**Omarchy / Quickshell version:** not captured during static validation

## What happened

Static validation found several settings and bar-slot behaviors that are contract-sensitive but easy to regress without explicit tests. The affected areas include per-style settings normalization, bar layout entry normalization, and `OmarchyBar.qml` active-item measurement.

Without contract tests, fixes for these behaviors can drift between `lacuna.menu`, `lacuna.state`, and `lacuna.bar`.

## What you expected

The test suite should include static contract coverage for the expected settings and bar-slot behavior.

Expected coverage:

- `designStyles` exists in default settings data.
- Per-style bar settings are normalized by both the menu settings service and state service.
- Bar layout entry normalization has a documented policy for object-form and string-form entries.
- JSON-safe metadata preservation is covered if object-form metadata is supported.
- `OmarchyBar.qml` does not use only `activeItem.visible` as the slot content visibility source.
- Active item implicit width and height are included in slot visibility and natural-size calculations.

## Steps to reproduce

1. Inspect `tests/test_qml_contracts.py`.
2. Check coverage for settings normalization and `OmarchyBar.qml` slot measurement behavior.
3. Observe that the static validation findings need explicit regression coverage to prevent future drift.

## Shell logs / QML errors

Static validation finding; no shell logs captured.
```

## Assumptions

- Keep each issue focused on one fixable behavior.
- Use only the existing `bug` label.
- Do not create a separate issue for finding 7 because it is the same root cause as finding 5.
- The issue for finding 5 explicitly mentions that it also covers the related finding 7 symptom.
- Each issue includes enough static-validation evidence to be actionable without needing the original transcript:
  - affected plugin(s)
  - relevant file/path/function/component where known
  - observed behavior
  - expected behavior
  - why it is likely fixable
- Do not invent shell logs, runtime QML errors, Omarchy version, or Quickshell version.

## Special Wording for Issue 4

Phrase issue 4 neutrally because string-form entry support was not proven by existing tests.

Recommended framing:

> Static validation found inconsistent handling of string-form entries. Either normalize and support string-form entries consistently, or reject them explicitly with a clear validation error.

Avoid stronger claims such as:

> String-form entries are broken.

unless runtime behavior or tests prove that string-form entries are intended to work and currently fail.

## Finding 5 / Finding 7 Consolidation

Do not open a separate issue for finding 7.

The finding 5 issue includes this consolidation note:

```md
This issue also covers the related static-validation finding where the same root cause appears to produce collapsed or missing overflow/slot content when the active item has measurable implicit size but is treated as invisible.
```

## Execution Checklist

1. Prepare one temp body file per issue.
2. Verify each body matches the repo bug report template fields.
3. Confirm each issue uses only the `bug` label.
4. Create each issue with:

   ```bash
   gh issue create --repo OldJobobo/lacuna-omarchy-plugins --title "<title>" --label bug --body-file "<temp-body-file>"
   ```

5. Capture every created issue URL.
6. Report the created issues as:

   ```md
   - <title>: <issue URL>
   ```
