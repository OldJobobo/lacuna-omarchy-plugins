"""Execution tests for the bar-widget status shell scripts.

These scripts shell out to external tools (ccusage, codex-weekly-left, omarchy)
and must degrade gracefully when inputs or tools are missing. The tests drive
the deterministic paths: graceful-degradation guards, and the happy path via
stubbed helpers, without depending on the real external tools.
"""

import json
import contextlib
import importlib.machinery
import importlib.util
import io
import os
import shutil
import stat
import subprocess
import sys
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


def load_script(path: Path, name: str):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


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
        self.assertTrue(payload["sessionAvailable"])
        self.assertFalse(payload["sessionAvailabilityKnown"])
        self.assertEqual(payload["class"], "normal")
        self.assertEqual(payload["source"], "ccusage (calibrated)")

        self.assertTrue(payload["weekActive"])
        self.assertEqual(payload["weekUsedPercent"], 10)
        self.assertEqual(payload["weekText"], "10% wk")
        self.assertIn("7-day", payload["tooltip"])

    def test_uses_provider_windows_and_reports_session_capability(self):
        with tempfile.TemporaryDirectory() as tmp:
            stub = self._stub_ccusage(tmp, self.BLOCKS_STUB)
            api_file = Path(tmp) / "usage.json"
            api_file.write_text(
                json.dumps(
                    {
                        "five_hour": {"utilization": 0.24, "resets_at": "2026-07-15T23:00:00Z"},
                        "seven_day": {"utilization": 0.41, "resets_at": "2026-07-20T18:00:00Z"},
                    }
                ),
                encoding="utf-8",
            )
            env = self._env(tmp, stub)
            env["CLAUDE_USAGE_API_FILE"] = str(api_file)
            result = run([str(self.SCRIPT)], env)

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["source"], "Claude usage API")
        self.assertTrue(payload["sessionAvailabilityKnown"])
        self.assertTrue(payload["sessionAvailable"])
        self.assertEqual(payload["usedPercent"], 24)
        self.assertEqual(payload["weekUsedPercent"], 41)
        self.assertNotIn("suppressed", payload["tooltip"])

    def test_provider_omission_suppresses_session_but_keeps_weekly(self):
        with tempfile.TemporaryDirectory() as tmp:
            stub = self._stub_ccusage(tmp, self.BLOCKS_STUB)
            api_file = Path(tmp) / "usage.json"
            api_file.write_text(
                json.dumps(
                    {
                        "five_hour": None,
                        "seven_day": {"utilization": 0.41, "resets_at": "2026-07-20T18:00:00Z"},
                    }
                ),
                encoding="utf-8",
            )
            env = self._env(tmp, stub)
            env["CLAUDE_USAGE_API_FILE"] = str(api_file)
            result = run([str(self.SCRIPT)], env)

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["sessionAvailabilityKnown"])
        self.assertFalse(payload["sessionAvailable"])
        self.assertFalse(payload["active"])
        self.assertEqual(payload["text"], "41% used")
        self.assertTrue(payload["weekActive"])
        self.assertEqual(payload["weekUsedPercent"], 41)
        self.assertIn("5h block: suppressed", payload["tooltip"])

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
    LEFT_SCRIPT = ROOT / "lacuna.codex-usage" / "scripts" / "codex-weekly-left"

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
            "5h limit left: 88%\n"
            "5h used: 12%\n"
            "5h resets: 2026-06-18 02:00 PM\n"
            "Weekly limit left: 37%\n"
            "Weekly used: 63%\n"
            "Weekly resets: 2026-06-20 09:00 AM\n"
            "Plan: pro\n"
            "Source: OpenAI usage API via Pi OAuth\n"
            "Source event: 2026-06-18T12:34:56Z\n"
            "Source file: /tmp/codex-session.jsonl\n"
            "OUT\n"
        )
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "12% used")
        self.assertEqual(payload["shortText"], "12%")
        self.assertEqual(payload["class"], "normal")
        self.assertEqual(payload["leftPercent"], 88)
        self.assertEqual(payload["usedPercent"], 12)
        self.assertIs(payload["active"], True)
        self.assertIs(payload["sessionAvailable"], True)
        self.assertEqual(payload["resetText"], "2026-06-18 02:00 PM")
        self.assertIs(payload["weekActive"], True)
        self.assertEqual(payload["weekText"], "63% wk")
        self.assertEqual(payload["weekLeftPercent"], 37)
        self.assertEqual(payload["weekUsedPercent"], 63)
        self.assertEqual(payload["weekResetText"], "2026-06-20 09:00 AM")
        self.assertEqual(payload["planText"], "Pro")
        self.assertEqual(payload["sourceFileText"], "/tmp/codex-session.jsonl")
        self.assertEqual(payload["source"], "OpenAI usage API via Pi OAuth")
        self.assertIn("Codex Usage", payload["tooltip"])

    def test_low_balance_is_flagged_alert(self):
        helper = "#!/usr/bin/env bash\nprintf 'Weekly limit left: 5%%\\nPlan: plus\\n'\n"
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "95% used")
        self.assertEqual(payload["class"], "alert")
        self.assertIs(payload["sessionAvailable"], False)

    def test_hides_when_helper_emits_no_weekly_line(self):
        helper = "#!/usr/bin/env bash\nprintf 'nothing useful here\\n'\n"
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), HIDDEN)

    def test_weekly_left_reads_pi_oauth_usage_without_caching_auth_data(self):
        future = int(datetime.now().timestamp()) + 604800
        payload = {
            "user_id": "must-not-be-cached",
            "account_id": "must-not-be-cached",
            "email": "must-not-be-cached@example.com",
            "plan_type": "prolite",
            "rate_limit": {
                "primary_window": {
                    "used_percent": 30,
                    "limit_window_seconds": 604800,
                    "reset_at": future,
                },
                "secondary_window": None,
            },
        }
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = root / "usage.json"
            fixture.write_text(json.dumps(payload), encoding="utf-8")
            cache_home = root / "cache"
            result = run(
                [str(self.LEFT_SCRIPT)],
                {
                    "HOME": str(root),
                    "XDG_CACHE_HOME": str(cache_home),
                    "PI_CODING_AGENT_DIR": str(root / "pi-agent"),
                    "LACUNA_CODEX_USAGE_API_FIXTURE": str(fixture),
                },
            )
            cache = cache_home / "lacuna" / "codex-usage.json"
            cached_text = cache.read_text(encoding="utf-8")
            cache_mode = stat.S_IMODE(cache.stat().st_mode)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("5h used", result.stdout)
        self.assertIn("Weekly used: 30.0%", result.stdout)
        self.assertIn("Source: OpenAI usage API via Pi OAuth", result.stdout)
        self.assertEqual(cache_mode, 0o600)
        for secret in ("user_id", "account_id", "email", "access", "refresh", "must-not-be-cached"):
            self.assertNotIn(secret, cached_text)

    def test_weekly_left_uses_sanitized_cache_when_api_is_unavailable(self):
        future = int(datetime.now().timestamp()) + 604800
        payload = {
            "plan_type": "pro",
            "rate_limit": {
                "primary_window": {
                    "used_percent": 44,
                    "limit_window_seconds": 604800,
                    "reset_at": future,
                },
                "secondary_window": None,
            },
        }
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = root / "usage.json"
            fixture.write_text(json.dumps(payload), encoding="utf-8")
            env = {
                "HOME": str(root),
                "XDG_CACHE_HOME": str(root / "cache"),
                "PI_CODING_AGENT_DIR": str(root / "pi-agent"),
                "LACUNA_CODEX_USAGE_API_FIXTURE": str(fixture),
            }
            first = run([str(self.LEFT_SCRIPT)], env)
            fixture.unlink()
            env.pop("LACUNA_CODEX_USAGE_API_FIXTURE")
            second = run([str(self.LEFT_SCRIPT)], env)

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("Weekly used: 44.0%", second.stdout)
        self.assertIn("Source: OpenAI usage API via Pi OAuth (cached)", second.stdout)

    def test_weekly_left_rejects_permissive_pi_auth_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            agent_dir = root / "pi-agent"
            agent_dir.mkdir()
            auth = agent_dir / "auth.json"
            auth.write_text(json.dumps({
                "openai-codex": {
                    "type": "oauth",
                    "access": "must-not-be-used",
                    "accountId": "must-not-be-used",
                }
            }), encoding="utf-8")
            auth.chmod(0o644)
            result = run(
                [str(self.LEFT_SCRIPT)],
                {
                    "HOME": str(root),
                    "XDG_CACHE_HOME": str(root / "cache"),
                    "PI_CODING_AGENT_DIR": str(agent_dir),
                },
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("must-not-be-used", result.stdout + result.stderr)

    def test_weekly_left_prefers_canonical_codex_limit_over_newer_variant(self):
        def token_event(timestamp, limit_id, weekly_used, weekly_reset):
            return {
                "timestamp": timestamp,
                "type": "event_msg",
                "payload": {
                    "type": "token_count",
                    "rate_limits": {
                        "limit_id": limit_id,
                        "plan_type": "prolite",
                        "primary": {"used_percent": 0.0, "resets_at": 1782047254},
                        "secondary": {
                            "used_percent": weekly_used,
                            "resets_at": weekly_reset,
                            "window_minutes": 10080,
                        },
                    },
                },
            }

        future = int(datetime.now().timestamp()) + 86400
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            sessions = home / ".codex" / "sessions" / "2026" / "06" / "21"
            sessions.mkdir(parents=True)
            session_file = sessions / "session.jsonl"
            session_file.write_text(
                "\n".join(
                    [
                        json.dumps(token_event("2026-06-21T08:09:59.582Z", "codex", 62.0, future)),
                        json.dumps(token_event("2026-06-21T16:02:44.298Z", "codex_bengalfox", 0.0, future)),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            result = run([str(self.LEFT_SCRIPT)], {
                "HOME": str(home),
                "XDG_CACHE_HOME": str(home / "cache"),
                "PI_CODING_AGENT_DIR": str(home / "pi-agent"),
            })

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Weekly limit left: 38.0%", result.stdout)
        self.assertIn("Weekly used: 62.0%", result.stdout)

    def test_weekly_left_recognizes_weekly_window_in_primary(self):
        event = {
            "timestamp": "2026-07-12T22:45:31.079Z",
            "type": "event_msg",
            "payload": {
                "type": "token_count",
                "rate_limits": {
                    "limit_id": "codex",
                    "plan_type": "prolite",
                    "primary": {
                        "used_percent": 7.0,
                        "resets_at": 1784487505,
                        "window_minutes": 10080,
                    },
                    "secondary": None,
                },
            },
        }

        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            sessions = home / ".codex" / "sessions" / "2026" / "07" / "12"
            sessions.mkdir(parents=True)
            (sessions / "session.jsonl").write_text(json.dumps(event) + "\n", encoding="utf-8")
            result = run([str(self.LEFT_SCRIPT)], {
                "HOME": str(home),
                "XDG_CACHE_HOME": str(home / "cache"),
                "PI_CODING_AGENT_DIR": str(home / "pi-agent"),
            })

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("5h used", result.stdout)
        self.assertIn("Weekly limit left: 93.0%", result.stdout)
        self.assertIn("Weekly used: 7.0%", result.stdout)

    def test_weekly_left_combines_split_five_hour_and_weekly_streams(self):
        def event(timestamp, limit_id, minutes, used, reset):
            return {
                "timestamp": timestamp,
                "type": "event_msg",
                "payload": {
                    "type": "token_count",
                    "rate_limits": {
                        "limit_id": limit_id,
                        "plan_type": "prolite",
                        "primary": {
                            "used_percent": used,
                            "resets_at": reset,
                            "window_minutes": minutes,
                        },
                        "secondary": None,
                    },
                },
            }

        future = int(datetime.now().timestamp()) + 86400
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            sessions = home / ".codex" / "sessions" / "2026" / "07" / "12"
            sessions.mkdir(parents=True)
            (sessions / "session.jsonl").write_text(
                "\n".join(
                    [
                        json.dumps(event("2026-07-12T22:00:00Z", "codex_bengalfox", 300, 12.0, future)),
                        json.dumps(event("2026-07-12T22:01:00Z", "codex", 10080, 9.0, future)),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            result = run([str(self.LEFT_SCRIPT)], {
                "HOME": str(home),
                "XDG_CACHE_HOME": str(home / "cache"),
                "PI_CODING_AGENT_DIR": str(home / "pi-agent"),
            })

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("5h used: 12.0%", result.stdout)
        self.assertIn("Weekly used: 9.0%", result.stdout)

    def test_weekly_left_drops_stale_five_hour_window_after_canonical_omission(self):
        def event(timestamp, minutes, used, reset):
            return {
                "timestamp": timestamp,
                "type": "event_msg",
                "payload": {
                    "type": "token_count",
                    "rate_limits": {
                        "limit_id": "codex",
                        "plan_type": "prolite",
                        "primary": {
                            "used_percent": used,
                            "resets_at": reset,
                            "window_minutes": minutes,
                        },
                        "secondary": None,
                    },
                },
            }

        future = int(datetime.now().timestamp()) + 86400
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            sessions = home / ".codex" / "sessions" / "2026" / "07" / "15"
            sessions.mkdir(parents=True)
            (sessions / "session.jsonl").write_text(
                "\n".join(
                    [
                        json.dumps(event("2026-07-14T20:00:00Z", 300, 56.0, future)),
                        json.dumps(event("2026-07-15T20:00:00Z", 10080, 6.0, future)),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            result = run([str(self.LEFT_SCRIPT)], {
                "HOME": str(home),
                "XDG_CACHE_HOME": str(home / "cache"),
                "PI_CODING_AGENT_DIR": str(home / "pi-agent"),
            })

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("5h used", result.stdout)
        self.assertIn("Weekly used: 6.0%", result.stdout)


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


class MediaPlayerScriptTests(unittest.TestCase):
    CHECK_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "media-player-check"
    SEARCH_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "media-player-search"
    CONTROL_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "media-player-control"
    INFO_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "media-player-info"
    REFRESH_FAVORITES_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "media-player-refresh-favorites"
    PREVIEW_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "media-player-preview"
    JELLYFIN_SEARCH_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "jellyfin-search"
    JELLYFIN_STREAM_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "jellyfin-stream"
    AUTH_SCRIPT = ROOT / "lacuna.media-player" / "scripts" / "youtube-auth"

    def test_dependency_check_reports_missing_tools(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            env = {"PATH": tmpdir}
            result = run([sys.executable, str(self.CHECK_SCRIPT)], env)

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertIs(payload["mpv"], False)
        self.assertIs(payload["ytdlp"], False)
        self.assertIn("mpv", payload["message"])
        self.assertIn("yt-dlp", payload["message"])

    def test_search_normalizes_ytdlp_json_lines(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "print(json.dumps({\n"
                "  'id': 'abc123',\n"
                "  'title': 'Demo Track',\n"
                "  'uploader': 'Demo Artist - Topic',\n"
                "  'duration': 125,\n"
                "  'thumbnails': [{'url': 'small.jpg'}, {'url': 'large.jpg'}]\n"
                "}))\n",
            )
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--limit", "3", "demo query"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["error"], "")
        self.assertEqual(len(payload["results"]), 1)
        self.assertIn("--flat-playlist", argv)
        self.assertIn("--lazy-playlist", argv)
        self.assertIn("ytsearch3:demo query", argv)
        item = payload["results"][0]
        self.assertEqual(item["id"], "abc123")
        self.assertEqual(item["title"], "Demo Track")
        self.assertEqual(item["uploader"], "Demo Artist - Topic")
        self.assertEqual(item["durationText"], "2:05")
        self.assertEqual(item["thumbnail"], "https://i.ytimg.com/vi/abc123/hqdefault.jpg")
        self.assertEqual(item["url"], "https://www.youtube.com/watch?v=abc123")

    def test_search_ignores_legacy_music_filter(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json\n"
                "rows = [\n"
                "  {'id': 'review1', 'title': 'Demo Track reaction review', 'uploader': 'Video Channel', 'duration': 720},\n"
                "  {'id': 'song1', 'title': 'Demo Track Official Audio', 'uploader': 'Demo Artist - Topic', 'duration': 185},\n"
                "]\n"
                "for row in rows: print(json.dumps(row))\n",
            )
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--filter", "music", "--limit", "2", "demo track"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["review1", "song1"])

    def test_search_keeps_all_video_results_for_legacy_music_filter(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json\n"
                "rows = [\n"
                "  {'id': 'song1', 'title': 'Small Artist - First Track', 'uploader': 'Small Artist', 'duration': 185},\n"
                "  {'id': 'song2', 'title': 'Second Track', 'uploader': 'Small Artist', 'duration': 205},\n"
                "  {'id': 'pod1', 'title': 'Small Artist interview podcast', 'uploader': 'Talk Channel', 'duration': 3600},\n"
                "]\n"
                "for row in rows: print(json.dumps(row))\n",
            )
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--filter", "music", "--limit", "3", "small artist"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["song1", "song2", "pod1"])

    def test_search_keeps_all_result_order_for_legacy_music_filter(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json\n"
                "rows = [\n"
                "  {'id': 'album1', 'title': 'Small Artist - Full Album', 'uploader': 'Small Artist', 'duration': 3180},\n"
                "  {'id': 'mix1', 'title': 'Small Artist live set mix', 'uploader': 'Small Artist', 'duration': 5420},\n"
                "  {'id': 'stream1', 'title': 'Small Artist livestream playlist', 'uploader': 'Small Artist', 'duration': 14400},\n"
                "  {'id': 'review1', 'title': 'Small Artist album review', 'uploader': 'Talk Channel', 'duration': 920},\n"
                "]\n"
                "for row in rows: print(json.dumps(row))\n",
            )
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--filter", "music", "--limit", "4", "small artist"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["album1", "mix1", "stream1", "review1"])

    def test_search_uses_large_candidate_pool_for_scroll_reveal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "for idx in range(3): print(json.dumps({'id': f'id{idx}', 'title': f'Mix {idx}', 'duration': 3600}))\n",
            )
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--filter", "music", "--limit", "80", "ambient mix"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ytsearch80:ambient mix", argv)

    def test_all_filter_keeps_general_youtube_order(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "rows = [\n"
                "  {'id': 'general1', 'title': 'Demo Track reaction review', 'uploader': 'Video Channel', 'duration': 720},\n"
                "  {'id': 'song1', 'title': 'Demo Track Official Audio', 'uploader': 'Demo Artist - Topic', 'duration': 185},\n"
                "]\n"
                "for row in rows: print(json.dumps(row))\n",
            )
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--filter", "all", "--limit", "2", "demo track"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ytsearch2:demo track", argv)
        self.assertNotIn("ytsearch2:demo track music", argv)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["general1", "song1"])

    def test_public_search_does_not_load_browser_cookies(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "print(json.dumps({'id': 'general1', 'title': 'General YouTube Video', 'uploader': 'Video Channel', 'duration': 300}))\n",
            )
            config = json.dumps({"enabled": True, "cookiesFromBrowser": "firefox"})
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--config-json", config, "--limit", "5", "demo"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("--cookies-from-browser", argv)
        self.assertNotIn("firefox", argv)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["error"], "")
        self.assertEqual(payload["results"][0]["id"], "general1")
        self.assertEqual(payload["results"][0]["source"], "YouTube")

    def test_default_suggestions_use_broad_video_search(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "rows = [\n"
                "  {'id': 'home1', 'title': 'Personal Coding Video', 'uploader': 'Dev Channel', 'duration': 1260},\n"
                "  {'id': 'home2', 'title': 'Longform Essay', 'uploader': 'Essay Channel', 'duration': 4184},\n"
                "]\n"
                "for row in rows: print(json.dumps(row))\n",
            )
            config = json.dumps({"enabled": True, "cookiesFromBrowser": "firefox"})
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--config-json", config, "--filter", "all", "--limit", "5", "--suggestions"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("--cookies-from-browser", argv)
        self.assertIn("ytsearch5:latest videos", argv)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["error"], "")
        self.assertEqual([item["id"] for item in payload["results"]], ["home1", "home2"])
        self.assertNotEqual(payload["results"][0]["source"], "YouTube Home Music")

    def test_default_suggestions_do_not_depend_on_authenticated_home_feed(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "print('Extracted 0 cookies from brave (54 could not be decrypted)', file=sys.stderr)\n",
            )
            config = json.dumps({"enabled": True, "cookiesFromBrowser": "brave"})
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--config-json", config, "--filter", "all", "--limit", "5", "--suggestions"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ytsearch5:latest videos", argv)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["results"], [])
        self.assertEqual(payload["error"], "")

    def test_music_filter_cannot_enable_authenticated_home_feed(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "rows = [\n"
                "  {'id': 'code1', 'title': 'Your Apps Dont Need an API Anymore', 'uploader': 'Dev Channel', 'duration': 1260},\n"
                "  {'id': 'music1', 'title': 'Artist - Song Title', 'uploader': 'Artist', 'duration': 180},\n"
                "  {'id': 'review1', 'title': 'Classic Album Review', 'uploader': 'Talk Channel', 'duration': 900},\n"
                "  {'id': 'mix1', 'title': 'Deep Focus Synthwave Mix', 'uploader': 'Music Channel', 'duration': 3600},\n"
                "]\n"
                "for row in rows: print(json.dumps(row))\n",
            )
            config = json.dumps({"enabled": True, "cookiesFromBrowser": "firefox"})
            result = run(
                [sys.executable, str(self.SEARCH_SCRIPT), "--config-json", config, "--filter", "music", "--limit", "3", "--suggestions"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("--cookies-from-browser", argv)
        self.assertNotIn("firefox", argv)
        self.assertIn("ytsearch3:latest videos", argv)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["error"], "")
        self.assertEqual([item["id"] for item in payload["results"]], ["code1", "music1", "review1"])
        self.assertEqual(payload["results"][0]["source"], "YouTube")

    def test_auth_helper_handles_missing_auth_dir_and_enables_browser_cookies(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            for tool in ["dirname", "mkdir", "mv", "rm"]:
                (bin_dir / tool).symlink_to(shutil.which(tool))
            write_exec(bin_dir / "firefox", "#!/bin/sh\nexit 0\n")
            write_exec(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
            for terminal in ["foot", "ghostty", "alacritty", "kitty", "wezterm", "xterm"]:
                write_exec(bin_dir / terminal, "#!/bin/sh\nexit 0\n")
            auth_dir = tmp / "omarchy" / "lacuna" / "youtube"
            result = run(
                ["/bin/bash", str(self.AUTH_SCRIPT), "--auth-dir", str(auth_dir)],
                {
                    "PATH": str(bin_dir),
                    "HOME": str(tmp),
                    "XDG_CONFIG_HOME": str(tmp / "config"),
                    "PYTHON": sys.executable,
                },
            )
            settings = json.loads((tmp / "omarchy" / "lacuna" / "settings.json").read_text(encoding="utf-8"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(settings["mediaProviders"]["youtube"]["enabled"])
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFromBrowser"], "firefox")
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFile"], "")

    def test_auth_helper_clears_stale_cookie_file_when_using_browser_source(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            for tool in ["dirname", "mkdir", "mv", "rm"]:
                (bin_dir / tool).symlink_to(shutil.which(tool))
            write_exec(bin_dir / "firefox", "#!/bin/sh\nexit 0\n")
            write_exec(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
            for terminal in ["foot", "ghostty", "alacritty", "kitty", "wezterm", "xterm"]:
                write_exec(bin_dir / terminal, "#!/bin/sh\nexit 0\n")
            auth_dir = tmp / "omarchy" / "lacuna" / "youtube"
            settings_path = tmp / "omarchy" / "lacuna" / "settings.json"
            settings_path.parent.mkdir(parents=True)
            stale = auth_dir / "cookies.txt"
            settings_path.write_text(
                json.dumps({"mediaProviders": {"youtube": {"enabled": True, "cookiesFromBrowser": "", "cookiesFile": str(stale)}}}),
                encoding="utf-8",
            )
            result = run(
                ["/bin/bash", str(self.AUTH_SCRIPT), "--auth-dir", str(auth_dir)],
                {
                    "PATH": str(bin_dir),
                    "HOME": str(tmp),
                    "XDG_CONFIG_HOME": str(tmp / "config"),
                    "PYTHON": sys.executable,
                },
            )
            settings = json.loads(settings_path.read_text(encoding="utf-8"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFromBrowser"], "firefox")
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFile"], "")

    def test_auth_helper_maps_zen_to_firefox_profile_cookie_source(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            for tool in ["dirname", "mkdir", "mv", "rm"]:
                (bin_dir / tool).symlink_to(shutil.which(tool))
            write_exec(bin_dir / "zen-browser", "#!/bin/sh\nexit 0\n")
            write_exec(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
            for terminal in ["foot", "ghostty", "alacritty", "kitty", "wezterm", "xterm"]:
                write_exec(bin_dir / terminal, "#!/bin/sh\nexit 0\n")
            profile = tmp / ".zen" / "abc.default"
            profile.mkdir(parents=True)
            (profile / "cookies.sqlite").write_text("", encoding="utf-8")
            auth_dir = tmp / "omarchy" / "lacuna" / "youtube"
            result = run(
                ["/bin/bash", str(self.AUTH_SCRIPT), "--auth-dir", str(auth_dir)],
                {
                    "PATH": str(bin_dir),
                    "HOME": str(tmp),
                    "XDG_CONFIG_HOME": str(tmp / "config"),
                    "PYTHON": sys.executable,
                },
            )
            settings = json.loads((tmp / "omarchy" / "lacuna" / "settings.json").read_text(encoding="utf-8"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFromBrowser"], f"firefox:{profile}")

    def test_auth_helper_uses_gnome_keyring_for_chromium_browser_cookies(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            for tool in ["dirname", "mkdir", "mv", "rm"]:
                (bin_dir / tool).symlink_to(shutil.which(tool))
            write_exec(bin_dir / "brave-browser", "#!/bin/sh\nexit 0\n")
            write_exec(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
            for terminal in ["foot", "ghostty", "alacritty", "kitty", "wezterm", "xterm"]:
                write_exec(bin_dir / terminal, "#!/bin/sh\nexit 0\n")
            auth_dir = tmp / "omarchy" / "lacuna" / "youtube"
            result = run(
                ["/bin/bash", str(self.AUTH_SCRIPT), "--auth-dir", str(auth_dir)],
                {
                    "PATH": str(bin_dir),
                    "HOME": str(tmp),
                    "XDG_CONFIG_HOME": str(tmp / "config"),
                    "PYTHON": sys.executable,
                },
            )
            settings = json.loads((tmp / "omarchy" / "lacuna" / "settings.json").read_text(encoding="utf-8"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFromBrowser"], "brave+gnomekeyring")

    def test_auth_helper_exports_browser_cookies_to_file_when_ytdlp_available(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            for tool in ["dirname", "mkdir", "mv", "rm"]:
                (bin_dir / tool).symlink_to(shutil.which(tool))
            write_exec(bin_dir / "firefox", "#!/bin/sh\nexit 0\n")
            write_exec(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import pathlib, sys\n"
                "path = pathlib.Path(sys.argv[sys.argv.index('--cookies') + 1])\n"
                "path.write_text('# Netscape HTTP Cookie File\\n.youtube.com\\tTRUE\\t/\\tTRUE\\t0\\tSID\\ttest\\n')\n",
            )
            for terminal in ["foot", "ghostty", "alacritty", "kitty", "wezterm", "xterm"]:
                write_exec(bin_dir / terminal, "#!/bin/sh\nexit 0\n")
            auth_dir = tmp / "omarchy" / "lacuna" / "youtube"
            result = run(
                ["/bin/bash", str(self.AUTH_SCRIPT), "--auth-dir", str(auth_dir)],
                {
                    "PATH": str(bin_dir),
                    "HOME": str(tmp),
                    "XDG_CONFIG_HOME": str(tmp / "config"),
                    "PYTHON": sys.executable,
                },
            )
            settings = json.loads((tmp / "omarchy" / "lacuna" / "settings.json").read_text(encoding="utf-8"))
            cookies_file = auth_dir / "cookies.txt"
            cookies_file_exists = cookies_file.exists()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(cookies_file_exists)
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFile"], str(cookies_file))
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFromBrowser"], "")

    def test_auth_helper_rejects_anonymous_exported_cookie_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            for tool in ["dirname", "mkdir", "mv", "rm"]:
                (bin_dir / tool).symlink_to(shutil.which(tool))
            write_exec(bin_dir / "firefox", "#!/bin/sh\nexit 0\n")
            write_exec(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import pathlib, sys\n"
                "path = pathlib.Path(sys.argv[sys.argv.index('--cookies') + 1])\n"
                "path.write_text('# Netscape HTTP Cookie File\\n.youtube.com\\tTRUE\\t/\\tTRUE\\t0\\tVISITOR_INFO1_LIVE\\ttest\\n')\n",
            )
            for terminal in ["foot", "ghostty", "alacritty", "kitty", "wezterm", "xterm"]:
                write_exec(bin_dir / terminal, "#!/bin/sh\nexit 0\n")
            auth_dir = tmp / "omarchy" / "lacuna" / "youtube"
            result = run(
                ["/bin/bash", str(self.AUTH_SCRIPT), "--auth-dir", str(auth_dir)],
                {
                    "PATH": str(bin_dir),
                    "HOME": str(tmp),
                    "XDG_CONFIG_HOME": str(tmp / "config"),
                    "PYTHON": sys.executable,
                },
            )
            settings = json.loads((tmp / "omarchy" / "lacuna" / "settings.json").read_text(encoding="utf-8"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((auth_dir / "cookies.txt").exists())
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFile"], "")
        self.assertEqual(settings["mediaProviders"]["youtube"]["cookiesFromBrowser"], "firefox")

    def test_search_handles_missing_ytdlp(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            result = run([sys.executable, str(self.SEARCH_SCRIPT), "demo"], {"PATH": tmpdir})

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["results"], [])
        self.assertIn("yt-dlp", payload["error"])

    def test_info_normalizes_direct_youtube_url_metadata(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "print(json.dumps({\n"
                "  'id': 'url123',\n"
                "  'title': 'Direct URL Title',\n"
                "  'uploader': 'Direct Artist',\n"
                "  'duration': 215,\n"
                "  'webpage_url': 'https://www.youtube.com/watch?v=url123'\n"
                "}))\n",
            )
            result = run(
                [sys.executable, str(self.INFO_SCRIPT), "https://youtu.be/url123"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--dump-single-json", argv)
        self.assertIn("--no-playlist", argv)
        self.assertIn("https://youtu.be/url123", argv)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["error"], "")
        item = payload["track"]
        self.assertEqual(item["id"], "url123")
        self.assertEqual(item["title"], "Direct URL Title")
        self.assertEqual(item["uploader"], "Direct Artist")
        self.assertEqual(item["durationText"], "3:35")
        self.assertEqual(item["thumbnail"], "https://i.ytimg.com/vi/url123/hqdefault.jpg")
        self.assertEqual(item["url"], "https://www.youtube.com/watch?v=url123")
        self.assertEqual(item["source"], "YouTube")

    def test_refresh_favorites_repairs_placeholder_youtube_titles(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            state_file = tmp / "media-player.json"
            state_file.write_text(json.dumps({
                "version": 3,
                "favorites": [{
                    "id": "url123",
                    "provider": "youtube",
                    "mediaType": "video",
                    "streamKind": "video",
                    "title": "YouTube video url123",
                    "uploader": "",
                    "duration": "",
                    "thumbnail": "old.jpg",
                    "source": "YouTube",
                    "url": "https://www.youtube.com/watch?v=url123",
                }, {
                    "id": "keep",
                    "provider": "youtube",
                    "title": "Already Real",
                    "url": "https://www.youtube.com/watch?v=keep",
                }],
            }), encoding="utf-8")
            info_script = tmp / "media-player-info"
            write_exec(
                info_script,
                "#!/usr/bin/env python3\n"
                "import json\n"
                "print(json.dumps({'track': {\n"
                "  'id': 'url123',\n"
                "  'title': 'Resolved Favorite Title',\n"
                "  'uploader': 'Resolved Artist',\n"
                "  'durationText': '3:35',\n"
                "  'thumbnail': 'new.jpg',\n"
                "  'source': 'YouTube',\n"
                "  'url': 'https://www.youtube.com/watch?v=url123'\n"
                "}, 'error': ''}))\n",
            )

            result = run([
                sys.executable,
                str(self.REFRESH_FAVORITES_SCRIPT),
                str(state_file),
                str(info_script),
            ], {})
            state = json.loads(state_file.read_text(encoding="utf-8"))

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["checked"], 1)
        self.assertEqual(payload["changed"], 1)
        self.assertEqual(state["favorites"][0]["title"], "Resolved Favorite Title")
        self.assertEqual(state["favorites"][0]["uploader"], "Resolved Artist")
        self.assertEqual(state["favorites"][0]["duration"], "3:35")
        self.assertEqual(state["favorites"][0]["thumbnail"], "new.jpg")
        self.assertEqual(state["favorites"][1]["title"], "Already Real")

    def test_jellyfin_search_normalizes_playable_media(self):
        module = load_script(self.JELLYFIN_SEARCH_SCRIPT, "youtube_music_jellyfin_search_test")
        seen = {}

        def fake_request_json(url, api_key):
            seen["url"] = url
            seen["api_key"] = api_key
            return {
                "Items": [{
                    "Id": "audio-1",
                    "Type": "Audio",
                    "MediaType": "Audio",
                    "Name": "Jelly Song",
                    "Artists": ["Jelly Artist"],
                    "RunTimeTicks": 1850000000,
                    "ImageTags": {"Primary": "tag"},
                }, {
                    "Id": "movie-1",
                    "Type": "Movie",
                    "MediaType": "Video",
                    "Name": "Jelly Movie",
                    "ProductionYear": 2026,
                    "RunTimeTicks": 72000000000,
                    "ImageTags": {"Primary": "tag"},
                }]
            }

        module.request_json = fake_request_json
        config = json.dumps({
            "enabled": True,
            "serverUrl": "https://jellyfin.example/base/",
            "apiKey": "secret-token",
            "userId": "user-1",
        })
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            code = module.main(["--config-json", config, "--limit", "5", "jelly"])

        self.assertEqual(code, 0)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(payload["error"], "")
        self.assertTrue(seen["url"].startswith("https://jellyfin.example/base/Users/user-1/Items?"))
        self.assertIn("SearchTerm=jelly", seen["url"])
        self.assertIn("IncludeItemTypes=Movie%2CEpisode%2CMusicVideo%2CVideo", seen["url"])
        self.assertEqual(seen["api_key"], "secret-token")
        self.assertEqual([item["provider"] for item in payload["results"]], ["jellyfin"])
        self.assertEqual(payload["results"][0]["mediaType"], "video")
        self.assertEqual(payload["results"][0]["streamKind"], "video")
        self.assertEqual(payload["results"][0]["url"], "jellyfin://item/movie-1")
        self.assertNotIn("secret-token", json.dumps(payload))

    def test_jellyfin_search_promotes_exact_movie_titles(self):
        module = load_script(self.JELLYFIN_SEARCH_SCRIPT, "youtube_music_jellyfin_rank_test")

        def fake_request_json(_url, _api_key):
            return {
                "Items": [
                    {"Id": "clip-1", "Type": "Video", "Name": "Matrix Revolutions Disc 2 title 05"},
                    {"Id": "movie-1", "Type": "Movie", "Name": "The Matrix"},
                    {"Id": "movie-2", "Type": "Movie", "Name": "The Matrix Revolutions"},
                ]
            }

        module.request_json = fake_request_json
        config = json.dumps({
            "enabled": True,
            "serverUrl": "https://jellyfin.example",
            "apiKey": "secret-token",
        })
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            code = module.main(["--config-json", config, "matrix"])

        self.assertEqual(code, 0)
        payload = json.loads(stdout.getvalue())
        self.assertEqual([item["title"] for item in payload["results"]], [
            "The Matrix",
            "The Matrix Revolutions",
            "Matrix Revolutions Disc 2 title 05",
        ])

    def test_jellyfin_search_missing_config_is_nonfatal(self):
        result = run([
            sys.executable,
            str(self.JELLYFIN_SEARCH_SCRIPT),
            "--config-json",
            '{"enabled": true}',
            "demo",
        ], {})

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["results"], [])
        self.assertIn("Jellyfin", payload["error"])

    def test_jellyfin_stream_resolver_returns_direct_urls(self):
        config = json.dumps({
            "enabled": True,
            "serverUrl": "https://jellyfin.example/base/",
            "apiKey": "secret-token",
        })
        result = run([
            sys.executable,
            str(self.JELLYFIN_STREAM_SCRIPT),
            "--config-json",
            config,
            "--item-id",
            "movie 1",
            "--media-type",
            "video",
        ], {})

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["error"], "")
        self.assertEqual(payload["mediaType"], "video")
        self.assertEqual(payload["url"], "https://jellyfin.example/base/Items/movie%201/Download?api_key=secret-token")
        self.assertEqual(payload["thumbnail"], "https://jellyfin.example/base/Items/movie%201/Images/Primary?fillWidth=420&quality=90&api_key=secret-token")

    def test_jellyfin_scripts_load_credentials_from_settings_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            settings = Path(tmpdir) / "settings.json"
            settings.write_text(json.dumps({
                "mediaProviders": {
                    "jellyfin": {
                        "enabled": True,
                        "serverUrl": "https://jellyfin.example",
                        "apiKey": "secret-token",
                    }
                }
            }), encoding="utf-8")
            result = run([
                sys.executable,
                str(self.JELLYFIN_STREAM_SCRIPT),
                "--settings-file",
                str(settings),
                "--item-id",
                "movie-1",
            ], {})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("api_key=secret-token", json.loads(result.stdout)["url"])

    def test_cleanup_does_not_signal_unverified_pid(self):
        module = load_script(self.CONTROL_SCRIPT, "media_player_control_cleanup_test")
        killed = []
        with tempfile.TemporaryDirectory() as tmpdir:
            socket_path = str(Path(tmpdir) / "mpv.sock")
            Path(module.pid_path(socket_path)).write_text("4242", encoding="utf-8")
            module.pid_matches_player = lambda pid, path: False
            module.os.kill = lambda pid, signal: killed.append((pid, signal))
            module.cleanup_socket(socket_path)

        self.assertEqual(killed, [])

    def test_preview_prefers_direct_mp4_format(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "print('https://video.example/preview.mp4')\n",
            )
            result = run(
                [sys.executable, str(self.PREVIEW_SCRIPT), "https://www.youtube.com/watch?v=abc123"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--extractor-args", argv)
        self.assertIn("youtube:player_client=web_embedded", argv)
        self.assertIn("18/best[ext=mp4][vcodec!=none][acodec!=none]", " ".join(argv))
        payload = json.loads(result.stdout)
        self.assertEqual(payload["url"], "https://video.example/preview.mp4")
        self.assertEqual(payload["error"], "")

    def test_preview_retries_without_embedded_client_on_failure(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"calls = pathlib.Path({str(tmp / 'calls.jsonl')!r})\n"
                "calls.write_text(calls.read_text() + json.dumps(sys.argv) + '\\n' if calls.exists() else json.dumps(sys.argv) + '\\n')\n"
                "if any('player_client=web_embedded' in arg for arg in sys.argv):\n"
                "    print('embedded rejected', file=sys.stderr)\n"
                "    raise SystemExit(1)\n"
                "print('https://video.example/fallback.mp4')\n",
            )
            result = run(
                [sys.executable, str(self.PREVIEW_SCRIPT), "https://www.youtube.com/watch?v=abc123"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            calls = [json.loads(line) for line in (tmp / "calls.jsonl").read_text().splitlines()]

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 2)
        self.assertTrue(any("player_client=web_embedded" in " ".join(call) for call in calls[:1]))
        self.assertFalse(any("player_client=web_embedded" in arg for arg in calls[1]))
        self.assertEqual(json.loads(result.stdout)["url"], "https://video.example/fallback.mp4")

    def test_background_resolver_uses_youtube_embedded_client(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(tmp / 'argv.json')!r}).write_text(json.dumps(sys.argv))\n"
                "print('https://video.example/background.mp4')\n",
            )
            result = run(
                [sys.executable, str(ROOT / "lacuna.media-player" / "scripts" / "media-player-background"), "https://www.youtube.com/watch?v=abc123"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--extractor-args", argv)
        self.assertIn("youtube:player_client=web_embedded", argv)
        self.assertIn("18/best[ext=mp4][vcodec!=none][acodec!=none]", " ".join(argv))
        payload = json.loads(result.stdout)
        self.assertEqual(payload["url"], "https://video.example/background.mp4")
        self.assertEqual(payload["error"], "")

    def test_background_resolver_retries_without_embedded_client_on_failure(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                "#!/usr/bin/env python3\n"
                "import json, pathlib, sys\n"
                f"calls = pathlib.Path({str(tmp / 'calls.jsonl')!r})\n"
                "calls.write_text(calls.read_text() + json.dumps(sys.argv) + '\\n' if calls.exists() else json.dumps(sys.argv) + '\\n')\n"
                "if any('player_client=web_embedded' in arg for arg in sys.argv):\n"
                "    print('embedded rejected', file=sys.stderr)\n"
                "    raise SystemExit(1)\n"
                "print('https://video.example/background-fallback.mp4')\n",
            )
            result = run(
                [sys.executable, str(ROOT / "lacuna.media-player" / "scripts" / "media-player-background"), "https://www.youtube.com/watch?v=abc123"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            calls = [json.loads(line) for line in (tmp / "calls.jsonl").read_text().splitlines()]

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 2)
        self.assertTrue(any("player_client=web_embedded" in " ".join(call) for call in calls[:1]))
        self.assertFalse(any("player_client=web_embedded" in arg for arg in calls[1]))
        self.assertEqual(json.loads(result.stdout)["url"], "https://video.example/background-fallback.mp4")

    def test_control_command_reports_missing_socket_without_crashing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            socket_path = str(Path(tmpdir) / "missing.sock")
            result = run(
                [
                    sys.executable,
                    str(self.CONTROL_SCRIPT),
                    "command",
                    "--socket",
                    socket_path,
                    "--payload",
                    '{"command":["cycle","pause"]}',
                ],
                {},
            )

        self.assertEqual(result.returncode, 1)
        payload = json.loads(result.stdout)
        self.assertIs(payload["ok"], False)
        self.assertIn("error", payload)

    def test_control_start_uses_audio_cache_flags(self):
        text = self.CONTROL_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('YOUTUBE_PLAYER_CLIENT = "web_embedded"', text)
        self.assertIn("extractor-args=youtube:player_client={YOUTUBE_PLAYER_CLIENT}", text)
        self.assertIn("--ytdl-format=18/best[height<=360][ext=mp4]/bestaudio[ext=m4a]/best", text)
        self.assertIn("--keep-open=yes", text)
        self.assertIn("--cache=yes", text)
        self.assertIn("--cache-pause-initial=yes", text)
        self.assertIn("--cache-pause-wait=10", text)
        self.assertIn("--cache-secs=300", text)
        self.assertIn("--demuxer-readahead-secs=180", text)
        self.assertIn("--demuxer-max-bytes=512MiB", text)
        self.assertIn("--audio-buffer=1", text)
        self.assertIn("--volume={args.volume}", text)
        self.assertIn("mpv.pid", text)
        self.assertIn('sub.add_parser("cleanup")', text)

    def test_control_probe_reports_dead_player(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            socket_path = str(Path(tmpdir) / "missing.sock")
            result = run(
                [sys.executable, str(self.CONTROL_SCRIPT), "probe", "--socket", socket_path],
                {},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertIs(payload["ok"], False)
        self.assertIs(payload["running"], False)
        self.assertIs(payload["eofReached"], False)
        self.assertIsNone(payload["timePos"])
        self.assertIsNone(payload["duration"])

    def test_control_probe_reads_eof_state_and_skips_ipc_events(self):
        import socket as socket_module
        import threading

        properties = {
            "eof-reached": True,
            "idle-active": False,
            "pause": True,
            "time-pos": 187.2,
            "duration": 190.0,
        }

        def serve(server):
            connection, _addr = server.accept()
            with connection:
                # mpv broadcasts event lines to every IPC client; the probe
                # must skip them and match replies by request_id.
                connection.sendall(b'{"event":"file-loaded"}\n')
                buffer = b""
                handled = 0
                while handled < len(properties):
                    chunk = connection.recv(4096)
                    if not chunk:
                        break
                    buffer += chunk
                    while b"\n" in buffer:
                        line, buffer = buffer.split(b"\n", 1)
                        if not line.strip():
                            continue
                        message = json.loads(line)
                        reply = {
                            "error": "success",
                            "data": properties[message["command"][1]],
                            "request_id": message["request_id"],
                        }
                        connection.sendall(b'{"event":"property-change"}\n')
                        connection.sendall((json.dumps(reply) + "\n").encode("utf-8"))
                        handled += 1

        with tempfile.TemporaryDirectory() as tmpdir:
            socket_path = str(Path(tmpdir) / "mpv.sock")
            (Path(tmpdir) / "mpv.pid").write_text(str(os.getpid()), encoding="utf-8")
            server = socket_module.socket(socket_module.AF_UNIX, socket_module.SOCK_STREAM)
            server.bind(socket_path)
            server.listen(1)
            thread = threading.Thread(target=serve, args=(server,), daemon=True)
            thread.start()
            try:
                result = run(
                    [sys.executable, str(self.CONTROL_SCRIPT), "probe", "--socket", socket_path],
                    {},
                )
            finally:
                server.close()
                thread.join(timeout=5)

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertIs(payload["ok"], True)
        self.assertIs(payload["running"], True)
        self.assertIs(payload["eofReached"], True)
        self.assertIs(payload["idleActive"], False)
        self.assertIs(payload["paused"], True)
        self.assertEqual(payload["timePos"], 187.2)
        self.assertEqual(payload["duration"], 190.0)


if __name__ == "__main__":
    unittest.main()
