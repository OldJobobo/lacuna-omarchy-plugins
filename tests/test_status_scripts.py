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
            "5h limit left: 88%\n"
            "5h used: 12%\n"
            "5h resets: 2026-06-18 02:00 PM\n"
            "Weekly limit left: 37%\n"
            "Weekly used: 63%\n"
            "Weekly resets: 2026-06-20 09:00 AM\n"
            "Plan: pro\n"
            "Source event: 2026-06-18T12:34:56Z\n"
            "Source file: /tmp/codex-session.jsonl\n"
            "OUT\n"
        )
        with tempfile.TemporaryDirectory() as tmp:
            staged = self._staged(tmp, helper)
            result = run([str(staged)], {})
        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "88% 5h")
        self.assertEqual(payload["shortText"], "88%")
        self.assertEqual(payload["class"], "normal")
        self.assertEqual(payload["leftPercent"], 88)
        self.assertEqual(payload["usedPercent"], 12)
        self.assertIs(payload["active"], True)
        self.assertEqual(payload["resetText"], "2026-06-18 02:00 PM")
        self.assertIs(payload["weekActive"], True)
        self.assertEqual(payload["weekText"], "37% wk")
        self.assertEqual(payload["weekLeftPercent"], 37)
        self.assertEqual(payload["weekUsedPercent"], 63)
        self.assertEqual(payload["weekResetText"], "2026-06-20 09:00 AM")
        self.assertEqual(payload["planText"], "Pro")
        self.assertEqual(payload["sourceFileText"], "/tmp/codex-session.jsonl")
        self.assertEqual(payload["source"], "local Codex token_count event")
        self.assertIn("Codex Usage", payload["tooltip"])

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


class YoutubeMusicScriptTests(unittest.TestCase):
    CHECK_SCRIPT = ROOT / "lacuna.youtube-music" / "scripts" / "youtube-music-check"
    SEARCH_SCRIPT = ROOT / "lacuna.youtube-music" / "scripts" / "youtube-music-search"
    CONTROL_SCRIPT = ROOT / "lacuna.youtube-music" / "scripts" / "youtube-music-control"
    PREVIEW_SCRIPT = ROOT / "lacuna.youtube-music" / "scripts" / "youtube-music-preview"

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
        self.assertIn("ytsearch40:demo query music", argv)
        item = payload["results"][0]
        self.assertEqual(item["id"], "abc123")
        self.assertEqual(item["title"], "Demo Track")
        self.assertEqual(item["uploader"], "Demo Artist - Topic")
        self.assertEqual(item["durationText"], "2:05")
        self.assertEqual(item["thumbnail"], "https://i.ytimg.com/vi/abc123/hqdefault.jpg")
        self.assertEqual(item["url"], "https://www.youtube.com/watch?v=abc123")

    def test_search_ranks_music_results_above_general_videos(self):
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
                [sys.executable, str(self.SEARCH_SCRIPT), "--limit", "2", "demo track"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["song1"])

    def test_search_keeps_neutral_music_fallbacks(self):
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
                [sys.executable, str(self.SEARCH_SCRIPT), "--limit", "3", "small artist"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["song1", "song2"])

    def test_search_keeps_album_mix_and_live_results(self):
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
                [sys.executable, str(self.SEARCH_SCRIPT), "--limit", "4", "small artist"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual([item["id"] for item in payload["results"]], ["album1", "mix1", "stream1"])

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
                [sys.executable, str(self.SEARCH_SCRIPT), "--limit", "80", "ambient mix"],
                {"PATH": f"{bin_dir}:{os.environ.get('PATH', '')}"},
            )
            argv = json.loads((tmp / "argv.json").read_text())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ytsearch80:ambient mix music", argv)

    def test_search_handles_missing_ytdlp(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            result = run([sys.executable, str(self.SEARCH_SCRIPT), "demo"], {"PATH": tmpdir})

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["results"], [])
        self.assertIn("yt-dlp", payload["error"])

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
        self.assertIn("160/worstvideo[ext=mp4][vcodec!=none]", " ".join(argv))
        payload = json.loads(result.stdout)
        self.assertEqual(payload["url"], "https://video.example/preview.mp4")
        self.assertEqual(payload["error"], "")

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
        self.assertIn("--ytdl-format=18/best[height<=360][ext=mp4]/bestaudio[ext=m4a]/best", text)
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

if __name__ == "__main__":
    unittest.main()
