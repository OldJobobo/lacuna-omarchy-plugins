# Lacuna Bar Size Mode Plan

Status: updated for the current repository state. This is still a plan; the
bar-size mode service and UI control are not implemented yet.

## Goal

Let Lacuna offer a fast `theme` / `compact` / `full` bar-height control while
respecting the current Omarchy shell model, where bar size is owned by the
active theme's `shell.toml`.

The key design rule is separation of concerns:

1. Omarchy themes own default bar dimensions through `[bar]` in `shell.toml`.
2. Lacuna may store a user override intent.
3. Lacuna's existing `compact` setting remains Lacuna UI density only.

## Current Omarchy Model

The current shell reads bar dimensions from the active generated theme file:

```text
~/.config/omarchy/current/theme/shell.toml
```

The relevant keys are:

```toml
[bar]
size-horizontal = 26
size-vertical = 28
```

Omarchy shell then exposes the resolved size to bar widgets as `bar.barSize`.
Lacuna widgets should continue to derive their layout from that injected value
instead of calculating the shell bar height independently.

Normal Omarchy theme design still belongs to the theme layer. When designing or
auditing theme palettes, shell colors, and visual coherence, use the
`omarchy-theme-design` skill:

```text
/home/oldjobobo/.codex/skills/omarchy-theme-design/SKILL.md
```

That skill's constraint matters here: normal themes may define theme values, but
they should not be expected to provide Lacuna widget behavior, panel structure,
or runtime control logic.

## Current Repo State

The repo has moved past the original scaffold. The relevant current files are:

1. `plugins/omarchy.lacuna-menu/Menu.qml`
   - Thin entry point that instantiates `menu/MenuWindow.qml`.
2. `plugins/omarchy.lacuna-menu/menu/MenuWindow.qml`
   - Main menu surface and settings flyout host.
   - Owns `lacunaSettings`, `compactState`, `sidebarState`, `menuTheme`,
     `commands`, `registry`, and action dispatch.
   - Already has `resolvedOmarchyPath()` and `shellIpcCommand(target, method,
     args)`, which build explicit `OMARCHY_PATH=... <omarchy>/bin/omarchy-shell`
     commands.
   - Already derives panel offsets from injected shell/bar state through
     `currentBarSize()`, `topBarHeight()`, and `barBottomY`.
3. `plugins/omarchy.lacuna-menu/services/LacunaSettings.qml`
   - Owns `~/.config/omarchy/lacuna/settings.json`.
   - Current defaults are `version`, `designStyle`, `colorProfile`, `compact`,
     `customQuickLaunchApps`, `customQuickLaunchNames`, `preferredApps`, and
     `sidebar`.
4. `plugins/omarchy.lacuna-menu/services/CompactState.qml`
   - Owns only Lacuna UI density.
   - Reads and writes `settings.data.compact`.
5. `plugins/omarchy.lacuna-menu/services/Theme.qml`
   - Already watches `colors.toml`, `shell.toml`, and `theme.name` under
     `~/.config/omarchy/current/theme`.
   - Parses string-valued shell roles for Lacuna colors, but does not parse or
     write `[bar]` dimensions.
6. `plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml`
   - Current settings UI is a right-opening attached flyout.
   - The `layout` section currently contains Density, Sidebar Display, Window
     Mode, and Corner Pieces rows.
   - Segment rows already exist and are used for Design Style and desktop clock
     anchor controls.
7. `plugins/omarchy.lacuna-menu/settings/SettingsRow.qml`
   - Already supports `segments`, `toggle`, `button`, `value`, and `nav`
     controls.
8. `plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml`
   - Supplies menu/settings metadata and actions.
   - Current quick preferences still call the Lacuna density action
     `toggle-bar-density`; that name is now misleading but still means Lacuna UI
     density.
9. `plugins/omarchy.lacuna-compact-pill/scripts/compact-state`
   - Separate bar widget helper for toggling Lacuna UI density from the bar.
   - It preserves the settings JSON shape it loads, so adding `barSizeMode` and
     `barSizeSnapshot` should not require changes unless the script's fallback
     defaults need to advertise the new keys.
10. `config/settings.example.json`
    - Example Lacuna runtime settings file. It should be updated with the new
      defaults when implementation lands.

There is no `BarSizeMode.qml` service yet, and no settings UI exposes
`barSizeMode` yet.

## Chosen Design

Add a new Lacuna setting:

```json
{
  "barSizeMode": "theme"
}
```

Supported values:

1. `theme`: do not override the active Omarchy theme bar size.
2. `compact`: set the active generated theme to `size-horizontal = 26` and
   `size-vertical = 28`.
