import json
import shutil
import subprocess
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class BarIndicatorModelTests(unittest.TestCase):
    def test_extent_uses_axis_specific_hint_and_bounded_fallback(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/PanelIndicatorModel.js");
            const hinted = { openPanelIndicatorWidth: 37.6, openPanelIndicatorHeight: 21.2 };
            console.log(JSON.stringify({
              horizontalHint: model.extent(false, hinted, 100, 30, 10),
              verticalHint: model.extent(true, hinted, 100, 30, 10),
              horizontalFallback: model.extent(false, {}, 100, 30, 10),
              verticalFallback: model.extent(true, {}, 100, 30, 10),
              minimumFallback: model.extent(false, {}, 8, 30, 10),
              invalidHintFallback: model.extent(false, { openPanelIndicatorWidth: 0 }, 40, 30, 10)
            }));
            """
        )
        result = subprocess.run(
            [shutil.which("node"), "-e", script],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(0, result.returncode, result.stderr)
        data = json.loads(result.stdout)
        self.assertEqual(38, data["horizontalHint"])
        self.assertEqual(21, data["verticalHint"])
        self.assertEqual(55, data["horizontalFallback"])
        self.assertEqual(17, data["verticalFallback"])
        self.assertEqual(10, data["minimumFallback"])
        self.assertEqual(22, data["invalidHintFallback"])


if __name__ == "__main__":
    unittest.main()
