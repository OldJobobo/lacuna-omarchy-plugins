import importlib.machinery
import importlib.util
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _load_sync_vendored():
    loader = importlib.machinery.SourceFileLoader("sync_vendored", str(ROOT / "scripts" / "sync-vendored"))
    spec = importlib.util.spec_from_loader("sync_vendored", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class VendoredFileTests(unittest.TestCase):
    def test_vendored_files_match_canonical_sources(self):
        result = subprocess.run(
            [str(ROOT / "scripts" / "sync-vendored"), "--check"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_vendor_exclusions_are_declared_in_manifests(self):
        # Divergent vendored copies are declared per-plugin via
        # lacuna.vendorExclude, not a central hardcoded list, so adding a
        # widget with a customized ColorProfile/MotionTokens can't silently
        # break parity.
        module = _load_sync_vendored()
        self.assertEqual(
            module.vendor_exclusions(),
            {
                "lacuna.mpris/ColorProfile.qml",
                "lacuna.theme/ColorProfile.qml",
                "lacuna.wallpaper/ColorProfile.qml",
                "lacuna.workspaces/ColorProfile.qml",
                "lacuna.menu/services/MotionTokens.qml",
                "lacuna.bar/OmarchyBar.qml",
                "lacuna.mpris/components/MotionTokens.qml",
                "lacuna.shell-settings/services/MotionTokens.qml",
                "lacuna.workspaces/components/MotionTokens.qml",
            },
        )
        # The excluded targets must actually exist on disk.
        for rel in module.vendor_exclusions():
            self.assertTrue((ROOT / rel).exists(), rel)


if __name__ == "__main__":
    unittest.main()