3. `full`: set the active generated theme to `size-horizontal = 32` and
   `size-vertical = 34`.

The setting lives in Lacuna runtime state:

```text
~/.config/omarchy/lacuna/settings.json
```

It must not be added to Omarchy bar-widget manifest schemas because it is not a
per-widget option. It controls the host bar geometry.

`compact` remains a Lacuna density setting. To reduce future confusion, new code
and labels should call the existing density action "Lacuna Density" or
`toggle-lacuna-density`; keeping `toggle-bar-density` as an internal
compatibility alias is acceptable during the first implementation pass.

## Runtime Behavior

Implement a dedicated Lacuna service, for example `BarSizeMode.qml`, rather
than folding this into the existing compact-density service.

The service should:

1. Read and normalize `barSizeMode` from `LacunaSettings.qml`.
2. Watch the active theme name and generated `shell.toml`.
3. Patch only the generated active file:

   ```text
   ~/.config/omarchy/current/theme/shell.toml
   ```

4. Never modify source theme directories under `~/.config/omarchy/themes/` or
   `~/.local/share/omarchy/themes/`.
5. Call the current shell command path with explicit `OMARCHY_PATH`, matching
   `MenuWindow.qml::shellIpcCommand(...)`, then ask the shell to reload theme
   data.
6. Avoid write loops by no-oping when the file already contains the desired
   values.

Before applying `compact` or `full` for a theme, snapshot the theme's original
bar values in Lacuna settings. The snapshot only needs enough data to restore
the current theme:

```json
{
  "barSizeSnapshot": {
    "themeName": "theme-name",
    "sizeHorizontal": 32,
    "sizeVertical": 34
  }
}
```

When `barSizeMode` returns to `theme`, restore the snapshotted values, reload
the shell theme, and clear the snapshot for that theme.

If the theme changes while `barSizeMode` is `compact` or `full`, take a fresh
snapshot for the new theme before applying the selected override.

`BarSizeMode.qml` can either duplicate the current `Theme.qml` path helpers or
receive `themeService` and `omarchyPath` as properties from `MenuWindow.qml`.
Prefer the property-injection approach if it keeps path construction and active
theme detection aligned with the existing menu service.

The writer should preserve unrelated `shell.toml` content. It only needs to
replace or insert these two keys inside `[bar]`:

```toml
size-horizontal = 26
size-vertical = 28
```

Use a small, explicit line-based TOML patcher because Quickshell/QML does not
currently expose a TOML writer in this repo. Do not use regex replacement across
the whole file in a way that can touch other sections.

## UI Behavior

Keep the current Lacuna compact-density toggle as a Lacuna layout preference.
It should continue to mean tighter Lacuna spacing and should not edit
`shell.toml`.

Add a separate bar-size control in the Lacuna settings/menu surface:

```text
Bar Size: Theme | Compact | Full
```

For v1, do not add a new topbar widget. The control should live in the Lacuna
menu/settings surface where it can be clearly separated from Lacuna UI density.

In the current settings UI, place this row in
`SettingsWindow.qml::itemsFor("layout")`, near but separate from Density:

```text
Density: Normal | Compact       # existing Lacuna UI density
Bar Size: Theme | Compact | Full # new Omarchy host bar geometry
```

Use a segment control, following the existing Design Style and desktop clock
anchor rows. The row action prefix should be something explicit, such as
`set-bar-size-mode-`.

The compact rail button and `omarchy.lacuna-compact-pill` should continue to
toggle Lacuna density only. They should not become bar-height controls.

## Implementation Notes

Recommended implementation areas:

1. `plugins/omarchy.lacuna-menu/services/LacunaSettings.qml`
   - Add default `barSizeMode: "theme"`.
   - Normalize unknown values back to `theme`.
   - Persist optional `barSizeSnapshot`.
2. `plugins/omarchy.lacuna-menu/services/BarSizeMode.qml`
   - Own file patching, snapshot restore, theme-change reapply, and reload.
3. `plugins/omarchy.lacuna-menu/menu/MenuWindow.qml`
   - Instantiate `BarSizeMode`.
   - Pass `lacunaSettings`, `menuTheme.themeName`, and the resolved Omarchy path
     or shell IPC command helper data.
   - Add action handling for `set-bar-size-mode-theme`,
     `set-bar-size-mode-compact`, and `set-bar-size-mode-full`.
   - Pass the current `barSizeMode` into `MenuRegistry.qml`.
4. `plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml`
   - Add `barSizeMode` and helper text/name functions for menu rows that need
     to summarize the mode.
   - Optionally rename new user-facing density labels to "Lacuna Density" while
     leaving the old action string as a compatibility alias.
