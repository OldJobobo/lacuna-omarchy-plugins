# Graph Report - .  (2026-06-21)

## Corpus Check
- 160 files · ~301,280 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1440 nodes · 1670 edges · 74 communities (65 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.87)
- Token cost: 57,252 input · 25,010 output

## Community Hubs (Navigation)
- [[_COMMUNITY_QML Contract Tests|QML Contract Tests]]
- [[_COMMUNITY_Design System Core|Design System Core]]
- [[_COMMUNITY_Status Script Tests|Status Script Tests]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Background Effect Manifest|Background Effect Manifest]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Effect Manifest Settings|Effect Manifest Settings]]
- [[_COMMUNITY_Blur Effect Manifest|Blur Effect Manifest]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Glitch Effect Manifest|Glitch Effect Manifest]]
- [[_COMMUNITY_Installer Tests|Installer Tests]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Rain Effect Manifest|Rain Effect Manifest]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Visual Effect Manifest|Visual Effect Manifest]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Desktop Clock Manifest|Desktop Clock Manifest]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_Widget Manifest Contracts|Widget Manifest Contracts]]
- [[_COMMUNITY_App Picker Manifest|App Picker Manifest]]
- [[_COMMUNITY_Overlay Manifest|Overlay Manifest]]
- [[_COMMUNITY_Overlay Manifest|Overlay Manifest]]
- [[_COMMUNITY_Panel Service Manifest|Panel Service Manifest]]
- [[_COMMUNITY_Menu Manifest|Menu Manifest]]
- [[_COMMUNITY_Settings Panel Manifest|Settings Panel Manifest]]
- [[_COMMUNITY_State Service Manifest|State Service Manifest]]
- [[_COMMUNITY_Theme Service Manifest|Theme Service Manifest]]
- [[_COMMUNITY_Bar Option Manifest|Bar Option Manifest]]
- [[_COMMUNITY_Shell Settings State|Shell Settings State]]
- [[_COMMUNITY_Shell Settings State|Shell Settings State]]
- [[_COMMUNITY_State Script Tests|State Script Tests]]
- [[_COMMUNITY_Bar Model Logic|Bar Model Logic]]
- [[_COMMUNITY_Live Load Smoke|Live Load Smoke]]
- [[_COMMUNITY_Desktop App Catalog|Desktop App Catalog]]
- [[_COMMUNITY_Docs Contract Tests|Docs Contract Tests]]
- [[_COMMUNITY_Plugin Kind Contracts|Plugin Kind Contracts]]
- [[_COMMUNITY_Live Behavior Tests|Live Behavior Tests]]
- [[_COMMUNITY_Plugin Load Smoke|Plugin Load Smoke]]
- [[_COMMUNITY_Manifest Contract Tests|Manifest Contract Tests]]
- [[_COMMUNITY_Theme Preloader Script|Theme Preloader Script]]
- [[_COMMUNITY_Bar Model Tests|Bar Model Tests]]
- [[_COMMUNITY_Repository Policy|Repository Policy]]
- [[_COMMUNITY_Claude Usage Script|Claude Usage Script]]
- [[_COMMUNITY_Desktop App Script|Desktop App Script]]
- [[_COMMUNITY_Vendored File Tests|Vendored File Tests]]
- [[_COMMUNITY_Plugin Contracts|Plugin Contracts]]
- [[_COMMUNITY_Settings State Split|Settings State Split]]
- [[_COMMUNITY_Validation Tooling|Validation Tooling]]
- [[_COMMUNITY_Codex Usage Script|Codex Usage Script]]
- [[_COMMUNITY_Theme Background Refresh|Theme Background Refresh]]
- [[_COMMUNITY_Overlay Runtime Rules|Overlay Runtime Rules]]
- [[_COMMUNITY_Check Script|Check Script]]
- [[_COMMUNITY_Native Widget Policy|Native Widget Policy]]
- [[_COMMUNITY_Density Geometry|Density Geometry]]
- [[_COMMUNITY_Typography Rules|Typography Rules]]

