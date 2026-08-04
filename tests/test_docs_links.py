import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "check_docs_links.py"
SPEC = importlib.util.spec_from_file_location("check_docs_links", SCRIPT)
assert SPEC and SPEC.loader
LINKS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LINKS)


class GeneratedDocsLinkTests(unittest.TestCase):
    def write_page(self, root: Path, relative: str, body: str) -> None:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def test_accepts_prefixed_relative_pages_assets_and_fragments(self):
        with tempfile.TemporaryDirectory() as temporary:
            site = Path(temporary)
            self.write_page(
                site,
                "index.html",
                '<a href="guide/#answer">Guide</a><img src="assets/mark.svg">',
            )
            self.write_page(site, "guide/index.html", '<h1 id="answer">Answer</h1>')
            self.write_page(site, "assets/mark.svg", "<svg></svg>")
            self.assertEqual([], LINKS.check_site(site, "/lacuna-shell/"))

    def test_rejects_missing_generated_page_and_fragment(self):
        with tempfile.TemporaryDirectory() as temporary:
            site = Path(temporary)
            self.write_page(
                site,
                "index.html",
                '<a href="roadmap/">Missing page</a><a href="guide/#missing">Missing anchor</a>',
            )
            self.write_page(site, "guide/index.html", '<h1 id="answer">Answer</h1>')
            failures = LINKS.check_site(site, "/lacuna-shell/")
            self.assertEqual(2, len(failures))
            self.assertTrue(any("no generated target" in failure for failure in failures))
            self.assertTrue(any("no matching fragment" in failure for failure in failures))

    def test_rejects_root_absolute_link_that_escapes_pages_prefix(self):
        with tempfile.TemporaryDirectory() as temporary:
            site = Path(temporary)
            self.write_page(site, "index.html", '<a href="/configuration/">Wrong root</a>')
            failures = LINKS.check_site(site, "/lacuna-shell/")
            self.assertEqual(1, len(failures))
            self.assertIn("escapes site prefix", failures[0])


if __name__ == "__main__":
    unittest.main()
