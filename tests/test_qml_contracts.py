import unittest
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def read_json(path):
    return json.loads(read(path))


class QmlContractTests(unittest.TestCase):
    def test_lacuna_settings_keeps_carbon_as_legacy_lacuna_alias(self):
        qml = read("plugins/omarchy.lacuna-menu/services/LacunaSettings.qml")

        self.assertIn('designStyle: "lacuna"', qml)
        self.assertIn('style === "lacuna" || style === "carbon"', qml)
        self.assertIn('return "lacuna"', qml)

    def test_lacuna_settings_has_pending_save_merge_for_quick_launch_state(self):
        qml = read("plugins/omarchy.lacuna-menu/services/LacunaSettings.qml")

        self.assertIn("function mergePendingSave", qml)
        self.assertIn("merged.customQuickLaunchApps = loadedBase.customQuickLaunchApps", qml)
        self.assertIn("merged.customQuickLaunchNames = loadedBase.customQuickLaunchNames", qml)

    def test_custom_quick_launch_context_menu_can_delete_items(self):
        content = read("plugins/omarchy.lacuna-menu/menu/MenuContent.qml")
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")

        self.assertIn("signal quickLaunchRemoveRequested(string appId)", content)
        self.assertIn('text: "Delete"', content)
        self.assertIn("function openQuickLaunchContext", content)
        self.assertIn("onSecondaryClicked: function(x, y)", content)
        self.assertIn("root.quickLaunchRemoveRequested(quickLaunchContextAppId)", content)
        self.assertIn("function removeCustomQuickLaunchApp(id)", window)
        self.assertIn("next.customQuickLaunchApps = ids", window)
        self.assertIn("next.customQuickLaunchNames = names", window)
        self.assertIn("onQuickLaunchRemoveRequested", window)

    def test_app_picker_does_not_cap_search_results(self):
        picker = read("plugins/omarchy.lacuna-menu/menu/FlyoutAppPickerContent.qml")
        filtered = picker.split("function filteredApps()", 1)[1].split("return list", 1)[0]

        self.assertNotIn("list.length >= 80", filtered)
        self.assertNotIn("break", filtered)

    def test_quick_launch_add_action_lives_in_header_controls(self):
        registry = read("plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml")
        content = read("plugins/omarchy.lacuna-menu/menu/MenuContent.qml")
        section = read("plugins/omarchy.lacuna-menu/menu/MenuSection.qml")
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")

        self.assertIn('header.headerAction = "open-custom-quick-launch-picker"', registry)
        self.assertIn('header.headerActionIcon = "plus"', registry)
        self.assertIn('var header = entries.header("Daily Launch", "nav", "launch")', registry)
        self.assertIn('var header = entries.header("Shortcuts", "nav", "shortcuts")', registry)
        self.assertIn('header.optionActionPrefix = "set-shortcuts-layout-"', registry)
        self.assertIn('if (root.shortcutsLayout === "grid")', registry)
        self.assertIn('entry.action.indexOf("set-shortcuts-layout-") === 0', window)
        self.assertIn("function setShortcutsLayout", window)
        self.assertIn("var launchers = customQuickLaunchItems()", registry)
        self.assertNotIn('entries.action({ icon: "plus", label: "Add Quick Launch App"', registry)
        self.assertIn("onActionTriggered", content)
        self.assertIn("signal actionTriggered()", section)
        self.assertIn("var header = entry", content)
        self.assertNotIn("for (var key in entry) header[key] = entry[key]", content)
        self.assertIn("width: itemList.width", content)
        self.assertIn("width: implicitWidth", section)
        self.assertIn("width: root.options.length * height", section)

    def test_system_restart_requires_confirmation_unless_enabled(self):
        registry = read("plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml")
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")
        settings = read("plugins/omarchy.lacuna-menu/services/LacunaSettings.qml")
        state_service = read("plugins/omarchy.lacuna-state/Service.qml")
        settings_window = read("plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml")

        self.assertIn('instantRestart: false', settings)
        self.assertIn('instantRestart: false', state_service)
        self.assertIn('action: "confirm-system-restart"', registry)
        self.assertNotIn('label: "Restart", hint: "Reboot machine", command: "omarchy-system-reboot"', registry)
        self.assertIn("property bool pendingSystemRestartConfirmation", window)
        self.assertIn("function requestSystemRestart()", window)
        self.assertIn("function confirmSystemRestart()", window)
        self.assertIn('commands.run("omarchy-system-reboot")', window)
        self.assertIn('entry.action === "confirm-system-restart"', window)
        self.assertIn('entry.action === "toggle-instant-restart"', window)
        self.assertIn('"Instant Restart"', settings_window)
        self.assertIn('"toggle-instant-restart"', settings_window)

    def test_rail_has_no_compact_density_button(self):
        rail = read("plugins/omarchy.lacuna-menu/menu/MenuRail.qml")
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")

        self.assertNotIn("signal compactToggleRequested", rail)
        self.assertNotIn("id: compactButton", rail)
        self.assertNotIn("Compact density", rail)
        self.assertNotIn("Normal density", rail)
        self.assertNotIn("onCompactToggleRequested", window)

    def test_idle_indicator_uses_stable_reveal_and_clear_icon(self):
        combined = read("plugins/omarchy.lacuna-indicators/Widget.qml")
        standalone = read("plugins/omarchy.lacuna-idle-inhibitor/Widget.qml")

        self.assertIn('if (id === "StayAwake") return "Zz"', combined)
        self.assertIn('text: "Zz"', standalone)
        self.assertIn("opacity: root.stayAwake || mouseArea.containsMouse ? 1 : 0.55", standalone)
        self.assertIn('font.bold: indicatorButton.indicatorId === "StayAwake"', combined)
        self.assertIn("function hasConfiguredActiveIndicator", combined)
        self.assertIn("function readableIndicatorColor(id, active)", combined)
        self.assertIn("contrastDistance(candidate, background) >= 0.24", combined)
        self.assertIn("opacity: indicatorButton.active || clickArea.containsMouse ? 1 : 0.72", combined)
        self.assertIn("property int hoveredIndicators", combined)
        self.assertIn('readonly property bool showInactive: boolSetting("showInactive", false)', combined)
        self.assertIn("readonly property bool tooltipHovered: visible && opacity > 0 && hoveredIndicators > 0", combined)
        self.assertIn("visible: active || root.showInactive", combined)
        self.assertNotIn("revealInactive", combined)
        self.assertNotIn("revealCollapseDelay", combined)
        self.assertNotIn('text: "󰄲"', combined)
        self.assertIn("visible: stayAwake || showInactive || mouseArea.containsMouse", standalone)

    def test_grouped_indicators_match_standalone_controls(self):
        combined = read("plugins/omarchy.lacuna-indicators/Widget.qml")
        manifest = read_json("plugins/omarchy.lacuna-indicators/manifest.json")

        self.assertFalse(manifest["barWidget"]["defaults"]["showInactive"])
        self.assertIn("showInactive", [entry["key"] for entry in manifest["barWidget"]["schema"]])
        self.assertIn("readonly property int pendingCount", combined)
        self.assertIn('if (id === "Dnd") return dnd || pendingCount > 0', combined)
        self.assertIn('pendingCount + " pending notification"', combined)
        self.assertIn('bar.run("omarchy-shell notifications showHistory")', combined)
        self.assertIn('bar.run("omarchy toggle notification silencing")', combined)
        self.assertIn('else if (recording) bar.run("omarchy-capture-screenrecording --stop-recording")', combined)
        self.assertIn("Qt.LeftButton | Qt.MiddleButton | Qt.RightButton", combined)
        self.assertIn('indicatorButton.indicatorId === "Dnd" && root.pendingCount > 0 && !root.dnd', combined)

    def test_indicator_status_roles_have_visible_palette_slots(self):
        combined = read("plugins/omarchy.lacuna-indicators/Widget.qml")

        self.assertIn('if (id === "Dnd") return "color13"', combined)
        self.assertIn('if (id === "NightLight") return "color11"', combined)
        self.assertIn('if (id === "StayAwake") return "color14"', combined)
        self.assertIn('if (id === "ScreenRecording") return "color9"', combined)
        self.assertIn('if (id === "Dictation") return "color6"', combined)
        self.assertIn('return "foreground"', combined)

    def test_topbar_tooltip_targets_expose_hover_state(self):
        root_target_widgets = [
            "omarchy.lacuna-audio",
            "omarchy.lacuna-bluetooth",
            "omarchy.lacuna-clock",
            "omarchy.lacuna-bar-size-pill",
            "omarchy.lacuna-claude-usage",
            "omarchy.lacuna-codex-usage",
            "omarchy.lacuna-compact-pill",
            "omarchy.lacuna-idle-inhibitor",
            "omarchy.lacuna-indicators",
            "omarchy.lacuna-nightlight",
            "omarchy.lacuna-menu-button",
            "omarchy.lacuna-network",
            "omarchy.lacuna-notifications",
            "omarchy.lacuna-power",
            "omarchy.lacuna-script-pill",
            "omarchy.lacuna-screen-recording",
            "omarchy.lacuna-system-update",
            "omarchy.lacuna-temperature",
            "omarchy.lacuna-theme",
            "omarchy.lacuna-voxtype",
            "omarchy.lacuna-wallpaper",
            "omarchy.lacuna-weather",
        ]

        for plugin in root_target_widgets:
            qml = read(f"plugins/{plugin}/Widget.qml")
            self.assertIn("readonly property bool tooltipHovered", qml, plugin)
            if plugin == "omarchy.lacuna-indicators":
                self.assertIn("hoveredIndicators > 0", qml, plugin)
            else:
                self.assertIn("mouseArea.containsMouse", qml, plugin)

        system_stats = read("plugins/omarchy.lacuna-system-stats/Widget.qml")
        self.assertIn("readonly property bool tooltipHovered", system_stats)
        self.assertIn("parent.bar.showTooltip(parent, parent.tooltip)", system_stats)

        for path in [
            "plugins/omarchy.lacuna-mpris/components/LacunaMprisButton.qml",
            "plugins/omarchy.lacuna-workspaces/components/LacunaWorkspaceButton.qml",
        ]:
            qml = read(path)
            self.assertIn("readonly property bool tooltipHovered", qml, path)
            self.assertIn("clickArea.containsMouse", qml, path)

    def test_lacuna_native_replacement_widgets_have_expected_contracts(self):
        replacements = {
            "omarchy.lacuna-system-update": "SystemUpdate",
            "omarchy.lacuna-clock": "Clock",
            "omarchy.lacuna-weather": "Weather",
            "omarchy.lacuna-notifications": "NotificationCenter",
            "omarchy.lacuna-nightlight": "NightLight",
            "omarchy.lacuna-idle-inhibitor": "idleInhibitor",
            "omarchy.lacuna-screen-recording": "screenRecording",
            "omarchy.lacuna-voxtype": "voxtype",
            "omarchy.lacuna-tray": "Tray",
            "omarchy.lacuna-bluetooth": "BluetoothPanel",
            "omarchy.lacuna-network": "NetworkPanel",
            "omarchy.lacuna-audio": "AudioPanel",
            "omarchy.lacuna-power": "PowerPanel",
        }

        example = read_json("config/shell.lacuna-native-replacements.example.json")
        layout_ids = []
        for section in ["left", "center", "right"]:
            layout_ids.extend(entry["id"] for entry in example["bar"]["layout"][section])

        for plugin_id, native_id in replacements.items():
            manifest = read_json(f"plugins/{plugin_id}/manifest.json")
            qml = read(f"plugins/{plugin_id}/Widget.qml")

            self.assertEqual(plugin_id, manifest["id"])
            self.assertIn("bar-widget", manifest["kinds"])
            self.assertEqual("Widget.qml", manifest["entryPoints"]["barWidget"])
            self.assertEqual("Lacuna", manifest["barWidget"]["category"])
            self.assertIn(plugin_id, layout_ids)
            self.assertNotIn(f'moduleName: "{native_id}"', qml)
            self.assertIn(f'moduleName: "{plugin_id}"', qml)
            self.assertIn("barSize", qml)
            if plugin_id != "omarchy.lacuna-tray":
                self.assertIn("colorProfile", qml)

    def test_lacuna_tray_dispatches_status_notifier_context_menus(self):
        manifest = read_json("plugins/omarchy.lacuna-tray/manifest.json")
        qml = read("plugins/omarchy.lacuna-tray/Widget.qml")
        registry = read("plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml")

        self.assertEqual("omarchy.lacuna-tray", manifest["id"])
        self.assertEqual("Widget.qml", manifest["entryPoints"]["barWidget"])
        self.assertIn("bar-widget", manifest["kinds"])
        self.assertNotIn("QsMenuAnchor", qml)
        self.assertIn("property bool trayMenuOpen", qml)
        self.assertIn("readonly property bool expanded: drawerHovered || trayMenuOpen", qml)
        self.assertIn("function markTrayMenuRequested", qml)
        self.assertIn("trayMenuReset.restart()", qml)
        self.assertIn("onPressed: function(mouse)", qml)
        self.assertIn("mouse.button === Qt.RightButton", qml)
        self.assertIn("trayItemRoot.modelData.onlyMenu && trayItemRoot.modelData.hasMenu", qml)
        self.assertIn("root.markTrayMenuRequested()", qml)
        self.assertIn("trayItemRoot.modelData.display(trayItemRoot.QsWindow.window, point.x, point.y)", qml)
        self.assertIn('root.bar.shell.updateEntryInline(id, { id: id, pinned: pinned, hidden: hidden })', qml)
        self.assertIn('if (key === "omarchy.lacuna-tray") return "apps"', registry)

    def test_system_stats_uses_tabler_cpu_icon(self):
        qml = read("plugins/omarchy.lacuna-system-stats/Widget.qml")
        icon = read("plugins/omarchy.lacuna-system-stats/assets/tabler/cpu.svg")

        self.assertIn('iconSource: Qt.resolvedUrl("assets/tabler/cpu.svg")', qml)
        self.assertNotIn('iconSource: Qt.resolvedUrl("assets/tabler/assembly-filled.svg")', qml)
        self.assertIn("icon-tabler-cpu", icon)

    def test_weather_splits_leading_condition_icon_from_label(self):
        qml = read("plugins/omarchy.lacuna-weather/Widget.qml")

        self.assertIn("function leadingWeatherIcon(raw)", qml)
        self.assertIn("function textWithoutLeadingWeatherIcon(raw)", qml)
        self.assertIn('readonly property string weatherIcon: leadingWeatherIcon(weatherText) || "󰖐"', qml)
        self.assertIn("text: root.weatherIcon", qml)
        self.assertIn("text: root.displayText", qml)
        self.assertNotIn("text: root.weatherText", qml)

    def test_wallpaper_commands_force_live_background_refresh(self):
        widget = read("plugins/omarchy.lacuna-wallpaper/Widget.qml")
        catalog = read("plugins/omarchy.lacuna-menu/menu/MenuCommandCatalog.qml")
        panel = read("plugins/omarchy.lacuna-shell-settings/Panel.qml")

        self.assertIn("function nextBackgroundCommand()", widget)
        self.assertIn("bar.run(root.nextBackgroundCommand())", widget)
        for qml in [widget, catalog, panel]:
            self.assertIn("function applyCurrentBackgroundCommand()", qml)
            self.assertIn("readlink -f", qml)
            self.assertIn("background setInstant", qml)

    def test_background_animations_use_single_selected_effect_contract(self):
        manifest = read_json("plugins/omarchy.lacuna-aurora-drift/manifest.json")
        qml = read("plugins/omarchy.lacuna-aurora-drift/Overlay.qml")
        rain_manifest = read_json("plugins/omarchy.lacuna-rainfall-overlay/manifest.json")
        rain = read("plugins/omarchy.lacuna-rainfall-overlay/Overlay.qml")
        cinematic_manifest = read_json("plugins/omarchy.lacuna-cinematic-light-overlay/manifest.json")
        cinematic = read("plugins/omarchy.lacuna-cinematic-light-overlay/Overlay.qml")
        crt_manifest = read_json("plugins/omarchy.lacuna-crt-overlay/manifest.json")
        crt = read("plugins/omarchy.lacuna-crt-overlay/Overlay.qml")
        vhs_manifest = read_json("plugins/omarchy.lacuna-vhs-overlay/manifest.json")
        vhs = read("plugins/omarchy.lacuna-vhs-overlay/Overlay.qml")
        vignette_manifest = read_json("plugins/omarchy.lacuna-background-vignette/manifest.json")
        vignette = read("plugins/omarchy.lacuna-background-vignette/Overlay.qml")
        settings = read("plugins/omarchy.lacuna-menu/services/LacunaSettings.qml")
        state_service = read("plugins/omarchy.lacuna-state/Service.qml")
        registry = read("plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml")
        shell_settings_panel = read("plugins/omarchy.lacuna-shell-settings/Panel.qml")
        settings_window = read("plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml")
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")
        example = read_json("config/shell.lacuna-native-replacements.example.json")

        self.assertEqual("omarchy.lacuna-aurora-drift", manifest["id"])
        self.assertEqual(["overlay"], manifest["kinds"])
        self.assertEqual("Overlay.qml", manifest["entryPoints"]["overlay"])
        self.assertEqual("omarchy.lacuna-rainfall-overlay", rain_manifest["id"])
        self.assertEqual(["overlay"], rain_manifest["kinds"])
        self.assertEqual("Overlay.qml", rain_manifest["entryPoints"]["overlay"])
        self.assertEqual("omarchy.lacuna-cinematic-light-overlay", cinematic_manifest["id"])
        self.assertEqual(["overlay"], cinematic_manifest["kinds"])
        self.assertEqual("persistent", cinematic_manifest["activation"])
        self.assertIs(cinematic_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", cinematic_manifest["entryPoints"]["overlay"])
        self.assertEqual(1, cinematic_manifest["defaults"]["intensity"])
        self.assertEqual("lightLeak", cinematic_manifest["defaults"]["stylePreset"])
        self.assertTrue(cinematic_manifest["defaults"]["slowDrift"])
        self.assertFalse(cinematic_manifest["defaults"]["occasionalSweeps"])
        self.assertFalse(cinematic_manifest["defaults"]["activeShimmer"])
        self.assertEqual("omarchy.lacuna-crt-overlay", crt_manifest["id"])
        self.assertEqual(["overlay"], crt_manifest["kinds"])
        self.assertEqual("persistent", crt_manifest["activation"])
        self.assertIs(crt_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", crt_manifest["entryPoints"]["overlay"])
        self.assertFalse(crt_manifest["defaults"]["foregroundOverlay"])
        self.assertTrue(crt_manifest["defaults"]["distortion"])
        self.assertTrue(crt_manifest["defaults"]["bloomPulse"])
        self.assertFalse(vhs_manifest["defaults"]["foregroundOverlay"])
        self.assertEqual("omarchy.lacuna-background-vignette", vignette_manifest["id"])
        self.assertEqual(["overlay"], vignette_manifest["kinds"])
        self.assertEqual("persistent", vignette_manifest["activation"])
        self.assertIs(vignette_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", vignette_manifest["entryPoints"]["overlay"])
        self.assertIn("backgroundVignette", settings)
        self.assertIn("ignoreBackgroundAnimationLayer", settings)
        self.assertIn("backgroundVignetteSettings()", vignette)
        self.assertIn("WlrLayer.Background", vignette)
        self.assertIn("WlrLayer.Bottom", vignette)
        self.assertIn("stylePreset", [entry["key"] for entry in cinematic_manifest["schema"]])
        self.assertIn("slowDrift", [entry["key"] for entry in cinematic_manifest["schema"]])
        self.assertIn("occasionalSweeps", [entry["key"] for entry in cinematic_manifest["schema"]])
        self.assertIn("activeShimmer", [entry["key"] for entry in cinematic_manifest["schema"]])
        self.assertIn("foregroundOverlay", [entry["key"] for entry in crt_manifest["schema"]])
        self.assertIn("distortion", [entry["key"] for entry in crt_manifest["schema"]])
        self.assertIn("distortionAmount", [entry["key"] for entry in crt_manifest["schema"]])
        self.assertIn("bloomPulse", [entry["key"] for entry in crt_manifest["schema"]])
        self.assertIn("bloomPulseAmount", [entry["key"] for entry in crt_manifest["schema"]])
        self.assertIn("bloomPulseInterval", [entry["key"] for entry in crt_manifest["schema"]])
        self.assertIn("foregroundOverlay", [entry["key"] for entry in vhs_manifest["schema"]])
        self.assertIn('backgroundEffectEnabled("auroraDrift", true)', qml)
        self.assertIn('backgroundEffectEnabled("rainfall", true)', rain)
        self.assertIn('backgroundEffectEnabled("cinematicLight", true)', cinematic)
        self.assertIn('backgroundEffectEnabled("crt", true)', crt)
        self.assertIn("backgroundEffects.activeEffect", qml)
        self.assertIn("backgroundEffects.activeEffect", vhs)
        self.assertIn("backgroundEffects.activeEffect", rain)
        self.assertIn("backgroundEffects.activeEffect", cinematic)
        self.assertIn("backgroundEffects.activeEffect", crt)
        self.assertIn('target: "lacuna-aurora-drift"', qml)
        self.assertIn('WlrLayershell.namespace: "lacuna-aurora-drift"', qml)
        self.assertIn('target: "lacuna-rainfall-overlay"', rain)
        self.assertIn('WlrLayershell.namespace: "lacuna-rainfall-overlay"', rain)
        self.assertIn('target: "lacuna-cinematic-light-overlay"', cinematic)
        self.assertIn('WlrLayershell.namespace: "lacuna-cinematic-light-overlay"', cinematic)
        self.assertIn('target: "lacuna-crt-overlay"', crt)
        self.assertIn('WlrLayershell.namespace: "lacuna-crt-overlay"', crt)
        self.assertIn("WlrLayershell.layer: root.foregroundOverlay ? WlrLayer.Overlay : WlrLayer.Bottom", vhs)
        self.assertIn("WlrLayershell.layer: root.foregroundOverlay ? WlrLayer.Overlay : WlrLayer.Bottom", crt)
        self.assertIn("WlrLayershell.layer: WlrLayer.Bottom", qml)
        self.assertIn("WlrLayershell.layer: WlrLayer.Bottom", rain)
        self.assertIn("WlrLayershell.layer: WlrLayer.Bottom", cinematic)
        self.assertIn("mask: Region {}", qml)
        self.assertIn("mask: Region {}", rain)
        self.assertIn("mask: Region {}", cinematic)
        self.assertIn("mask: Region {}", crt)
        self.assertIn("staticBand", crt)
        self.assertIn("curvedGlassDistortion", crt)
        self.assertIn("visible: root.foregroundOverlay && root.distortion", crt)
        self.assertIn('readonly property string stylePreset: normalizeStylePreset(settingValue("stylePreset", "lightLeak"))', cinematic)
        self.assertIn("readonly property bool slowDriftEnabled", cinematic)
        self.assertIn("readonly property bool occasionalSweepsEnabled", cinematic)
        self.assertIn("readonly property bool activeShimmerEnabled", cinematic)
        self.assertIn('if (preset === "cinematicFlare" || preset === "anamorphicGlow") return preset', cinematic)
        self.assertIn('if (mode === "occasionalSweeps" || mode === "activeShimmer") return mode', cinematic)
        self.assertIn("motionModes: {", cinematic)
        self.assertIn("readonly property real xSwing: 0.055", qml)
        self.assertIn("readonly property real ySwing: 0.04", qml)
        self.assertIn("readonly property int cycleXDirection", cinematic)
        self.assertIn("readonly property int cycleYDirection", cinematic)
        self.assertIn('activeEffect: "trackingLines"', settings)
        self.assertIn('auroraDrift: {', settings)
        self.assertIn('rainfall: {', settings)
        self.assertIn('cinematicLight: {', settings)
        self.assertIn('crt: {', settings)
        self.assertIn('activeEffect: "trackingLines"', state_service)
        self.assertIn('auroraDrift: {', state_service)
        self.assertIn('rainfall: {', state_service)
        self.assertIn('cinematicLight: {', state_service)
        self.assertIn('crt: {', state_service)
        self.assertIn("function activeBackgroundEffect", registry)
        self.assertIn("function backgroundEffectOptions", registry)
        self.assertIn("root.pluginRegistry.isEnabled(id)", registry)
        self.assertIn("pluginRegistry.isEnabled(id)", shell_settings_panel)
        self.assertIn("shellBarWidgetExistsAnywhere(id)", registry)
        self.assertIn("function backgroundEffectPluginId", registry)
        self.assertIn("function backgroundEffectForegroundEnabled", registry)
        self.assertIn("function cinematicLightSettings", registry)
        self.assertIn("function cinematicLightIntensityOptions", registry)
        self.assertIn("function cinematicLightIntensity", registry)
        self.assertIn("function cinematicLightIntensityHint", registry)
        self.assertIn("function cinematicLightStyleOptions", registry)
        self.assertIn("function cinematicLightMotionModes", registry)
        self.assertIn("function cinematicLightSlowDriftEnabled", registry)
        self.assertIn("function cinematicLightOccasionalSweepsEnabled", registry)
        self.assertIn("function cinematicLightActiveShimmerEnabled", registry)
        self.assertIn('if (effectId === "auroraDrift") return "Aurora Drift"', registry)
        self.assertIn('if (effectId === "rainfall") return "Rainfall"', registry)
        self.assertIn('if (effectId === "cinematicLight") return "Cinematic Light"', registry)
        self.assertIn('if (effectId === "crt") return "CRT"', registry)
        self.assertIn('"toggle-background-effects"', settings_window)
        self.assertIn('"toggle-background-vignette"', settings_window)
        self.assertIn('"set-background-effect-"', settings_window)
        self.assertIn('"toggle-background-effect-foreground-"', settings_window)
        self.assertIn('root.registry.activeBackgroundEffect() === "cinematicLight"', settings_window)
        self.assertIn('"set-cinematic-light-style-"', settings_window)
        self.assertIn('"set-cinematic-light-intensity-"', settings_window)
        self.assertIn('"toggle-cinematic-light-motion-slowDrift"', settings_window)
        self.assertIn('"toggle-cinematic-light-motion-occasionalSweeps"', settings_window)
        self.assertIn('"toggle-cinematic-light-motion-activeShimmer"', settings_window)
        self.assertIn("SettingsSelectRow", settings_window)
        self.assertIn("function setBackgroundEffectsEnabled", window)
        self.assertIn("function setBackgroundVignetteEnabled", window)
        self.assertIn("function setBackgroundEffect", window)
        self.assertIn("function toggleBackgroundEffectForeground", window)
        self.assertIn("setShellPluginEnabled(pluginId, true)", window)
        self.assertIn("function setCinematicLightSetting", window)
        self.assertIn("function toggleCinematicLightMotion", window)
        self.assertIn('shell.updateEntryInline("omarchy.lacuna-cinematic-light-overlay", next)', window)
        self.assertIn("shell.updateEntryInline(pluginId, next)", window)
        self.assertIn('entry.action.indexOf("toggle-background-effect-foreground-") === 0', window)
        self.assertIn('entry.action.indexOf("set-cinematic-light-style-") === 0', window)
        self.assertIn('entry.action.indexOf("set-cinematic-light-intensity-") === 0', window)
        self.assertIn('entry.action.indexOf("toggle-cinematic-light-motion-") === 0', window)
        self.assertNotIn('"toggle-background-effect-auroraDrift"', settings_window)
        self.assertIn("omarchy.lacuna-aurora-drift", [entry["id"] for entry in example["plugins"]])
        self.assertIn("omarchy.lacuna-rainfall-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("omarchy.lacuna-cinematic-light-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("omarchy.lacuna-crt-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("omarchy.lacuna-background-vignette", [entry["id"] for entry in example["plugins"]])

    def test_workspace_lacuna_selected_state_has_no_fill_or_underline(self):
        qml = read("plugins/omarchy.lacuna-workspaces/components/LacunaWorkspaceButton.qml")

        self.assertNotIn("root.active ? 0.08", qml)
        self.assertNotIn("height: 2\n    color: root.accent\n    opacity: root.active", qml)
        self.assertIn('property string designStyle: "lacuna"', qml)

    def test_lacuna_menu_button_uses_lacuna_icon_asset(self):
        qml = read("plugins/omarchy.lacuna-menu-button/Widget.qml")

        self.assertIn("circle-dotted-letter-l.svg", qml)
        self.assertNotIn("layout-sidebar-left-expand-filled.svg", qml)

    def test_lacuna_menu_uses_unified_accent_except_danger(self):
        for path in [
            "plugins/omarchy.lacuna-menu/menu/MenuContent.qml",
            "plugins/omarchy.lacuna-menu/menu/MenuRail.qml",
            "plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml",
            "plugins/omarchy.lacuna-menu/settings/OmarchyShellSettingsWindow.qml",
        ]:
            qml = read(path)
            tone_function = qml.split("function toneAccent", 1)[1].split("\n  }", 1)[0]

            self.assertIn('if (tone === "danger") return root.dangerAccent', tone_function, path)
            self.assertIn("return root.accent", tone_function, path)
            self.assertNotIn("return root.shellAccent", tone_function, path)
            self.assertNotIn("return root.sessionAccent", tone_function, path)
            self.assertNotIn("return root.navAccent", tone_function, path)

        docs = read("docs/lacuna-menu-unified-color-model.md")
        self.assertIn("one primary theme accent", docs)
        self.assertIn("Reserve a separate danger accent", docs)

    def test_design_token_consumers_use_lacuna_not_carbon_flag(self):
        paths = [
            "plugins/omarchy.lacuna-menu/settings/SettingsRail.qml",
            "plugins/omarchy.lacuna-menu/settings/SettingsRow.qml",
            "plugins/omarchy.lacuna-menu/modules/LacunaMenuItem.qml",
            "plugins/omarchy.lacuna-menu/menu/MenuContent.qml",
            "plugins/omarchy.lacuna-menu/menu/FlyoutAppPickerContent.qml",
        ]

        for path in paths:
            qml = read(path)
            self.assertNotIn("designTokens.carbon", qml, path)

    def test_daily_launch_system_editor_uses_omarchy_editor_launcher(self):
        qml = read("plugins/omarchy.lacuna-menu/menu/MenuAppModel.qml")

        self.assertIn('role === "editor") return root.commands.hyprExec("omarchy-launch-editor")', qml)
        self.assertNotIn('role === "editor") return root.commands.hyprExec("omarchy launch editor")', qml)

    def test_sidebar_default_mode_is_separate_from_runtime_toggle(self):
        settings = read("plugins/omarchy.lacuna-menu/services/LacunaSettings.qml")
        sidebar = read("plugins/omarchy.lacuna-menu/services/SidebarState.qml")
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")
        settings_window = read("plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml")

        self.assertIn('defaultMode: "off"', settings)
        self.assertIn("function setDefaultMode", sidebar)
        self.assertIn('entry.action.indexOf("set-sidebar-default-")', window)
        self.assertIn('"Sidebar Default"', settings_window)
        self.assertNotIn('"set-sidebar-display-"', settings_window)

    def test_lacuna_settings_persistence_service_restores_idle_state(self):
        manifest = read("plugins/omarchy.lacuna-settings-persistence/manifest.json")
        qml = read("plugins/omarchy.lacuna-settings-persistence/Service.qml")
        panel = read("plugins/omarchy.lacuna-settings-persistence/Panel.qml")

        self.assertIn('"name": "Lacuna Settings Persistence"', manifest)
        self.assertIn('"kinds": ["service", "panel"]', manifest)
        self.assertIn('"service": "Service.qml"', manifest)
        self.assertIn('"panel": "Panel.qml"', manifest)
        self.assertIn("settings-persistence.json", qml)
        self.assertIn("manageIdle", qml)
        self.assertIn("manageNightlight", qml)
        self.assertIn("omarchy-shell idle status", qml)
        self.assertIn("omarchy-shell idle \" + (enabled ? \"enable\" : \"disable\")", qml)
        self.assertIn("omarchy-toggle-nightlight --status", qml)
        self.assertIn("hyprctl hyprsunset temperature", qml)
        self.assertIn('target: "lacuna-settings-persistence"', qml)
        self.assertIn("Idle Inhibit", panel)
        self.assertIn("Nightlight", panel)
        self.assertIn("setManagedToggles", panel)

    def test_window_gaps_toggle_uses_theme_size_when_enabled(self):
        service = read("plugins/omarchy.lacuna-shell-settings/Service.qml")
        state_script = read("plugins/omarchy.lacuna-shell-settings/scripts/omarchy-shell-settings-state.py")
        settings_window = read("plugins/omarchy.lacuna-shell-settings/settings/OmarchyShellSettingsWindow.qml")

        self.assertIn("rm -f \" + quote(stockFile) + \" \" + quote(oldLacunaFile) + \" \" + quote(lacunaFile)", service)
        self.assertIn("Disable Hyprland window gaps without changing theme borders", service)
        self.assertNotIn("border_size", service)
        self.assertIn("live_gaps_enabled = any(value and value > 0 for value in [gaps_in, gaps_out])", state_script)
        self.assertIn("Use the active theme's tiled-window gap size", settings_window)

    def test_fake_frame_topbar_reserve_matches_rendered_caster_size(self):
        window = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")
        overlay = read("plugins/omarchy.lacuna-menu/menu/LacunaFrameOverlay.qml")

        self.assertIn("property int barEdgeCasterSize: frameThickness", window)
        self.assertIn("property int sidebarReserveExtra: 2", window)
        self.assertIn("barEdgeCasterSize: root.barEdgeCasterSize", window)
        self.assertIn("cornerPieces: sidebarState.cornerPieces", window)
        self.assertIn("function holdFlyoutAfterSettingsActivation()", window)
        self.assertIn("if (Date.now() < ignoreFlyoutFocusClearUntil) return", window)
        self.assertIn("property real barEdgeCasterSize: frameThickness", overlay)
        self.assertIn("property bool cornerPieces: true", overlay)
        self.assertIn("root.fullFrame && root.cornerPieces && root.topBar && !root.leftBar && !root.leftEdgeOccupied", overlay)
        self.assertIn("frameReserveRight: frameReserveActive && frameMode === \"fullframe\" && !root.panelOnRight && !root.rightBar ? frameThickness + reservePadding : 0", window)
        self.assertIn("topBarShadowReserve: frameReserveActive && root.topBar ? reservePadding : 0", window)

    def test_plugin_manifests_have_existing_item_entrypoints(self):
        for manifest_path in sorted((ROOT / "plugins").glob("*/manifest.json")):
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            entry_points = manifest.get("entryPoints", {})
            self.assertIsInstance(entry_points, dict, manifest_path)
            self.assertTrue(entry_points, manifest_path)

            for entry_path in entry_points.values():
                qml_path = manifest_path.parent / entry_path
                self.assertTrue(qml_path.exists(), qml_path)
                self.assertNotIn("ShellRoot", qml_path.read_text(encoding="utf-8"), qml_path)

    def test_theme_widget_schema_exposes_defaults_for_bar_settings(self):
        manifest = read_json("plugins/omarchy.lacuna-theme/manifest.json")
        schema = {entry["key"]: entry for entry in manifest["barWidget"]["schema"]}
        qml = read("plugins/omarchy.lacuna-theme/Widget.qml")

        self.assertEqual("boolean", schema["enabled"]["type"])
        self.assertIs(schema["enabled"]["defaultValue"], True)
        self.assertEqual(26, schema["maxTextLength"]["defaultValue"])
        self.assertEqual("boolean", schema["showIcon"]["type"])
        self.assertIs(schema["showIcon"]["defaultValue"], True)
        self.assertEqual("semantic", schema["colorProfile"]["defaultValue"])
        self.assertIn('readonly property bool widgetEnabled: boolSetting("enabled", true)', qml)
        self.assertIn("visible: widgetEnabled && themeTitle.length > 0", qml)
        self.assertIn('readonly property bool showIcon: boolSetting("showIcon", true)', qml)

    def test_wallpaper_widget_schema_exposes_real_enabled_setting(self):
        manifest = read_json("plugins/omarchy.lacuna-wallpaper/manifest.json")
        schema = {entry["key"]: entry for entry in manifest["barWidget"]["schema"]}
        qml = read("plugins/omarchy.lacuna-wallpaper/Widget.qml")

        self.assertEqual("boolean", schema["enabled"]["type"])
        self.assertIs(schema["enabled"]["defaultValue"], True)
        self.assertEqual(18, schema["maxTextLength"]["defaultValue"])
        self.assertEqual("boolean", schema["showIcon"]["type"])
        self.assertIs(schema["showIcon"]["defaultValue"], True)
        self.assertEqual("semantic", schema["colorProfile"]["defaultValue"])
        self.assertIn('readonly property bool widgetEnabled: boolSetting("enabled", true)', qml)
        self.assertIn("visible: widgetEnabled && displayText.length > 0", qml)
        self.assertIn('readonly property bool showIcon: boolSetting("showIcon", true)', qml)

    def test_lacuna_state_and_shell_settings_are_split_plugins(self):
        state_manifest = read_json("plugins/omarchy.lacuna-state/manifest.json")
        shell_settings_manifest = read_json("plugins/omarchy.lacuna-shell-settings/manifest.json")
        menu = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")
        settings = read("plugins/omarchy.lacuna-menu/services/LacunaSettings.qml")
        settings_window = read("plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml")

        self.assertIn("service", state_manifest["kinds"])
        self.assertEqual("Service.qml", state_manifest["entryPoints"]["service"])
        self.assertIn("service", shell_settings_manifest["kinds"])
        self.assertIn("panel", shell_settings_manifest["kinds"])
        self.assertEqual("Service.qml", shell_settings_manifest["entryPoints"]["service"])
        self.assertEqual("Panel.qml", shell_settings_manifest["entryPoints"]["panel"])
        self.assertIn('ensureService("omarchy.lacuna-state")', menu)
        self.assertIn('ensureService("omarchy.lacuna-shell-settings")', menu)
        self.assertIn('panelController.openFlyout("shellSettings")', menu)
        self.assertIn("OmarchyShellSettingsWindow", menu)
        self.assertIn("shellSettingsSurface", menu)
        shell_section = menu.split("function openShellSettingsSection", 1)[1].split("function requestFlyoutFocus", 1)[0]
        self.assertNotIn("sidebarState.expand()", shell_section)
        self.assertIn("return settingsFlyoutY(panelHeight)", menu)
        self.assertIn('surface: "flyout"', settings)
        self.assertIn('"Shell Settings Surface"', settings_window)
        self.assertIn('"set-shell-settings-surface-"', settings_window)

    def test_lacuna_settings_windows_use_parent_control_state(self):
        settings_window = read("plugins/omarchy.lacuna-menu/settings/SettingsWindow.qml")
        menu_shell_settings = read("plugins/omarchy.lacuna-menu/settings/OmarchyShellSettingsWindow.qml")
        standalone_shell_settings = read("plugins/omarchy.lacuna-shell-settings/settings/OmarchyShellSettingsWindow.qml")

        for qml in [settings_window, menu_shell_settings, standalone_shell_settings]:
            self.assertIn("property var controlOverrides", qml)
            self.assertIn("function currentControlChecked", qml)
            self.assertIn("function currentControlValue", qml)
            self.assertIn("function activateControl", qml)
            self.assertIn("checked: root.currentControlChecked(parent.entry)", qml)
            self.assertIn("optionValue: root.currentControlValue(parent.entry)", qml)
            self.assertIn("onTriggered: root.activateControl(parent.entry)", qml)

        self.assertIn("function entryWithDesiredChecked", settings_window)
        self.assertIn("next.desiredChecked = desiredChecked === true", settings_window)
        self.assertIn("function desiredChecked", read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml"))

    def test_simple_bar_helpers_match_canonical_vendored_templates(self):
        color_template = read("shared/qml/simple-bar/ColorProfile.qml")
        motion_template = read("shared/qml/simple-bar/MotionTokens.qml")
        simple_color_plugins = [
            "omarchy.lacuna-audio",
            "omarchy.lacuna-bluetooth",
            "omarchy.lacuna-bar-size-pill",
            "omarchy.lacuna-clock",
            "omarchy.lacuna-claude-usage",
            "omarchy.lacuna-codex-usage",
            "omarchy.lacuna-compact-pill",
            "omarchy.lacuna-idle-inhibitor",
            "omarchy.lacuna-indicators",
            "omarchy.lacuna-nightlight",
            "omarchy.lacuna-menu-button",
            "omarchy.lacuna-network",
            "omarchy.lacuna-notifications",
            "omarchy.lacuna-power",
            "omarchy.lacuna-script-pill",
            "omarchy.lacuna-screen-recording",
            "omarchy.lacuna-system-stats",
            "omarchy.lacuna-system-update",
            "omarchy.lacuna-temperature",
            "omarchy.lacuna-voxtype",
            "omarchy.lacuna-weather",
        ]
        simple_motion_plugins = simple_color_plugins + [
            "omarchy.lacuna-theme",
            "omarchy.lacuna-wallpaper",
        ]

        for plugin in simple_color_plugins:
            self.assertEqual(read(f"plugins/{plugin}/ColorProfile.qml"), color_template, plugin)
        for plugin in simple_motion_plugins:
            self.assertEqual(read(f"plugins/{plugin}/MotionTokens.qml"), motion_template, plugin)
