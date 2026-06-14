"""Execution tests for lacuna.menu/scripts/desktop-app-catalog.py.

The script scans XDG application directories and prints a filtered, categorized
JSON catalog. Tests drive it against a temp XDG_DATA_HOME with fixture .desktop
files and an empty XDG_DATA_DIRS so the system's real apps don't leak in.
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "lacuna.menu" / "scripts" / "desktop-app-catalog.py"


def write_desktop(apps_dir: Path, stem: str, **fields: str) -> None:
    lines = ["[Desktop Entry]"] + [f"{key}={value}" for key, value in fields.items()]
    (apps_dir / f"{stem}.desktop").write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_catalog(data_home: Path) -> list[dict]:
    env = dict(os.environ)
    env["XDG_DATA_HOME"] = str(data_home)
    env["XDG_DATA_DIRS"] = ""  # isolate from real system applications
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


class DesktopAppCatalogTests(unittest.TestCase):
    def _apps_dir(self, tmp: str) -> Path:
        apps = Path(tmp) / "applications"
        apps.mkdir(parents=True)
        return apps

    def test_categorizes_and_sorts_visible_applications(self):
        with tempfile.TemporaryDirectory() as tmp:
            apps = self._apps_dir(tmp)
            write_desktop(apps, "zcode", Name="Zed", Exec="zed", Categories="Development;")
            write_desktop(apps, "abrowser", Name="A Browser", Exec="browse", Categories="Network;")
            result = run_catalog(Path(tmp))

        self.assertEqual([a["Name"] for a in result], ["A Browser", "Zed"])
        by_id = {a["id"]: a for a in result}
        self.assertEqual(by_id["zcode"]["category"], "development")
        self.assertEqual(by_id["abrowser"]["category"], "internet")

    def test_filters_hidden_nonapplication_and_incomplete_entries(self):
        with tempfile.TemporaryDirectory() as tmp:
            apps = self._apps_dir(tmp)
            write_desktop(apps, "ok", Name="Ok", Exec="ok")
            write_desktop(apps, "nodisp", Name="No", Exec="x", NoDisplay="true")
            write_desktop(apps, "hidden", Name="Hidden", Exec="x", Hidden="true")
            write_desktop(apps, "link", Name="Link", Exec="x", Type="Link")
            write_desktop(apps, "noexec", Name="NoExec")
            write_desktop(apps, "noname", Exec="x")
            result = run_catalog(Path(tmp))

        self.assertEqual([a["id"] for a in result], ["ok"])

    def test_terminal_flag_and_games_keyword_heuristic(self):
        with tempfile.TemporaryDirectory() as tmp:
            apps = self._apps_dir(tmp)
            write_desktop(apps, "term", Name="Tool", Exec="tool", Terminal="true")
            write_desktop(apps, "steam", Name="Steam", Exec="steam", Comment="play games")
            result = run_catalog(Path(tmp))

        by_id = {a["id"]: a for a in result}
        self.assertTrue(by_id["term"]["Terminal"])
        self.assertEqual(by_id["steam"]["category"], "games")


if __name__ == "__main__":
    unittest.main()