## God Nodes (most connected - your core abstractions)
1. `QmlContractTests` - 71 edges
2. `read()` - 67 edges
3. `LacunaInstallerTests` - 25 edges
4. `run()` - 20 edges
5. `defaults` - 15 edges
6. `load_installer_module()` - 15 edges
7. `read_json()` - 15 edges
8. `write_exec()` - 12 edges
9. `defaults` - 11 edges
10. `defaults` - 11 edges

## Surprising Connections (you probably didn't know these)
- `lacuna.script-pill` --conceptually_related_to--> `Omarchy-native Service Preference`  [INFERRED]
  docs/plugins/widgets.md → AGENTS.md
- `check.sh Validation Gate` --conceptually_related_to--> `Vendored File Parity Hook`  [INFERRED]
  docs/development/testing.md → .pre-commit-config.yaml
- `Vendored sync tooling` --implements--> `Vendored File Parity Hook`  [INFERRED]
  docs/plans/lacuna-suite-improvement-plan.md → .pre-commit-config.yaml
- `LacunaGeometry` --implements--> `curveKappa single curve constant`  [INFERRED]
  lacuna.menu/components/README.md → docs/lacuna-design-system/02-geometry.md
- `Settings flyout screenshot` --exemplifies--> `Attached flyout geometry`  [INFERRED]
  docs/screenshots/reference/03-lacuna-menu-settings-flyout.png → docs/lacuna-design-system/02-geometry.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Lacuna Design Language Core** — lacuna_design_system_00_philosophy_lacuna_metaphor, lacuna_design_system_00_philosophy_four_principles, lacuna_design_system_06_roadmap_design_language_migration [EXTRACTED 1.00]
- **Attached Flyout Contract** — lacuna_design_system_02_geometry_molding_connector, lacuna_design_system_02_geometry_attached_flyout_geometry, lacuna_design_system_02_geometry_fill_only_surfaces [EXTRACTED 1.00]
- **Plugin Suite Architecture** — architecture_plugin_contracts_plugin_contracts, plugins_readme_metadata_contract, plugins_menu_lacuna_menu_bundle, plugins_bar_lacuna_bar [INFERRED 0.85]

## Communities (74 total, 9 thin omitted)

### Community 0 - "QML Contract Tests"
Cohesion: 0.06
Nodes (4): plugin_manifest_paths(), QmlContractTests, read(), read_json()

### Community 1 - "Design System Core"
Cohesion: 0.06
Nodes (36): Icon policy, LacunaGeometry, plugin-local QML primitives, Absence has weight, Four Lacuna design principles, Lacuna gap metaphor, Reveal, dont appear, Show the seam (+28 more)

### Community 2 - "Status Script Tests"
Cohesion: 0.16
Nodes (9): CompletedProcess, ClaudeCodeStatusTests, CodexWeeklyStatusTests, PreloadThemeSwitcherTests, Path, Execution tests for the bar-widget status shell scripts.  These scripts shell ou, run(), write_exec() (+1 more)

### Community 3 - "Widget Manifest Contracts"
Cohesion: 0.06
Nodes (32): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+24 more)

### Community 4 - "Background Effect Manifest"
Cohesion: 0.06
Nodes (32): activation, author, defaults, bloomPulse, bloomPulseAmount, bloomPulseInterval, distortion, distortionAmount (+24 more)

### Community 5 - "Widget Manifest Contracts"
Cohesion: 0.06
Nodes (30): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+22 more)

### Community 6 - "Effect Manifest Settings"
Cohesion: 0.07
Nodes (28): activation, author, defaults, accentBlend, activeShimmer, effectEnabled, flareCount, intensity (+20 more)

### Community 7 - "Blur Effect Manifest"
Cohesion: 0.07
Nodes (28): activation, author, defaults, accentBlend, blurSoftness, effectEnabled, intensity, origin (+20 more)

### Community 8 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (28): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+20 more)

### Community 9 - "Glitch Effect Manifest"
Cohesion: 0.07
Nodes (28): activation, author, defaults, chromaBleed, effectEnabled, foregroundOverlay, glitchAmount, intensity (+20 more)

### Community 10 - "Installer Tests"
Cohesion: 0.13
Nodes (4): LacunaInstallerTests, load_installer_module(), run_lacuna(), run_lacuna_unchecked()

