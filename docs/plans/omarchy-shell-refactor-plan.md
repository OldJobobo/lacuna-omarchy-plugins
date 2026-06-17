# Lacuna Omarchy Shell Refactor Plan

Status: superseded by the current plugin-suite architecture

## Goal

Move Lacuna from a standalone Quickshell experiment into the future
`omarchy-shell` architecture without losing the parts that make Lacuna useful:
the slim bar rhythm, the left command sidebar, the Lacuna visual language, and
the local status widgets.

The target is not to run a second `quickshell -p shell.qml` process. The target
is to make Lacuna load inside Omarchy's single long-running shell as plugin
surfaces and bar widgets.

The implementation target is a new external plugin repository, not an in-place
refactor of this standalone Lacuna repo. This repo should remain the prototype
and source reference while the new repo carries only plugin-mode code.

The plugin repo should reduce duplication with `omarchy-shell`, not recreate a
parallel shell inside it. It should reuse Omarchy's existing targets, services,
widgets, and IPC surfaces wherever they already cover the behavior. Only port
or replicate a Lacuna piece when it provides a distinct interaction, visual
treatment, or workflow that Omarchy does not already have.

## Omarchy Shell Model

The future Omarchy shell lives under:

```text
../omarchy/shell/
```

Important constraints from that implementation:

1. `shell.qml` is the only `ShellRoot`.
2. First-party Omarchy plugins live under `shell/plugins/<id>/` in the installed Omarchy source.
3. User plugins live under `~/.config/omarchy/plugins/<id>/`.
4. Every plugin has a `manifest.json`.
5. Plugin entry points are `Item`s, not `ShellRoot` or standalone app roots.
6. Panel, overlay, and menu plugins expose `open(payloadJson)` and `close()`.
7. Bar widgets expose an `Item` with `implicitWidth` and `implicitHeight`.
8. Bar widgets receive injected `bar`, `moduleName`, and `settings`.
9. Shared registries and services are owned by the host and injected into
   plugins.
10. IPC goes through `omarchy-shell`, not ad hoc process launches.

## Current Omarchy Compatibility Notes

The live Omarchy shell now owns several pipelines that affect Lacuna:

1. `~/.config/omarchy/shell.json` is authoritative for plugin enablement,
   placement, and per-entry settings. Manifest `schema` fields are the correct
   way to expose bar-widget options in Omarchy Settings.
2. Bar font selection is resolved through fontconfig and injected as
   `bar.fontFamily`; do not store a bar font in Lacuna config.
3. Theme colors include an explicit `accent` key. Lacuna should prefer that
   key and fall back to older numbered colors only when needed.
4. The first-party image picker is available through
   `omarchy.image-picker` / `image-selector`; do not launch or clean up the old
   standalone `background-switcher.qml`.
5. The first-party menu can be extended with
   `~/.config/omarchy/extensions/omarchy-menu.jsonc` when Lacuna only needs
   command entries. Keep `lacuna.menu` for the distinct sidebar UI.
6. Use current commands such as `omarchy restart shell`,
   `omarchy theme switcher`, `omarchy theme bg-switcher`, and
   `omarchy style corners sharp|round`.

### Upstream Settings Finding

The current Omarchy Settings panel is schema-driven. It reads each discovered
widget/plugin manifest and builds the settings UI from the manifest metadata
instead of relying on hand-written controls for every module.

For Lacuna bar widgets, the important manifest fields are:

```json
"barWidget": {
  "defaults": {
    "maxTextLength": 34,
    "sweepOnPlaying": true
  },
  "schema": [
    { "key": "maxTextLength", "type": "integer", "label": "Maximum text length" },
    { "key": "sweepOnPlaying", "type": "boolean", "label": "Sweep text while playing" }
  ]
}
```

Omarchy Settings turns those schema rows into controls and writes the selected
values inline to the matching `bar.layout.<section>[]` entry in
`~/.config/omarchy/shell.json`. The widget then receives those values through
its injected `settings` property.

Implications for Lacuna:

1. Keep Lacuna bar-widget settings in `manifest.json`, not in a custom settings
   panel, when the setting is meant to be user-facing in Omarchy Settings.
2. Treat manifest labels, defaults, ranges, and enum option names as user-facing
   UI copy.
3. Use Lacuna-private settings files only for runtime/sidebar state that should
   not be edited from Omarchy Settings.
