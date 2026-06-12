import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "lacuna"


def run_lacuna(args, config_home=None):
    if config_home is None:
        with tempfile.TemporaryDirectory() as tmp:
            return run_lacuna(args, config_home=Path(tmp) / "config")

    env = os.environ.copy()
    env["XDG_CONFIG_HOME"] = str(config_home)
    return subprocess.run(
        [str(INSTALLER), *args],
        check=True,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def load_installer_module():
    import importlib.util
    import importlib.machinery

    loader = importlib.machinery.SourceFileLoader("lacuna_installer", str(INSTALLER))
    spec = importlib.util.spec_from_loader("lacuna_installer", loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules["lacuna_installer"] = module
    spec.loader.exec_module(module)
    return module


class LacunaInstallerTests(unittest.TestCase):
    def test_core_profile_dry_run_uses_current_omarchy_plugin_routes(self):
        result = run_lacuna(["install", "--profile", "core", "--dry-run", "--yes"])

        self.assertIn("Install plan", result.stdout)
        self.assertIn("stage lacuna.state ->", result.stdout)
        self.assertIn("stage lacuna.menu-button ->", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)
        self.assertNotIn("omarchy-shell-refactor", result.stdout)

    def test_global_flags_work_before_or_after_subcommand(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            before = run_lacuna(["--dry-run", "--yes", "install", "--profile", "core"], config_home=config_home).stdout
            after = run_lacuna(["install", "--profile", "core", "--dry-run", "--yes"], config_home=config_home).stdout

        self.assertEqual(before, after)

    def test_full_profile_excludes_legacy_and_native_replacements_by_default(self):
        result = run_lacuna(["install", "--profile", "full", "--dry-run", "--yes"])

        self.assertIn("lacuna.menu-button", result.stdout)
        self.assertIn("lacuna.theme-preloader", result.stdout)
        self.assertNotIn("lacuna.indicators", result.stdout)
        self.assertNotIn("lacuna.audio", result.stdout)
        self.assertNotIn("lacuna.compact-pill", result.stdout)

    def test_full_profile_can_include_native_replacements(self):
        result = run_lacuna(["install", "--profile", "full", "--include-replacements", "--dry-run", "--yes"])

        self.assertIn("lacuna.indicators", result.stdout)
        self.assertIn("lacuna.audio", result.stdout)
        self.assertNotIn("lacuna.compact-pill", result.stdout)

    def test_custom_plugin_selection_adds_required_dependencies(self):
        result = run_lacuna(["install", "--plugin", "lacuna.menu-button", "--dry-run", "--yes"])

        self.assertIn("lacuna.state", result.stdout)
        self.assertIn("lacuna.shell-settings", result.stdout)
        self.assertIn("lacuna.menu", result.stdout)
        self.assertIn("lacuna.menu-button", result.stdout)

    def test_apply_layout_prints_bar_move_routes(self):
        result = run_lacuna(["install", "--profile", "native", "--activate", "--apply-layout", "--dry-run", "--yes"])

        self.assertIn("Activation", result.stdout)
        self.assertIn("Layout", result.stdout)
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
        self.assertIn("disable lacuna.clock if enabled", result.stdout)
        self.assertIn("remove", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)
        self.assertNotIn("omarchy plugin remove", result.stdout)

    def test_gum_wrapper_does_not_hide_interactive_ui(self):
        module = load_installer_module()

        with mock.patch.object(module.subprocess, "run") as run:
            run.return_value = subprocess.CompletedProcess(["gum"], 0, stdout="Full Lacuna install\n")

            self.assertEqual(
                module.run_gum(["choose", "--header=Lacuna", "Full Lacuna install"]),
                "Full Lacuna install",
            )

        self.assertIsNone(run.call_args.kwargs["stderr"])

    def test_default_source_url_prefers_local_checkout(self):
        module = load_installer_module()

        self.assertEqual(module.default_source_url(), str(ROOT))

    def test_stale_source_catalog_reports_repair_commands(self):
        module = load_installer_module()

        with mock.patch.object(module, "source_catalog_ids", return_value=set()):
            result = module.verify_source_catalog("lacuna", ["lacuna.state"])

        self.assertEqual(result, 1)

    def test_menu_full_install_stages_without_activation_or_layout(self):
        module = load_installer_module()
        args = module.normalize_args(module.parser().parse_args([]))

        with mock.patch.object(module, "choose", return_value="Full Lacuna install"), \
            mock.patch.object(module, "install", return_value=0) as install:
            result = module.menu(args)

        self.assertEqual(result, 0)
        install_args = install.call_args.args[0]
        self.assertEqual(install_args.profile, "full")
        self.assertIs(install_args.include_replacements, False)
        self.assertIs(install_args.activate, False)
        self.assertIs(install_args.apply_layout, False)


if __name__ == "__main__":
    unittest.main()