### Community 11 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (27): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+19 more)

### Community 12 - "Rain Effect Manifest"
Cohesion: 0.07
Nodes (27): activation, author, defaults, accentBlend, dropCount, effectEnabled, intensity, mistAmount (+19 more)

### Community 13 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (27): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+19 more)

### Community 14 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (27): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+19 more)

### Community 15 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (26): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+18 more)

### Community 16 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (26): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+18 more)

### Community 17 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (26): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+18 more)

### Community 18 - "Widget Manifest Contracts"
Cohesion: 0.07
Nodes (26): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+18 more)

### Community 19 - "Visual Effect Manifest"
Cohesion: 0.08
Nodes (25): activation, author, defaults, accentBlend, blurSoftness, effectEnabled, intensity, ribbonCount (+17 more)

### Community 20 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (25): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+17 more)

### Community 21 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (25): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+17 more)

### Community 22 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (25): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+17 more)

### Community 23 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (25): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+17 more)

### Community 24 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (25): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+17 more)

### Community 25 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (25): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+17 more)

### Community 26 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 27 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 28 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 29 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 30 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 31 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 32 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 33 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (24): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+16 more)

### Community 34 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (23): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+15 more)

### Community 35 - "Desktop Clock Manifest"
Cohesion: 0.08
Nodes (23): activation, author, defaults, anchor, offsetX, offsetY, scale, use12Hour (+15 more)

### Community 36 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (23): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+15 more)

### Community 37 - "Widget Manifest Contracts"
Cohesion: 0.08
Nodes (23): activation, author, barWidget, allowMultiple, category, defaults, description, displayName (+15 more)

### Community 38 - "App Picker Manifest"
Cohesion: 0.09
Nodes (22): activation, author, defaults, audioOnly, maxResults, volume, description, entryPoints (+14 more)

### Community 39 - "Overlay Manifest"
Cohesion: 0.10
Nodes (20): activation, author, defaults, targetOutput, description, entryPoints, overlay, id (+12 more)

### Community 40 - "Overlay Manifest"
Cohesion: 0.11
Nodes (18): activation, author, defaults, description, entryPoints, overlay, id, keepLoaded (+10 more)

### Community 41 - "Panel Service Manifest"
Cohesion: 0.11
Nodes (18): activation, author, description, entryPoints, panel, service, id, keepLoaded (+10 more)

### Community 42 - "Menu Manifest"
Cohesion: 0.11
Nodes (17): activation, author, description, entryPoints, menu, id, keepLoaded, kinds (+9 more)

### Community 43 - "Settings Panel Manifest"
Cohesion: 0.11
Nodes (17): activation, author, description, entryPoints, panel, service, id, keepLoaded (+9 more)

### Community 44 - "State Service Manifest"
Cohesion: 0.12
Nodes (16): activation, author, description, entryPoints, service, id, keepLoaded, kinds (+8 more)

### Community 45 - "Theme Service Manifest"
Cohesion: 0.12
Nodes (16): activation, author, description, entryPoints, service, id, keepLoaded, kinds (+8 more)

### Community 46 - "Bar Option Manifest"
Cohesion: 0.12
Nodes (15): author, description, entryPoints, bar, id, kinds, lacuna, bundle (+7 more)

### Community 47 - "Shell Settings State"
Cohesion: 0.29
Nodes (15): available(), command_matrix(), css_gap_value(), first_int(), focused_monitor(), hypr_option(), hypr_state(), idle_status() (+7 more)

### Community 48 - "Shell Settings State"
Cohesion: 0.29
Nodes (15): available(), command_matrix(), css_gap_value(), first_int(), focused_monitor(), hypr_option(), hypr_state(), idle_status() (+7 more)

### Community 49 - "State Script Tests"
Cohesion: 0.34
Nodes (8): assert_preserved(), env_for(), read_json(), run_script(), run_shell_script(), seed_config(), StateScriptTests, write_json()

### Community 50 - "Bar Model Logic"
Cohesion: 0.27
Nodes (12): customModulePath(), customModuleSafeName(), customModuleType(), entriesAfter(), entriesBefore(), entryId(), entryIndex(), entrySettings() (+4 more)