4. Add or revise widget settings by changing the manifest schema first, then
   reading the injected `settings` object in QML.

## Current Lacuna Shape

Current standalone root:

```text
shell.qml
  LacunaMenuState
  CompactState
  SidebarState
  LacunaBar
  LacunaMenu
```

Current major modules:

```text
LacunaBar.qml                  standalone bar surface
modules/LacunaMenu.qml         wrapper around menu/MenuWindow.qml
modules/menu/*                 sidebar/menu surface
modules/*Pill.qml              bar widgets and status controls
services/*                     local state, theme, command, app catalog
scripts/*                      status helpers
assets/*                       icons and fonts
components/*                   Lacuna primitives
```

This is already close to a plugin layout, but ownership is wrong for
`omarchy-shell`: Lacuna owns the process root and state instances today.
Omarchy needs Lacuna to become loadable components inside its host.

## Reuse Policy

Default rule: use Omarchy-owned surfaces unless Lacuna adds a clearly distinct
workflow, status signal, or visual treatment. A script-backed Lacuna widget
should not replace a native Omarchy module just because it can.

Use Omarchy-owned surfaces for:

1. Shell startup, restart, and IPC.
2. Theme/background selection where the new image picker and shell IPC already
   exist.
3. Native bar widgets that already provide richer functionality:
   - audio
   - network
   - Bluetooth
   - calendar
   - notification center
   - media
   - tray
   - battery
   - idle/update indicators when the native Omarchy behavior is sufficient
4. Shared theme/color data where Omarchy's `Commons/Color.qml` already owns the
   source of truth.

Port Lacuna code when it adds one of these:

1. A visual language Omarchy does not already provide.
2. A workflow that is meaningfully different from Omarchy's current surface.
3. A small status pill that does not exist as a native Omarchy widget.
4. A sidebar-specific behavior that should not live in the generic Omarchy menu.
5. A script-backed experiment that has proven useful enough to graduate from
   `lacuna.script-pill` into its own plugin.

`lacuna.mpris` is included under this exception because the native media
module does not own Lacuna's original per-character sweep animation treatment.

The sidebar is the intentional exception. It overlaps with `omarchy.menu`, but
it is a different interaction model: persistent left rail, docked/overlay mode,
corner-piece geometry, Lacuna command hierarchy, and fast access to shell/layout
controls. It should still call Omarchy shell targets where possible instead of
re-implementing their internals.

## Target Plugin Split

### `lacuna.menu`

Type: `menu`

Use `menu` for the first implementation because Lacuna is a command/navigation
surface, even though it is visually a left sidebar. Reconsider `panel` only if
Omarchy Settings or plugin categorization treats `menu` plugins too narrowly.

Source:

```text
modules/menu/MenuWindow.qml
modules/menu/MenuSurface.qml
modules/menu/MenuContent.qml
modules/menu/MenuHeader.qml
modules/menu/MenuRail.qml
modules/menu/MenuRegistry.qml
modules/LacunaMenuItem.qml
components/*
services/AppCatalog.qml
services/CommandRunner.qml
services/LacunaMenuState.qml
services/SidebarState.qml
```

Required changes:

1. Convert `MenuWindow.qml` root from `Scope` to `Item`.
2. Add plugin-injected properties:
   - `property string omarchyPath`
   - `property var shell`
   - `property var manifest`
   - `property var pluginRegistry`
3. Add lifecycle methods:
   - `open(payloadJson)`
   - `close()`
4. When the sidebar closes itself through keyboard, command, or menu actions,
   call `shell.hide("lacuna.menu")` so the Omarchy host clears its
   open-plugin state. Guard this path so host-initiated `close()` does not
   recurse.
5. Replace restart/self-update commands that assume standalone Lacuna.
6. Replace actions that launch legacy standalone helpers with Omarchy shell IPC
   targets where those targets exist.
7. Keep sidebar runtime state in Lacuna's own state/settings files, but expose
   Omarchy-visible widget preferences through manifest schemas so they persist
   inline on the matching `shell.json` entries.

Current Omarchy recommendation: `shell.json` is the authoritative file for
plugin enablement, placement, and per-entry settings. Use Lacuna-private files
only for state that Omarchy Settings should not own.

Starter manifest:

```json
{
  "schemaVersion": 1,
  "id": "lacuna.menu",
  "name": "Lacuna Menu",
  "version": "0.1.0",
  "author": "Lacuna",
  "description": "Left command sidebar for Omarchy shell",
  "kinds": ["menu"],
  "activation": "on-demand",
  "keepLoaded": true,
  "entryPoints": { "menu": "Menu.qml" }
}
```

### Lacuna Bar Widgets

Type: `bar-widget`

Candidate widgets:

```text
Workspaces.qml
MprisPill.qml
ScriptPill.qml
ClockPill.qml
ThemePill.qml
WallpaperPill.qml
AudioPill.qml
BatteryPill.qml
SystemStats.qml
TemperaturePill.qml
CompactPill.qml
Tray.qml
```

Not every candidate should be ported. This list is an inventory, not a target
state. If Omarchy already has a better native widget, Lacuna should either style
or configure that widget instead of carrying a duplicate.

Required changes:

1. Each widget root must be an `Item` with stable `implicitWidth` and
   `implicitHeight`.
2. Accept Omarchy bar injection:
   - `property var bar`
   - `property string moduleName`
   - `property var settings`
3. Replace direct `theme` property wiring with either:
   - values from `bar.foreground`, `bar.background`, `bar.urgent`, or
   - a Lacuna style adapter.
4. Replace local command runners with `bar.run(command)` where practical.
5. Replace `LACUNA_PATH` and `PWD` assumptions with plugin-relative script
   paths.

Starter widget manifest:

```json
{
  "schemaVersion": 1,
  "id": "lacuna.script-pill",
  "name": "Lacuna Script Pill",
  "version": "0.1.0",
  "author": "Lacuna",
  "description": "Lacuna-styled script status pill",
  "kinds": ["bar-widget"],
  "activation": "on-demand",
  "entryPoints": { "barWidget": "Widget.qml" },
  "barWidget": {
    "displayName": "Lacuna Script",
    "category": "Lacuna",
    "allowMultiple": true,
    "defaults": {
      "script": "",
      "interval": 30000,
      "maxTextLength": 32
    },
    "schema": [
      { "key": "script", "type": "string", "label": "Script" },
      { "key": "interval", "type": "number", "label": "Interval" },
      { "key": "maxTextLength", "type": "number", "label": "Max text length" }
    ]
  }
}
```

Initial recommendation: port only the highest-value widgets first:

```text
ScriptPill
CompactPill
SystemStats
TemperaturePill
```

`ThemePill` and `WallpaperPill` are not first-pass ports. If they return, they
should act as Lacuna-styled launch/status facades over Omarchy's shell image
picker and theme/background commands, not carry a separate selector path.

Omarchy already has rich equivalents for media, audio, network, Bluetooth,
calendar, notification center, battery, idle/update indicators, and system
tray. Lacuna should not duplicate those by default. Duplicate only if the
Lacuna version is visually or behaviorally important enough to justify the
maintenance cost.

### Reuse Matrix

| Lacuna area | First-pass direction |
|-------------|----------------------|
| Sidebar/menu | Port as `lacuna.menu`, but delegate actions to Omarchy targets. |
| Shell restart/update controls | Use `omarchy restart shell` and Omarchy update commands. |
| Theme/background selection | Reuse Omarchy shell image picker and theme/background commands. |
| Audio/network/Bluetooth/media/calendar/battery/tray | Reuse Omarchy native widgets. |
| Notifications | Reuse Omarchy notification service and targets. |
| Script-backed status pills | Keep `script-pill` as the experiment path; promote only proven non-native workflows. |
| Lacuna visual primitives | Keep plugin-local at first; consider style-layer extraction later. |

### Lacuna Bar as a Whole

Type: not a normal third-party plugin

`omarchy-shell` reserves `kind: "bar"` for the first-party host bar. A complete
Lacuna bar replacement is possible, but it is a larger Omarchy source change,
not a simple user plugin.

Options:

1. Port Lacuna as a set of bar widgets for the existing Omarchy bar.
2. Add a first-party alternate `lacuna.bar` inside Omarchy.
3. Refactor Omarchy's bar host to support selectable bar engines.

Initial recommendation: choose option 1 for the first implementation branch.
It fits the current plugin contract and avoids fighting the host.

### Topbar Styling Boundary

