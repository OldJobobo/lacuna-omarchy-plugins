import importlib.machinery
import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "quattro-compatibility"


def load_module():
    loader = importlib.machinery.SourceFileLoader("quattro_compatibility", str(SCRIPT))
    spec = importlib.util.spec_from_loader("quattro_compatibility", loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules["quattro_compatibility"] = module
    spec.loader.exec_module(module)
    return module


class QuattroCompatibilityTests(unittest.TestCase):
    def test_repo_only_report_is_deterministic_and_checkable(self):
        module = load_module()

        result = module.report(repo_only=True)

        self.assertEqual("compatible", result["status"])
        self.assertEqual("unknown", result["omarchyVersion"])
        self.assertEqual("unknown", result["quickshellVersion"])
        self.assertIsNone(result["vendoredParity"])
        self.assertTrue(all(state == "skipped" for state in result["corePluginValidation"].values()))

    def test_json_cli_exposes_explicit_live_result(self):
        result = subprocess.run(
            [str(SCRIPT), "--json"],
            cwd=ROOT,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        self.assertEqual(0, result.returncode, result.stderr)
        report = json.loads(result.stdout)
        self.assertIn(report["status"], {"compatible", "unknown"})
        self.assertIn("upstreamBarFiles", report)
        self.assertIn("lacuna.bar", report["corePluginValidation"])


if __name__ == "__main__":
    unittest.main()
