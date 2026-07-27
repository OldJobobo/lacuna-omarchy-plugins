import json
import shutil
import subprocess
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class MenuFlyoutGeometryTests(unittest.TestCase):
    def test_geometry_is_bounded_on_short_and_narrow_outputs(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("node is not installed")
        script = textwrap.dedent(
            """
            const geometry = require("./lacuna.menu/menu/MenuFlyoutGeometry.js");
            const cases = [
              { screenWidth: 800, screenHeight: 480, leftInset: 328, rightInset: 44, topInset: 44, bottomInset: 16, preferredWidth: 560, preferredHeight: 660, preferredY: -100 },
              { screenWidth: 1024, screenHeight: 600, leftInset: 288, rightInset: 44, topInset: 40, bottomInset: 14, preferredWidth: 520, preferredHeight: 660, preferredY: 500 },
              { screenWidth: 1280, screenHeight: 720, leftInset: 328, rightInset: 44, topInset: 44, bottomInset: 16, preferredWidth: 420, preferredHeight: 600, preferredY: 80 }
            ];
            console.log(JSON.stringify(cases.map(c => ({ input: c, output: geometry.boundedGeometry(c) }))));
            """
        )
        result = subprocess.run([node, "-e", script], cwd=ROOT, text=True, capture_output=True, check=False)
        self.assertEqual(0, result.returncode, result.stderr)
        for case in json.loads(result.stdout):
            source = case["input"]
            output = case["output"]
            self.assertGreaterEqual(output["y"], source["topInset"])
            self.assertLessEqual(output["y"] + output["height"], source["screenHeight"] - source["bottomInset"])
            self.assertLessEqual(output["width"], source["screenWidth"] - source["leftInset"] - source["rightInset"])
            self.assertGreater(output["width"], 0)
            self.assertGreater(output["height"], 0)

    def test_menu_uses_one_bounded_geometry_source_for_paint_and_masks(self):
        menu = (ROOT / "lacuna.menu/menu/MenuWindow.qml").read_text(encoding="utf-8")
        self.assertIn('import "MenuFlyoutGeometry.js" as MenuFlyoutGeometry', menu)
        self.assertIn("function flyoutGeometryFor(screen, kind, connectorWidthOverride)", menu)
        self.assertIn("preferredWidth: preferredFlyoutWidth(kind)", menu)
        self.assertIn("Math.max(0, root.flyoutGeometryFor(modelData, root.geometryTargetFlyout).width)", menu)
        self.assertIn("flyoutWidth: panelHost.flyoutMaskWidth", menu)
        self.assertNotIn("return Math.max(360, Math.min(availableHeight", menu)


if __name__ == "__main__":
    unittest.main()