Omarchy's current bar supports position, layout, native widgets, third-party
bar widgets, and theme-derived colors. It does not currently expose a general
style API for replacing native widget chrome, bar height, padding, radius,
opacity, or typography from a plugin.

First-pass Lacuna topbar work should therefore be limited to Lacuna-styled
bar widgets that live inside the existing Omarchy bar. A full Lacuna topbar
skin for Omarchy's native widgets requires an `omarchy-shell` source change,
such as adding a bar style contract to the host and teaching native widgets to
read it.

## Proposed Repository Layout

Create a new repository outside this Lacuna folder, for example:

```text
lacuna-omarchy-plugins/
  README.md
  lacuna.script-pill/
    manifest.json
    Widget.qml
    components/
    services/
      scripts/
    lacuna.compact-pill/
      manifest.json
      Widget.qml
      components/
      services/
    lacuna.system-stats/
      manifest.json
      Widget.qml
      components/
      services/
    lacuna.temperature/
      manifest.json
      Widget.qml
      components/
      services/
    lacuna.menu/
      manifest.json
      Menu.qml
      menu/
      components/
      services/
      assets/
  config/
    settings.example.json
  docs/
    migration-notes.md
```

This Lacuna repo remains a reference source for:

```text
modules/
services/
components/
assets/
scripts/
```

Do not make `shell.qml`, `run.sh`, `LacunaBar.qml`, or the standalone process
root part of the plugin repo. Copy behavior selectively and adapt it to the
Omarchy plugin contract as it enters the new repository.

First-party Omarchy integration can be considered later, but it is explicitly
not the first implementation target.

Install/test shape for user plugins:

1. Copy or symlink each plugin directory from the new repo into
   `~/.config/omarchy/plugins/<plugin-id>/`.
2. Run `omarchy plugin rescan` or restart the shell.
3. Enable the plugin through Omarchy Settings or by adding its id to
   `~/.config/omarchy/shell.json`.
4. Keep bar-widget options in the manifest schema and inline `shell.json`
   settings. Keep Lacuna runtime/app state in
   `~/.config/omarchy/lacuna/settings.json` only when it is not an Omarchy
   plugin preference.

## State Migration

Current Lacuna state:

```text
~/.local/state/omarchy/lacuna/compact.state
~/.local/state/omarchy/lacuna/menu.state
~/.local/state/omarchy/lacuna/sidebar.state
```

Lacuna runtime/app state:

```json
{
  "version": 1,
  "compact": false,
  "sidebar": {
    "collapsed": false,
    "exclusive": true,
    "cornerPieces": true
  }
}
```

`compact` is retained as the compatibility key for Lacuna UI density. It does
not control Omarchy's topbar height.

Recommended path:

```text
~/.config/omarchy/lacuna/settings.json
```

`~/.config/omarchy/shell.json` should contain the Omarchy plugin entry needed
to enable or place Lacuna. For bar widgets, it may also contain settings from
the plugin manifest schema:

```json
{
  "bar": {
    "layout": {
      "left": [
        { "id": "lacuna.script-pill", "script": "scripts/example-status", "interval": 30000 }
      ]
    }
  },
  "plugins": [{ "id": "lacuna.menu" }]
}
```

First pass:

1. Keep current state files for transient runtime state such as menu open/close
   and navigation stack.
2. Add a Lacuna settings service that reads and writes
   `~/.config/omarchy/lacuna/settings.json`.
3. Migrate density/sidebar preferences from the existing state files into the
   Lacuna settings file once.
4. Move bar-widget preferences into manifest schemas instead of a separate
   Lacuna settings service.

Second pass:

1. Add a Lacuna settings surface for compact/sidebar/widget preferences.
2. Optionally expose a launcher from Omarchy Settings that opens Lacuna's
   settings surface.
3. Keep Omarchy Settings responsible only for enabling/disabling Lacuna plugins
   and arranging bar widget placement.

## Path And Command Cleanup

Replace standalone assumptions:

```text
LACUNA_PATH
PWD
quickshell kill -p <lacuna>/shell.qml
setsid <lacuna>/run.sh
```

With plugin-safe equivalents:

```text
manifest.__sourceDir
omarchyPath
omarchy-shell shell hide lacuna.menu
omarchy restart shell
```

Also replace legacy image selector reset paths with the new Omarchy shell image
picker IPC where possible.

## Implementation Phases

