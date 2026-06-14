"""Structural load-smoke for the plugin suite.

This does not launch a live shell (that needs Quickshell + a compositor), but
it catches the load-time failures that pure per-file linting misses:

* a manifest entry point that points at a missing file, and
* a QML ``import "..."`` whose relative path does not resolve, escapes the
  repo, reaches the repo root, or reaches into another plugin that the
  importer does not declare in ``lacuna.requires``.

The last rule enforces the CLAUDE.md "plugins must be self-contained" contract
while allowing the deliberate, dependency-backed composition in the core
bundle (e.g. lacuna.bar, which requires lacuna.menu, hosting menu QML).
"""

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN_DIRS = sorted(p for p in ROOT.glob("lacuna.*") if (p / "manifest.json").exists())
RELATIVE_IMPORT_RE = re.compile(r'^\s*import\s+"([^"]+)"', re.MULTILINE)


def plugin_id_for(path: Path) -> str | None:
    """Return the lacuna.* plugin directory name containing *path*, if any."""
    try:
        rel = path.resolve().relative_to(ROOT)
    except ValueError:
        return None
    if rel.parts and rel.parts[0].startswith("lacuna."):
        return rel.parts[0]
    return None


def manifest_requires(plugin_dir: Path) -> set[str]:
    data = json.loads((plugin_dir / "manifest.json").read_text(encoding="utf-8"))
    return set((data.get("lacuna") or {}).get("requires") or [])


class PluginLoadSmokeTests(unittest.TestCase):
    def test_manifest_entry_points_exist(self):
        for plugin_dir in PLUGIN_DIRS:
            data = json.loads((plugin_dir / "manifest.json").read_text(encoding="utf-8"))
            entry_points = data.get("entryPoints") or {}
            self.assertTrue(entry_points, f"{plugin_dir.name} declares no entryPoints")
            for kind, target in entry_points.items():
                self.assertTrue(
                    (plugin_dir / str(target)).exists(),
                    f"{plugin_dir.name} entryPoint {kind} -> {target} is missing",
                )

    def test_relative_imports_stay_self_contained(self):
        for plugin_dir in PLUGIN_DIRS:
            plugin_id = plugin_dir.name
            allowed_foreign = manifest_requires(plugin_dir)
            for qml in plugin_dir.rglob("*.qml"):
                text = qml.read_text(encoding="utf-8")
                for spec in RELATIVE_IMPORT_RE.findall(text):
                    target = (qml.parent / spec).resolve()
                    label = f"{qml.relative_to(ROOT)} imports {spec!r}"

                    self.assertTrue(target.exists(), f"{label}: path does not resolve")

                    try:
                        target.relative_to(ROOT)
                    except ValueError:
                        self.fail(f"{label}: escapes the repository")
                        continue

                    self.assertNotEqual(target, ROOT, f"{label}: imports the repo root")

                    target_plugin = plugin_id_for(target)
                    if target_plugin is None:
                        self.fail(f"{label}: resolves outside any plugin ({target.relative_to(ROOT)})")
                    elif target_plugin != plugin_id:
                        self.assertIn(
                            target_plugin,
                            allowed_foreign,
                            f"{label}: cross-plugin import into {target_plugin} "
                            f"not declared in {plugin_id} lacuna.requires",
                        )


if __name__ == "__main__":
    unittest.main()
