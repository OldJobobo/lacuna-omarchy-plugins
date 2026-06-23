import unittest
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def read_json(path):
    return json.loads(read(path))


def plugin_manifest_paths():
    return sorted(ROOT.glob("lacuna.*/manifest.json"))


class QmlContractTests(unittest.TestCase):
    def test_bar_seam_widget_contract(self):
        manifest = read_json("lacuna.bar-seam/manifest.json")
        self.assertEqual(["bar-widget"], manifest["kinds"])
        self.assertEqual("Widget.qml", manifest["entryPoints"]["barWidget"])
        schema_keys = {option["key"] for option in manifest["barWidget"]["schema"]}
        self.assertIn("gapWidth", schema_keys)

        widget = read("lacuna.bar-seam/Widget.qml")
        # bar-widget injection contract
        self.assertIn("property var bar", widget)
        self.assertIn("property string moduleName", widget)
        self.assertIn("property var settings", widget)
        # reserves the separation gap and drives the breathing glow from a Timer
        self.assertIn("implicitWidth: gapWidth", widget)
        self.assertIn("gapBreath", widget)
        self.assertIn("readonly property int glowHeight", widget)
        self.assertIn("seamGap + Math.round(gapBreath * barSize * 0.58)", widget)
        self.assertIn("height: root.glowHeight", widget)
        self.assertNotIn("readonly property color seam", widget)
        self.assertNotIn("color: root.seam", widget)
        self.assertIn("width: 5", widget)
        self.assertIn("width: 3", widget)
        self.assertIn("width: 1", widget)
        self.assertIn("Timer", widget)
        # vendored helpers travel with the plugin
        self.assertTrue((ROOT / "lacuna.bar-seam/ColorProfile.qml").exists())
        self.assertTrue((ROOT / "lacuna.bar-seam/MotionTokens.qml").exists())


    def test_lacuna_settings_keeps_carbon_as_legacy_lacuna_alias(self):
        qml = read("lacuna.menu/services/LacunaSettings.qml")

        self.assertIn('designStyle: "lacuna"', qml)
        self.assertIn("designStyles: {", qml)
        self.assertIn("function normalizeDesignStyles", qml)
        self.assertIn("function normalizeDesignStyleBar", qml)
        self.assertIn("function normalizeBarLayoutEntry", qml)
        self.assertIn('style === "lacuna" || style === "carbon"', qml)
        self.assertIn('return "lacuna"', qml)

    def test_lacuna_menu_surface_ignores_shell_surface_alpha(self):
        qml = read("lacuna.menu/services/Theme.qml")

        self.assertIn('property color panelBackground: shellSurfaceColor("bar.background", color("background"))', qml)
        self.assertIn("function shellSurfaceColor", qml)
        self.assertIn("function opaqueColor", qml)
        self.assertIn("return opaqueColor(shellColor(name, fallbackColor))", qml)
        self.assertNotIn('shellValues[name + "-alpha"]', qml)
        self.assertNotIn("function alphaFor", qml)
        self.assertIn("function parseColor", qml)
        self.assertIn("rgba?", qml)
        self.assertIn("rgbHexAlpha", qml)
        self.assertIn("hyprHex", qml)
        self.assertIn("function stripInlineComment", qml)
        self.assertIn("function unquoteValue", qml)
        self.assertIn('var match = line.match(/^([A-Za-z0-9_-]+)\\s*=\\s*(.+)$/)', qml)
        self.assertNotIn("property color panelBackground: color(\"background\")", qml)

    def test_theme_parse_fallbacks_emit_diagnostics(self):
        qml = read("lacuna.menu/services/Theme.qml")
        # An unparseable (non-empty) color value and a non-empty theme file
        # that yields no entries are real authoring mistakes, so they warn
        # instead of silently snapping to the built-in fallback palette.
        self.assertIn("could not parse color value", qml)
        self.assertIn("colors.toml has content but produced no parseable entries", qml)
        self.assertIn("shell.toml has content but produced no parseable entries", qml)
        # Only the genuine-mistake paths warn; routine per-key misses do not.
        self.assertIn("if (raw.length > 0)", qml)
        self.assertNotIn("function rawColor(name) {\n    console.warn", qml)
        # Documented color formats stay supported (#RRGGBB[AA], rgb/rgba, 0xAARRGGBB).
        self.assertIn("/^#?([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$/", qml)
        self.assertIn("/^rgba\\(\\s*#?([0-9a-f]{6})([0-9a-f]{2})\\s*\\)$/", qml)
        self.assertIn("/^0x([0-9a-f]{2})([0-9a-f]{6})$/", qml)

    def test_lacuna_log_helper_exists_and_is_adopted(self):
        # Shared level-gated logger, vendored to both component dirs.
        for path in [
            "lacuna.shell-settings/components/LacunaLog.qml",
            "lacuna.menu/components/LacunaLog.qml",
        ]:
            log = read(path)
            self.assertIn("function warn(message)", log, path)
            self.assertIn("property int level: 1", log, path)
            self.assertIn("console.warn(format(message))", log, path)
        # Adopted by the menu-only services that have real failure sites; their
        # diagnostics route through log.warn instead of bare console.warn.
        for path in [
            "lacuna.menu/services/Theme.qml",
            "lacuna.menu/services/BarSizeMode.qml",
        ]:
            qml = read(path)
            self.assertIn('import "../components"', qml, path)
            self.assertIn("LacunaLog {", qml, path)
            self.assertIn("log.warn(", qml, path)
            self.assertNotIn("console.warn(", qml, path)

    def test_menu_value_helpers_extracted_and_delegated(self):
        # Pure validators/converters moved out of MenuWindow into a stateless
        # helper; MenuWindow keeps same-named delegators so call sites and the
        # source contract are unchanged.
        helpers = read("lacuna.menu/menu/MenuValueHelpers.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")
        for fn in [
            "function localPath", "function positiveInt", "function safeValue",
            "function numberSetting", "function boolSetting", "function validFrameMode",
            "function validFrameReserveMode", "function validShellSettingsSurface",
            "function desiredChecked", "function validClockAnchor",
            "function clockAnchorHorizontal", "function clockAnchorVertical",
            "function clockAnchorFromParts",
        ]:
            self.assertIn(fn, helpers, fn)
        self.assertIn("MenuValueHelpers {", window)
        self.assertIn("id: valueHelpers", window)
        self.assertIn("return valueHelpers.validClockAnchor(value)", window)
        self.assertIn("return valueHelpers.boolSetting(value, fallback)", window)
        # The pure bodies no longer live in MenuWindow.
        self.assertNotIn('"top-left": true', window)

    def test_lacuna_panel_surfaces_use_opaque_bar_surface_color(self):
        menu = read("lacuna.menu/menu/MenuWindow.qml")
        shell_settings = read("lacuna.shell-settings/Panel.qml")
        bar = read("lacuna.bar/OmarchyBar.qml")

        self.assertIn("property color surfaceBackground: menuTheme.panelBackground", menu)
        self.assertIn("property color panelColor: surfaceBackground", menu)
        self.assertIn("panelColor: root.panelColor", menu)
        self.assertIn("frameColor: root.panelColor", menu)
        self.assertIn("background: root.background", menu)
        self.assertNotIn("background: root.surfaceBackground", menu)
        self.assertNotIn("color: root.surfaceBackground", menu)
        self.assertIn("readonly property color surfaceBackground: opaqueColor(Color.bar.background)", shell_settings)
        self.assertIn("function opaqueColor(colorValue)", shell_settings)
        self.assertIn('color: "transparent"', shell_settings)
        self.assertIn("color: root.surfaceBackground", shell_settings)
        self.assertIn("background: Color.background", shell_settings)
        self.assertIn("property color background: opaqueColor(Color.bar.background)", bar)
        self.assertIn("function opaqueColor(colorValue)", bar)
        self.assertIn("property string fontFamily: proportionalFontFamily(Style.font.family)", bar)
        self.assertIn("function proportionalFontFamily(value)", bar)
        self.assertIn('return "Hack Nerd Font Propo"', bar)
        self.assertIn('return "BlexMono Nerd Font Propo"', bar)
        self.assertIn('return "JetBrainsMono Nerd Font Propo"', bar)
        self.assertIn("requestedTransparent = false", bar)
        self.assertIn("color: root.background", bar)
        self.assertNotIn('root.transparent ? "transparent" : root.background', bar)

    def test_lacuna_panel_surface_geometry_is_owned_by_surface_components(self):
        host = read("lacuna.menu/menu/LacunaPanelHost.qml")
        flyout = read("lacuna.menu/menu/LacunaAttachedFlyout.qml")
        connector = read("lacuna.menu/menu/LacunaPanelConnector.qml")
        overlay = read("lacuna.menu/menu/LacunaFrameOverlay.qml")
        surface = read("lacuna.menu/menu/MenuSurface.qml")
        unified = read("lacuna.menu/menu/LacunaPanelUnifiedSurface.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")

        self.assertIn("connectorRenderable ? effectiveFlyoutHeight + effectiveConnectorWidth * 2 : 0", host)
        self.assertIn("readonly property real flyoutCurrentWidth: Math.max(0, effectiveFlyoutWidth * clampedFlyoutProgress)", host)
        self.assertIn("readonly property real flyoutX: effectiveAnchorRight ? 0 : panelWidth + effectiveConnectorWidth", host)
        self.assertIn("property int flyoutLaneWidth: lacunaEnabled && panelController.menuRenderable ? maxFlyoutLaneWidth + panelShadowOutset : 0", window)
        self.assertIn("readonly property int panelShadowBlurMax: 28", window)
        self.assertIn("readonly property int panelShadowOutset: frameShadow ? Math.ceil(panelShadowBlurMax + Math.abs(frameShadowOffsetX)) : 0", window)
        self.assertIn("connectorWidth: root.settingsConnectorWidth", window)
        self.assertIn("x: panelHost.connectorX", window)
        self.assertIn("openX: panelHost.flyoutX", window)
        self.assertIn("panelRadius: root.lacunaJoinRadius", window)
        self.assertIn("topLeftCornerState: root.openToLeft ? 0 : -1", flyout)
        self.assertIn("bottomLeftCornerState: root.openToLeft ? 0 : -1", flyout)
        self.assertIn("topRightCornerState: root.openToLeft ? -1 : 0", flyout)
        self.assertIn("bottomRightCornerState: root.openToLeft ? -1 : 0", flyout)
        self.assertIn("property bool backgroundVisible: true", flyout)
        self.assertIn("property real contentProgress: Math.max(0, Math.min(1, progress))", flyout)
        self.assertNotIn("Rectangle.radius", flyout)
        shape_surface = read("lacuna.menu/menu/LacunaShapeSurface.qml")
        self.assertNotIn("surfaceAlpha", shape_surface)
        self.assertIn("readonly property color solidPanelColor", shape_surface)
        self.assertIn("readonly property real curveKappa: lacunaGeometry.curveKappa", connector)
        self.assertIn("property bool backgroundVisible: true", connector)
        self.assertIn("property color foreground: \"#d8dee9\"", connector)
        self.assertIn("readonly property int joinLineGap", connector)
        self.assertIn("id: joinLine", connector)
        self.assertIn("opacity: root.clampedProgress * 0.58", connector)
        self.assertIn("opacity: backgroundVisible ? 1 : 0", connector)
        self.assertNotIn("surfaceAlpha", connector)
        self.assertIn("height: contentHeight + connectorWidth * 2", connector)
        self.assertIn("y: root.connectorWidth + root.contentHeight", connector)
        self.assertGreaterEqual(connector.count("strokeWidth: 0"), 2)
        self.assertIn("property bool backgroundVisible: true", surface)
        self.assertIn("readonly property color solidPanelColor", surface)
        self.assertIn("height: Math.max(0, (root.fullFrame ? root.bottomJoinTop : surface.height) - root.joinTop)", surface)
        self.assertIn("id: barJoinShape", surface)
        self.assertIn("id: bottomFrameJoinShape", surface)
        self.assertIn("LacunaPanelUnifiedSurface", window)
        self.assertLess(window.index("LacunaPanelUnifiedSurface"), window.index("MenuSurface"))
        self.assertIn("shadowEnabled: root.lacunaEnabled && root.frameShadow && (root.sidebarSurfaceVisible || panelController.flyoutRenderable)", window)
        self.assertIn("shadowBlurMax: root.panelShadowBlurMax", window)
        self.assertIn("backgroundVisible: false", window)
        self.assertIn("LacunaDropShadow", unified)
        self.assertIn("source: surfaceSource", unified)
        self.assertIn("Math.max(0, frameThickness + shadowBlurMax + Math.abs(shadowOffsetY))", unified)
        self.assertIn("id: shadowClip", unified)
        self.assertIn("height: Math.max(0, parent.height - root.shadowBottomClipInset)", unified)
        self.assertIn("clip: root.shadowBottomClipInset > 0", unified)
        self.assertIn("id: shadowRenderLayer", unified)
        self.assertIn("MenuSurface {", unified)
        self.assertIn("LacunaPanelConnector {", unified)
        self.assertIn("LacunaAttachedFlyout {", unified)
        self.assertIn("property real contentProgress: Math.max(0, Math.min(1, flyoutProgress))", unified)
        self.assertIn("readonly property real contentProgress: Math.max(0, Math.min(1, flyoutProgress))", read("lacuna.menu/services/PanelController.qml"))
        self.assertIn("progress: root.flyoutProgress", unified)
        self.assertIn("progress: panelController.flyoutProgress", window)
        self.assertIn("backgroundVisible: true", unified)
        self.assertIn("y: root.barBottomY", overlay)
        self.assertIn("readonly property color solidFrameColor", overlay)
        self.assertIn("readonly property real frameAlpha: 1", overlay)
        self.assertIn("readonly property real shadowAlphaCompensation: 1", overlay)
        self.assertIn("shadowOpacity: root.shadowOpacity * root.shadowAlphaCompensation", overlay)
        self.assertNotIn("id: sidebarTopFrameCornerPiece", window)
        self.assertNotIn("id: sidebarBottomFrameCornerPiece", window)

    def test_lacuna_settings_has_pending_save_merge_for_quick_launch_state(self):
        qml = read("lacuna.menu/services/LacunaSettings.qml")

        self.assertIn("function mergePendingSave", qml)
        self.assertIn("pendingSaveTouchedQuickLaunch", qml)
        self.assertIn("pendingSaveTouchedSidebar", qml)
        self.assertIn("queuedTouchedQuickLaunch", qml)
        self.assertIn("queuedTouchedSidebar", qml)
        self.assertIn("queuedTouchedQuickLaunch !== true", qml)
        self.assertIn("merged.customQuickLaunchApps = loadedBase.customQuickLaunchApps", qml)
        self.assertIn("merged.customQuickLaunchNames = loadedBase.customQuickLaunchNames", qml)
        self.assertIn("merged.sidebar = loadedBase.sidebar", qml)

    def test_bar_size_mode_debounces_theme_changes_and_verifies_writes(self):
        qml = read("lacuna.menu/services/BarSizeMode.qml")
        # Theme-name flicker is debounced through a timer rather than reloading
        # both FileViews inline on every change.
        self.assertIn("id: themeReloadTimer", qml)
        self.assertIn("themeReloadTimer.restart()", qml)
        # The patched shell.toml must re-parse to the intended sizes before it
        # is written, so a bad patch can never half-apply a bar size.
        self.assertIn("function patchedValuesMatch", qml)
        self.assertIn("if (!patchedValuesMatch(patched, desired.sizeHorizontal, desired.sizeVertical))", qml)
        self.assertIn("if (!patchedValuesMatch(restored, snapshot.sizeHorizontal, snapshot.sizeVertical))", qml)

    def test_bar_size_theme_mode_is_reachable(self):
        settings = read("lacuna.menu/services/LacunaSettings.qml")
        state_service = read("lacuna.state/Service.qml")
        bar_size = read("lacuna.menu/services/BarSizeMode.qml")
        registry = read("lacuna.menu/menu/MenuRegistry.qml")
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")

        for qml in [settings, state_service]:
            self.assertIn('barSizeMode: "theme"', qml)
            self.assertIn('mode === "theme" || mode === "compact" || mode === "full"', qml)

        self.assertIn('if (value === "theme" || value === "compact" || value === "full") return value', bar_size)
        self.assertIn('if (mode === "theme")', bar_size)
        self.assertIn('savePatch({ barSizeSnapshot: null })', bar_size)
        self.assertIn('if (root.barSizeMode === "theme") return "Theme"', registry)
        self.assertIn('if (root.barSizeMode === "theme") return "Use the active Omarchy theme bar sizing"', registry)
        self.assertIn('{ value: "theme", label: "Theme" }', settings_window)

    def test_lacuna_settings_uses_fileview_for_load_save(self):
        for path in [
            "lacuna.state/Service.qml",
            "lacuna.menu/services/LacunaSettings.qml",
        ]:
            qml = read(path)

            self.assertIn("function applyLoadedText", qml, path)
            self.assertIn("function writePayload", qml, path)
            self.assertIn("settingsFileView.setText(payload)", qml, path)
            self.assertIn("atomicWrites: true", qml, path)
            self.assertIn("suppressFileReloads", qml, path)
            self.assertNotIn("id: loadProc", qml, path)
            self.assertNotIn("id: saveProc", qml, path)
            self.assertNotIn('"bash", "-lc"', qml, path)

    def test_lacuna_settings_load_emits_loaded_signal_without_shadowing(self):
        # Regression: a local `var loaded` in applyLoadedText shadowed the
        # `signal loaded()`, so calling loaded() threw and the pending-save
        # tail never ran. The local must not be named `loaded`.
        for path in [
            "lacuna.state/Service.qml",
            "lacuna.menu/services/LacunaSettings.qml",
        ]:
            qml = read(path)

            self.assertIn("signal loaded()", qml, path)
            self.assertIn("function applyLoadedText", qml, path)
            self.assertIn("var parsed", qml, path)
            self.assertIn("data = parsed", qml, path)
            # The buggy local assignment must be gone.
            self.assertNotIn("data = loaded\n", qml, path)
            self.assertNotIn("loaded = normalize(", qml, path)

    def test_lacuna_settings_backs_up_corrupt_settings_before_defaults(self):
        # Regression: corrupt settings.json silently wiped all customization.
        # The parse-failure path must back the bad file up and flag recovery.
        for path in [
            "lacuna.state/Service.qml",
            "lacuna.menu/services/LacunaSettings.qml",
        ]:
            qml = read(path)

            self.assertIn("recoveredFromCorruptSettings", qml, path)
            self.assertIn("settingsBackupFileView.setText(corrupt)", qml, path)
            self.assertIn('path: root.settingsFile + ".bak"', qml, path)

    def test_curve_kappa_constant_has_single_definition(self):
        # The Bezier circular-arc kappa is defined once in LacunaGeometry and
        # referenced everywhere else, so the molding geometry can never drift.
        literal = "0.5522847498"
        geometry_files = {
            "lacuna.shell-settings/components/LacunaGeometry.qml",
            "lacuna.menu/components/LacunaGeometry.qml",
            "lacuna.bar/LacunaGeometry.qml",
            "lacuna.claude-usage/LacunaGeometry.qml",
            "lacuna.codex-usage/LacunaGeometry.qml",
        }
        for path in sorted(geometry_files):
            self.assertIn("readonly property real curveKappa: " + literal, read(path), path)

        consumers = [
            "lacuna.menu/menu/MenuSurface.qml",
            "lacuna.menu/menu/LacunaFrameOverlay.qml",
            "lacuna.menu/menu/LacunaPanelConnector.qml",
            "lacuna.menu/menu/LacunaAttachedFlyout.qml",
            "lacuna.menu/settings/SettingsWindow.qml",
            "lacuna.menu/settings/OmarchyShellSettingsWindow.qml",
            "lacuna.shell-settings/settings/OmarchyShellSettingsWindow.qml",
            "lacuna.bar/LacunaFrameWindow.qml",
            "lacuna.claude-usage/BarFlyoutSurface.qml",
            "lacuna.codex-usage/BarFlyoutSurface.qml",
        ]
        for path in consumers:
            qml = read(path)
            self.assertIn("readonly property real curveKappa: lacunaGeometry.curveKappa", qml, path)
            self.assertIn("LacunaGeometry { id: lacunaGeometry }", qml, path)

        # The literal must not leak into any other QML file in the suite.
        for qml_path in ROOT.glob("lacuna.*/**/*.qml"):
            rel = qml_path.relative_to(ROOT).as_posix()
            if rel in geometry_files:
                continue
            self.assertNotIn(literal, qml_path.read_text(encoding="utf-8"), rel)

    def test_lacuna_menu_state_uses_fileview_for_load_save(self):
        qml = read("lacuna.menu/services/LacunaMenuState.qml")

        self.assertIn("function savePayload", qml)
        self.assertIn("stateFileView.setText(savePayload())", qml)
        self.assertIn("atomicWrites: true", qml)
        self.assertNotIn("saveCommand", qml)
        self.assertNotIn("id: loadProc", qml)
        self.assertNotIn("id: saveProc", qml)
        self.assertNotIn('"bash", "-lc"', qml)

    def test_qml_processes_do_not_use_noninteractive_login_shells(self):
        login_shell_exceptions = {
            "lacuna.bar/OmarchyBar.qml",
            "lacuna.shell-settings/Panel.qml",
        }
        for path in sorted(ROOT.glob("lacuna.*/*.qml")):
            if path.relative_to(ROOT).as_posix() in login_shell_exceptions:
                continue
            qml = path.read_text(encoding="utf-8")
            self.assertNotIn('"bash", "-lc"', qml, str(path.relative_to(ROOT)))
            self.assertNotIn('"-lc"', qml, str(path.relative_to(ROOT)))

        for path in [
            "lacuna.menu/menu/MenuCommandCatalog.qml",
            "lacuna.shell-settings/Panel.qml",
        ]:
            qml = read(path)
            self.assertIn("Interactive terminal sessions intentionally use a login shell", qml, path)

    def test_settings_persistence_preserves_observed_nightlight_temperatures(self):
        qml = read("lacuna.settings-persistence/Service.qml")

        self.assertIn("function noteNightlightTemperature", qml)
        self.assertIn("function targetNightlightTemperature", qml)
        self.assertIn("temp < 5000", qml)
        self.assertIn("nightlightApplyProc.appliedTemperature", qml)
        self.assertNotIn("expected ? 4000 : 6000", qml)

    def test_custom_quick_launch_context_menu_can_delete_items(self):
        content = read("lacuna.menu/menu/MenuContent.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")

        self.assertIn("signal quickLaunchRemoveRequested(string appId)", content)
        self.assertIn('text: "Delete"', content)
        self.assertIn("function openQuickLaunchContext", content)
        self.assertIn("onSecondaryClicked: function(x, y)", content)
        self.assertIn("root.quickLaunchRemoveRequested(quickLaunchContextAppId)", content)
        self.assertIn("function removeCustomQuickLaunchApp(id)", window)
        self.assertIn("next.customQuickLaunchApps = ids", window)
        self.assertIn("next.customQuickLaunchNames = names", window)
        self.assertIn("lacunaSettings.save(next, true)", window)
        self.assertIn("onQuickLaunchRemoveRequested", window)

    def test_app_picker_does_not_cap_search_results(self):
        picker = read("lacuna.menu/menu/FlyoutAppPickerContent.qml")
        filtered = picker.split("function filteredApps()", 1)[1].split("return list", 1)[0]

        self.assertNotIn("list.length >= 80", filtered)
        self.assertNotIn("break", filtered)

    def test_quick_launch_add_action_lives_in_header_controls(self):
        registry = read("lacuna.menu/menu/MenuRegistry.qml")
        content = read("lacuna.menu/menu/MenuContent.qml")
        section = read("lacuna.menu/menu/MenuSection.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")

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
        registry = read("lacuna.menu/menu/MenuRegistry.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")
        settings = read("lacuna.menu/services/LacunaSettings.qml")
        state_service = read("lacuna.state/Service.qml")
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")

        self.assertIn('instantRestart: false', settings)
        self.assertIn('instantRestart: false', state_service)
        self.assertIn('action: "confirm-system-restart"', registry)
        self.assertNotIn('label: "Restart", hint: "Reboot machine", command: "omarchy system reboot"', registry)
        self.assertIn("property bool pendingSystemRestartConfirmation", window)
        self.assertIn("function requestSystemRestart()", window)
        self.assertIn("function confirmSystemRestart()", window)
        self.assertIn('commands.run("omarchy system reboot")', window)
        self.assertIn('entry.action === "confirm-system-restart"', window)
        self.assertIn('entry.action === "toggle-instant-restart"', window)
        self.assertIn('"Skip Restart Confirmation"', settings_window)
        self.assertIn('"toggle-instant-restart"', settings_window)

    def test_rail_has_no_compact_density_button(self):
        rail = read("lacuna.menu/menu/MenuRail.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")

        self.assertNotIn("signal compactToggleRequested", rail)
        self.assertNotIn("id: compactButton", rail)
        self.assertNotIn("Compact density", rail)
        self.assertNotIn("Normal density", rail)
        self.assertNotIn("onCompactToggleRequested", window)

    def test_idle_indicator_uses_stable_reveal_and_clear_icon(self):
        combined = read("lacuna.indicators/Widget.qml")
        standalone = read("lacuna.idle-inhibitor/Widget.qml")

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
        combined = read("lacuna.indicators/Widget.qml")
        manifest = read_json("lacuna.indicators/manifest.json")

        self.assertFalse(manifest["barWidget"]["defaults"]["showInactive"])
        self.assertIn("showInactive", [entry["key"] for entry in manifest["barWidget"]["schema"]])
        self.assertIn("readonly property int pendingCount", combined)
        self.assertIn('if (id === "Dnd") return dnd || pendingCount > 0', combined)
        self.assertIn('pendingCount + " pending notification"', combined)
        self.assertIn('bar.run("omarchy shell notifications showHistory")', combined)
        self.assertIn('bar.run("omarchy toggle notification silencing")', combined)
        self.assertIn('else if (recording) bar.run("omarchy capture screenrecording --stop-recording")', combined)
        self.assertIn("Qt.LeftButton | Qt.MiddleButton | Qt.RightButton", combined)
        self.assertIn('indicatorButton.indicatorId === "Dnd" && root.pendingCount > 0 && !root.dnd', combined)

    def test_indicator_status_roles_have_visible_palette_slots(self):
        combined = read("lacuna.indicators/Widget.qml")

        self.assertIn('if (id === "Dnd") return "color13"', combined)
        self.assertIn('if (id === "NightLight") return "color11"', combined)
        self.assertIn('if (id === "StayAwake") return "color14"', combined)
        self.assertIn('if (id === "ScreenRecording") return "color9"', combined)
        self.assertIn('if (id === "Dictation") return "color6"', combined)
        self.assertIn('return "foreground"', combined)

    def test_topbar_tooltip_targets_expose_hover_state(self):
        root_target_widgets = [
            "lacuna.audio",
            "lacuna.bluetooth",
            "lacuna.clock",
            "lacuna.bar-size-pill",
            "lacuna.claude-usage",
            "lacuna.codex-usage",
            "lacuna.compact-pill",
            "lacuna.idle-inhibitor",
            "lacuna.indicators",
            "lacuna.nightlight",
            "lacuna.menu-button",
            "lacuna.network",
            "lacuna.notifications",
            "lacuna.power",
            "lacuna.script-pill",
            "lacuna.screen-recording",
            "lacuna.system-update",
            "lacuna.temperature",
            "lacuna.theme",
            "lacuna.voxtype",
            "lacuna.wallpaper",
            "lacuna.weather",
        ]

        for plugin in root_target_widgets:
            qml = read(f"{plugin}/Widget.qml")
            self.assertIn("readonly property bool tooltipHovered", qml, plugin)
            if plugin == "lacuna.indicators":
                self.assertIn("hoveredIndicators > 0", qml, plugin)
            else:
                self.assertIn("mouseArea.containsMouse", qml, plugin)

        system_stats = read("lacuna.system-stats/Widget.qml")
        self.assertIn("readonly property bool tooltipHovered", system_stats)
        self.assertIn("parent.bar.showTooltip(parent, parent.tooltip)", system_stats)
        self.assertIn('path: "/proc/stat"', system_stats)
        self.assertIn('path: "/proc/meminfo"', system_stats)
        self.assertNotIn('"head -n1 /proc/stat"', system_stats)
        self.assertNotIn('"head -n3 /proc/meminfo"', system_stats)

        for path in [
            "lacuna.mpris/components/LacunaMprisButton.qml",
            "lacuna.workspaces/components/LacunaWorkspaceButton.qml",
        ]:
            qml = read(path)
            self.assertIn("readonly property bool tooltipHovered", qml, path)
            self.assertIn("clickArea.containsMouse", qml, path)

    def test_lacuna_native_replacement_widgets_have_expected_contracts(self):
        replacements = {
            "lacuna.system-update": "SystemUpdate",
            "lacuna.clock": "Clock",
            "lacuna.weather": "Weather",
            "lacuna.notifications": "NotificationCenter",
            "lacuna.nightlight": "NightLight",
            "lacuna.idle-inhibitor": "idleInhibitor",
            "lacuna.screen-recording": "screenRecording",
            "lacuna.voxtype": "voxtype",
            "lacuna.tray": "Tray",
            "lacuna.bluetooth": "BluetoothPanel",
            "lacuna.network": "NetworkPanel",
            "lacuna.audio": "AudioPanel",
            "lacuna.power": "PowerPanel",
        }

        example = read_json("config/shell.lacuna-native-replacements.example.json")
        layout_ids = []
        for section in ["left", "center", "right"]:
            layout_ids.extend(entry["id"] for entry in example["bar"]["layout"][section])

        omarchy_default_system_widgets = {
            "lacuna.bluetooth": "omarchy.bluetooth",
            "lacuna.network": "omarchy.network",
            "lacuna.audio": "omarchy.audio",
            "lacuna.power": "omarchy.power",
        }

        for plugin_id, native_id in replacements.items():
            manifest = read_json(f"{plugin_id}/manifest.json")
            qml = read(f"{plugin_id}/Widget.qml")

            self.assertEqual(plugin_id, manifest["id"])
            self.assertIn("bar-widget", manifest["kinds"])
            self.assertEqual("Widget.qml", manifest["entryPoints"]["barWidget"])
            self.assertEqual("Lacuna", manifest["barWidget"]["category"])
            if plugin_id in omarchy_default_system_widgets:
                self.assertIn(omarchy_default_system_widgets[plugin_id], layout_ids)
                self.assertNotIn(plugin_id, layout_ids)
            else:
                self.assertIn(plugin_id, layout_ids)
            self.assertNotIn(f'moduleName: "{native_id}"', qml)
            self.assertIn(f'moduleName: "{plugin_id}"', qml)
            self.assertIn("barSize", qml)
            if plugin_id != "lacuna.tray":
                self.assertIn("colorProfile", qml)

    def test_lacuna_tray_dispatches_status_notifier_context_menus(self):
        manifest = read_json("lacuna.tray/manifest.json")
        qml = read("lacuna.tray/Widget.qml")
        registry = read("lacuna.menu/menu/MenuRegistry.qml")

        self.assertEqual("lacuna.tray", manifest["id"])
        self.assertEqual("Widget.qml", manifest["entryPoints"]["barWidget"])
        self.assertIn("bar-widget", manifest["kinds"])
        self.assertNotIn("QsMenuAnchor", qml)
        self.assertIn("import Quickshell", qml)
        self.assertIn("property bool trayMenuOpen", qml)
        self.assertIn("property var activeTrayItem: null", qml)
        self.assertIn("property var activeTrayAnchor: null", qml)
        self.assertIn("readonly property bool expanded: drawerHovered || trayMenuOpen", qml)
        self.assertIn("function openTrayMenu(item, anchorItem, mouse)", qml)
        self.assertIn("if (!item.menu)", qml)
        self.assertIn("QsMenuOpener", qml)
        self.assertIn("menu: root.activeTrayItem ? root.activeTrayItem.menu : null", qml)
        self.assertIn("id: trayMenuPopup", qml)
        self.assertIn("model: trayMenuOpener.children", qml)
        self.assertIn("menuRow.modelData.triggered()", qml)
        self.assertIn("onPressed: function(mouse)", qml)
        self.assertIn("mouse.button === Qt.RightButton", qml)
        self.assertIn("trayItemRoot.displayMenu(mouse)", qml)
        self.assertIn("trayItemRoot.modelData.onlyMenu", qml)
        self.assertIn("item.display(anchorItem.QsWindow.window, point.x, point.y)", qml)
        self.assertNotIn("trayMenuReset", qml)
        self.assertNotIn("markTrayMenuRequested", qml)
        self.assertIn('root.bar.shell.updateEntryInline(id, { id: id, pinned: pinned, hidden: hidden })', qml)
        self.assertIn('if (key === "lacuna.tray") return "apps"', registry)

    def test_system_stats_uses_tabler_cpu_icon(self):
        qml = read("lacuna.system-stats/Widget.qml")
        icon = read("lacuna.system-stats/assets/tabler/cpu.svg")

        self.assertIn('iconSource: Qt.resolvedUrl("assets/tabler/cpu.svg")', qml)
        self.assertNotIn('iconSource: Qt.resolvedUrl("assets/tabler/assembly-filled.svg")', qml)
        self.assertIn("icon-tabler-cpu", icon)

    def test_weather_splits_leading_condition_icon_from_label(self):
        qml = read("lacuna.weather/Widget.qml")

        self.assertIn("function leadingWeatherIcon(raw)", qml)
        self.assertIn("function textWithoutLeadingWeatherIcon(raw)", qml)
        self.assertIn('readonly property string weatherIcon: leadingWeatherIcon(weatherText) || "󰖐"', qml)
        self.assertIn("text: root.weatherIcon", qml)
        self.assertIn("text: root.displayText", qml)
        self.assertNotIn("text: root.weatherText", qml)

    def test_theme_and_wallpaper_commands_use_current_omarchy_routes_without_extra_ipc(self):
        theme = read("lacuna.theme/Widget.qml")
        widget = read("lacuna.wallpaper/Widget.qml")
        catalog = read("lacuna.menu/menu/MenuCommandCatalog.qml")
        panel = read("lacuna.shell-settings/Panel.qml")

        self.assertIn("omarchy theme switcher", theme)
        self.assertIn("omarchy theme set", theme)
        self.assertIn("omarchy theme current", theme)
        self.assertIn("omarchy theme list", theme)
        self.assertIn("function nextBackgroundCommand()", widget)
        self.assertIn("bar.run(root.nextBackgroundCommand())", widget)
        for qml in [theme, widget, catalog, panel]:
            self.assertIn("omarchy theme", qml)
            self.assertNotIn("refreshThemeBackgroundCommand", qml)
            self.assertNotIn("applyCurrentBackgroundCommand", qml)
            self.assertNotIn("background setInstant", qml)

    def test_background_animations_use_single_selected_effect_contract(self):
        manifest = read_json("lacuna.aurora-drift/manifest.json")
        qml = read("lacuna.aurora-drift/Overlay.qml")
        rain_manifest = read_json("lacuna.rainfall-overlay/manifest.json")
        rain = read("lacuna.rainfall-overlay/Overlay.qml")
        cinematic_manifest = read_json("lacuna.cinematic-light-overlay/manifest.json")
        cinematic = read("lacuna.cinematic-light-overlay/Overlay.qml")
        crt_manifest = read_json("lacuna.crt-overlay/manifest.json")
        crt = read("lacuna.crt-overlay/Overlay.qml")
        vhs_manifest = read_json("lacuna.vhs-overlay/manifest.json")
        vhs = read("lacuna.vhs-overlay/Overlay.qml")
        film_manifest = read_json("lacuna.film-grain-overlay/manifest.json")
        film = read("lacuna.film-grain-overlay/Overlay.qml")
        dust_manifest = read_json("lacuna.dust-motes-overlay/manifest.json")
        dust = read("lacuna.dust-motes-overlay/Overlay.qml")
        vignette_manifest = read_json("lacuna.background-vignette/manifest.json")
        vignette = read("lacuna.background-vignette/Overlay.qml")
        settings = read("lacuna.menu/services/LacunaSettings.qml")
        state_service = read("lacuna.state/Service.qml")
        registry = read("lacuna.menu/menu/MenuRegistry.qml")
        shell_settings_panel = read("lacuna.shell-settings/Panel.qml")
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")
        example = read_json("config/shell.lacuna-native-replacements.example.json")

        self.assertEqual("lacuna.aurora-drift", manifest["id"])
        self.assertEqual(["overlay"], manifest["kinds"])
        self.assertEqual("Overlay.qml", manifest["entryPoints"]["overlay"])
        self.assertEqual("lacuna.rainfall-overlay", rain_manifest["id"])
        self.assertEqual(["overlay"], rain_manifest["kinds"])
        self.assertEqual("Overlay.qml", rain_manifest["entryPoints"]["overlay"])
        self.assertEqual("lacuna.cinematic-light-overlay", cinematic_manifest["id"])
        self.assertEqual(["overlay"], cinematic_manifest["kinds"])
        self.assertEqual("persistent", cinematic_manifest["activation"])
        self.assertIs(cinematic_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", cinematic_manifest["entryPoints"]["overlay"])
        self.assertEqual("lacuna.film-grain-overlay", film_manifest["id"])
        self.assertEqual(["overlay"], film_manifest["kinds"])
        self.assertEqual("persistent", film_manifest["activation"])
        self.assertIs(film_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", film_manifest["entryPoints"]["overlay"])
        self.assertEqual("lacuna.dust-motes-overlay", dust_manifest["id"])
        self.assertEqual(["overlay"], dust_manifest["kinds"])
        self.assertEqual("persistent", dust_manifest["activation"])
        self.assertIs(dust_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", dust_manifest["entryPoints"]["overlay"])
        self.assertEqual(1, cinematic_manifest["defaults"]["intensity"])
        self.assertEqual("lightLeak", cinematic_manifest["defaults"]["stylePreset"])
        self.assertTrue(cinematic_manifest["defaults"]["slowDrift"])
        self.assertFalse(cinematic_manifest["defaults"]["occasionalSweeps"])
        self.assertFalse(cinematic_manifest["defaults"]["activeShimmer"])
        self.assertEqual("lacuna.crt-overlay", crt_manifest["id"])
        self.assertEqual(["overlay"], crt_manifest["kinds"])
        self.assertEqual("persistent", crt_manifest["activation"])
        self.assertIs(crt_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", crt_manifest["entryPoints"]["overlay"])
        self.assertFalse(crt_manifest["defaults"]["foregroundOverlay"])
        self.assertTrue(crt_manifest["defaults"]["distortion"])
        self.assertTrue(crt_manifest["defaults"]["bloomPulse"])
        self.assertFalse(vhs_manifest["defaults"]["foregroundOverlay"])
        self.assertEqual("lacuna.background-vignette", vignette_manifest["id"])
        self.assertEqual(["overlay"], vignette_manifest["kinds"])
        self.assertEqual("persistent", vignette_manifest["activation"])
        self.assertIs(vignette_manifest["keepLoaded"], True)
        self.assertEqual("Overlay.qml", vignette_manifest["entryPoints"]["overlay"])
        self.assertIn("backgroundVignette", settings)
        self.assertIn("ignoreBackgroundAnimationLayer", settings)
        self.assertIn("backgroundVignetteSettings()", vignette)
        self.assertIn("WlrLayer.Background", vignette)
        self.assertIn("WlrLayer.Bottom", vignette)
        self.assertIn("function resolveFrameRect(screen)", vignette)
        self.assertIn("readonly property string frameGeometryKey: resolveFrameGeometryKey()", vignette)
        self.assertIn("function resolveFrameGeometryKey()", vignette)
        self.assertIn("root.shell.bar.lacunaFrameGeometryKey", vignette)
        self.assertIn("root.shell.bar.lacunaFrameContentRect(screen)", vignette)
        self.assertIn("readonly property var frameRect: {", vignette)
        self.assertIn("root.frameGeometryKey", vignette)
        self.assertIn("modelData.width", vignette)
        self.assertIn("modelData.height", vignette)
        self.assertIn("return root.resolveFrameRect(modelData)", vignette)
        self.assertIn("x: Math.round(vignetteWindow.frameRect.x)", vignette)
        self.assertIn("y: Math.round(vignetteWindow.frameRect.y)", vignette)
        self.assertIn("width: Math.round(vignetteWindow.frameRect.width)", vignette)
        self.assertIn("height: Math.round(vignetteWindow.frameRect.height)", vignette)
        self.assertIn("radius: Math.max(0, Number(vignetteWindow.frameRect.radius || 0))", vignette)
        self.assertIn('color: "transparent"', vignette)
        self.assertIn("clip: true", vignette)
        self.assertIn('source: Qt.resolvedUrl("assets/vignette.svg")', vignette)
        self.assertIn("sourceSize.width: width", vignette)
        self.assertIn("sourceSize.height: height", vignette)
        self.assertIn("fillMode: Image.Stretch", vignette)
        self.assertNotIn("LacunaVignette", vignette)
        self.assertNotIn("Canvas {", vignette)
        self.assertNotIn("gradient: Gradient", vignette)
        self.assertNotIn("ShaderEffect", vignette)
        self.assertTrue((ROOT / "lacuna.background-vignette/assets/vignette.svg").exists())
        vignette_asset = read("lacuna.background-vignette/assets/vignette.svg")
        self.assertIn('id="left-edge"', vignette_asset)
        self.assertIn('id="right-edge"', vignette_asset)

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
        self.assertIn("grainCount", [entry["key"] for entry in film_manifest["schema"]])
        self.assertIn("grainSize", [entry["key"] for entry in film_manifest["schema"]])
        self.assertIn("moteCount", [entry["key"] for entry in dust_manifest["schema"]])
        self.assertIn("moteSize", [entry["key"] for entry in dust_manifest["schema"]])
        self.assertIn("mouseReactive", [entry["key"] for entry in dust_manifest["schema"]])
        self.assertIn("mouseInfluence", [entry["key"] for entry in dust_manifest["schema"]])
        self.assertIn('backgroundEffectEnabled("auroraDrift", true)', qml)
        self.assertIn('backgroundEffectEnabled("filmGrain", true)', film)
        self.assertIn('backgroundEffectEnabled("dustMotes", true)', dust)
        self.assertIn('backgroundEffectEnabled("rainfall", true)', rain)
        self.assertIn('backgroundEffectEnabled("cinematicLight", true)', cinematic)
        self.assertIn('backgroundEffectEnabled("crt", true)', crt)
        self.assertIn("foregroundOverlay: false", settings)
        self.assertIn("foregroundOverlay: false", state_service)
        self.assertIn("activeEffects: [", settings)
        self.assertIn("activeEffects: [", state_service)
        self.assertIn("function normalizeBackgroundEffectStack", settings)
        self.assertIn("function normalizeBackgroundEffectStack", state_service)
        self.assertIn("backgroundEffects.activeEffect", qml)
        self.assertIn("backgroundEffects.activeEffect", vhs)
        self.assertIn("backgroundEffects.activeEffect", film)
        self.assertIn("backgroundEffects.activeEffect", dust)
        self.assertIn("backgroundEffects.activeEffect", rain)
        self.assertIn("backgroundEffects.activeEffect", cinematic)
        self.assertIn("backgroundEffects.activeEffect", crt)
        for overlay in [qml, vhs, film, dust, rain, cinematic, crt, read("lacuna.god-rays-overlay/Overlay.qml")]:
            self.assertIn("Array.isArray(backgroundEffects.activeEffects)", overlay)
            self.assertIn("backgroundEffects.activeEffects.length", overlay)
            self.assertIn("readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()", overlay)
            self.assertIn("function backgroundForegroundOverlayEnabled", overlay)
            self.assertIn("backgroundEffects.foregroundOverlay === true", overlay)
            self.assertIn("WlrLayershell.layer: root.foregroundOverlay ? WlrLayer.Overlay : WlrLayer.Bottom", overlay)
        self.assertIn('target: "lacuna-film-grain-overlay"', film)
        self.assertIn('WlrLayershell.namespace: "lacuna-film-grain-overlay"', film)
        self.assertIn("Timer {", film)
        self.assertIn("grainTick++", film)
        self.assertIn('target: "lacuna-dust-motes-overlay"', dust)
        self.assertIn('WlrLayershell.namespace: "lacuna-dust-motes-overlay"', dust)
        self.assertIn('readonly property bool mouseReactive: boolSetting("mouseReactive", true)', dust)
        self.assertIn('readonly property real mouseInfluence: clamp(numberSetting("mouseInfluence", 0.28), 0, 1)', dust)
        self.assertIn('cursorProc.command = ["hyprctl", "cursorpos", "-j"]', dust)
        self.assertIn("function applyCursorPayload", dust)
        self.assertIn("cursorDecayTimer.restart()", dust)
        self.assertIn("readonly property real cursorFalloff", dust)
        self.assertIn("transform: [", dust)
        self.assertIn("Translate {", dust)
        self.assertIn("mote.cursorFalloff * root.cursorKick", dust)
        self.assertIn("SequentialAnimation on x", dust)
        self.assertIn("SequentialAnimation on y", dust)
        self.assertIn('target: "lacuna-aurora-drift"', qml)
        self.assertIn('WlrLayershell.namespace: "lacuna-aurora-drift"', qml)
        self.assertIn('target: "lacuna-rainfall-overlay"', rain)
        self.assertIn('WlrLayershell.namespace: "lacuna-rainfall-overlay"', rain)
        self.assertIn('target: "lacuna-cinematic-light-overlay"', cinematic)
        self.assertIn('WlrLayershell.namespace: "lacuna-cinematic-light-overlay"', cinematic)
        self.assertIn('target: "lacuna-crt-overlay"', crt)
        self.assertIn('WlrLayershell.namespace: "lacuna-crt-overlay"', crt)
        self.assertIn("mask: Region {}", qml)
        self.assertIn("mask: Region {}", film)
        self.assertIn("mask: Region {}", dust)
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
        self.assertIn("readonly property real ambientWashOpacity", cinematic)
        self.assertIn("readonly property real ambientBandOpacity", cinematic)
        self.assertIn("property real ambientPulse", cinematic)
        self.assertIn("running: root.effectVisible && root.slowDriftEnabled", cinematic)
        self.assertIn("readonly property int hiddenPause: root.slowDriftEnabled", cinematic)
        self.assertIn("readonly property int darkPause: root.slowDriftEnabled", cinematic)
        self.assertIn('if (preset === "cinematicFlare" || preset === "anamorphicGlow") return preset', cinematic)
        self.assertIn('if (mode === "occasionalSweeps" || mode === "activeShimmer") return mode', cinematic)
        self.assertIn("motionModes: {", cinematic)
        self.assertIn("readonly property real xSwing: 0.055", qml)
        self.assertIn("readonly property real ySwing: 0.04", qml)
        self.assertIn("readonly property int cycleXDirection", cinematic)
        self.assertIn("readonly property int cycleYDirection", cinematic)
        self.assertIn('activeEffect: "trackingLines"', settings)
        self.assertIn('"trackingLines"', settings)
        self.assertIn('filmGrain: {', settings)
        self.assertIn('dustMotes: {', settings)
        self.assertIn('auroraDrift: {', settings)
        self.assertIn('rainfall: {', settings)
        self.assertIn('cinematicLight: {', settings)
        self.assertIn('godRays: {', settings)
        self.assertIn('crt: {', settings)
        self.assertIn('activeEffect: "trackingLines"', state_service)
        self.assertIn('"trackingLines"', state_service)
        self.assertIn('filmGrain: {', state_service)
        self.assertIn('dustMotes: {', state_service)
        self.assertIn('auroraDrift: {', state_service)
        self.assertIn('rainfall: {', state_service)
        self.assertIn('cinematicLight: {', state_service)
        self.assertIn('godRays: {', state_service)
        self.assertIn('crt: {', state_service)
        self.assertIn("function activeBackgroundEffect", registry)
        self.assertIn("function activeBackgroundEffects", registry)
        self.assertIn("function backgroundEffectStackIndex", registry)
        self.assertIn("function backgroundEffectStackCount", registry)
        self.assertIn("function backgroundEffectStackWarning", registry)
        self.assertIn("function backgroundEffectOptions", registry)
        self.assertIn("root.pluginRegistry.isEnabled(id)", registry)
        self.assertIn("pluginRegistry.isEnabled(id)", shell_settings_panel)
        self.assertIn("shellBarWidgetExistsAnywhere(id)", registry)
        self.assertIn("function backgroundEffectPluginId", registry)
        self.assertIn('if (effectId === "filmGrain") return "lacuna.film-grain-overlay"', registry)
        self.assertIn('if (effectId === "dustMotes") return "lacuna.dust-motes-overlay"', registry)
        self.assertIn('if (effectId === "auroraDrift") return "lacuna.aurora-drift"', registry)
        self.assertIn('if (effectId === "rainfall") return "lacuna.rainfall-overlay"', registry)
        self.assertIn('if (effectId === "cinematicLight") return "lacuna.cinematic-light-overlay"', registry)
        self.assertIn("function backgroundEffectForegroundEnabled", registry)
        self.assertIn("function backgroundEffectsForegroundOverlayEnabled", registry)
        self.assertIn("function backgroundVignetteIntensity", registry)
        self.assertIn("function backgroundVignetteIntensityName", registry)
        self.assertIn("function backgroundVignetteIntensityHint", registry)
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
        self.assertIn('if (effectId === "filmGrain") return "Film Grain"', registry)
        self.assertIn('if (effectId === "dustMotes") return "Dust Motes"', registry)
        self.assertIn('if (effectId === "rainfall") return "Rainfall"', registry)
        self.assertIn('if (effectId === "cinematicLight") return "Cinematic Light"', registry)
        self.assertIn('if (effectId === "godRays") return "God Rays"', registry)
        self.assertIn('if (effectId === "crt") return "CRT"', registry)
        self.assertIn('"toggle-background-effects"', settings_window)
        self.assertIn('{ id: "animations", icon: "background", label: "Animations"', settings_window)
        self.assertIn('navRow("background", "Animations", root.registry.backgroundEffectsHint(), "animations"', settings_window)
        self.assertIn('if (sectionId === "animations")', settings_window)
        self.assertIn('return backgroundEffectRows()', settings_window)
        self.assertIn('width: 560', settings_window)
        self.assertIn('height: 660', settings_window)
        self.assertNotIn('].concat(backgroundEffectRows())', settings_window)
        self.assertNotIn('showLabels: true', settings_window)
        self.assertIn('"toggle-background-vignette"', settings_window)
        self.assertIn('"Vignette Intensity"', settings_window)
        self.assertIn('"slider"', settings_window)
        self.assertIn('"set-background-vignette-intensity-"', settings_window)
        self.assertIn('"Global"', settings_window)
        self.assertIn('"Active Animations"', settings_window)
        self.assertIn('"Add Animation"', settings_window)
        self.assertIn('"Effect Controls"', settings_window)
        self.assertIn('"stack-effect"', settings_window)
        self.assertIn("SettingsStackRow", settings_window)
        self.assertIn('"move-background-effect-up-"', settings_window)
        self.assertIn('"move-background-effect-down-"', settings_window)
        self.assertIn("function activateEntryAction", settings_window)
        self.assertIn('next.control = "button"', settings_window)
        slider = read("lacuna.menu/components/LacunaSlider.qml")
        stack_row = read("lacuna.menu/settings/SettingsStackRow.qml")
        self.assertIn('root.control === "slider"', read("lacuna.menu/settings/SettingsRow.qml"))
        self.assertIn("LacunaSlider", read("lacuna.menu/settings/SettingsRow.qml"))
        self.assertIn("signal sliderChanged(string value)", read("lacuna.menu/settings/SettingsRow.qml"))
        self.assertIn("signal edited(real value)", slider)
        self.assertIn("id: sliderHitArea", slider)
        self.assertIn("anchors.fill: parent", slider)
        self.assertIn("cursorShape: Qt.PointingHandCursor", slider)
        self.assertIn("onPressed: function(mouse)", slider)
        self.assertIn("root.previewAt(mouse.x)", slider)
        self.assertIn("onPositionChanged: function(mouse)", slider)
        self.assertIn("if (pressed) root.previewAt(mouse.x)", slider)
        self.assertIn("onReleased: function(mouse)", slider)
        self.assertIn("root.commitEdit()", slider)
        self.assertIn("signal edited(real value)", slider)
        self.assertIn("property bool editing: false", slider)
        self.assertIn("Behavior on scale", slider)
        self.assertIn("visualNormalizedValue", slider)
        self.assertNotIn("Math.round(raw / step) * step", slider)
        self.assertIn("signal moveUp()", stack_row)
        self.assertIn("signal moveDown()", stack_row)
        self.assertIn('icon: "arrow-up"', stack_row)
        self.assertIn('icon: "arrow-down"', stack_row)
        self.assertIn('name: "plus"', stack_row)
        self.assertIn('text: "Add"', stack_row)
        self.assertIn('"set-background-effect-"', window)
        self.assertNotIn('selectRow("background", "Animation"', settings_window)
        self.assertIn('"toggle-background-effect-foreground-"', settings_window)
        self.assertIn('root.registry.backgroundEffectEnabled("cinematicLight")', settings_window)
        self.assertIn('"set-cinematic-light-style-"', settings_window)
        self.assertIn('"set-cinematic-light-intensity-"', settings_window)
        self.assertIn('"toggle-cinematic-light-motion-slowDrift"', settings_window)
        self.assertIn('"toggle-cinematic-light-motion-occasionalSweeps"', settings_window)
        self.assertIn('"toggle-cinematic-light-motion-activeShimmer"', settings_window)
        self.assertIn("SettingsSelectRow", settings_window)
        self.assertIn("function setBackgroundEffectsEnabled", window)
        self.assertIn("function setBackgroundVignetteEnabled", window)
        self.assertIn("function setBackgroundVignetteIntensity", window)
        self.assertIn("function setBackgroundEffect", window)
        self.assertIn("function setBackgroundEffectStackEnabled", window)
        self.assertIn("function moveBackgroundEffectInStack", window)
        self.assertIn("next.backgroundEffects.activeEffects = stack", window)
        self.assertIn('entry.action.indexOf("toggle-background-effect-") === 0 && entry.action.indexOf("toggle-background-effect-foreground-") !== 0', window)
        self.assertIn('entry.action.indexOf("move-background-effect-up-") === 0', window)
        self.assertIn('entry.action.indexOf("move-background-effect-down-") === 0', window)
        self.assertIn("function toggleBackgroundEffectForeground", window)
        self.assertIn("next.backgroundEffects.foregroundOverlay = enabled === true", window)
        self.assertIn("setShellPluginEnabled(pluginId, true)", window)
        self.assertIn("function setCinematicLightSetting", window)
        self.assertIn("function toggleCinematicLightMotion", window)
        self.assertIn('shell.updateEntryInline("lacuna.cinematic-light-overlay", next)', window)
        self.assertNotIn("next.foregroundOverlay = enabled === true", window)
        self.assertIn('entry.action.indexOf("toggle-background-effect-foreground-") === 0', window)
        self.assertIn('entry.action.indexOf("set-background-vignette-intensity-") === 0', window)
        self.assertIn('entry.action.indexOf("set-cinematic-light-style-") === 0', window)
        self.assertIn('entry.action.indexOf("set-cinematic-light-intensity-") === 0', window)
        self.assertIn('entry.action.indexOf("toggle-cinematic-light-motion-") === 0', window)
        self.assertNotIn('"toggle-background-effect-auroraDrift"', settings_window)
        self.assertIn("lacuna.aurora-drift", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.film-grain-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.dust-motes-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.rainfall-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.cinematic-light-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.god-rays-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.crt-overlay", [entry["id"] for entry in example["plugins"]])
        self.assertIn("lacuna.background-vignette", [entry["id"] for entry in example["plugins"]])

    def test_youtube_music_video_waits_for_high_res_background_stream(self):
        overlay = read("lacuna.youtube-music-video/Overlay.qml")
        bar = read("lacuna.bar/Bar.qml")

        self.assertIn("readonly property string highResVideoSource", overlay)
        self.assertIn("readonly property bool waitingForHighRes", overlay)
        self.assertIn("readonly property int backgroundRequestRevision", overlay)
        self.assertIn("property bool fadeCoverVisible: false", overlay)
        self.assertIn("property real fadeCoverOpacity: 0", overlay)
        self.assertIn("property double fadeCoverStartedAt: 0", overlay)
        self.assertIn("property int fadeRevealDelay: 0", overlay)
        self.assertIn("property bool fadeCoverRising: false", overlay)
        self.assertIn("property int fadeCoverDuration: fadeInDuration", overlay)
        self.assertIn("property bool exitTransitionActive: false", overlay)
        self.assertIn("property bool clearingWallpaperAfterExit: false", overlay)
        self.assertIn("property int wallpaperFadeGateDelay: 0", overlay)
        self.assertIn("property bool wallpaperPositionRefreshPending: false", overlay)
        self.assertIn('property string wallpaperPositionRefreshKey: ""', overlay)
        self.assertIn("readonly property bool wallpaperLayerVisible", overlay)
        self.assertIn("readonly property int fadeInDuration: 7000", overlay)
        self.assertIn("readonly property int fadeOutDuration: 7000", overlay)
        self.assertIn("readonly property int exitFadeToBlackDuration", overlay)
        self.assertIn("readonly property int exitFadeFromBlackDuration", overlay)
        self.assertIn("import QtMultimedia", overlay)
        self.assertIn("function resolveFrameRect(screen)", overlay)
        self.assertIn("root.shell.bar.lacunaFrameContentRect(screen)", overlay)
        self.assertIn("MediaPlayer", overlay)
        self.assertIn("VideoOutput", overlay)
        self.assertIn("AudioOutput", overlay)
        self.assertIn("muted: true", overlay)
        self.assertIn("fillMode: VideoOutput.PreserveAspectCrop", overlay)
        self.assertIn("source: videoWindow.renderable ? root.activeSource : \"\"", overlay)
        self.assertIn('WlrLayershell.namespace: "lacuna-youtube-music-video"', overlay)
        self.assertIn('WlrLayershell.namespace: "lacuna-youtube-music-video-fade"', overlay)
        self.assertIn("WlrLayershell.layer: WlrLayer.Background", overlay)
        self.assertNotIn("WlrLayershell.layer: WlrLayer.Bottom", overlay)
        self.assertIn("x: Math.round(videoWindow.frameRect.x)", overlay)
        self.assertIn("width: Math.round(videoWindow.frameRect.width)", overlay)
        self.assertIn("radius: Math.max(0, Number(videoWindow.frameRect.radius || 0))", overlay)
        self.assertIn("if (waitingForHighRes) holdFadeCover()", overlay)
        self.assertIn("onBackgroundRequestRevisionChanged", overlay)
        self.assertIn("fadeCoverStartedAt = Date.now()", overlay)
        self.assertIn("fadeCoverRising = true", overlay)
        self.assertIn("function beginWallpaperExit()", overlay)
        self.assertIn("function clearWallpaperNow()", overlay)
        self.assertIn("exitClearTimer.restart()", overlay)
        self.assertIn("id: exitClearTimer", overlay)
        self.assertIn("activeSource !== videoSource && !fadeCoverRising", overlay)
        self.assertIn("wallpaperFadeGateDelay = fadeInDuration", overlay)
        self.assertIn("function fadeInRemaining()", overlay)
        self.assertIn("var remainingFadeIn = fadeInRemaining()", overlay)
        self.assertIn("wallpaperFadeGateTimer.restart()", overlay)
        self.assertIn("service.updatePlaybackPosition()", overlay)
        self.assertIn("id: wallpaperPositionRefreshTimer", overlay)
        self.assertIn("wallpaperPositionRefreshKey !== refreshKey", overlay)
        self.assertIn("root.wallpaperPositionRefreshKey = root.videoSource + \"#\" + root.backgroundRequestRevision", overlay)
        self.assertIn("fadeRevealDelay = Math.max(500, fadeInDuration - elapsed)", overlay)
        self.assertIn("visible: renderable", overlay)
        self.assertIn("visible: targetMatched && root.fadeCoverVisible", overlay)
        self.assertIn("interval: root.fadeRevealDelay", overlay)
        self.assertIn("id: wallpaperFadeGateTimer", overlay)
        self.assertIn("interval: 500", overlay)
        self.assertIn("root.releaseFadeCoverSoon()", overlay)
        self.assertIn("function syncVideoPosition(force)", overlay)
        self.assertIn("Math.abs(player.position - target) > 900", overlay)
        self.assertIn("backgroundPlayer.play()", overlay)
        self.assertIn("backgroundPlayer.pause()", overlay)
        self.assertIn('if (root.activeSource === "") backgroundPlayer.stop()', overlay)
        self.assertIn("interval: 1000", overlay)
        self.assertIn("duration: root.fadeCoverDuration", overlay)
        self.assertIn("fadeCoverDuration: root.fadeCoverDuration", overlay)
        self.assertIn("exitTransitionActive: root.exitTransitionActive", overlay)
        self.assertIn('backend: "qml-framed-video"', overlay)
        self.assertIn("function lacunaFrameContentRect(screen)", bar)
        self.assertIn("var bleed = root.frameEnabled ? Math.max(t + 2, Math.ceil(root.frameRadius * 0.5)) : 0", bar)
        self.assertIn("innerWidth: Math.max(1, right - x)", bar)
        self.assertNotIn("mpvpaper", overlay)
        self.assertNotIn("input-ipc-server=", overlay)
        self.assertNotIn("adoptBackgroundPlayback", overlay)
        self.assertNotIn("preferredVideoSource", overlay)
        self.assertNotIn("previewVideoSource", overlay)

    def test_workspace_lacuna_selected_state_has_no_fill_or_underline(self):
        qml = read("lacuna.workspaces/components/LacunaWorkspaceButton.qml")

        self.assertNotIn("root.active ? 0.08", qml)
        self.assertNotIn("height: 2\n    color: root.accent\n    opacity: root.active", qml)
        self.assertIn('property string designStyle: "lacuna"', qml)

    def test_lacuna_menu_button_uses_lacuna_icon_asset(self):
        qml = read("lacuna.menu-button/Widget.qml")

        self.assertIn("circle-dotted-letter-l.svg", qml)
        self.assertNotIn("layout-sidebar-left-expand-filled.svg", qml)

    def test_lacuna_menu_uses_unified_accent_except_danger(self):
        for path in [
            "lacuna.menu/menu/MenuContent.qml",
            "lacuna.menu/menu/MenuRail.qml",
            "lacuna.menu/settings/SettingsWindow.qml",
            "lacuna.menu/settings/OmarchyShellSettingsWindow.qml",
        ]:
            qml = read(path)
            tone_function = qml.split("function toneAccent", 1)[1].split("\n  }", 1)[0]

            self.assertIn('if (tone === "danger") return root.dangerAccent', tone_function, path)
            if path.endswith("OmarchyShellSettingsWindow.qml"):
                self.assertIn('if (tone === "shell") return root.shellAccent', tone_function, path)
                self.assertIn("return root.navAccent", tone_function, path)
            else:
                self.assertIn("return root.accent", tone_function, path)
                self.assertNotIn("return root.shellAccent", tone_function, path)
                self.assertNotIn("return root.sessionAccent", tone_function, path)
                self.assertNotIn("return root.navAccent", tone_function, path)

        docs = read("docs/lacuna-design-system/01-color.md")
        self.assertIn("One accent for everything non-destructive", docs)
        self.assertIn("reserved for destructive actions only", docs)
        self.assertIn('tone === "danger" ? danger : accent', docs)

    def test_design_token_consumers_use_lacuna_not_carbon_flag(self):
        paths = [
            "lacuna.menu/settings/SettingsRail.qml",
            "lacuna.menu/settings/SettingsRow.qml",
            "lacuna.menu/modules/LacunaMenuItem.qml",
            "lacuna.menu/menu/MenuContent.qml",
            "lacuna.menu/menu/FlyoutAppPickerContent.qml",
        ]

        for path in paths:
            qml = read(path)
            self.assertNotIn("designTokens.carbon", qml, path)

    def test_design_tokens_retire_carbon_lineage(self):
        # Phase A of the Lacuna design language: the design-system core no
        # longer names Carbon. The persisted-settings layer (LacunaSettings /
        # lacuna.state) still migrates a legacy "carbon" value to "lacuna";
        # that is covered separately and intentionally kept.
        for path in [
            "lacuna.menu/services/DesignTokens.qml",
            "lacuna.shell-settings/services/DesignTokens.qml",
        ]:
            qml = read(path)
            self.assertNotIn("carbon", qml, path)
            self.assertIn('if (styleName === "lacuna") return "lacuna"', qml, path)

        rail = read("lacuna.menu/menu/MenuRail.qml")
        self.assertNotIn('"carbon"', rail)
        self.assertIn('designStyle: "lacuna"', rail)

    def test_recess_interaction_vocabulary_named_and_wired(self):
        # Phase B of the Lacuna design language: the "recess" interaction-depth
        # family is named in the token registry and consumed by the state
        # layer, replacing inline alpha literals (pure indirection).
        tokens = read("lacuna.shell-settings/components/LacunaTokens.qml")
        for name in ("recessRest", "recessHover", "recessPress"):
            self.assertIn(name, tokens)

        layer = read("lacuna.shell-settings/components/LacunaStateLayer.qml")
        self.assertIn("property real hoverOpacity: tokens.recessHover", layer)
        self.assertIn("property real pressOpacity: tokens.recessPress", layer)
        self.assertIn("LacunaTokens { id: tokens }", layer)
        self.assertNotIn("property real hoverOpacity: 0.06", layer)

    def test_theme_exposes_design_language_color_roles(self):
        # Phase C: named, theme-derived color roles (01-color.md). Additive
        # aliases over the canonical derivations plus the exposed danger/warning
        # roles; no rendered-value change.
        theme = read("lacuna.menu/services/Theme.qml")
        self.assertIn("readonly property color field: background", theme)
        self.assertIn("readonly property color plate: panelBackground", theme)
        self.assertIn("readonly property color ink: foreground", theme)
        self.assertIn("readonly property color whisper: muted", theme)
        self.assertIn("readonly property color seam: border", theme)
        self.assertIn('readonly property color danger: color("color9")', theme)
        self.assertIn('readonly property color warning: color("color11")', theme)

        profile = read("shared/qml/simple-bar/ColorProfile.qml")
        self.assertIn("readonly property color ink: foreground", profile)

    def test_motion_uses_one_named_reveal_scale(self):
        # Phase D: a single named "reveal" scale (03-motion.md) replaces the
        # legacy + noctalia timing sets. animation* survive as same-value
        # aliases; the divergent legacy* scale is removed.
        for path in [
            "lacuna.menu/services/MotionTokens.qml",
            "lacuna.shell-settings/services/MotionTokens.qml",
        ]:
            qml = read(path)
            for name in ("instant", "quick", "color", "reveal", "settle",
                         "ambient", "pulse", "sweep"):
                self.assertIn("property int %s:" % name, qml, path)
            self.assertNotIn("legacyFast", qml, path)
            self.assertNotIn("legacyNormal", qml, path)
            self.assertNotIn("legacySlow", qml, path)
            self.assertNotIn("legacyDurationFor", qml, path)
            self.assertIn("readonly property int animationNormal: reveal", qml, path)
            self.assertIn("function duration(baseMs)", qml, path)
            self.assertIn("panelBezierCurve", qml, path)

        anim = read("lacuna.shell-settings/components/LacunaAnim.qml")
        self.assertIn('if (value === "fast") return 150', anim)
        self.assertIn('if (value === "slow") return 450', anim)

        widget = read("shared/qml/simple-bar/MotionTokens.qml")
        self.assertIn("readonly property int quick: 150", widget)
        self.assertIn("readonly property int hoverDuration: quick", widget)

    def test_typography_adopts_hack_nerd_font_propo(self):
        # Phase E follow-up: shell chrome uses the proportional Nerd Font
        # variant; Tektur stays the display/title face. No JetBrains Mono
        # literals or quoted monospace fallbacks remain in QML.
        tokens = read("lacuna.shell-settings/components/LacunaTokens.qml")
        self.assertIn('readonly property string monoFont: "Hack Nerd Font Propo"', tokens)

        for path in [
            "lacuna.menu/menu/MenuWindow.qml",
            "lacuna.menu/menu/MenuContent.qml",
            "lacuna.shell-settings/settings/SettingsRow.qml",
        ]:
            qml = read(path)
            self.assertNotIn("JetBrains Mono", qml, path)
            self.assertNotIn('"Hack Nerd Font"', qml, path)
            self.assertIn('"Hack Nerd Font Propo"', qml, path)

        for qml_path in ROOT.glob("lacuna.*/**/*.qml"):
            rel = qml_path.relative_to(ROOT).as_posix()
            if rel == "lacuna.bar/OmarchyBar.qml":
                continue
            self.assertNotIn('"monospace"', qml_path.read_text(encoding="utf-8"), rel)

        # Tektur remains the title/display face.
        self.assertIn("Tektur", read("lacuna.menu/menu/MenuContent.qml"))

    def test_reduce_motion_setting_feeds_the_motion_hook(self):
        # Cleanup follow-up: the central reduced-motion hook
        # (MotionTokens.animationDisabled) is now bound to a real persisted
        # setting and shared into the structural animators.
        settings = read("lacuna.state/Service.qml")
        self.assertIn("reduceMotion: false", settings)
        self.assertIn("next.reduceMotion = value.reduceMotion === true", settings)

        window = read("lacuna.menu/menu/MenuWindow.qml")
        self.assertIn("reduceMotionEnabled", window)
        self.assertIn("animationDisabled: root.reduceMotionEnabled", window)
        # The shared instance reaches the panel + content animators.
        self.assertIn("motionTokens: sharedMotion", window)

    def test_visible_metaphor_treatments_are_wired(self):
        # Visible redesign: the identity is carried by seams + the gap (lacuna)
        # motif, gated to the lacuna style. (The darker "void well" was dropped:
        # tonal recess can't read on near-black themes.)
        for path in [
            "lacuna.menu/services/DesignTokens.qml",
            "lacuna.shell-settings/services/DesignTokens.qml",
        ]:
            tokens = read(path)
            self.assertIn("readonly property bool gappedDividers: lacuna", tokens)
            self.assertIn("readonly property int dividerGap:", tokens)
            self.assertNotIn("voidWells", tokens)

        content = read("lacuna.menu/menu/MenuContent.qml")
        self.assertIn("readonly property color seam:", content)
        self.assertIn("root.designTokens.dividerGap > 0", content)

        # The section seam (gapped) repeats the lacuna mark down the menu.
        self.assertIn("root.designTokens.dividerGap", read("lacuna.menu/menu/MenuSection.qml"))

        # The void well is gone.
        self.assertNotIn("contentWell", read("lacuna.menu/menu/MenuWindow.qml"))

    def test_daily_launch_system_editor_uses_omarchy_editor_launcher(self):
        qml = read("lacuna.menu/menu/MenuAppModel.qml")

        self.assertIn('role === "editor") return root.commands.hyprExec("omarchy launch editor")', qml)
        old_editor_helper = "omarchy" + "-launch-editor"
        self.assertNotIn(f'role === "editor") return root.commands.hyprExec("{old_editor_helper}")', qml)

    def test_sidebar_default_mode_is_separate_from_runtime_toggle(self):
        settings = read("lacuna.menu/services/LacunaSettings.qml")
        sidebar = read("lacuna.menu/services/SidebarState.qml")
        window = read("lacuna.menu/menu/MenuWindow.qml")
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")

        self.assertIn('defaultMode: "off"', settings)
        self.assertIn("function setDefaultMode", sidebar)
        # The persisted preference and the session toggle are named distinctly,
        # and save() persists the real runtime collapse rather than a value
        # re-derived from defaultMode.
        self.assertIn("readonly property string desiredDefaultMode: defaultMode", sidebar)
        self.assertIn("readonly property bool runtimeCollapsed: collapsed", sidebar)
        self.assertIn("collapsed: collapsed", sidebar)
        self.assertIn("settingsService.save(next, false, true)", sidebar)
        self.assertNotIn('collapsed: defaultMode === "rail"', sidebar)
        self.assertIn("settingsService.hasLoaded !== false", sidebar)
        self.assertIn("function sidebarDefaultMode", window)
        self.assertIn("function sidebarDefaultKeepsMenuOpen", window)
        self.assertIn("function sidebarSettingsLoaded", window)
        self.assertIn("return lacunaSettings && lacunaSettings.hasLoaded === true", window)
        self.assertIn("function applyInitialSidebarDefaultNow", window)
        self.assertIn("initialSidebarDefaultRetry.restart()", window)
        self.assertIn("if (!sidebarSettingsLoaded())", window)
        self.assertIn("if (!lacunaEnabled) return false", window)
        self.assertIn("if (!sidebarSettingsLoaded()) return false", window)
        self.assertIn("lacunaSettings.data.sidebar", window)
        self.assertIn("var mode = sidebarDefaultMode()", window)
        self.assertIn("sidebarDefaultMode: root.sidebarDefaultMode()", window)
        self.assertNotIn("sidebarDefaultMode: sidebarState.defaultMode", window)
        self.assertIn("if (!root.sidebarSettingsLoaded())", window)
        self.assertIn("if (root.sidebarDefaultKeepsMenuOpen())", window)
        self.assertIn("root.applySidebarDefaultState()", window)
        self.assertLess(
            window.index("if (root.sidebarDefaultKeepsMenuOpen())"),
            window.index("if (root.hostManaged) return"),
        )
        self.assertIn('entry.action.indexOf("set-sidebar-default-")', window)
        self.assertIn('"Sidebar Default"', settings_window)
        self.assertNotIn('"set-sidebar-display-"', settings_window)

    def test_lacuna_settings_persistence_service_restores_idle_state(self):
        manifest = read_json("lacuna.settings-persistence/manifest.json")
        qml = read("lacuna.settings-persistence/Service.qml")
        panel = read("lacuna.settings-persistence/Panel.qml")

        self.assertEqual("Lacuna Settings Persistence", manifest["name"])
        self.assertEqual(["service", "panel"], manifest["kinds"])
        self.assertEqual("Service.qml", manifest["entryPoints"]["service"])
        self.assertEqual("Panel.qml", manifest["entryPoints"]["panel"])
        self.assertIn("settings-persistence.json", qml)
        self.assertIn("manageIdle", qml)
        self.assertIn("manageNightlight", qml)
        self.assertIn("omarchy shell idle status", qml)
        self.assertIn("omarchy shell idle \" + (enabled ? \"enable\" : \"disable\")", qml)
        self.assertIn("omarchy toggle nightlight --status", qml)
        self.assertIn("hyprctl hyprsunset temperature", qml)
        self.assertIn('target: "lacuna-settings-persistence"', qml)
        self.assertIn("Idle Inhibit", panel)
        self.assertIn("Nightlight", panel)
        self.assertIn("setManagedToggles", panel)

    def test_window_gaps_toggle_uses_theme_size_when_enabled(self):
        service = read("lacuna.shell-settings/Service.qml")
        state_script = read("lacuna.shell-settings/scripts/omarchy-shell-settings-state.py")
        settings_window = read("lacuna.shell-settings/settings/OmarchyShellSettingsWindow.qml")

        self.assertIn("rm -f \" + quote(stockFile) + \" \" + quote(oldLacunaFile) + \" \" + quote(lacunaFile)", service)
        self.assertIn("Disable Hyprland window gaps without changing theme borders", service)
        self.assertNotIn("border_size", service)
        self.assertIn("live_gaps_enabled = any(value and value > 0 for value in [gaps_in, gaps_out])", state_script)
        self.assertIn("Use the active theme's tiled-window gap size", settings_window)

    def test_shell_settings_service_load_has_timeout_watchdog(self):
        # A hung state subprocess must not wedge the service. A watchdog
        # terminates it, a single resolver clears `loading` exactly once
        # (so process-exit and timeout can't double-count), the data is
        # marked stale, and a bounded retry is scheduled.
        for path in [
            "lacuna.shell-settings/Service.qml",
            "lacuna.menu/services/OmarchyShellSettingsService.qml",
        ]:
            qml = read(path)
            self.assertIn("function resolveLoad", qml, path)
            self.assertIn("function handleLoadTimeout", qml, path)
            self.assertIn("id: loadWatchdog", qml, path)
            self.assertIn("onTriggered: root.handleLoadTimeout()", qml, path)
            self.assertIn("loadWatchdog.restart()", qml, path)
            self.assertIn("if (loadProc.running) loadProc.running = false", qml, path)
            self.assertIn("property bool stale: false", qml, path)
            self.assertIn("loadFailureStreak <= maxAutoRetries", qml, path)
            self.assertIn("id: retryTimer", qml, path)

    def test_fake_frame_topbar_reserve_matches_rendered_caster_size(self):
        window = read("lacuna.menu/menu/MenuWindow.qml")
        overlay = read("lacuna.menu/menu/LacunaFrameOverlay.qml")
        reserve = read("lacuna.menu/menu/LacunaFrameReserveWindow.qml")

        self.assertIn("property int barEdgeCasterSize: frameThickness", window)
        self.assertIn("property int sidebarReserveExtra: 0", window)
        self.assertIn("readonly property bool externalLeftFrameReserveActive: frameMode === \"fullframe\" && !root.leftBar && !root.panelOnRight", window)
        self.assertIn("readonly property int barOwnedLeftFrameReserve: barOwnsLacunaFrame && externalLeftFrameReserveActive && !sidebarSurfaceVisible ? frameThickness : 0", window)
        self.assertIn("readonly property int sidebarReserveSize: sidebarReserveActive ? Math.max(0, panelWidth + effectiveSidebarReserveExtra - barOwnedLeftFrameReserve) : 0", window)
        self.assertIn('property string frameReserveMode: "auto"', read("lacuna.menu/menu/MenuRegistry.qml"))
        self.assertIn('reserveMode: "auto"', read("lacuna.menu/services/LacunaSettings.qml"))
        self.assertIn("readonly property bool frameReserveFlush: frameReserveMode === \"flush\" || hyprWindowGapsDisabled || (frameReserveMode === \"auto\" && fakeFullscreenWorkspaceActive())", window)
        self.assertIn("readonly property bool barOwnsLacunaFrame: hostManaged || (shell && shell.bar && shell.bar.lacunaFrameHost === true)", window)
        self.assertIn("property bool hostManaged: false", window)
        self.assertIn("if (root.hostManaged) return", window)
        self.assertIn("readonly property int frameOverlayWidth: !lacunaEnabled || barOwnsLacunaFrame || frameMode === \"off\" ? 0", window)
        self.assertIn('mode: root.lacunaEnabled && !root.barOwnsLacunaFrame ? root.frameMode : "off"', window)
        self.assertIn('shadowEnabled: root.lacunaEnabled && !root.barOwnsLacunaFrame && root.frameShadow && root.frameMode !== "off"', window)
        self.assertIn("readonly property bool frameReserveActive: !barOwnsLacunaFrame && lacunaEnabled", window)
        self.assertIn("readonly property int effectiveSidebarReserveExtra: frameReserveFlush ? 0 : sidebarReserveExtra", window)
        self.assertIn("readonly property bool hyprWindowGapsDisabled", window)
        self.assertIn("shellHyprState.windowGapsEnabled === false", window)
        self.assertIn("function hyprGapValue(value)", window)
        self.assertIn("function fakeFullscreenWorkspaceActive()", window)
        self.assertIn("function gapslessWorkspaceActive()", window)
        self.assertIn("return hyprWindowGapsDisabled || fakeFullscreenWorkspaceActive()", window)
        self.assertIn("Hyprland.monitorFor(root.sidebarScreen)", window)
        self.assertIn("if (monitor && monitor.activeWorkspace) return monitor.activeWorkspace", window)
        self.assertIn("import Quickshell.Hyprland", window)
        self.assertIn("property int hostBarSize: 0", window)
        self.assertIn("if (hostBarSize > 0) return positiveInt(hostBarSize, verticalFallback)", window)
        self.assertIn("if (hostBarSize > 0) return positiveInt(hostBarSize, configBarHeight())", window)
        self.assertIn("barEdgeCasterSize: root.barEdgeCasterSize", window)
        self.assertIn("cornerPieces: sidebarState.cornerPieces", window)
        self.assertIn("function holdFlyoutAfterSettingsActivation()", window)
        self.assertIn("function openPayload(payloadJson)", window)
        self.assertIn("function openPayloadFlyout(payload)", window)
        self.assertIn('if (flyout === "settings")', window)
        self.assertIn('if (flyout === "shellSettings")', window)
        self.assertIn('if (flyout === "appPicker")', window)
        self.assertIn("if (flyoutFocusClearHold.running) return", window)
        self.assertIn("id: flyoutFocusClearHold", window)
        self.assertNotIn("Date.now()", window)
        self.assertIn("property int railReferenceBarHeight: Math.max(1, root.topBar && root.barHeight > 0 ? root.barHeight : configBarHeight())", window)
        self.assertIn("property int railPanelWidth: Math.round(railReferenceBarHeight)", window)
        self.assertIn("property int railButtonWidth: railPanelWidth", window)
        self.assertIn("property int railLeftInset: 0", window)
        self.assertIn("property int railRightInset: 0", window)
        self.assertIn("property int panelWidth: sidebarSurfaceVisible ? (sidebarState.collapsed ? railPanelWidth : fullPanelWidth) : 0", window)
        self.assertIn("property real barEdgeCasterSize: frameThickness", overlay)
        self.assertIn("readonly property real sidebarOccupiedWidth: sidebarWidth + (sidebarCornerVisible ? sidebarCornerWidth : 0)", overlay)
        self.assertIn("readonly property real horizontalBarShadowX: leftEdgeOccupied ? Math.max(0, sidebarX + sidebarOccupiedWidth) : 0", overlay)
        self.assertIn("readonly property real horizontalBarShadowWidth", overlay)
        self.assertIn("visible: root.topBar && root.horizontalBarShadowWidth > 0", overlay)
        self.assertIn("x: root.horizontalBarShadowX", overlay)
        self.assertIn("property bool cornerPieces: true", overlay)
        self.assertNotIn("id: surfaceShadowLayer", overlay)
        self.assertIn("LacunaPanelUnifiedSurface", window)
        self.assertIn("flyoutRenderable: panelController.flyoutRenderable", window)
        self.assertIn("connectorRenderable: root.sidebarSurfaceVisible && panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0", window)
        self.assertIn("backgroundVisible: false", window)
        self.assertIn("source: frameSource", overlay)
        self.assertNotIn("id: sidebarSilhouette", overlay)
        self.assertNotIn("id: connectorSilhouette", overlay)
        self.assertNotIn("id: flyoutSilhouette", overlay)
        self.assertNotIn("drawCoveredSurfaceSilhouettes", overlay)
        self.assertIn("root.fullFrame && root.cornerPieces && root.topBar && !root.leftBar && !root.leftEdgeOccupied", overlay)
        surface = read("lacuna.menu/menu/MenuSurface.qml")
        self.assertIn("property bool fullFrame: false", surface)
        self.assertIn("id: bottomFrameJoinShape", surface)
        self.assertIn("visible: root.backgroundVisible && root.fullFrame && root.cornerPieces && root.bodyRightInset > 0", surface)
        self.assertIn("fullFrame: root.frameMode === \"fullframe\"", window)
        self.assertIn("frameThickness: root.frameThickness", window)
        self.assertNotIn("import QtQuick.Shapes", window)
        self.assertIn("frameReserveRight: frameReserveActive && frameMode === \"fullframe\" && !root.panelOnRight && !root.rightBar ? frameThickness + reservePadding : 0", window)
        self.assertIn("topBarShadowReserve: frameReserveActive && root.topBar ? reservePadding : 0", window)
        self.assertIn("WlrLayershell.namespace: layerNamespace + \"-\" + edge", reserve)
        self.assertIn("edge suffix keeps", reserve)

    def test_plugin_manifests_have_existing_item_entrypoints(self):
        kind_entry_points = {
            "bar": "bar",
            "bar-widget": "barWidget",
            "panel": "panel",
            "overlay": "overlay",
            "menu": "menu",
            "service": "service",
        }

        manifest_paths = plugin_manifest_paths()
        self.assertTrue(manifest_paths)
        self.assertFalse((ROOT / "plugins").exists())

        for manifest_path in manifest_paths:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(1, manifest.get("schemaVersion"), manifest_path)
            self.assertIsInstance(manifest.get("id"), str, manifest_path)
            self.assertTrue(manifest["id"].startswith("lacuna."), manifest_path)
            self.assertFalse(manifest["id"].startswith("omarchy."), manifest_path)
            self.assertEqual(manifest_path.parent.name, manifest["id"], manifest_path)
            for required in ["name", "version", "kinds", "entryPoints"]:
                self.assertIn(required, manifest, manifest_path)

            entry_points = manifest.get("entryPoints", {})
            self.assertIsInstance(entry_points, dict, manifest_path)
            self.assertTrue(entry_points, manifest_path)

            for kind in manifest["kinds"]:
                self.assertIn(kind, kind_entry_points, manifest_path)
                self.assertIn(kind_entry_points[kind], entry_points, manifest_path)

            for entry_path in entry_points.values():
                self.assertIsInstance(entry_path, str, manifest_path)
                self.assertFalse(entry_path.startswith("/"), manifest_path)
                self.assertNotIn("..", entry_path, manifest_path)
                qml_path = manifest_path.parent / entry_path
                self.assertTrue(qml_path.exists(), qml_path)
                self.assertNotIn("ShellRoot", qml_path.read_text(encoding="utf-8"), qml_path)

    def test_plugin_manifest_schemas_have_coherent_defaults(self):
        for manifest_path in plugin_manifest_paths():
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            containers = []
            if isinstance(manifest.get("barWidget"), dict):
                containers.append(("barWidget", manifest["barWidget"]))
            containers.append(("root", manifest))

            for label, container in containers:
                schema = container.get("schema", [])
                defaults = container.get("defaults", {})
                if not schema:
                    continue

                self.assertIsInstance(defaults, dict, (manifest_path, label))
                for entry in schema:
                    key = entry["key"]
                    self.assertIn(key, defaults, (manifest_path, label, key))
                    self.assertIn("defaultValue", entry, (manifest_path, label, key))
                    self.assertEqual(defaults[key], entry["defaultValue"], (manifest_path, label, key))

    def test_command_runners_do_not_log_successful_command_payloads(self):
        for path in [
            "lacuna.menu/services/CommandRunner.qml",
            "lacuna.shell-settings/CommandRunner.qml",
        ]:
            qml = read(path)
            self.assertNotIn("console.log", qml, path)
            self.assertIn("console.warn(\"lacuna command failed:\"", qml, path)
            self.assertIn("property var failureQueue", qml, path)
            self.assertIn("function notifyFailure", qml, path)
            self.assertIn("function drainFailures", qml, path)
            self.assertIn("onExited: root.drainFailures()", qml, path)

    def test_youtube_music_favorites_are_persisted_and_exposed(self):
        service = read("lacuna.youtube-music/Service.qml")

        for snippet in [
            "property var favorites: []",
            "property int favoritesRevision: 0",
            "readonly property int favoritesLength: favoritesRevision >= 0 ? favorites.length : 0",
            "readonly property bool currentFavorite: favoritesRevision >= 0 && isFavorite(currentTrack)",
            "version: 3",
            "favorites: normalizeUniqueTrackList(source.favorites, 500)",
            "repeatMode: normalizeRepeatMode(source.repeatMode)",
            "favorites: favorites",
            "repeatMode: repeatMode",
            "favorites = restored.favorites",
            "repeatMode = restored.repeatMode",
            "function normalizeUniqueTrackList",
            "function normalizeRepeatMode",
            "function isYoutubeUrl(value)",
            "function normalizeYoutubeUrl(value)",
            "function playUrl(url)",
            "readonly property string defaultSuggestionsQuery",
            "property bool pendingDefaultSuggestions: false",
            "function loadDefaultSuggestions()",
            "pendingDefaultSuggestions = true",
            "if (root.pendingDefaultSuggestions && root.ytdlpAvailable) root.loadDefaultSuggestions()",
            "videoIdFromUrl(normalizedUrl)",
            "Paste a YouTube URL",
            "function favoriteIndex(track)",
            "function isFavorite(track)",
            "function favoriteTrack(track)",
            "function unfavoriteTrack(track)",
            "function toggleFavorite(track)",
            "function removeFavorite(index)",
            "function playFavorite(index)",
            "function clearFavorites()",
            "function setRepeatMode(mode)",
            "function cycleRepeatMode()",
            "function handlePlaybackEnded()",
            "if (repeatMode === \"one\" && currentTrack)",
            "playNextFromQueue(true, repeatMode === \"all\")",
            "stop()",
            "onRepeatModeChanged: scheduleStateSave()",
            "playbackProbeFailures >= 2",
            "property int backgroundRequestRevision: 0",
            "backgroundRequestRevision += 1",
            "if (hasTrack && (backgroundVideoEnabled || backgroundStreamUrl === \"\")) resolveBackground(currentTrack)",
            "resolvingBackground = false",
            "backgroundStreamUrl = \"\"",
            "backgroundRequestUrl = \"\"",
            "if (hasTrack && previewStreamUrl === \"\" && !resolvingPreview) resolvePreview(currentTrack)",
            "backgroundRequestRevision: root.backgroundRequestRevision",
            "repeatMode: root.repeatMode",
            "onFavoritesChanged: {",
            "favoritesRevision += 1",
            "favoritesLength: root.favoritesLength",
            "currentFavorite: root.currentFavorite",
            "function toggleFavoriteCurrent(): string",
            "function cycleRepeatMode(): string",
        ]:
            self.assertIn(snippet, service)

    def test_youtube_music_favorites_are_available_in_menu_ui(self):
        flyout = read("lacuna.menu/menu/FlyoutYoutubeMusicContent.qml")
        tile = read("lacuna.menu/menu/YoutubeMusicTile.qml")
        icons = read("lacuna.menu/components/LacunaTablerIcon.qml")

        for snippet in [
            'id: "favorites"',
            'icon: "heart"',
            'label: "Favorites"',
            "readonly property string repeatMode",
            "readonly property int favoritesLength",
            "readonly property int favoritesRevision",
            "readonly property bool inputIsYoutubeUrl",
            "service.playUrl(searchInput.text)",
            "service.loadDefaultSuggestions()",
            "function ensureDefaultSuggestions()",
            "id: defaultSuggestionsTimer",
            "defaultSuggestionsTimer.restart()",
            "onOpenChanged: ensureDefaultSuggestions()",
            "onActiveTabChanged: ensureDefaultSuggestions()",
            'text: "Search or paste URL"',
            'icon: root.inputIsYoutubeUrl ? "player-play" : "search"',
            "id: transportControls",
            'visible: root.activeTab !== "search"',
            "id: durationBadgeText",
            "text: modelData.duration || \"\"",
            "function isFavorite(track)",
            "var revision = favoritesRevision",
            "root.service.clearFavorites()",
            "root.service.toggleFavorite(modelData)",
            "root.service.playFavorite(index)",
            "root.service.removeFavorite(index)",
            "Favorite tracks from Search or Queue",
            "id: favoritesScroll",
            "id: headerFavoriteButton",
            "showLabels: false",
            "root.service.cycleRepeatMode()",
            'icon: root.repeatMode === "one" ? "repeat-once" : "repeat"',
            "model: root.favoritesRevision >= 0 && root.service && root.service.favorites ? root.service.favorites : []",
        ]:
            self.assertIn(snippet, flyout)

        self.assertIn('icon: root.service && root.service.currentFavorite ? "heart-filled" : "heart"', flyout)
        self.assertIn('icon: root.currentFavorite ? "heart-filled" : "heart"', tile)
        self.assertIn("readonly property int favoritesRevision", tile)
        self.assertIn("id: tileFavoriteButton", tile)
        self.assertIn("anchors.right: parent.right", tile)
        self.assertIn("anchors.rightMargin: root.tileInset + tileFavoriteButton.width", tile)
        self.assertIn("root.service.toggleFavorite(root.service.currentTrack)", tile)
        self.assertIn("root.service.toggleBackgroundVideo()", tile)
        self.assertNotIn("root.service.setBackgroundVideoEnabled(true)", tile)
        self.assertIn("root.service.cycleRepeatMode()", tile)
        self.assertIn('icon: root.repeatMode === "one" ? "repeat-once" : "repeat"', tile)
        self.assertIn("readonly property real playbackPosition", tile)
        self.assertIn("readonly property bool localPreviewVisible: hasTrack && !sentToBackground", tile)
        self.assertIn("function syncPreviewPosition(force)", tile)
        self.assertIn("if (!localPreviewVisible) {", tile)
        self.assertIn("previewPlayer.pause()", tile)
        self.assertIn("previewPlayer.setPosition(target)", tile)
        self.assertIn("onPlaybackPositionChanged: syncPreviewPosition(false)", tile)
        self.assertIn('name === "heart-filled"', icons)
        self.assertIn('if (icon === "heart" || icon === "heart-filled")', icons)
        self.assertIn('if (icon === "repeat")', icons)
        self.assertIn('if (icon === "repeat-once")', icons)

    def test_lacuna_manifest_metadata_describes_install_groups(self):
        manifests = {
            path.parent.name: json.loads(path.read_text(encoding="utf-8"))
            for path in plugin_manifest_paths()
        }
        standalone = {
            "lacuna.audio",
            "lacuna.aurora-drift",
            "lacuna.background-vignette",
            "lacuna.bar-seam",
            "lacuna.bar-size-pill",
            "lacuna.bluetooth",
            "lacuna.cinematic-light-overlay",
            "lacuna.claude-usage",
            "lacuna.clock",
            "lacuna.codex-usage",
            "lacuna.crt-overlay",
            "lacuna.desktop-clock",
            "lacuna.dust-motes-overlay",
            "lacuna.film-grain-overlay",
            "lacuna.god-rays-overlay",
            "lacuna.idle-inhibitor",
            "lacuna.indicators",
            "lacuna.mpris",
            "lacuna.network",
            "lacuna.nightlight",
            "lacuna.notifications",
            "lacuna.power",
            "lacuna.rainfall-overlay",
            "lacuna.screen-recording",
            "lacuna.script-pill",
            "lacuna.settings-persistence",
            "lacuna.system-stats",
            "lacuna.system-update",
            "lacuna.temperature",
            "lacuna.theme",
            "lacuna.tray",
            "lacuna.vhs-overlay",
            "lacuna.voxtype",
            "lacuna.wallpaper",
            "lacuna.weather",
            "lacuna.workspaces",
            "lacuna.youtube-music",
            "lacuna.youtube-music-video",
        }
        bundle_only = set(manifests) - standalone

        self.assertEqual(
            {
                "lacuna.compact-pill",
                "lacuna.bar",
                "lacuna.menu",
                "lacuna.menu-button",
                "lacuna.shell-settings",
                "lacuna.state",
                "lacuna.theme-preloader",
            },
            bundle_only,
        )
        for plugin_id, manifest in manifests.items():
            metadata = manifest.get("lacuna", {})
            self.assertIsInstance(metadata.get("standalone"), bool, plugin_id)
            self.assertIn(metadata.get("bundle"), {"standalone", "core", "theme", "legacy"}, plugin_id)
            self.assertIsInstance(metadata.get("requires"), list, plugin_id)
            self.assertIsInstance(metadata.get("recommends"), list, plugin_id)
            for dependency in metadata["requires"] + metadata["recommends"]:
                self.assertIn(dependency, manifests, plugin_id)

        for plugin_id in standalone:
            self.assertTrue(manifests[plugin_id]["lacuna"]["standalone"], plugin_id)
            self.assertEqual("standalone", manifests[plugin_id]["lacuna"]["bundle"], plugin_id)
        for plugin_id in bundle_only:
            self.assertFalse(manifests[plugin_id]["lacuna"]["standalone"], plugin_id)

        self.assertEqual(["lacuna.menu"], manifests["lacuna.menu-button"]["lacuna"]["requires"])
        self.assertEqual(
            ["lacuna.state", "lacuna.shell-settings"],
            manifests["lacuna.menu"]["lacuna"]["requires"],
        )
        self.assertEqual(
            ["lacuna.state", "lacuna.shell-settings", "lacuna.menu"],
            manifests["lacuna.bar"]["lacuna"]["requires"],
        )
        self.assertEqual(["lacuna.bar-size-pill"], manifests["lacuna.compact-pill"]["lacuna"]["requires"])

    def test_lacuna_bar_is_bar_option_frame_host(self):
        manifest = read_json("lacuna.bar/manifest.json")
        bar = read("lacuna.bar/Bar.qml")
        adapter = read("lacuna.bar/OmarchyBarAdapter.qml")
        frame = read("lacuna.bar/LacunaFrameWindow.qml")
        omarchy_bar = read("lacuna.bar/OmarchyBar.qml")

        self.assertEqual(["bar"], manifest["kinds"])
        self.assertEqual("Bar.qml", manifest["entryPoints"]["bar"])
        self.assertIn('property string omarchyPath: ""', bar)
        self.assertIn("property var barWidgetRegistry: null", bar)
        self.assertIn("property var barConfig: ({})", bar)
        self.assertNotIn("required property string omarchyPath", bar)
        self.assertIn("property bool lacunaFrameHost: true", bar)
        self.assertIn("readonly property bool barHidden: omarchyBar.barItem && omarchyBar.barItem.barHidden === true", bar)
        self.assertIn("readonly property bool hostedMenuOpen: hostedMenu.menuState && hostedMenu.menuState.open === true", bar)
        self.assertIn('import "../lacuna.menu/menu"', bar)
        self.assertIn('import "../lacuna.menu/services"', bar)
        self.assertIn("readonly property string lacunaMenuSourceDir", bar)
        self.assertIn('id: "lacuna.menu"', bar)
        self.assertIn("readonly property bool hostedSidebarVisible", bar)
        self.assertIn("hostBarSize: root.barSize", bar)
        self.assertIn("readonly property bool hostedSidebarOnLeft", bar)
        self.assertIn("function hostedSidebarOccupiesEdge(edge, screen)", bar)
        self.assertIn("readonly property real hostedSidebarFrameOcclusionWidth", bar)
        self.assertIn("readonly property string lacunaFrameGeometryKey", bar)
        self.assertIn("hostedSidebarFrameOcclusionWidth", bar)
        self.assertIn("The full-frame cutout is cast from the visible sidebar body edge", bar)
        self.assertIn("pushes", bar)
        self.assertIn("the cutout and shadow past the actual frame edge", bar)
        self.assertNotIn("hostedSidebarOccupiedWidth", bar)
        self.assertIn("Theme {", bar)
        self.assertIn("function toggleMenu(payloadJson)", bar)
        self.assertIn("MenuWindow", bar)
        self.assertIn("hostManaged: true", bar)
        self.assertIn('root.shell.ensureService("lacuna.state")', bar)

        menu_entry = read("lacuna.menu/Menu.qml")
        self.assertIn("readonly property bool barHostAvailable", menu_entry)
        self.assertIn("shell.bar.lacunaFrameHost === true", menu_entry)
        self.assertIn("function unloadFallback", menu_entry)
        self.assertIn("onBarHostAvailableChanged", menu_entry)
        self.assertIn("fallbackLoader.active = false", menu_entry)
        self.assertIn("shell.bar.openMenu(payloadJson || \"{}\")", menu_entry)
        self.assertIn("shell.bar.closeMenu()", menu_entry)
        self.assertIn("Loader", menu_entry)
        self.assertIn("MenuWindow", menu_entry)
        self.assertIn('bar.toggleMenu("{}")', read("lacuna.menu-button/Widget.qml"))
        self.assertIn('readonly property bool frameEnabled: frameMode === "fullframe"', bar)
        self.assertIn("OmarchyBarAdapter", bar)
        self.assertIn("LacunaFrameWindow", bar)
        self.assertNotIn("LacunaFrameShadowWindow", bar)
        self.assertIn("OmarchyBar", adapter)
        self.assertIn("readonly property var barItem: omarchyBar", adapter)
        self.assertIn("function debugBarGeometry()", adapter)
        self.assertIn("function openConfigPanel()", adapter)
        self.assertIn("readonly property real itemImplicitWidth", omarchy_bar)
        self.assertIn("readonly property real itemImplicitHeight", omarchy_bar)
        self.assertIn("activeItem.visible !== false || itemImplicitWidth > 0 || itemImplicitHeight > 0", omarchy_bar)
        self.assertNotIn("readonly property bool contentVisible: activeItem && activeItem.visible", omarchy_bar)
        self.assertIn('WlrLayershell.namespace: "lacuna-bar-frame"', frame)
        self.assertIn("WlrLayershell.exclusionMode: ExclusionMode.Ignore", frame)
        self.assertIn("mask: Region {}", frame)
        self.assertIn('import "../lacuna.menu/components"', frame)
        self.assertIn("property bool leftEdgeOccupied: false", frame)
        self.assertIn("property bool rightEdgeOccupied: false", frame)
        self.assertIn("property real leftOccupiedWidth: 0", frame)
        self.assertIn("readonly property real holeX: Math.max(0, leftEdgeOccupied ? leftOcclusion : leftInset)", frame)
        self.assertIn("readonly property real holeRight: Math.max(holeX + 1, width - (rightEdgeOccupied ? rightOcclusion : rightInset))", frame)
        self.assertIn("readonly property real holeRadius: cornerPieces ? Math.max(minArcRadius, Math.min(r, holeWidth / 2, holeHeight / 2)) : minArcRadius", frame)
        self.assertIn("property bool shadowEnabled: false", frame)
        self.assertIn("readonly property int topInset: topBar ? Math.max(0, barSize) : t", frame)
        self.assertIn("readonly property int leftInset: leftBar ? Math.max(0, barSize) : t", frame)
        self.assertIn("readonly property color effectiveFrameColor", frame)
        self.assertIn("LacunaDropShadow", frame)
        self.assertIn("source: frameSource", frame)
        self.assertIn("shadowEnabled: root.active && root.shadowEnabled", frame)
        self.assertIn("Shape {", frame)
        self.assertIn("id: frameSource", frame)
        self.assertIn("fillRule: ShapePath.OddEvenFill", frame)
        self.assertIn("PathMove", frame)
        self.assertNotIn("Rectangle {", frame)
        self.assertNotIn("gradient: Gradient", frame)
        self.assertNotIn("Canvas {", frame)
        self.assertNotIn("ShaderEffectSource", frame)
        self.assertIn("frameColor: barTheme.panelBackground", bar)
        self.assertIn("shadowEnabled: root.frameShadow", bar)
        self.assertIn("shadowOffsetX: root.frameShadowOffsetX", bar)
        self.assertIn("shadowOffsetY: root.frameShadowOffsetY", bar)
        self.assertIn("leftEdgeOccupied: root.hostedSidebarVisible && hostedMenu.sidebarScreen === modelData && !hostedMenu.panelOnRight", bar)
        self.assertIn("frameRadius: root.frameRadius", bar)
        self.assertIn("cornerPieces: root.cornerPieces", bar)
        self.assertIn("leftOccupiedWidth: root.hostedSidebarFrameOcclusionWidth", bar)
        self.assertIn("rightOccupiedWidth: root.hostedSidebarFrameOcclusionWidth", bar)
        self.assertNotIn("readonly property real hostedSidebarShadowInset", bar)

    def test_theme_preloader_is_loaded_as_a_service(self):
        manifest = read_json("lacuna.theme-preloader/manifest.json")

        self.assertEqual(["service"], manifest["kinds"])
        self.assertEqual("Service.qml", manifest["entryPoints"]["service"])
        self.assertNotIn("panel", manifest["entryPoints"])

    def test_example_shell_configs_use_current_widget_ids(self):
        stale_ids = {
            "spacer",
            "tray",
            "calendar",
            "omarchy",
            "bluetoothPanel",
            "networkPanel",
            "audioPanel",
            "battery",
            "controlCenter",
        }

        for path in [
            "config/shell.phase1.example.json",
            "config/shell.lacuna-native-replacements.example.json",
        ]:
            config = read_json(path)
            layout = config["bar"]["layout"]
            ids = [entry["id"] for section in ["left", "center", "right"] for entry in layout[section]]
            self.assertFalse(stale_ids.intersection(ids), path)

    def test_theme_widget_schema_exposes_defaults_for_bar_settings(self):
        manifest = read_json("lacuna.theme/manifest.json")
        schema = {entry["key"]: entry for entry in manifest["barWidget"]["schema"]}
        qml = read("lacuna.theme/Widget.qml")

        self.assertEqual("boolean", schema["enabled"]["type"])
        self.assertIs(schema["enabled"]["defaultValue"], True)
        self.assertEqual(26, schema["maxTextLength"]["defaultValue"])
        self.assertEqual("boolean", schema["showIcon"]["type"])
        self.assertIs(schema["showIcon"]["defaultValue"], True)
        self.assertEqual("semantic", schema["colorProfile"]["defaultValue"])
        self.assertIn('readonly property bool widgetEnabled: boolSetting("enabled", true)', qml)
        self.assertIn("visible: widgetEnabled && themeTitle.length > 0", qml)
        self.assertIn('readonly property bool showIcon: boolSetting("showIcon", true)', qml)

    def test_usage_widgets_place_meter_away_from_open_indicator_edge(self):
        for plugin in ["lacuna.claude-usage", "lacuna.codex-usage"]:
            qml = read(f"{plugin}/Widget.qml")
            self.assertIn('readonly property bool showProgress: setting("showProgress", true) === true', qml)
            self.assertIn("readonly property int stableMinimumWidth: root.vertical ? root.barSize : (root.compact ? 58 : 104)", qml)
            self.assertIn("width: root.vertical ? root.barSize : Math.max(stableMinimumWidth, content.implicitWidth + horizontalPadding * 2)", qml)
            self.assertIn('readonly property bool meterAtTop: !root.vertical && root.bar && root.bar.position === "top"', qml)
            self.assertIn("y: button.meterAtTop ? 3 : parent.height - height - 3", qml)
            self.assertIn("anchors.verticalCenterOffset: button.meterHeight > 0 ? (button.meterAtTop ? 1 : -1) : 0", qml)
            self.assertIn("readonly property int activeUsedPercent: activeMode === 1 ? weekUsedPercent : usedPercent", qml)
            self.assertIn("parent.width * root.activeUsedPercent / 100", qml)

        claude_qml = read("lacuna.claude-usage/Widget.qml")
        claude_manifest = read_json("lacuna.claude-usage/manifest.json")
        claude_schema = {entry["key"]: entry for entry in claude_manifest["barWidget"]["schema"]}
        self.assertNotIn("secondaryText", claude_qml)
        self.assertNotIn("resetLabel", claude_qml)
        self.assertNotIn("showReset", claude_qml)
        self.assertNotIn("showReset", claude_manifest["barWidget"]["defaults"])
        self.assertNotIn("showReset", claude_schema)

        codex_manifest = read_json("lacuna.codex-usage/manifest.json")
        codex_schema = {entry["key"]: entry for entry in codex_manifest["barWidget"]["schema"]}
        self.assertIs(codex_manifest["barWidget"]["defaults"]["showProgress"], True)
        self.assertEqual("boolean", codex_schema["showProgress"]["type"])
        self.assertIs(codex_schema["showProgress"]["defaultValue"], True)
        self.assertIs(codex_manifest["barWidget"]["defaults"]["showWeekly"], True)
        self.assertEqual("boolean", codex_schema["showWeekly"]["type"])
        self.assertEqual(6000, codex_manifest["barWidget"]["defaults"]["cycleInterval"])
        self.assertEqual("integer", codex_schema["cycleInterval"]["type"])
        self.assertEqual("left", codex_manifest["barWidget"]["defaults"]["displayMode"])
        self.assertEqual("enum", codex_schema["displayMode"]["type"])

    def test_codex_usage_rotates_between_5h_and_weekly_windows(self):
        qml = read("lacuna.codex-usage/Widget.qml")
        self.assertIn("property int displayCycle: 0", qml)
        self.assertIn("readonly property bool weeklyReady: loadedOnce && showWeekly && weekActive", qml)
        self.assertIn("readonly property int activeMode: (weeklyReady && (displayCycle % 2 === 1)) ? 1 : 0", qml)
        self.assertIn("readonly property string primaryText: activeMode === 1 ? weekPrimary : sessionPrimary", qml)
        self.assertIn("running: root.weeklyReady && !root.flyoutOpen && !mouseArea.containsMouse", qml)
        self.assertIn("BarCycleText {", qml)
        self.assertIn("text: root.primaryText", qml)
        self.assertIn("weekActive = payload.weekActive === true", qml)
        self.assertIn("weekUsedPercent = boundedPercent(payload.weekUsedPercent", qml)

        flyout = read("lacuna.codex-usage/CodexUsageFlyout.qml")
        self.assertIn("property bool weekActive: false", flyout)
        self.assertIn("property int weekUsedPercent: 0", flyout)
        self.assertIn('text: "5h limit"', flyout)
        self.assertIn('text: "Weekly limit"', flyout)

    def test_usage_flyout_shadows_reserve_bottom_render_padding(self):
        for path in [
            "lacuna.claude-usage/ClaudeUsageFlyout.qml",
            "lacuna.codex-usage/CodexUsageFlyout.qml",
        ]:
            qml = read(path)
            self.assertIn("readonly property int shadowBottomMargin", qml)
            self.assertIn("implicitHeight: surface.implicitHeight + shadowBottomMargin", qml)
            self.assertIn("id: shadowSource", qml)
            self.assertIn("height: root.implicitHeight", qml)
            self.assertIn("source: shadowSource", qml)
            self.assertNotIn("autoPaddingEnabled: true", qml)

    def test_wallpaper_widget_schema_exposes_real_enabled_setting(self):
        manifest = read_json("lacuna.wallpaper/manifest.json")
        schema = {entry["key"]: entry for entry in manifest["barWidget"]["schema"]}
        qml = read("lacuna.wallpaper/Widget.qml")

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
        state_manifest = read_json("lacuna.state/manifest.json")
        shell_settings_manifest = read_json("lacuna.shell-settings/manifest.json")
        menu = read("lacuna.menu/menu/MenuWindow.qml")
        settings = read("lacuna.menu/services/LacunaSettings.qml")
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")

        self.assertIn("service", state_manifest["kinds"])
        self.assertEqual("Service.qml", state_manifest["entryPoints"]["service"])
        self.assertIn("service", shell_settings_manifest["kinds"])
        self.assertIn("panel", shell_settings_manifest["kinds"])
        self.assertEqual("Service.qml", shell_settings_manifest["entryPoints"]["service"])
        self.assertEqual("Panel.qml", shell_settings_manifest["entryPoints"]["panel"])
        self.assertIn('ensureService("lacuna.state")', menu)
        self.assertIn('ensureService("lacuna.shell-settings")', menu)
        self.assertIn('panelController.openFlyout("shellSettings")', menu)
        self.assertIn("OmarchyShellSettingsWindow", menu)
        self.assertIn("shellSettingsSurface", menu)
        self.assertIn("property int settingsPanelWidth: Math.round(sizeMix(560, 500))", menu)
        self.assertIn("return Math.max(360, Math.min(availableHeight, compact ? 560 : 660))", menu)
        shell_section = menu.split("function openShellSettingsSection", 1)[1].split("function requestFlyoutFocus", 1)[0]
        self.assertNotIn("sidebarState.expand()", shell_section)
        self.assertIn("return settingsFlyoutY(panelHeight)", menu)
        self.assertIn('surface: "flyout"', settings)
        self.assertIn('"Omarchy Settings Link"', settings_window)
        self.assertIn('"set-shell-settings-surface-"', settings_window)

    def test_lacuna_settings_only_exposes_lacuna_owned_settings(self):
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")

        self.assertIn('"Lacuna Tools"', settings_window)
        self.assertIn('"Lacuna Maintenance"', settings_window)
        self.assertIn('"Reload App Catalog"', settings_window)
        self.assertIn('"Open Plugin Source"', settings_window)
        self.assertIn('"Skip Restart Confirmation"', settings_window)
        self.assertIn('"Omarchy Settings Link"', settings_window)

        self.assertNotIn('"Runtime", hint: "Diagnostics and maintenance"', settings_window)
        self.assertNotIn('"Shortcuts for the host theme workflow."', settings_window)
        self.assertNotIn('"Theme", "Switch Omarchy theme"', settings_window)
        self.assertNotIn('"Background", "Switch the active theme background"', settings_window)
        self.assertNotIn('"Wallpaper Catalog"', settings_window)
        self.assertNotIn('"Restart Shell"', settings_window)
        self.assertNotIn('"Open Log"', settings_window)

        for path in [
            "lacuna.menu/settings/OmarchyShellSettingsWindow.qml",
            "lacuna.shell-settings/settings/OmarchyShellSettingsWindow.qml",
        ]:
            qml = read(path)
            self.assertIn('"Theme", "Switch Omarchy theme"', qml, path)
            self.assertIn('"Background", "Switch active theme background"', qml, path)
            self.assertIn('"Wallpaper Catalog"', qml, path)
            self.assertIn('"Restart Shell"', qml, path)
            self.assertIn('"Open Log"', qml, path)

    def test_lacuna_settings_windows_use_parent_control_state(self):
        settings_window = read("lacuna.menu/settings/SettingsWindow.qml")
        menu_shell_settings = read("lacuna.menu/settings/OmarchyShellSettingsWindow.qml")
        standalone_shell_settings = read("lacuna.shell-settings/settings/OmarchyShellSettingsWindow.qml")

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
        self.assertIn("function desiredChecked", read("lacuna.menu/menu/MenuWindow.qml"))

    def test_omarchy_shell_settings_sections_have_distinct_models(self):
        for path in [
            "lacuna.menu/settings/OmarchyShellSettingsWindow.qml",
            "lacuna.shell-settings/settings/OmarchyShellSettingsWindow.qml",
        ]:
            qml = read(path)

            self.assertIn("property var currentItems", qml, path)
            self.assertIn("property string modelError", qml, path)
            self.assertIn("function refreshItems()", qml, path)
            self.assertIn("try {", qml, path)
            self.assertIn('"Section Error"', qml, path)
            self.assertIn("function registryCommand(name)", qml, path)
            self.assertIn("model: root.currentItems", qml, path)
            self.assertIn('if (sectionId === "notifications")', qml, path)
            self.assertIn('if (sectionId === "plugins") return pluginItems()', qml, path)
            self.assertIn("typeof root.registry.installedShellPluginRows", qml, path)
            self.assertIn('commandRow("refresh", "Restart Shell"', qml, path)
            self.assertIn("showLabels: true", qml, path)

        menu = read("lacuna.menu/menu/MenuWindow.qml")
        self.assertIn("property var registryRef: registry", menu)
        self.assertIn("registry: shellSettingsPanel.registryRef", menu)
        self.assertIn("onCurrentSectionChanged: root.shellSettingsSection = currentSection", menu)

        for path in [
            "lacuna.menu/settings/SettingsRail.qml",
            "lacuna.shell-settings/settings/SettingsRail.qml",
        ]:
            qml = read(path)

            self.assertIn("signal sectionSelected(string sectionId)", qml, path)
            self.assertIn("readonly property string sectionId", qml, path)
            self.assertIn("property bool showLabels", qml, path)
            self.assertIn("text: modelData.label || \"\"", qml, path)
            self.assertIn("onTriggered: root.sectionSelected(parent.sectionId)", qml, path)

    def test_simple_bar_helpers_match_canonical_vendored_templates(self):
        color_template = read("shared/qml/simple-bar/ColorProfile.qml")
        motion_template = read("shared/qml/simple-bar/MotionTokens.qml")
        simple_color_plugins = [
            "lacuna.audio",
            "lacuna.bluetooth",
            "lacuna.bar-size-pill",
            "lacuna.clock",
            "lacuna.claude-usage",
            "lacuna.codex-usage",
            "lacuna.compact-pill",
            "lacuna.idle-inhibitor",
            "lacuna.indicators",
            "lacuna.nightlight",
            "lacuna.menu-button",
            "lacuna.network",
            "lacuna.notifications",
            "lacuna.power",
            "lacuna.script-pill",
            "lacuna.screen-recording",
            "lacuna.system-stats",
            "lacuna.system-update",
            "lacuna.temperature",
            "lacuna.voxtype",
            "lacuna.weather",
        ]
        simple_motion_plugins = simple_color_plugins + [
            "lacuna.theme",
            "lacuna.wallpaper",
        ]

        for plugin in simple_color_plugins:
            self.assertEqual(read(f"{plugin}/ColorProfile.qml"), color_template, plugin)
        for plugin in simple_motion_plugins:
            self.assertEqual(read(f"{plugin}/MotionTokens.qml"), motion_template, plugin)
