import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "fixtures" / "full-settings.json"
BAR_SIZE_STATE = ROOT / "lacuna.bar-size-pill" / "scripts" / "bar-size-state"
COMPACT_STATE = ROOT / "lacuna.compact-pill" / "scripts" / "compact-state"
REFRESH_THEME_BACKGROUND = ROOT / "lacuna.theme-preloader" / "scripts" / "refresh-theme-background.sh"

PRESERVED_KEYS = [
    "customQuickLaunchApps",
    "customQuickLaunchNames",
    "preferredApps",
    "sidebar",
    "frame",
]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def seed_config(tmp_path):
    config_home = tmp_path / "config"
    settings_path = config_home / "omarchy" / "lacuna" / "settings.json"
    settings = read_json(FIXTURE)
    write_json(settings_path, settings)

    theme_dir = config_home / "omarchy" / "current" / "theme"
    theme_dir.mkdir(parents=True, exist_ok=True)
    (config_home / "omarchy" / "current" / "theme.name").write_text("fixture-theme\n", encoding="utf-8")
    (theme_dir / "colors.toml").write_text("[colors]\n", encoding="utf-8")
    (theme_dir / "shell.toml").write_text(
        "[bar]\nsize-horizontal = 30\nsize-vertical = 32\n",
        encoding="utf-8",
    )

    omarchy_path = tmp_path / "omarchy"
    (omarchy_path / "bin").mkdir(parents=True, exist_ok=True)

    return config_home, omarchy_path, settings_path, settings


def env_for(config_home, omarchy_path):
    env = os.environ.copy()
    env["XDG_CONFIG_HOME"] = str(config_home)
    env["OMARCHY_PATH"] = str(omarchy_path)
    return env


def run_script(script, action, config_home, omarchy_path):
    return subprocess.run(
        [sys.executable, str(script), action],
        check=True,
        env=env_for(config_home, omarchy_path),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def run_shell_script(script, args, config_home, omarchy_path, extra_env=None):
    env = env_for(config_home, omarchy_path)
    if extra_env:
        env.update(extra_env)
    return subprocess.run(
        [str(script)] + list(args),
        check=True,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def assert_preserved(testcase, before, after):
    for key in PRESERVED_KEYS:
        testcase.assertEqual(after[key], before[key], key)


class StateScriptTests(unittest.TestCase):
    def test_bar_size_state_preserves_user_runtime_state_on_toggle(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home, omarchy_path, settings_path, before = seed_config(Path(tmp))

            result = run_script(BAR_SIZE_STATE, "compact", config_home, omarchy_path)
            payload = json.loads(result.stdout)
            after = read_json(settings_path)

            self.assertEqual(payload["mode"], "compact")
            self.assertEqual(after["barSizeMode"], "compact")
            self.assertIs(after["compact"], True)
            self.assertGreater(after["sizeTransition"]["holdUntil"], 0)
            assert_preserved(self, before, after)

    def test_compact_state_preserves_user_runtime_state_without_delegate(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home, omarchy_path, settings_path, before = seed_config(Path(tmp))

            result = run_script(COMPACT_STATE, "toggle", config_home, omarchy_path)
            payload = json.loads(result.stdout)
            after = read_json(settings_path)

            self.assertIs(payload["compact"], True)
            self.assertEqual(after["barSizeMode"], "compact")
            self.assertIs(after["compact"], True)
            self.assertGreater(after["sizeTransition"]["holdUntil"], 0)
            assert_preserved(self, before, after)

    def test_compact_state_delegates_to_bar_size_state_and_preserves_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            config_home, omarchy_path, settings_path, before = seed_config(Path(tmp))
            delegated = config_home / "omarchy" / "plugins" / "lacuna.bar-size-pill" / "scripts" / "bar-size-state"
            delegated.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(BAR_SIZE_STATE, delegated)

            result = run_script(COMPACT_STATE, "compact", config_home, omarchy_path)
            payload = json.loads(result.stdout)
            after = read_json(settings_path)

            self.assertIs(payload["compact"], True)
            self.assertEqual(after["barSizeMode"], "compact")
            assert_preserved(self, before, after)

    def test_theme_background_refresh_relinks_reused_current_theme_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            config_home, omarchy_path, _settings_path, _before = seed_config(tmp_path)
            theme_name = "fixture-theme"
            current_background = config_home / "omarchy" / "current" / "theme" / "backgrounds" / "same-name.jpg"
            source_background = config_home / "omarchy" / "themes" / theme_name / "backgrounds" / "same-name.jpg"
            current_background.parent.mkdir(parents=True, exist_ok=True)
            source_background.parent.mkdir(parents=True, exist_ok=True)
            current_background.write_bytes(b"old-current-copy")
            source_background.write_bytes(b"new-source-image")
            background_link = config_home / "omarchy" / "current" / "background"
            background_link.symlink_to(current_background)

            fake_bin = tmp_path / "bin"
            fake_bin.mkdir()
            shell_log = tmp_path / "omarchy-shell.log"
            fake_omarchy = fake_bin / "omarchy"
            fake_omarchy.write_text(
                "#!/usr/bin/env bash\n"
                "printf '%s\\n' \"$*\" >> \"$OMARCHY_SHELL_LOG\"\n",
                encoding="utf-8",
            )
            fake_omarchy.chmod(0o755)

            run_shell_script(
                REFRESH_THEME_BACKGROUND,
                [theme_name],
                config_home,
                omarchy_path,
                {
                    "PATH": str(fake_bin) + os.pathsep + os.environ.get("PATH", ""),
                    "OMARCHY_SHELL_LOG": str(shell_log),
                },
            )

            self.assertEqual(background_link.resolve(), source_background)
            self.assertIn("shell -q background set " + str(source_background), shell_log.read_text(encoding="utf-8"))
