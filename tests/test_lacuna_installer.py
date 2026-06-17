import os
import shutil
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


def run_lacuna_unchecked(args, config_home=None):
    if config_home is None:
        with tempfile.TemporaryDirectory() as tmp:
            return run_lacuna_unchecked(args, config_home=Path(tmp) / "config")

    env = os.environ.copy()
    env["XDG_CONFIG_HOME"] = str(config_home)
    return subprocess.run(
        [str(INSTALLER), *args],
        check=False,
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
        self.assertIn("stage lacuna.bar ->", result.stdout)
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
        self.assertIn("update", result.stdout)
        self.assertIn("shell.json once", result.stdout)
        self.assertIn("apply Lacuna bar host layout in shell.json", result.stdout)
        self.assertIn("apply Lacuna bar layout in shell.json", result.stdout)
        self.assertEqual(result.stdout.count("omarchy restart shell"), 1)
        self.assertEqual(result.stdout.count("omarchy plugin rescan"), 0)
        self.assertNotIn("omarchy plugin enable", result.stdout)
        self.assertNotIn("omarchy plugin bar move", result.stdout)

    def test_uninstall_all_dry_run_detects_installed_lacuna_plugins(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            installed = config_home / "omarchy" / "plugins" / "lacuna.clock"
            installed.mkdir(parents=True)
            (installed / "manifest.json").write_text("{}", encoding="utf-8")

            result = run_lacuna(["uninstall", "--all", "--dry-run", "--yes"], config_home=config_home)

        self.assertIn("Uninstall plan", result.stdout)
        self.assertIn("lacuna.clock", result.stdout)
        self.assertIn("shell.json once", result.stdout)
        self.assertIn("remove", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)
        self.assertNotIn("disable lacuna.clock if enabled", result.stdout)
        self.assertNotIn("omarchy plugin remove", result.stdout)

    def test_uninstall_requires_all_or_plugin_selection(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            installed = config_home / "omarchy" / "plugins" / "lacuna.clock"
            installed.mkdir(parents=True)
            (installed / "manifest.json").write_text("{}", encoding="utf-8")

            result = run_lacuna_unchecked(["uninstall", "--dry-run", "--yes"], config_home=config_home)

        self.assertEqual(result.returncode, 2)
        self.assertIn("Pass --all or --plugin", result.stderr)

    def test_prune_backups_keeps_latest_two_per_plugin(self):
        module = load_installer_module()

        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            backup_dir = config_home / "omarchy" / "plugins"
            backup_dir.mkdir(parents=True)
            for index in range(4):
                backup = backup_dir / f".lacuna.clock.bak.2026010100000{index}"
                backup.mkdir()
                os.utime(backup, (index, index))

            with mock.patch.dict(module.os.environ, {"XDG_CONFIG_HOME": str(config_home)}):
                module.prune_backups("lacuna.clock", keep=2)

            remaining = sorted(path.name for path in backup_dir.glob(".lacuna.clock.bak.*"))

        self.assertEqual(remaining, [".lacuna.clock.bak.20260101000002", ".lacuna.clock.bak.20260101000003"])

    def test_stage_plugin_ignores_pycache_directories(self):
        module = load_installer_module()

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            config_home = tmp_path / "config"
            source = tmp_path / "repo" / "lacuna.fake"
            (source / "__pycache__").mkdir(parents=True)
            (source / "__pycache__" / "stale.pyc").write_bytes(b"cache")
            (source / "manifest.json").write_text('{"id":"lacuna.fake"}\n', encoding="utf-8")

            with mock.patch.object(module, "ROOT", tmp_path / "repo"), \
                mock.patch.dict(module.os.environ, {"XDG_CONFIG_HOME": str(config_home)}), \
                mock.patch.object(module, "validate_plugin", return_value=0):
                result = module.stage_plugin("lacuna.fake", dry_run=False, reinstall=True)

            target = config_home / "omarchy" / "plugins" / "lacuna.fake"
            manifest_staged = (target / "manifest.json").exists()
            pycache_staged = (target / "__pycache__").exists()

        self.assertEqual(result, 0)
        self.assertTrue(manifest_staged)
        self.assertFalse(pycache_staged)

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

        with tempfile.TemporaryDirectory() as tmp, \
            mock.patch.object(module, "ROOT", Path(tmp)), \
            mock.patch.object(module, "source_catalog_ids", return_value=set()):
            result = module.verify_source_catalog("lacuna", ["lacuna.state"])

        self.assertEqual(result, 1)

    def test_stale_source_catalog_allows_local_checkout_plugins(self):
        module = load_installer_module()

        with mock.patch.object(module, "source_catalog_ids", return_value=set()):
            result = module.verify_source_catalog("lacuna", ["lacuna.state"])

        self.assertEqual(result, 0)

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

    def test_activation_mutates_shell_config_once(self):
        module = load_installer_module()

        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            shell_json = config_home / "omarchy" / "shell.json"
            shell_json.parent.mkdir(parents=True)
            shell_json.write_text(
                '{"version":1,"bar":{"layout":{"left":[],"center":[],"right":[]}},"plugins":[]}\n',
                encoding="utf-8",
            )
            plugins = module.load_plugins()

            with mock.patch.dict(module.os.environ, {"XDG_CONFIG_HOME": str(config_home)}), \
                mock.patch.object(module, "run_command", return_value=0) as run_command:
                result = module.activate_plugins(
                    ["lacuna.state", "lacuna.menu-button"],
                    plugins,
                    {"lacuna.state", "lacuna.menu-button"},
                    False,
                    False,
                )

            data = __import__("json").loads(shell_json.read_text(encoding="utf-8"))

        self.assertEqual(result, 0)
        self.assertEqual(run_command.call_count, 1)
        self.assertEqual(run_command.call_args.args[0], ["omarchy", "plugin", "rescan"])
        self.assertEqual(data["plugins"], [{"id": "lacuna.state"}])
        self.assertEqual(data["bar"]["layout"]["right"], [{"id": "lacuna.menu-button"}])

    def test_plugin_stability_is_read_and_surfaced_in_labels(self):
        module = load_installer_module()
        plugins = module.load_plugins()

        self.assertEqual(plugins["lacuna.script-pill"].stability, "experimental")
        self.assertEqual(plugins["lacuna.compact-pill"].stability, "deprecated")
        self.assertEqual(plugins["lacuna.menu"].stability, "stable")

        self.assertIn("[experimental]", module.label(plugins["lacuna.script-pill"]))
        self.assertIn("[deprecated]", module.label(plugins["lacuna.compact-pill"]))
        # Stable plugins carry no marker, and id parsing still round-trips.
        self.assertNotIn("[", module.label(plugins["lacuna.menu"]))
        self.assertEqual(
            module.id_from_label(module.label(plugins["lacuna.script-pill"])),
            "lacuna.script-pill",
        )

    def test_activation_selects_bar_options_with_bar_id(self):
        module = load_installer_module()

        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            shell_json = config_home / "omarchy" / "shell.json"
            shell_json.parent.mkdir(parents=True)
            shell_json.write_text(
                '{"version":1,"bar":{"layout":{"left":[],"center":[],"right":[]}},"plugins":[]}\n',
                encoding="utf-8",
            )
            plugins = module.load_plugins()

            with mock.patch.dict(module.os.environ, {"XDG_CONFIG_HOME": str(config_home)}), \
                mock.patch.object(module, "run_command", return_value=0) as run_command:
                result = module.activate_plugins(
                    ["lacuna.bar", "lacuna.state"],
                    plugins,
                    {"lacuna.bar", "lacuna.state"},
                    False,
                    False,
                )

            data = __import__("json").loads(shell_json.read_text(encoding="utf-8"))

        self.assertEqual(result, 0)
        self.assertEqual(run_command.call_count, 1)
        self.assertEqual(run_command.call_args.args[0], ["omarchy", "restart", "shell"])
        self.assertEqual(data["bar"]["id"], "lacuna.bar")
        self.assertEqual(data["plugins"], [{"id": "lacuna.state"}])
        self.assertEqual(data["bar"]["layout"]["right"], [])

    def test_lacuna_bar_layout_brackets_native_cluster_with_seams(self):
        module = load_installer_module()
        right = [entry["id"] for entry in module.LACUNA_BAR_LAYOUT["right"]]
        self.assertEqual(2, right.count("lacuna.bar-seam"))
        # a seam immediately precedes and follows the native (bt/net/audio/power) cluster
        self.assertEqual("lacuna.bar-seam", right[right.index("lacuna.bluetooth") - 1])
        self.assertEqual("lacuna.bar-seam", right[right.index("lacuna.power") + 1])

    def test_lacuna_bar_activation_replaces_omarchy_layout_with_lacuna_modules(self):
        module = load_installer_module()

        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            shell_json = config_home / "omarchy" / "shell.json"
            shell_json.parent.mkdir(parents=True)
            shell_json.write_text(
                """
{
  "version": 1,
  "bar": {
    "layout": {
      "left": [
        { "id": "omarchy.menu" },
        { "id": "omarchy.workspaces" }
      ],
      "center": [
        { "id": "omarchy.clock" }
      ],
      "right": [
        { "id": "omarchy.tray" },
        { "id": "lacuna.temperature", "mode": "compact" }
      ]
    }
  },
  "plugins": []
}
""",
                encoding="utf-8",
            )
            plugins = module.load_plugins()
            selected = {"lacuna.bar"} | module.LACUNA_BAR_LAYOUT_PLUGIN_IDS

            with mock.patch.dict(module.os.environ, {"XDG_CONFIG_HOME": str(config_home)}), \
                mock.patch.object(module, "installed_lacuna_plugins", return_value=[]), \
                mock.patch.object(module, "run_command", return_value=0):
                result = module.activate_plugins(
                    module.ordered(selected, plugins),
                    plugins,
                    selected,
                    False,
                    False,
                )

            data = __import__("json").loads(shell_json.read_text(encoding="utf-8"))
            layout_ids = [
                entry["id"]
                for section in ("left", "center", "right")
                for entry in data["bar"]["layout"][section]
            ]

        self.assertEqual(result, 0)
        self.assertEqual(data["bar"]["id"], "lacuna.bar")
        self.assertFalse([plugin_id for plugin_id in layout_ids if plugin_id.startswith("omarchy.")])
        self.assertEqual(data["bar"]["layout"]["left"][0]["id"], "lacuna.menu-button")
        self.assertEqual(data["bar"]["layout"]["center"][0]["id"], "lacuna.voxtype")
        self.assertEqual(data["bar"]["layout"]["right"][0]["id"], "lacuna.tray")
        self.assertIn({"id": "lacuna.temperature", "mode": "compact"}, data["bar"]["layout"]["right"])

    def test_lacuna_bar_layout_uses_available_modules_and_preserves_entry_settings(self):
        module = load_installer_module()
        config = module.ensure_shell_config_shape(
            {
                "version": 1,
                "bar": {
                    "centerAnchor": "omarchy.clock",
                    "layout": {
                        "left": [
                            {"id": "lacuna.codex-usage", "interval": 60},
                            {"id": "omarchy.workspaces"},
                        ],
                        "center": [
                            {"id": "lacuna.clock", "format": "HH:mm"},
                        ],
                        "right": [
                            {"id": "lacuna.temperature", "warmF": 140},
                            {"id": "omarchy.tray"},
                        ],
                    },
                },
                "plugins": [],
            }
        )

        module.apply_lacuna_bar_layout_to_config(
            config,
            {"lacuna.menu-button", "lacuna.codex-usage", "lacuna.clock", "lacuna.temperature"},
        )

        layout = config["bar"]["layout"]
        layout_ids = [
            entry["id"]
            for section in ("left", "center", "right")
            for entry in layout[section]
        ]

        self.assertEqual("lacuna.clock", config["bar"]["centerAnchor"])
        self.assertEqual(["lacuna.menu-button", "lacuna.codex-usage"], [entry["id"] for entry in layout["left"]])
        self.assertEqual(["lacuna.clock"], [entry["id"] for entry in layout["center"]])
        self.assertEqual(["lacuna.temperature"], [entry["id"] for entry in layout["right"]])
        self.assertNotIn("omarchy.workspaces", layout_ids)
        self.assertNotIn("omarchy.tray", layout_ids)
        self.assertNotIn("lacuna.tray", layout_ids)
        self.assertIn({"id": "lacuna.codex-usage", "interval": 60}, layout["left"])
        self.assertEqual("HH:mm", layout["center"][0]["format"])
        self.assertIn("formatAlt", layout["center"][0])
        self.assertIn("verticalFormat", layout["center"][0])
        self.assertIn({"id": "lacuna.temperature", "warmF": 140}, layout["right"])

    def test_status_reports_staged_vs_enabled_plugins(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            plugins_dir = config_home / "omarchy" / "plugins"
            for plugin_id in ("lacuna.clock", "lacuna.state"):
                target = plugins_dir / plugin_id
                target.mkdir(parents=True)
                (target / "manifest.json").write_text("{}", encoding="utf-8")

            shell_json = config_home / "omarchy" / "shell.json"
            shell_json.parent.mkdir(parents=True, exist_ok=True)
            shell_json.write_text(
                '{"version":1,"bar":{"layout":{"left":[],"center":[],"right":[{"id":"lacuna.clock"}]}},"plugins":[]}\n',
                encoding="utf-8",
            )

            result = run_lacuna(["status"], config_home=config_home)

        self.assertIn("lacuna.clock (enabled)", result.stdout)
        self.assertIn("lacuna.state (staged)", result.stdout)
        self.assertIn("installed unknown, repo 0.1.0", result.stdout)

    def test_update_dry_run_lists_only_changed_installed_plugins(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            plugins_dir = config_home / "omarchy" / "plugins"
            for plugin_id in ("lacuna.clock", "lacuna.state"):
                shutil.copytree(
                    ROOT / plugin_id,
                    plugins_dir / plugin_id,
                    ignore=shutil.ignore_patterns("__pycache__"),
                )

            widget = plugins_dir / "lacuna.clock" / "Widget.qml"
            widget.write_text(widget.read_text(encoding="utf-8") + "\n// local drift\n", encoding="utf-8")

            result = run_lacuna(["update", "--dry-run", "--yes"], config_home=config_home)

        self.assertIn("Update plan", result.stdout)
        self.assertIn("lacuna.clock", result.stdout)
        self.assertNotIn("lacuna.state", result.stdout)
        self.assertIn("Already current: 1 plugin(s)", result.stdout)
        self.assertIn("stage lacuna.clock ->", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)


if __name__ == "__main__":
    unittest.main()
