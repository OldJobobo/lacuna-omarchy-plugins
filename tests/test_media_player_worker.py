"""Behavior tests for the persistent Lacuna media backend worker."""

import json
import importlib.machinery
import importlib.util
import os
import select
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import urllib.parse
import unittest
from unittest import mock
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / "lacuna.media-player" / "scripts" / "media-player-worker"
SEARCH = ROOT / "lacuna.media-player" / "scripts" / "media-player-search"


def write_exec(path: Path, body: str) -> None:
    path.write_text(body, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


class WorkerProcess:
    def __init__(self, tmp: Path, *, path: str | None = None, script_dir: Path | None = None) -> None:
        runtime = tmp / "runtime"
        runtime.mkdir(mode=0o700)
        command = [
            sys.executable,
            str(WORKER),
            "--runtime-dir",
            str(runtime),
            "--socket",
            str(runtime / "mpv.sock"),
        ]
        if script_dir:
            command.extend(["--script-dir", str(script_dir)])
        env = dict(os.environ)
        if path is not None:
            env["PATH"] = path
        self.process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            env=env,
        )
        self.events = []
        self.wait_for(lambda event: event.get("type") == "ready")

    def send(self, payload) -> None:
        assert self.process.stdin is not None
        wire = payload if isinstance(payload, str) else json.dumps(payload)
        self.process.stdin.write(wire + "\n")
        self.process.stdin.flush()

    def read_one(self, timeout: float = 1.0):
        assert self.process.stdout is not None
        ready, _, _ = select.select([self.process.stdout], [], [], timeout)
        if not ready:
            return None
        line = self.process.stdout.readline()
        if not line:
            return None
        event = json.loads(line)
        self.events.append(event)
        return event

    def wait_for(self, predicate, timeout: float = 4.0):
        deadline = time.monotonic() + timeout
        for event in self.events:
            if predicate(event):
                return event
        while time.monotonic() < deadline:
            event = self.read_one(min(0.2, deadline - time.monotonic()))
            if event is not None and predicate(event):
                return event
        stderr = self.process.stderr.read() if self.process.poll() is not None and self.process.stderr else ""
        self.fail(f"worker event timed out; events={self.events!r}; stderr={stderr!r}")

    def collect(self, duration: float) -> list[dict]:
        deadline = time.monotonic() + duration
        found = []
        while time.monotonic() < deadline:
            event = self.read_one(min(0.1, deadline - time.monotonic()))
            if event is not None:
                found.append(event)
        return found

    def fail(self, message: str):
        raise AssertionError(message)

    def close(self) -> None:
        if self.process.poll() is not None:
            return
        try:
            self.send({"type": "shutdown"})
            self.wait_for(lambda event: event.get("type") == "shutdown", timeout=1.0)
        except (AssertionError, BrokenPipeError, OSError):
            pass
        try:
            self.process.wait(timeout=2.0)
        except subprocess.TimeoutExpired:
            self.process.terminate()
            self.process.wait(timeout=2.0)


