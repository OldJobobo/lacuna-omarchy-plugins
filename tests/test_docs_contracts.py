import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DocsContractTests(unittest.TestCase):
    def test_docs_have_status_markers(self):
        for path in sorted((ROOT / "docs").glob("*.md")):
            head = "\n".join(path.read_text(encoding="utf-8").splitlines()[:8])
            self.assertIn("Status:", head, str(path.relative_to(ROOT)))


if __name__ == "__main__":
    unittest.main()
