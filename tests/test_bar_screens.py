import json
import shutil
import subprocess
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BarScreenModelTests(unittest.TestCase):
    def test_filters_placeholders_duplicates_and_invalid_geometry(self):
        node = shutil.which("node")
        if not node:
            raise unittest.SkipTest("node is not installed")

        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/ScreenModel.js");
            const screens = [
              { name: "", width: 0, height: 0 },
              { name: "DP-1", width: 1920, height: 1080 },
              { name: "DP-1", width: 1920, height: 1080 },
              { name: "DP-2", width: 0, height: 1440 },
              { name: "DP-3", width: 2560, height: 1440 }
            ];
            const valid = model.validScreens(screens);
            const arrayLike = { 0: screens[1], 1: screens[4], length: 2 };
            console.log(JSON.stringify({
              names: valid.map(model.screenName),
              arrayLikeNames: model.validScreens(arrayLike).map(model.screenName),
              hasDp3: model.hasScreen(screens, "DP-3"),
              hasDp2: model.hasScreen(screens, "DP-2"),
              preferred: model.screenName(model.fallbackScreen(screens, "DP-3")),
              fallback: model.screenName(model.fallbackScreen(screens, "missing")),
              empty: model.fallbackScreen([], "DP-1")
            }));
            """
        )
        result = subprocess.run([node, "-e", script], cwd=ROOT, text=True, capture_output=True, check=False)
        if result.returncode != 0:
            raise AssertionError(result.stderr or result.stdout)
        data = json.loads(result.stdout)

        self.assertEqual(["DP-1", "DP-3"], data["names"])
        self.assertEqual(["DP-1", "DP-3"], data["arrayLikeNames"])
        self.assertTrue(data["hasDp3"])
        self.assertFalse(data["hasDp2"])
        self.assertEqual("DP-3", data["preferred"])
        self.assertEqual("DP-1", data["fallback"])
        self.assertIsNone(data["empty"])

    def test_bar_uses_shared_valid_screen_and_popup_context_contracts(self):
        qml = (ROOT / "lacuna.bar" / "OmarchyBar.qml").read_text(encoding="utf-8")
        host = (ROOT / "lacuna.bar" / "Bar.qml").read_text(encoding="utf-8")

        self.assertIn("readonly property var validBarScreens: ScreenModel.validScreens(Quickshell.screens)", qml)
        self.assertIn("function popupContext(anchorItem, moduleId)", qml)
        self.assertIn("function activateInteraction(anchorItem, moduleId)", qml)
        self.assertIn("function reconcileScreens()", qml)
        self.assertIn("function toggleMenu(payloadJson)", qml)
        self.assertIn("root.activateInteraction(slot.activeItem || slot, slot.moduleName)", qml)
        self.assertEqual(2, qml.count("model: root.validBarScreens"))
        self.assertEqual(2, host.count("model: root.validBarScreens"))

    def test_edit_mode_gates_dragging_and_cleans_up(self):
        qml = (ROOT / "lacuna.bar" / "OmarchyBar.qml").read_text(encoding="utf-8")
        panel = (ROOT / "lacuna.bar" / "BarConfigPanel.qml").read_text(encoding="utf-8")

        self.assertIn("property bool editMode: false", qml)
        self.assertIn("function enterEditMode()", qml)
        self.assertIn("function exitEditMode()", qml)
        self.assertIn("root.editMode && root.shell", qml)
        self.assertIn("onCloseRequested: root.finish()", panel)
        self.assertIn("onOpenedChanged: if (!opened) setEditing(false)", panel)

    def test_widget_polish_keeps_state_signals_bounded(self):
        stats = (ROOT / "lacuna.system-stats" / "Widget.qml").read_text(encoding="utf-8")
        workspaces = (ROOT / "lacuna.workspaces" / "Widget.qml").read_text(encoding="utf-8")
        media = (ROOT / "lacuna.mpris" / "Widget.qml").read_text(encoding="utf-8")

        self.assertIn("readonly property int historyLimit: 60", stats)
        self.assertIn("slice(-historyLimit)", stats)
        for history in ("cpuHistory", "memoryHistory", "diskHistory"):
            self.assertIn(f"property var {history}: []", stats)
        self.assertIn("readonly property bool workspaceOccupied", workspaces)
        self.assertIn('sweepActive: root.sweepOnPlaying && root.cssClass === "playing"', media)


if __name__ == "__main__":
    unittest.main()