### Phase 1: Topbar Plugin Modules

Start with Lacuna's topbar features, implemented as Omarchy `bar-widget`
plugins inside the existing Omarchy bar host. This proves the plugin path,
keeps the visible Lacuna rhythm, and avoids taking on sidebar layer-shell
behavior before the basic module contract is stable.

Do this work in the new external plugin repository. Use this Lacuna repo only
as the source reference for the original QML, scripts, services, and styling.

Initial module targets:

1. `lacuna.script-pill`
   - Source: `modules/ScriptPill.qml`
   - Purpose: script-backed status output with Lacuna pill styling.
2. `lacuna.compact-pill`
   - Source: `modules/CompactPill.qml`
   - Purpose: toggle Lacuna UI density through Lacuna's settings service.
3. `lacuna.system-stats`
   - Source: `modules/SystemStats.qml` plus `services/SystemMonitor.qml`
   - Purpose: Lacuna CPU, memory, and disk status treatment.
4. `lacuna.temperature`
   - Source: `modules/TemperaturePill.qml` plus `services/SystemMonitor.qml`
   - Purpose: Lacuna CPU temperature indicator and alert treatment.
5. `lacuna.theme`
   - Source: `modules/ThemePill.qml` plus `services/Theme.qml`
   - Purpose: show the active Omarchy theme, palette tooltip, and theme switcher.
6. `lacuna.wallpaper`
   - Source: `modules/WallpaperPill.qml`
   - Purpose: show the active Omarchy background and background switcher.

Do not port native-equivalent widgets unless the Lacuna behavior is the point.
Workspaces, media, audio, tray, network, Bluetooth, battery, calendar,
notifications, and other already-rich Omarchy widgets should stay Omarchy-native
by default. Keep `script-pill` as the escape hatch for experiments; graduate a
script only after it proves it is a durable Lacuna workflow.

Required work:

1. Create the new external plugin repository.
2. Create one root-level plugin directory per module, named with the plugin id.
3. Add a `manifest.json` with `kinds: ["bar-widget"]` and
   `entryPoints: { "barWidget": "Widget.qml" }`.
4. Wrap each Lacuna module in a plugin-safe `Widget.qml`.
5. Add a small Lacuna topbar style adapter for shared pill dimensions, colors,
   tooltip behavior, and Lacuna-owned density.
6. Use Omarchy bar injection:
   - `bar.foreground`
   - `bar.background`
   - `bar.urgent`
   - `bar.fontFamily`
   - `bar.barSize`
   - `settings`
7. Replace direct `CommandRunner` use with `bar.run(command)` where practical.
8. Replace `LACUNA_PATH` and `PWD` assumptions with `manifest.__sourceDir` or
   plugin-relative paths.
9. Add a sample Lacuna topbar layout snippet for `shell.json` that places the
   new modules and shows inline schema-backed widget settings.

Success criteria:

- At least one Lacuna bar-widget plugin appears in Omarchy Settings.
- The first-pass Lacuna widgets can be added to `bar.layout`.
- Script/status output updates inside the Omarchy bar process.
- Bar-widget settings persist through inline `shell.json` entries where needed.
- No widget starts a second Quickshell process.

### Phase 2: Menu Plugin Wrapper

Status: complete.

Validation:

- `python3 -m json.tool lacuna.menu/manifest.json`
- `qmllint lacuna.menu/Menu.qml lacuna.menu/menu/*.qml lacuna.menu/modules/*.qml lacuna.menu/services/*.qml lacuna.menu/components/*.qml`
- `omarchy plugin rescan`
- `omarchy-shell shell summon lacuna.menu '{}'`
- `omarchy-shell shell hide lacuna.menu`
- `hyprctl layers` before and after hide to confirm the `lacuna-menu` layer is created and removed.

Implemented notes:

- `lacuna.menu` is the hosted sidebar/menu plugin.
- `lacuna.menu-button` is the topbar launcher for the sidebar and
  belongs in `bar.layout.left`, typically after the stock `omarchy` button.

1. Create a plugin-shaped `Menu.qml` wrapper.
2. Move `MenuWindow.qml` behavior behind `open()` and `close()`.
3. Keep the existing left layer-shell `PanelWindow`.
4. Add a `manifest.json` for `lacuna.menu`.
5. Install or link the plugin directory to
   `~/.config/omarchy/lacuna.menu/`.
