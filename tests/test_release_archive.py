import hashlib
import json
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ReleaseArchiveTests(unittest.TestCase):
    def test_archive_is_reproducible_single_root_and_inventoried(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                [
                    str(ROOT / "scripts/build-release-archive"),
                    "--allow-dirty",
                    "--check-reproducible",
                    "--output-dir",
                    tmp,
                ],
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            output = Path(tmp)
            archive = next(output.glob("*.tar.gz"))
            inventory_path = next(output.glob("*.inventory.json"))
            checksum_path = next(output.glob("*.sha256"))
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            self.assertEqual(inventory["sha256"], digest)
            self.assertTrue(checksum_path.read_text(encoding="utf-8").startswith(digest))

            with tarfile.open(archive, "r:gz") as payload:
                names = payload.getnames()
            roots = {name.split("/", 1)[0] for name in names}
            self.assertEqual(roots, {f"lacuna-omarchy-plugins-{inventory['version']}"})
            archived_files = {
                name.split("/", 1)[1]
                for name in names
                if "/" in name and not name.endswith("/")
            }
            expected_files = {entry["path"] for entry in inventory["files"]}
            self.assertEqual(archived_files, expected_files)
            modes = {entry["path"]: entry["mode"] for entry in inventory["files"]}
            self.assertEqual(modes["scripts/lacuna"], "0755")
            self.assertFalse(any("graphify-out" in name or "__pycache__" in name for name in names))


if __name__ == "__main__":
    unittest.main()
