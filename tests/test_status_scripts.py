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
from datetime import datetime, timezone
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

    # ccusage `blocks --json` stub: one active 5h block and one earlier block
    # within the trailing 7 days, both $20. With budgets 200/400 that renders
    # session 10% and week (20+20)/400 = 10%.
    BLOCKS_STUB = (
        "#!/usr/bin/env bash\n"
        "now=$(date -u +%s)\n"
        'aend=$(date -u -d "@$((now+7200))" +%Y-%m-%dT%H:%M:%S.000Z)\n'
        'pend=$(date -u -d "@$((now-86400))" +%Y-%m-%dT%H:%M:%S.000Z)\n'
        "cat <<JSON\n"
        '{"blocks":[\n'
        '{"isActive":false,"isGap":false,"costUSD":20,"endTime":"$pend"},\n'
        '{"isActive":false,"isGap":true,"costUSD":999,"endTime":"$aend"},\n'
        '{"isActive":true,"isGap":false,"costUSD":20,"endTime":"$aend"}\n'
        "]}\n"
        "JSON\n"
    )

    def _env(self, tmp: str, ccusage_bin) -> dict:
        env = {
            "XDG_CACHE_HOME": str(Path(tmp) / "cache"),
            "CLAUDE_CONFIG_DIR": str(Path(tmp) / "claude-home"),
            "CLAUDE_CODE_STATUS_CACHE_TTL": "0",
            "CLAUDE_USAGE_SESSION_BUDGET": "200",
            "CLAUDE_USAGE_WEEK_BUDGET": "400",
        }
        if ccusage_bin is not None:
            env["CCUSAGE_BIN"] = str(ccusage_bin)
        return env

    def _stub_ccusage(self, tmp: str, body: str) -> Path:
        stub = Path(tmp) / "ccusage"
        write_exec(stub, body)
        return stub

    def test_hides_when_ccusage_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            missing = Path(tmp) / "no-such-ccusage"
            result = run([str(self.SCRIPT)], self._env(tmp, missing))
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), HIDDEN)

    def test_emits_calibrated_usage_from_ccusage(self):
        with tempfile.TemporaryDirectory() as tmp:
            stub = self._stub_ccusage(tmp, self.BLOCKS_STUB)
            result = run([str(self.SCRIPT)], self._env(tmp, stub))

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "10% used")
        self.assertEqual(payload["shortText"], "10%")
        self.assertEqual(payload["usedPercent"], 10)
        self.assertEqual(payload["leftPercent"], 90)
        self.assertTrue(payload["active"])
        self.assertEqual(payload["class"], "normal")
        self.assertEqual(payload["source"], "ccusage (calibrated)")

        self.assertTrue(payload["weekActive"])
        self.assertEqual(payload["weekUsedPercent"], 10)
        self.assertEqual(payload["weekText"], "10% wk")
        self.assertIn("7-day", payload["tooltip"])

    def test_serves_cache_when_ccusage_later_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            stub = self._stub_ccusage(tmp, self.BLOCKS_STUB)
            env = self._env(tmp, stub)
            env["CLAUDE_CODE_STATUS_CACHE_TTL"] = "300"
            first = run([str(self.SCRIPT)], env)
            self.assertEqual(json.loads(first.stdout)["usedPercent"], 10)

            write_exec(stub, "#!/usr/bin/env bash\nexit 1\n")
            second = run([str(self.SCRIPT)], env)
        self.assertEqual(second.returncode, 0)
        self.assertEqual(json.loads(second.stdout)["usedPercent"], 10)


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