6. Run `omarchy plugin rescan` or restart the shell.
7. Enable the plugin through Omarchy Settings or add
   `{ "id": "lacuna.menu" }` to `plugins[]` in `shell.json`.
8. Test through `omarchy-shell shell summon`; use standalone harnesses only
   for isolated local development outside the running Omarchy session.

Success criteria:

- `omarchy-shell shell summon lacuna.menu "{}"` opens the sidebar.
- `omarchy-shell shell hide lacuna.menu` closes it.
- Closing the sidebar from inside Lacuna also clears the host open state.
- Sidebar view stack, rail mode, and corner pieces still work.

### Phase 3: Shared Primitive Packaging

Status: complete.

Validation:

- `rg -n 'LACUNA_PATH|PWD|\.\./\.\.|import "/|import components|background-switcher|currentColor' lacuna.menu lacuna.*/assets/tabler docs/plans/omarchy-shell-refactor-plan.md`
- `qmllint lacuna.menu/Menu.qml lacuna.menu/menu/*.qml lacuna.menu/modules/*.qml lacuna.menu/services/*.qml lacuna.menu/components/*.qml`
- `omarchy plugin rescan`
- `omarchy-shell shell summon lacuna.menu '{}'`
- `omarchy-shell shell hide lacuna.menu`
- `hyprctl layers` before and after hide to confirm the `lacuna-menu` layer is created and removed.

1. Move reusable Lacuna primitives into a plugin-local import path.
2. Keep component names stable:
   - `LacunaRect`
   - `LacunaText`
   - `LacunaIconButton`
   - `LacunaStateLayer`
   - `LacunaTokens`
3. Keep helper primitives packaged beside them:
   - `LacunaAnim`
   - `LacunaColorAnim`
4. Add `qmldir` files only if Omarchy import paths require them. Current
   relative imports do not require one.
5. Use Tabler filled SVGs for dense topbar status icons where a filled
   equivalent exists. Store them under each plugin's `assets/tabler/`
   directory, normalize `fill="currentColor"` or `stroke="currentColor"` to
   `#ffffff` for Qt SVG compatibility, and tint them in QML with Omarchy
   colors.
6. Keep branded/non-Tabler SVGs only when Tabler does not provide an equivalent
   brand icon, such as the current Claude asset.

Success criteria:

- Menu plugin loads without relying on Lacuna repo root imports.
- No component import path depends on `PWD`.
- Stable primitive and Tabler icon rules are documented.

### Phase 4: Topbar Module Hardening

Status: complete.

Validation:

- `for f in lacuna.{script-pill,compact-pill,system-stats,temperature}/manifest.json; do python3 -m json.tool "$f" >/dev/null || exit 1; done`
- `qmllint lacuna.script-pill/Widget.qml lacuna.compact-pill/Widget.qml lacuna.system-stats/Widget.qml lacuna.temperature/Widget.qml`
- temperature sensor discovery command returns a readable millidegree value
- `omarchy restart shell`
- `omarchy plugin list`
- `quickshell log --path /home/oldjobobo/.local/share/omarchy/shell --tail 250 --newest`

After the menu and shared primitives are packaged, harden the first-pass
topbar modules and decide whether any additional Lacuna bar features deserve
their own plugin modules.

Implemented notes:

- `ScriptPill` is schema-backed, accepts Omarchy inline settings, and supports
  plugin-relative `scripts/...` commands.
- `CompactPill` is a plugin-local bar widget that toggles Lacuna runtime
  compact state without a second Quickshell process.
- `SystemStats` uses filled Tabler icons for disk, memory, and CPU, and relies
  on injected Omarchy bar colors.
- `TemperaturePill` uses a filled Tabler icon, injected bar colors, schema
  thresholds, and dynamic `/sys/class/hwmon` / `/sys/class/thermal` discovery
  instead of machine-specific sensor paths.
- Additional topbar modules worth considering after this phase: a compact
  style/theme pill and a wallpaper/theme status pill that trigger Omarchy's
  first-party picker pipelines.

Recommended order:

1. `ScriptPill`
2. `CompactPill`
3. `SystemStats`
4. `TemperaturePill`

For each widget:

