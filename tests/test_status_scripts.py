"""Execution tests for the bar-widget status shell scripts.

These scripts shell out to external tools (ccusage, codex-weekly-left, omarchy)
and must degrade gracefully when inputs or tools are missing. The tests drive
the deterministic paths: graceful-degradation guards, and the happy path via
stubbed helpers, without depending on the real external tools.
"""

import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HIDDEN = '{"text":"","tooltip":"","class":"hidden"}'


def write_exec(path: Path, body: str) -> None:
    path.write_text(body, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def run(cmd, env_overrides) -> subprocess.CompletedProcess:
    env = dict(os.environ)
    env.update(env_overrides)
    return subprocess.run(cmd, env=env, capture_output=True, text=True)


class ClaudeCodeStatusTests(unittest.TestCase):
    SCRIPT = ROOT / "lacuna.claude-usage" / "scripts" / "claude-code-status.sh"

    def test_hides_on_non_numeric_session_limit(self):
        result = run([str(self.SCRIPT)], {"CLAUDE_CODE_SESSION_LIMIT": "not-a-number"})
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), HIDDEN)

    def test_hides_on_zero_session_limit(self):
        result = run([str(self.SCRIPT)], {"CLAUDE_CODE_SESSION_LIMIT": "0"})
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), HIDDEN)

    def test_hides_when_claude_home_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run(
                [str(self.SCRIPT)],
                {
                    "CLAUDE_CODE_SESSION_LIMIT": "1000",
                    "CLAUDE_CONFIG_DIR": str(Path(tmp) / "does-not-exist"),
                },
            )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), HIDDEN)


class CodexWeeklyStatusTests(unittest.TestCase):
    SCRIPT = ROOT / "lacuna.codex-usage" / "scripts" / "codex-weekly-status.sh"

    def _staged(self, tmp: str, helper_body: str) -> Path:
        scripts = Path(tmp) / "scripts"
        scripts.mkdir(parents=True)
        staged = scripts / "codex-weekly-status.sh"
        shutil.copy2(self.SCRIPT, staged)
        write_exec(scripts / "codex-weekly-left", helper_body)
        return staged

    def test_emits_status_from_helper_output(self):
        helper = (
            "#!/usr/bin/env bash\n"
            "cat <<'OUT'\n"
            "Weekly limit left: 37%\n"
            "Weekly used: 63%\n"
            "Resets: 2026-06-20 09:00 AM\n"
            "Plan: pro\n"
            "OUT\n"
        )
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "37% left")
        self.assertEqual(payload["class"], "normal")
        self.assertIn("Codex Weekly Usage", payload["tooltip"])

    def test_low_balance_is_flagged_alert(self):
        helper = "#!/usr/bin/env bash\nprintf 'Weekly limit left: 5%%\\nPlan: plus\\n'\n"
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "5% left")
        self.assertEqual(payload["class"], "alert")

    def test_hides_when_helper_emits_no_weekly_line(self):
        helper = "#!/usr/bin/env bash\nprintf 'nothing useful here\\n'\n"
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), HIDDEN)


class PreloadThemeSwitcherTests(unittest.TestCase):
    SCRIPT = ROOT / "lacuna.theme-preloader" / "scripts" / "preload-theme-switcher.sh"

    def _env(self, tmp: Path, omarchy_exit: int = 0) -> dict:
        # Stub `omarchy` on PATH so the cache-warm call is deterministic.
        stub_bin = tmp / "bin"
        stub_bin.mkdir(parents=True, exist_ok=True)
        write_exec(stub_bin / "omarchy", f"#!/bin/sh\nexit {omarchy_exit}\n")
        return {
            "PATH": f"{stub_bin}:{os.environ.get('PATH', '')}",
            "OMARCHY_PATH": str(tmp / "omarchy-share"),  # no bin/omarchy here
            "USER_THEMES_PATH": str(tmp / "themes"),
            "OMARCHY_THEMES_PATH": str(tmp / "omarchy-themes"),
            "XDG_CACHE_HOME": str(tmp / "cache"),
        }

    def test_builds_preview_symlinks_and_warms_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            theme = tmp / "themes" / "mytheme"
            theme.mkdir(parents=True)
            (theme / "preview.png").write_bytes(b"img")
            env = self._env(tmp)

            result = run([str(self.SCRIPT), "--reason", "test"], env)

            self.assertEqual(result.returncode, 0, result.stderr)
            previews = tmp / "cache" / "omarchy" / "theme-selector" / "previews"
            self.assertTrue((previews / "mytheme.png").is_symlink())

            status = json.loads(
                (tmp / "cache" / "omarchy" / "theme-selector" / "preloader-status.json").read_text()
            )
            self.assertEqual(status["status"], "ok")
            self.assertEqual(status["changed"], True)
            self.assertEqual(status["themeCount"], 1)
            self.assertEqual(status["reason"], "test")

    def test_second_run_reports_unchanged_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            theme = tmp / "themes" / "mytheme"
            theme.mkdir(parents=True)
            (theme / "preview.png").write_bytes(b"img")
            env = self._env(tmp)

            run([str(self.SCRIPT)], env)
            result = run([str(self.SCRIPT)], env)

            status = json.loads(
                (tmp / "cache" / "omarchy" / "theme-selector" / "preloader-status.json").read_text()
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(status["status"], "ok")
            self.assertEqual(status["changed"], False)


if __name__ == "__main__":
    unittest.main()
