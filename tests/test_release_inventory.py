import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "config/release-inventory.json"


class ReleaseInventoryTests(unittest.TestCase):
    def test_checked_inventory_is_current_and_complete(self):
        result = subprocess.run(
            [str(ROOT / "scripts/release-inventory"), "--check"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(INVENTORY.read_text(encoding="utf-8"))
        manifest_ids = {
            json.loads(path.read_text(encoding="utf-8"))["id"]
            for path in ROOT.glob("lacuna.*/manifest.json")
        }
        inventory_ids = {plugin["id"] for plugin in data["plugins"]}
        self.assertEqual(manifest_ids, inventory_ids)
        self.assertEqual(data["package"]["requiredPackages"], ["omarchy", "python", "qt6-multimedia"])

    def test_inventory_entry_points_and_files_exist(self):
        data = json.loads(INVENTORY.read_text(encoding="utf-8"))
        for plugin in data["plugins"]:
            plugin_dir = ROOT / plugin["id"]
            self.assertIn("manifest.json", plugin["files"])
            for relative in plugin["entryPoints"].values():
                self.assertTrue((plugin_dir / relative).is_file(), f"{plugin['id']}: {relative}")
            for relative in plugin["files"]:
                self.assertTrue((plugin_dir / relative).is_file(), f"{plugin['id']}: {relative}")


if __name__ == "__main__":
    unittest.main()
