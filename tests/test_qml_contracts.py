import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


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
