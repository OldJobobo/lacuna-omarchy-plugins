import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


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


if __name__ == "__main__":
    unittest.main()