### Community 51 - "Live Load Smoke"
Cohesion: 0.36
Nodes (8): build_harness(), entry_points(), LiveLoadSmokeTests, omarchy_shell_dir(), Path, Live load-smoke: compile every self-contained plugin entry point in a real Quick, Return (self_contained, host_dependent) entry-point QML files., run_harness()

### Community 52 - "Desktop App Catalog"
Cohesion: 0.51
Nodes (5): DesktopAppCatalogTests, Path, Execution tests for lacuna.menu/scripts/desktop-app-catalog.py.  The script scan, run_catalog(), write_desktop()

### Community 54 - "Plugin Kind Contracts"
Cohesion: 0.42
Nodes (4): manifest(), PluginKindContractTests, Structural contracts for plugin kinds that lacked direct coverage: ambience over, read()

### Community 55 - "Live Behavior Tests"
Cohesion: 0.47
Nodes (5): harness(), LiveBehaviorTests, Path, Live behavioral tests: instantiate real plugin services in a Quickshell instance, run_quickshell()

### Community 56 - "Plugin Load Smoke"
Cohesion: 0.31
Nodes (6): manifest_requires(), plugin_id_for(), PluginLoadSmokeTests, Path, Structural load-smoke for the plugin suite.  This does not launch a live shell (, Return the lacuna.* plugin directory name containing *path*, if any.

### Community 57 - "Manifest Contract Tests"
Cohesion: 0.54
Nodes (3): manifest_paths(), ManifestContractTests, read_json()

### Community 58 - "Theme Preloader Script"
Cohesion: 0.47
Nodes (3): preload-theme-switcher.sh script, add_theme_preview(), write_status()

### Community 60 - "Repository Policy"
Cohesion: 0.40
Nodes (5): Flat lacuna.* Plugin Layout, Flyout Surface Geometry Rules, Omarchy-native Service Preference, Repository Guidelines, lacuna.script-pill

### Community 61 - "Claude Usage Script"
Cohesion: 0.70
Nodes (3): claude-code-status.sh script, hide(), serve_cache_or_hide()

### Community 62 - "Desktop App Script"
Cohesion: 0.70
Nodes (4): app_dirs(), category_for(), main(), read_desktop()

### Community 64 - "Plugin Contracts"
Cohesion: 0.50
Nodes (4): Shell vs Bar Injection Rule, Plugin Entry Points, Plugin Contracts Reference, Lacuna manifest metadata contract

### Community 65 - "Settings State Split"
Cohesion: 0.50
Nodes (4): lacuna.state Persistent Service, Lacuna Runtime settings.json, Omarchy shell.json, Configuration Settings Split

### Community 66 - "Validation Tooling"
Cohesion: 0.50
Nodes (4): check.sh Validation Gate, Vendored sync tooling, Vendored File Parity Hook, Check CI Workflow

### Community 69 - "Overlay Runtime Rules"
Cohesion: 0.67
Nodes (3): Omarchy shell runtime, Overlay Plugins, second Quickshell process

## Knowledge Gaps
- **922 isolated node(s):** `schemaVersion`, `id`, `name`, `version`, `author` (+917 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `schemaVersion`, `id`, `name` to the rest of the system?**
  _930 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `QML Contract Tests` be split into smaller, more focused modules?**
  _Cohesion score 0.05621621621621622 - nodes in this community are weakly interconnected._
- **Should `Design System Core` be split into smaller, more focused modules?**
  _Cohesion score 0.05714285714285714 - nodes in this community are weakly interconnected._
- **Should `Widget Manifest Contracts` be split into smaller, more focused modules?**
  _Cohesion score 0.06060606060606061 - nodes in this community are weakly interconnected._
- **Should `Background Effect Manifest` be split into smaller, more focused modules?**
  _Cohesion score 0.06060606060606061 - nodes in this community are weakly interconnected._
- **Should `Widget Manifest Contracts` be split into smaller, more focused modules?**
  _Cohesion score 0.06451612903225806 - nodes in this community are weakly interconnected._
- **Should `Effect Manifest Settings` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._