import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NODE = shutil.which("node")


@unittest.skipUnless(NODE, "node is required for documentation accessibility behavior tests")
class DocsAccessibilityBehaviorTests(unittest.TestCase):
    def test_header_controls_survive_repeated_instant_navigation(self):
        result = subprocess.run(
            [
                NODE,
                str(ROOT / "tests/fixtures/docs-accessibility-harness.js"),
                str(ROOT / "docs/assets/javascripts/accessibility.js"),
            ],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("docs accessibility behavior: PASS", result.stdout)


if __name__ == "__main__":
    unittest.main()