class MediaPlayerWorkerTests(unittest.TestCase):
    def test_jellyfin_video_candidates_include_required_media_source_id(self):
        loader = importlib.machinery.SourceFileLoader("lacuna_media_worker_jellyfin_test", str(WORKER))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        self.assertIsNotNone(spec)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)

        class WorkerProbe:
            def settings(self):
                return {
                    "mediaProviders": {
                        "jellyfin": {
                            "enabled": True,
                            "serverUrl": "https://jellyfin.example/base/",
                            "apiKey": "test-token",
                            "preferredAudioLanguage": "Default",
                        }
                    }
                }

        candidates = module.MediaWorker._resolve_jellyfin(WorkerProbe(), {
            "provider": "jellyfin",
            "providerId": "movie-source-id",
            "mediaType": "video",
        })
        parsed = urllib.parse.urlparse(candidates["adaptiveUrl"])
        query = urllib.parse.parse_qs(parsed.query)

        self.assertEqual(parsed.path, "/base/Videos/movie-source-id/master.m3u8")
        self.assertEqual(query["mediaSourceId"], ["movie-source-id"])
        self.assertEqual(query["VideoCodec"], ["h264"])

    def test_jellyfin_audio_language_selects_matching_stream(self):
        loader = importlib.machinery.SourceFileLoader("lacuna_media_worker_audio_test", str(WORKER))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        self.assertIsNotNone(spec)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)

        class WorkerProbe:
            def settings(self):
                return {
                    "mediaProviders": {
                        "jellyfin": {
                            "enabled": True,
                            "serverUrl": "https://jellyfin.example/base/",
                            "apiKey": "test-token",
                            "preferredAudioLanguage": "English",
                        }
                    }
                }

        class FakeResponse:
            def __enter__(self):
                return self

            def __exit__(self, *_args):
                return False

            def read(self):
                return json.dumps({
                    "Items": [{
                        "MediaSources": [{
                            "Id": "movie-source-id",
                            "MediaStreams": [
                                {"Type": "Audio", "Index": 1, "Language": "jpn", "IsDefault": True},
                                {"Type": "Audio", "Index": 2, "Language": "eng", "IsDefault": False},
                            ],
                        }]
                    }]
                }).encode()

        with mock.patch.object(module.urllib.request, "urlopen", return_value=FakeResponse()):
            candidates = module.MediaWorker._resolve_jellyfin(WorkerProbe(), {
                "provider": "jellyfin",
                "providerId": "movie-source-id",
                "mediaType": "video",
            })

        parsed = urllib.parse.urlparse(candidates["adaptiveUrl"])
        query = urllib.parse.parse_qs(parsed.query)
        progressive = urllib.parse.urlparse(candidates["progressiveUrl"])
        progressive_query = urllib.parse.parse_qs(progressive.query)
        self.assertEqual(candidates["audioStreamIndex"], 2)
        self.assertEqual(query["AudioStreamIndex"], ["2"])
        self.assertEqual(progressive.path, "/base/Videos/movie-source-id/stream")
        self.assertEqual(progressive_query["AudioStreamIndex"], ["2"])

    def test_new_playback_revision_clears_prior_eof_state(self):
        loader = importlib.machinery.SourceFileLoader("lacuna_media_worker_test", str(WORKER))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        self.assertIsNotNone(spec)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        connection = module.MpvConnection("/tmp/unused-lacuna-test.sock", lambda _event: None)
        connection._state["eof-reached"] = True
        connection._state["idle-active"] = True
        connection._state["duration"] = 120.0

        connection.prepare_playback(8, 4.5)

        connection._handle_line(json.dumps({
            "event": "property-change", "name": "eof-reached", "data": True
        }).encode())
        connection._handle_line(json.dumps({"event": "end-file", "reason": "eof"}).encode())

        self.assertEqual(connection.revision, 8)
        self.assertFalse(connection._state["eof-reached"])
        self.assertFalse(connection._state["idle-active"])
        self.assertIsNone(connection._state["duration"])
        self.assertEqual(connection._state["time-pos"], 4.5)

        connection._handle_line(json.dumps({"event": "start-file"}).encode())
        connection._handle_line(json.dumps({"event": "end-file", "reason": "eof"}).encode())
        self.assertTrue(connection._state["eof-reached"])

    def test_quit_does_not_launch_an_idle_player(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            worker = WorkerProcess(tmp, path=os.environ.get("PATH", ""))
            try:
                worker.send({"type": "command", "requestId": "idle-quit", "command": ["quit"]})
                result = worker.wait_for(
                    lambda event: event.get("type") == "command-result"
                    and event.get("requestId") == "idle-quit"
                )
            finally:
                worker.close()

            self.assertTrue(result["ok"])
            self.assertFalse((tmp / "runtime" / "mpv.pid").exists())

    def test_protocol_errors_are_nonfatal_and_shutdown_is_clean(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            worker = WorkerProcess(Path(tmpdir), path=os.environ.get("PATH", ""))
            try:
                worker.send("not-json")
                malformed = worker.wait_for(
                    lambda event: event.get("type") == "error" and event.get("scope") == "protocol"
                )
                self.assertIn("Malformed JSON", malformed["error"])

                worker.send({"wat": True})
                missing = worker.wait_for(
                    lambda event: event.get("type") == "error"
                    and "missing a type" in event.get("error", "")
                )
                self.assertNotIn("not-json", missing["error"])
            finally:
                worker.close()
            self.assertEqual(worker.process.returncode, 0)

    def test_search_emits_provider_results_as_each_provider_finishes(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            scripts = tmp / "scripts"
            bin_dir.mkdir()
            scripts.mkdir()
            shutil.copy2(SEARCH, scripts / "media-player-search")
            youtube_argv = tmp / "youtube-argv.json"
            jellyfin_argv = tmp / "jellyfin-argv.json"
            secret = "jellyfin-super-secret"
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import json, pathlib, sys, time\n"
                f"pathlib.Path({str(youtube_argv)!r}).write_text(json.dumps(sys.argv))\n"
                "time.sleep(0.25)\n"
                "print(json.dumps({'id':'reaction','title':'Demo reaction review','duration':720}))\n"
                "print(json.dumps({'id':'yt-1','title':'Demo Official Audio','uploader':'Artist - Topic','duration':120}))\n",
            )
            write_exec(
                scripts / "jellyfin-search",
                f"#!{sys.executable}\n"
                "import json, pathlib, sys\n"
                f"pathlib.Path({str(jellyfin_argv)!r}).write_text(json.dumps(sys.argv))\n"
                f"print(json.dumps({{'results':[{{'id':'jf-1','provider':'jellyfin','title':'Jellyfin Result'}}],'error':'provider rejected api_key={secret}'}}))\n",
            )
            settings = tmp / "settings.json"
            settings.write_text(
                json.dumps({
                    "mediaProviders": {
                        "youtube": {"enabled": True, "cookiesFile": str(tmp / "cookies.txt")},
                        "jellyfin": {
                            "enabled": True,
                            "serverUrl": "https://jellyfin.example",
                            "apiKey": secret,
                            "preferredAudioLanguage": "Default",
                        },
                    }
                }),
                encoding="utf-8",
            )
            path = f"{bin_dir}:{os.environ.get('PATH', '')}"
            worker = WorkerProcess(tmp, path=path, script_dir=scripts)
            try:
                worker.send({"type": "configure", "settingsFile": str(settings)})
                worker.wait_for(lambda event: event.get("type") == "configured")
                worker.send({
                    "type": "search",
                    "requestId": 41,
                    "query": "demo",
                    "limit": 18,
                    "providerFilter": "all",
                    "filter": "music",
                })
                first = worker.wait_for(
                    lambda event: event.get("type") == "provider-results" and event.get("requestId") == 41
                )
                second = worker.wait_for(
                    lambda event: event.get("type") == "provider-results"
                    and event.get("requestId") == 41
                    and event.get("provider") != first.get("provider")
                )
            finally:
                worker.close()

            self.assertEqual(first["provider"], "jellyfin")
            self.assertEqual(first["results"][0]["id"], "jf-1")
            self.assertNotIn(secret, json.dumps(first))
            self.assertIn("[redacted]", first["error"])
            self.assertEqual(second["provider"], "youtube")
            self.assertEqual(second["results"][0]["id"], "reaction")
            self.assertNotIn(secret, youtube_argv.read_text(encoding="utf-8"))
            self.assertNotIn(secret, jellyfin_argv.read_text(encoding="utf-8"))
            self.assertIn("--settings-file", jellyfin_argv.read_text(encoding="utf-8"))

    def test_cancel_suppresses_late_provider_results(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import json, time\n"
                "time.sleep(0.45)\n"
                "print(json.dumps({'id':'late','title':'Late Result'}))\n",
            )
            worker = WorkerProcess(tmp, path=f"{bin_dir}:{os.environ.get('PATH', '')}")
            try:
                worker.send({
                    "type": "search",
                    "requestId": "old-search",
                    "query": "slow",
                    "providers": ["youtube"],
                })
                worker.send({"type": "cancel", "requestId": "old-search"})
                cancelled = worker.wait_for(
                    lambda event: event.get("type") == "cancelled" and event.get("requestId") == "old-search"
                )
                later = worker.collect(0.75)
            finally:
                worker.close()

            self.assertTrue(cancelled["active"])
            self.assertFalse(any(
                event.get("type") == "provider-results" and event.get("requestId") == "old-search"
                for event in later
            ))

    def test_shutdown_terminates_active_provider_process_group(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            pid_file = tmp / "provider.pid"
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import json, os, pathlib, time\n"
                f"pathlib.Path({str(pid_file)!r}).write_text(str(os.getpid()))\n"
                "time.sleep(30)\n"
                "print(json.dumps({'id':'late','title':'Late Result'}))\n",
            )
            worker = WorkerProcess(tmp, path=f"{bin_dir}:{os.environ.get('PATH', '')}")
            try:
                worker.send({
                    "type": "search",
                    "requestId": "shutdown-search",
                    "query": "slow",
                    "providers": ["youtube"],
                })
                deadline = time.monotonic() + 2
                while not pid_file.exists() and time.monotonic() < deadline:
                    time.sleep(0.02)
                self.assertTrue(pid_file.exists(), "provider process did not start")
                provider_pid = int(pid_file.read_text(encoding="utf-8"))
                worker.send({"type": "shutdown"})
                worker.wait_for(lambda event: event.get("type") == "shutdown", timeout=2)
                worker.process.wait(timeout=2)
                deadline = time.monotonic() + 2
                while Path(f"/proc/{provider_pid}").exists() and time.monotonic() < deadline:
                    time.sleep(0.02)
                self.assertFalse(Path(f"/proc/{provider_pid}").exists())
            finally:
                worker.close()

    def test_new_search_makes_an_older_request_stale(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import json, sys, time\n"
                "query = sys.argv[-1]\n"
                "if query.endswith(':slow'): time.sleep(0.6)\n"
                "print(json.dumps({'id':query.rsplit(':', 1)[-1],'title':query}))\n",
            )
            worker = WorkerProcess(tmp, path=f"{bin_dir}:{os.environ.get('PATH', '')}")
            try:
                worker.send({
                    "type": "search",
                    "requestId": 1,
                    "query": "slow",
                    "providers": ["youtube"],
                })
                time.sleep(0.05)
                worker.send({
                    "type": "search",
                    "requestId": 2,
                    "query": "fast",
                    "providers": ["youtube"],
                })
                latest = worker.wait_for(
                    lambda event: event.get("type") == "provider-results" and event.get("requestId") == 2
                )
                later = worker.collect(0.7)
            finally:
                worker.close()

            self.assertEqual(latest["results"][0]["id"], "fast")
            self.assertFalse(any(
                event.get("type") == "provider-results" and event.get("requestId") == 1
                for event in worker.events + later
            ))

    def test_resolve_video_returns_adaptive_and_stable_candidates(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            write_exec(
                bin_dir / "yt-dlp",
                f"#!{sys.executable}\n"
                "import json\n"
                "print(json.dumps({'thumbnail':'cover.jpg','formats':[\n"
                " {'format_id':'18','url':'https://video.example/360.mp4','height':360,'ext':'mp4','protocol':'https','vcodec':'h264','acodec':'aac'},\n"
                " {'format_id':'95','url':'https://video.example/720.m3u8','height':720,'ext':'mp4','protocol':'m3u8_native','vcodec':'h264','acodec':'aac'},\n"
                " {'format_id':'96','url':'https://video.example/1080.m3u8','height':1080,'ext':'mp4','protocol':'m3u8_native','vcodec':'h264','acodec':'aac'}\n"
                "]}))\n",
            )
            worker = WorkerProcess(tmp, path=f"{bin_dir}:{os.environ.get('PATH', '')}")
            try:
                worker.send({
                    "type": "resolve-video",
                    "requestId": 7,
                    "revision": 3,
                    "track": {
                        "id": "yt-demo",
                        "provider": "youtube",
                        "url": "https://www.youtube.com/watch?v=yt-demo",
                    },
                })
                result = worker.wait_for(
                    lambda event: event.get("type") == "video-candidates" and event.get("requestId") == 7
                )
            finally:
                worker.close()

            self.assertEqual(result["revision"], 3)
            self.assertEqual(result["adaptiveUrl"], "https://video.example/720.m3u8")
            self.assertEqual(result["progressiveUrl"], "https://video.example/360.mp4")
            self.assertEqual(result["thumbnail"], "cover.jpg")
            self.assertEqual(result["error"], "")

    def test_play_starts_idle_mpv_then_sends_authenticated_url_over_ipc(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            argv_path = tmp / "mpv-argv.json"
            loaded_path = tmp / "loaded-url.txt"
            write_exec(
                bin_dir / "mpv",
                f"#!{sys.executable}\n"
                "import json, pathlib, socket, sys\n"
                f"argv_path = pathlib.Path({str(argv_path)!r})\n"
                f"loaded_path = pathlib.Path({str(loaded_path)!r})\n"
                "argv_path.write_text(json.dumps(sys.argv))\n"
                "socket_path = next(arg.split('=', 1)[1] for arg in sys.argv if arg.startswith('--input-ipc-server='))\n"
                "server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)\n"
                "server.bind(socket_path); server.listen(1)\n"
                "conn, _ = server.accept(); buffer = b''\n"
                "while True:\n"
                "  chunk = conn.recv(65536)\n"
                "  if not chunk: break\n"
                "  buffer += chunk\n"
                "  while b'\\n' in buffer:\n"
                "    raw, buffer = buffer.split(b'\\n', 1)\n"
                "    if not raw: continue\n"
                "    msg = json.loads(raw); cmd = msg.get('command', [])\n"
                "    reply = {'request_id': msg.get('request_id'), 'error':'success'}\n"
                "    conn.sendall((json.dumps(reply) + '\\n').encode())\n"
                "    if cmd and cmd[0] == 'loadfile':\n"
                "      loaded_path.write_text(cmd[1])\n"
                "      events = [\n"
                "       {'event':'property-change','name':'idle-active','data':False},\n"
                "       {'event':'property-change','name':'pause','data':False},\n"
                "       {'event':'property-change','name':'time-pos','data':12.5},\n"
                "       {'event':'property-change','name':'duration','data':120.0}\n"
                "      ]\n"
                "      conn.sendall(('\\n'.join(json.dumps(event) for event in events) + '\\n').encode())\n",
            )
            secret = "ipc-only-secret"
            settings = tmp / "settings.json"
            settings.write_text(json.dumps({
                "mediaProviders": {
                    "jellyfin": {
                        "enabled": True,
                        "serverUrl": "https://jellyfin.example",
                        "apiKey": secret,
                        "preferredAudioLanguage": "Default",
                    }
                }
            }), encoding="utf-8")
            worker = WorkerProcess(tmp, path=f"{bin_dir}:{os.environ.get('PATH', '')}")
            try:
                worker.send({"type": "configure", "settingsFile": str(settings)})
                worker.wait_for(lambda event: event.get("type") == "configured")
                worker.send({
                    "type": "play",
                    "revision": 7,
                    "track": {
                        "provider": "jellyfin",
                        "providerId": "movie 1",
                        "mediaType": "video",
                        "url": "jellyfin://item/movie%201",
                    },
                    "volume": 65,
                    "audioOnly": True,
                })
                played = worker.wait_for(
                    lambda event: event.get("type") == "play-result" and event.get("revision") == 7
                )
                sampled = worker.wait_for(
                    lambda event: event.get("type") == "playback"
                    and event.get("revision") == 7
                    and event.get("position") == 12.5
                )
            finally:
                worker.close()

            self.assertTrue(played["ok"])
            self.assertEqual(sampled["duration"], 120.0)
            argv = argv_path.read_text(encoding="utf-8")
            loaded = loaded_path.read_text(encoding="utf-8")
            self.assertNotIn(secret, argv)
            self.assertNotIn("jellyfin.example", argv)
            self.assertIn("--idle=yes", argv)
            self.assertIn(secret, loaded)
            self.assertIn("/Items/movie%201/Download?", loaded)


if __name__ == "__main__":
    unittest.main()