5. `plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml`
   - Add the `Theme | Compact | Full` segment control to the `layout` section.
   - Keep existing compact-density labels scoped to Lacuna UI density.
6. `plugins/omarchy.lacuna-menu/settings/SettingsRow.qml`
   - No structural change should be needed; segment controls already exist.
7. `plugins/omarchy.lacuna-menu/services/Theme.qml`
   - No write behavior should be added here unless the bar-size service needs a
     shared helper.
   - Keep theme color parsing separate from host bar-size mutation.
8. `config/settings.example.json`
   - Add `barSizeMode: "theme"`.
   - Optionally include an empty or omitted `barSizeSnapshot`; prefer omitted in
     the example because snapshots are runtime-only.
9. `plugins/omarchy.lacuna-compact-pill/scripts/compact-state`
   - Verify it preserves unknown settings keys when toggling `compact`.
   - Add fallback defaults for `barSizeMode` only if users will inspect emitted
     state or if tests are added around default settings shape.

The shell command helper should follow the current plugin pattern: set
`OMARCHY_PATH` explicitly and call the absolute `omarchy-shell` path rather
than relying on inherited environment.

Current repo note: `MenuWindow.qml::shellIpcCommand(...)` already implements the
explicit path pattern. Reuse that shape instead of adding a second ad hoc command
convention.

## Suggested Implementation Order

1. Extend settings normalization.
   - Add `barSizeMode` to `defaultData()`.
   - Add `normalizeBarSizeMode(value)`.
   - Preserve a valid `barSizeSnapshot` object when present.
2. Add `BarSizeMode.qml`.
   - Load/watch the generated `shell.toml`.
   - Extract current `[bar]` values for snapshots.
   - Patch only `[bar].size-horizontal` and `[bar].size-vertical`.
   - Restore the snapshot when mode returns to `theme`.
   - Reload shell theme data after writes.
3. Wire the service into `MenuWindow.qml`.
   - Instantiate beside `CompactState`, `SidebarState`, and `Theme`.
   - Add mode action dispatch.
   - Ensure theme changes while overridden reapply the chosen mode.
4. Add settings UI.
   - Add registry state/helper strings.
   - Add the Layout row in `SettingsWindow.qml`.
5. Update examples and labels.
   - Add `barSizeMode` to `config/settings.example.json`.
   - Clarify Density labels where needed.
6. Run static validation and then manual Omarchy smoke tests.

## Acceptance Criteria

1. `barSizeMode` defaults to `theme`.
2. `theme` mode leaves the active theme's bar size untouched.
3. `compact` mode updates active generated `shell.toml` to `26` / `28`.
4. `full` mode updates active generated `shell.toml` to `32` / `34`.
5. Returning to `theme` restores the snapshotted theme values.
6. Theme switching reapplies `compact` or `full` after the new active theme is
   generated.
7. Lacuna compact-density state does not control Omarchy bar height.
8. Existing Lacuna widgets continue to adapt through injected `bar.barSize`.
9. No source theme directory is modified.
10. No second Quickshell process is started.
11. Existing Lacuna Density controls keep changing only `settings.compact`.
12. The new settings row uses the existing segment-control presentation and does
    not require a new bar widget.

## Test Plan

Run static checks:

```bash
qmllint $(rg --files plugins -g '*.qml')
for f in plugins/*/manifest.json; do python3 -m json.tool "$f" >/dev/null || exit 1; done
```

Also inspect settings defaults:

```bash
python3 -m json.tool config/settings.example.json >/dev/null
rg -n "barSizeMode|barSizeSnapshot|toggle-bar-density|toggle-lacuna-density" plugins/omarchy.lacuna-menu plugins/omarchy.lacuna-compact-pill config
```

Manual Omarchy shell checks:

1. Start in `theme` mode and confirm `shell.toml` remains unchanged.
2. Select `compact`; confirm `[bar]` becomes `26` / `28` and the visible bar
   height shrinks after shell theme reload.
3. Select `full`; confirm `[bar]` becomes `32` / `34` and the visible bar height
   grows after shell theme reload.
4. Switch Omarchy themes while in `compact` or `full`; confirm the selected
   Lacuna override is applied to the newly generated active theme.
5. Select `theme`; confirm the snapshotted theme values are restored.
6. Toggle Lacuna compact-density mode; confirm it changes Lacuna spacing only
   and does not edit `shell.toml`.
7. Toggle the compact pill bar widget; confirm it changes Lacuna density only
   and does not edit `shell.toml`.
8. Restart Omarchy shell; confirm `barSizeMode`, any current override, and the
   Lacuna Density setting survive restart with the expected meanings.
