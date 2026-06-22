import argparse
import importlib.machinery
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
DEV = ROOT / "scripts" / "dev"


def run_dev(args, config_home=None):
    if config_home is None:
        with tempfile.TemporaryDirectory() as tmp:
            return run_dev(args, config_home=Path(tmp) / "config")

    env = os.environ.copy()
    env["XDG_CONFIG_HOME"] = str(config_home)
    return subprocess.run(
        [str(DEV), *args],
        check=True,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def load_dev_module():
    loader = importlib.machinery.SourceFileLoader("lacuna_dev_tool", str(DEV))
    spec = importlib.util.spec_from_loader("lacuna_dev_tool", loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules["lacuna_dev_tool"] = module
    spec.loader.exec_module(module)
    return module


class DevToolTests(unittest.TestCase):
    def test_deploy_dry_run_restarts_and_verifies_plugin(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            installed = config_home / "omarchy" / "plugins" / "lacuna.menu"
            installed.mkdir(parents=True)
            (installed / "manifest.json").write_text('{"id":"lacuna.menu","version":"old"}\n', encoding="utf-8")

            result = run_dev(["deploy", "lacuna.menu", "--dry-run"], config_home=config_home)

        self.assertIn("Dev deploy plan", result.stdout)
        self.assertIn("deploy lacuna.menu ->", result.stdout)
        self.assertIn("omarchy plugin rescan", result.stdout)
        self.assertIn("omarchy restart shell", result.stdout)
        self.assertIn("verify installed plugin files match this checkout", result.stdout)

    def test_deploy_copies_repo_plugin_and_verifies_installed_copy(self):
        module = load_dev_module()
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp) / "config"
            installed = config_home / "omarchy" / "plugins" / "lacuna.clock"
            installed.mkdir(parents=True)
            (installed / "manifest.json").write_text('{"id":"lacuna.clock","version":"old"}\n', encoding="utf-8")
            args = argparse.Namespace(
                plugins=["lacuna.clock"],
                all=False,
                dry_run=False,
                only_changed=False,
                restart_shell=True,
            )

            with mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": str(config_home)}), \
                mock.patch.object(module, "validate_plugin", return_value=0), \
                mock.patch.object(module, "run_command", return_value=0) as run_command:
                result = module.deploy(args)
                matches, issues = module.installed_matches_source("lacuna.clock")

        self.assertEqual(result, 0)
        self.assertTrue(matches, issues)
        self.assertEqual(
            [call.args[0] for call in run_command.call_args_list],
            [["omarchy", "plugin", "rescan"], ["omarchy", "restart", "shell"]],
        )


if __name__ == "__main__":
    unittest.main()
