import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "lacuna"


def run_lacuna(args, config_home=None):
    env = os.environ.copy()
    if config_home:
        env["XDG_CONFIG_HOME"] = str(config_home)
    return subprocess.run(
        [str(INSTALLER), *args],
        check=True,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


class LacunaInstallerTests(unittest.TestCase):
    def test_core_profile_dry_run_uses_current_omarchy_plugin_routes(self):
        result = run_lacuna(["install", "--profile", "core", "--dry-run", "--yes"])

        self.assertIn("Install plan", result.stdout)
        self.assertIn("omarchy plugin add lacuna.state --from lacuna --enable --yes", result.stdout)
        self.assertIn("omarchy plugin add lacuna.menu-button --from lacuna --enable --yes --no-refresh", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)
        self.assertNotIn("omarchy-shell-refactor", result.stdout)

    def test_global_flags_work_before_or_after_subcommand(self):
        before = run_lacuna(["--dry-run", "--yes", "install", "--profile", "core"]).stdout
        after = run_lacuna(["install", "--profile", "core", "--dry-run", "--yes"]).stdout

        self.assertEqual(before, after)

    def test_full_profile_excludes_legacy_compact_pill_by_default(self):
        result = run_lacuna(["install", "--profile", "full", "--dry-run", "--yes"])

        self.assertIn("lacuna.menu-button", result.stdout)
        self.assertIn("lacuna.theme-preloader", result.stdout)
        self.assertIn("lacuna.indicators", result.stdout)
        self.assertNotIn("lacuna.compact-pill", result.stdout)

    def test_custom_plugin_selection_adds_required_dependencies(self):
        result = run_lacuna(["install", "--plugin", "lacuna.menu-button", "--dry-run", "--yes"])

        self.assertIn("lacuna.state", result.stdout)
        self.assertIn("lacuna.shell-settings", result.stdout)
        self.assertIn("lacuna.menu", result.stdout)
        self.assertIn("lacuna.menu-button", result.stdout)

    def test_apply_layout_prints_bar_move_routes(self):
        result = run_lacuna(["install", "--profile", "native", "--apply-layout", "--dry-run", "--yes"])

        self.assertIn("Layout commands", result.stdout)
        self.assertIn("omarchy plugin bar move lacuna.menu-button --section left --index 0", result.stdout)
        self.assertIn("omarchy plugin bar move lacuna.clock --section center --index 1", result.stdout)
        self.assertIn("omarchy plugin bar move lacuna.audio --section right --index 5", result.stdout)

    def test_uninstall_all_dry_run_detects_installed_lacuna_plugins(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            installed = config_home / "omarchy" / "plugins" / "lacuna.clock"
            installed.mkdir(parents=True)
            (installed / "manifest.json").write_text("{}", encoding="utf-8")

            result = run_lacuna(["uninstall", "--all", "--dry-run", "--yes"], config_home=config_home)

        self.assertIn("Uninstall plan", result.stdout)
        self.assertIn("lacuna.clock", result.stdout)
        self.assertIn("omarchy plugin remove lacuna.clock --yes", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)


if __name__ == "__main__":
    unittest.main()