1. Add `manifest.json`.
2. Add `Widget.qml`.
3. Use `entryPoints: { "barWidget": "Widget.qml" }`.
4. Inject `bar`, `moduleName`, and `settings`.
5. Replace local theme wiring.
6. Validate in Omarchy bar layout.

Success criteria:

- Each Phase 1 widget appears in Omarchy Settings.
- Each widget can be added to `bar.layout`.
- Widget survives shell restart.
- Widget does not start a second Quickshell process.

### Phase 5: Settings Integration

Status: complete in the current plugin pass.

1. Add a Lacuna settings service backed by
   `~/.config/omarchy/lacuna/settings.json`.
2. Expose settings that matter:
   - Lacuna UI density (`compact` compatibility key)
   - Lacuna design style (`lacuna`, `omarchy`, or `material`; legacy `carbon` settings are normalized to `lacuna`)
   - Lacuna color profile (`semantic` or `colorful`)
   - sidebar collapsed
   - sidebar exclusive/overlay
   - corner pieces
3. Use Omarchy Settings and manifest schemas for script path, interval, max
   text length, thresholds, icon visibility, and other bar-widget options.
4. Add a Lacuna-owned settings surface or command path only for state not owned
   by Omarchy Settings.
5. Keep rarely changed visual constants in QML.

Success criteria:

- Omarchy Settings can enable/disable Lacuna plugins.
- Bar-widget preferences persist inline in `shell.json` through Omarchy
  Settings.
- Lacuna runtime/app state persists through Lacuna's own settings file.
- Lacuna-specific state has a clear owner.

Completed notes:

- `lacuna.menu` now uses a shared Lacuna settings service for density
  and sidebar state.
- Lacuna menu/sidebar now keeps `designStyle` separate from `colorProfile`:
  design style controls structure, borders, radius, spacing, state layers, and
  surface treatment while color profile controls color distribution.
- `lacuna.compact-pill` now reads and writes the same
  `~/.config/omarchy/lacuna/settings.json` file.
- Lacuna topbar modules support a global `colorProfile` plus per-widget
  Omarchy Settings overrides.
- Omarchy topbar height remains an upstream shell concern; Lacuna density only
  affects Lacuna-owned UI.

### Phase 6: Document Standalone Boundary

Status: complete in the current plugin pass.

1. Document that this repo is the standalone prototype/reference.
2. Document that the new plugin repo is the primary Omarchy integration path.
3. Replace plugin-mode `Restart Lacuna` actions with `Restart shell`.
4. Replace plugin-mode `Open source` paths with Omarchy-aware paths.
5. Update repository docs/READMEs so users know which path to run or install.

Success criteria:

- The plugin repo is the documented primary path for Omarchy integration.
- This Lacuna repo remains available as the standalone prototype/reference.
- Plugin-mode actions do not point users at obsolete standalone workflows.

Completed notes:

- Root `README.md` documents this repo as the Omarchy plugin integration path.
- Menu runtime actions use `omarchy restart shell` and open the installed plugin
  source path.
- Standalone Lacuna shell controls are kept out of plugin-mode actions.

## Open Questions

1. After the first port, should Lacuna's sidebar keep coexisting with
   `omarchy.menu`, replace it, or become a style variant of it?
2. Should Lacuna keep script-backed status pills where Omarchy already has
   richer native widgets?
3. Should Lacuna's visual primitives become a reusable Omarchy style layer?

## Risks

1. Duplicating Omarchy bar features can create two sources of truth for the same
   status.
2. Splitting Omarchy enablement from Lacuna settings requires clear docs so
   users know which file owns which behavior.
3. Plugin-relative path handling can break scripts and assets if copied by hand.
4. A full bar replacement may fight the current reserved `bar` plugin contract.
5. Menu layer-shell behavior needs careful testing because exclusive-zone and
   overlay behavior are central to Lacuna's sidebar feel.

## Initial Success Criteria

The first useful milestone is not "all of Lacuna is ported." It is:

1. At least one Lacuna topbar module loads through Omarchy's bar widget
   registry.
2. The module can be enabled and placed from Omarchy Settings or `shell.json`.
3. It uses the existing Omarchy shell process.
4. It preserves Lacuna pill styling and status behavior inside the Omarchy bar.
5. Bar-widget settings persist through Omarchy's inline `shell.json` entries;
   Lacuna-private settings are limited to runtime/app state.

Once that works, the rest of the port is mechanical.
