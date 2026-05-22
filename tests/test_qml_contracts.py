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

    def test_quick_launch_add_action_lives_in_header_controls(self):
        registry = read("plugins/omarchy.lacuna-menu/menu/MenuRegistry.qml")
        content = read("plugins/omarchy.lacuna-menu/menu/MenuContent.qml")
        section = read("plugins/omarchy.lacuna-menu/menu/MenuSection.qml")

        self.assertIn('header.headerAction = "open-custom-quick-launch-picker"', registry)
        self.assertIn('header.headerActionIcon = "plus"', registry)
        self.assertIn("var launchers = customQuickLaunchItems()", registry)
        self.assertNotIn('entries.action({ icon: "plus", label: "Add Quick Launch App"', registry)
        self.assertIn("onActionTriggered", content)
        self.assertIn("signal actionTriggered()", section)

    def test_workspace_lacuna_selected_state_has_no_fill_or_underline(self):
        qml = read("plugins/omarchy.lacuna-workspaces/components/LacunaWorkspaceButton.qml")

        self.assertNotIn("root.active ? 0.08", qml)
        self.assertNotIn("height: 2\n    color: root.accent\n    opacity: root.active", qml)
        self.assertIn('property string designStyle: "lacuna"', qml)

    def test_lacuna_menu_button_uses_lacuna_icon_asset(self):
        qml = read("plugins/omarchy.lacuna-menu-button/Widget.qml")

        self.assertIn("circle-dotted-letter-l.svg", qml)
        self.assertNotIn("layout-sidebar-left-expand-filled.svg", qml)

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

    def test_window_gaps_toggle_does_not_override_theme_border_size(self):
        service = read("plugins/omarchy.lacuna-shell-settings/Service.qml")
        state_script = read("plugins/omarchy.lacuna-shell-settings/scripts/omarchy-shell-settings-state.py")
        settings_window = read("plugins/omarchy.lacuna-shell-settings/settings/OmarchyShellSettingsWindow.qml")

        self.assertIn("without changing theme borders", service)
        self.assertNotIn("border_size", service)
        self.assertIn("live_gaps_enabled = any(value and value > 0 for value in [gaps_in, gaps_out])", state_script)
        self.assertIn("without changing theme borders", settings_window)

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

    def test_lacuna_state_and_shell_settings_are_split_plugins(self):
        state_manifest = read_json("plugins/omarchy.lacuna-state/manifest.json")
        shell_settings_manifest = read_json("plugins/omarchy.lacuna-shell-settings/manifest.json")
        menu = read("plugins/omarchy.lacuna-menu/menu/MenuWindow.qml")

        self.assertIn("service", state_manifest["kinds"])
        self.assertEqual("Service.qml", state_manifest["entryPoints"]["service"])
        self.assertIn("service", shell_settings_manifest["kinds"])
        self.assertIn("panel", shell_settings_manifest["kinds"])
        self.assertEqual("Service.qml", shell_settings_manifest["entryPoints"]["service"])
        self.assertEqual("Panel.qml", shell_settings_manifest["entryPoints"]["panel"])
        self.assertIn('ensureService("omarchy.lacuna-state")', menu)
        self.assertIn('summon("omarchy.lacuna-shell-settings"', menu)
        self.assertNotIn("OmarchyShellSettings {", menu)
        self.assertNotIn("OmarchyShellSettingsWindow", menu)

    def test_simple_bar_helpers_match_canonical_vendored_templates(self):
        color_template = read("shared/qml/simple-bar/ColorProfile.qml")
        motion_template = read("shared/qml/simple-bar/MotionTokens.qml")
        simple_color_plugins = [
            "omarchy.lacuna-bar-size-pill",
            "omarchy.lacuna-claude-usage",
            "omarchy.lacuna-codex-usage",
            "omarchy.lacuna-compact-pill",
            "omarchy.lacuna-menu-button",
            "omarchy.lacuna-script-pill",
            "omarchy.lacuna-system-stats",
            "omarchy.lacuna-temperature",
        ]
        simple_motion_plugins = simple_color_plugins + [
            "omarchy.lacuna-theme",
            "omarchy.lacuna-wallpaper",
        ]

        for plugin in simple_color_plugins:
            self.assertEqual(read(f"plugins/{plugin}/ColorProfile.qml"), color_template, plugin)
        for plugin in simple_motion_plugins:
            self.assertEqual(read(f"plugins/{plugin}/MotionTokens.qml"), motion_template, plugin)
