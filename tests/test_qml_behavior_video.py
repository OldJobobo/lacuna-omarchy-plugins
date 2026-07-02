import unittest
import tempfile
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class QmlVideoBehaviorContractTests(unittest.TestCase):
    def test_background_video_startup_is_gated_by_black_cover(self):
        overlay = read("lacuna.youtube-music-video/Overlay.qml")

        hold = overlay.index("holdFadeCover(exitFadeToBlackDuration)")
        gate_restart = overlay.index("wallpaperFadeGateTimer.restart()", hold)
        assign = overlay.index("activeSource = videoSource")
        self.assertLess(hold, gate_restart)
        self.assertLess(gate_restart, assign)
        self.assertIn("var remainingFadeCoverRise = fadeCoverRiseRemaining()", overlay)
        self.assertIn("if (remainingFadeCoverRise > 0)", overlay)
        self.assertIn("waitingForPlayerReady = true", overlay)
        self.assertIn("function notePlayerReady()", overlay)
        self.assertIn("releaseFadeCoverSoon()", overlay)

    def test_background_video_exit_clears_source_under_opaque_cover(self):
        overlay = read("lacuna.youtube-music-video/Overlay.qml")

        begin_exit = overlay.index("function beginWallpaperExit()")
        clear_timer = overlay.index("id: exitClearTimer")
        clear = overlay.index("root.clearWallpaperNow()", clear_timer)
        self.assertLess(begin_exit, clear_timer)
        self.assertLess(clear_timer, clear)
        self.assertIn("fadeCoverOpacity = 1", overlay[begin_exit:clear_timer])
        self.assertIn("clearingWallpaperAfterExit = true", overlay[clear_timer : clear + 80])
        self.assertNotIn("onWallpaperDesiredChanged: backgroundPlayer.stop()", overlay)
        self.assertIn('if (root.activeSource === "") backgroundPlayer.stop()', overlay)

    def test_background_video_watchdogs_release_black_cover(self):
        overlay = read("lacuna.youtube-music-video/Overlay.qml")

        self.assertIn("readonly property bool waitingForHighRes", overlay)
        self.assertIn("onBackgroundResolveFailedChanged: if (backgroundResolveFailed) giveUpWallpaper(\"resolve-failed\")", overlay)
        self.assertIn("id: failureWatchdog", overlay)
        self.assertIn(
            'if (root.waitingForHighRes || root.waitingForPlayerReady || root.backgroundResolveFailed) root.giveUpWallpaper("watchdog")',
            overlay,
        )
        give_up = overlay[overlay.index("function giveUpWallpaper(reason)") : overlay.index("function syncWallpaper()")]
        self.assertIn('activeSource = ""', give_up)
        self.assertIn("waitingForPlayerReady = false", give_up)
        self.assertIn("releaseFadeCoverNow()", give_up)

    def test_youtube_music_service_discards_stale_probe_results(self):
        service = read("lacuna.youtube-music/Service.qml")

        self.assertIn("property int playbackSessionRevision: 0", service)
        self.assertIn("positionProc.sessionRevision = playbackSessionRevision", service)
        self.assertIn("positionProc.command = [controlScript, \"probe\", \"--socket\", playbackSocket()]", service)
        self.assertIn("if (positionProc.sessionRevision !== root.playbackSessionRevision) return", service)
        self.assertIn("function handlePlaybackEnded()", service)


def make_youtube_music_source(payload: str, *, probe_sleep: str = "0") -> tuple[tempfile.TemporaryDirectory, Path]:
    temp = tempfile.TemporaryDirectory()
    root = Path(temp.name)
    scripts = root / "scripts"
    scripts.mkdir()

    executable_scripts = {
        "youtube-music-check": '#!/bin/sh\nprintf %s\\n \'{"mpv":true,"ytdlp":true,"message":""}\'\n',
        "youtube-music-control": (
            "#!/bin/sh\n"
            "case \"$1\" in\n"
            "  cleanup|start|command) exit 0 ;;\n"
            f"  probe) sleep {probe_sleep}; printf %s\\\\n '{payload}' ;;\n"
            "  *) exit 0 ;;\n"
            "esac\n"
        ),
        "youtube-music-preview": "#!/bin/sh\nprintf %s\\n '{}'\n",
        "youtube-music-background": "#!/bin/sh\nprintf %s\\n '{}'\n",
        "youtube-music-search": "#!/bin/sh\nprintf %s\\n '{\"results\":[]}'\n",
        "youtube-music-auth": "#!/bin/sh\nprintf %s\\n '{}'\n",
        "youtube-music-info": "#!/bin/sh\nprintf %s\\n '{}'\n",
        "youtube-music-refresh-favorites": "#!/bin/sh\nprintf %s\\n '[]'\n",
        "youtube-music-jellyfin-search": "#!/bin/sh\nprintf %s\\n '{\"results\":[]}'\n",
        "youtube-music-jellyfin-stream": "#!/bin/sh\nprintf %s\\n '{}'\n",
    }
    for name, content in executable_scripts.items():
        path = scripts / name
        path.write_text(content, encoding="utf-8")
        path.chmod(0o755)
    return temp, root


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlYoutubeMusicServiceBehaviorTests(unittest.TestCase):
    def test_stale_probe_result_is_discarded_at_runtime(self):
        source_owner, source = make_youtube_music_source('{"ok":true,"timePos":42,"duration":100}', probe_sleep="0.05")
        with source_owner, tempfile.TemporaryDirectory() as cfg:
            qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var svc: null

  function emitState(label) {{
    console.log("BEHAVE " + JSON.stringify({{
      label: label,
      playbackPosition: svc.playbackPosition,
      playbackDuration: svc.playbackDuration,
      playbackSessionRevision: svc.playbackSessionRevision,
      playbackProbeFailures: svc.playbackProbeFailures
    }}))
  }}

  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('lacuna.youtube-music/Service.qml')}", Component.PreferSynchronous)
    if (c.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + c.errorString())
      Qt.quit()
      return
    }}
    svc = c.createObject(root, {{ manifest: {{ __sourceDir: "{source}" }} }})
    setup.restart()
  }}

  Timer {{
    id: setup
    interval: 60
    repeat: false
    onTriggered: {{
      svc.mpvAvailable = true
      svc.ytdlpAvailable = true
      svc.playing = true
      svc.paused = false
      svc.playbackPosition = 7
      svc.playbackDuration = 0
      svc.playbackSessionRevision = 10
      svc.updatePlaybackPosition()
      svc.playbackSessionRevision = 11
      finish.restart()
    }}
  }}

  Timer {{
    id: finish
    interval: 180
    repeat: false
    onTriggered: {{
      root.emitState("final")
      Qt.quit()
    }}
  }}
}}
"""
            output = run_quickshell(qml, config_home=Path(cfg), timeout=8)
        require_no_qml_errors(output)
        final = parse_behave(output)[-1]
        self.assertEqual(final["playbackPosition"], 7, output[-2000:])
        self.assertEqual(final["playbackDuration"], 0, output[-2000:])
        self.assertEqual(final["playbackSessionRevision"], 11, output[-2000:])

    def test_eof_probe_advances_to_next_queue_track_at_runtime(self):
        source_owner, source = make_youtube_music_source('{"ok":true,"timePos":100,"duration":100,"eofReached":true}')
        with source_owner, tempfile.TemporaryDirectory() as cfg:
            qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var svc: null

  function emitState(label) {{
    console.log("BEHAVE " + JSON.stringify({{
      label: label,
      playing: svc.playing,
      title: svc.currentTrack ? svc.currentTrack.title : "",
      queueLength: svc.queue.length,
      historyLength: svc.history.length,
      playbackPosition: svc.playbackPosition,
      status: svc.status
    }}))
  }}

  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('lacuna.youtube-music/Service.qml')}", Component.PreferSynchronous)
    if (c.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + c.errorString())
      Qt.quit()
      return
    }}
    svc = c.createObject(root, {{ manifest: {{ __sourceDir: "{source}" }} }})
    setup.restart()
  }}

  Timer {{
    id: setup
    interval: 60
    repeat: false
    onTriggered: {{
      svc.mpvAvailable = true
      svc.ytdlpAvailable = true
      svc.currentTrack = {{ title: "First", url: "https://example.test/first" }}
      svc.queue = [{{ title: "Second", url: "https://example.test/second" }}]
      svc.playing = true
      svc.paused = false
      svc.playbackDuration = 100
      svc.playbackPosition = 99
      svc.updatePlaybackPosition()
      finish.restart()
    }}
  }}

  Timer {{
    id: finish
    interval: 180
    repeat: false
    onTriggered: {{
      root.emitState("final")
      Qt.quit()
    }}
  }}
}}
"""
            output = run_quickshell(qml, config_home=Path(cfg), timeout=8)
        require_no_qml_errors(output)
        final = parse_behave(output)[-1]
        self.assertTrue(final["playing"], output[-2000:])
        self.assertEqual(final["title"], "Second", output[-2000:])
        self.assertEqual(final["queueLength"], 0, output[-2000:])
        self.assertEqual(final["historyLength"], 1, output[-2000:])
        self.assertEqual(final["status"], "playing", output[-2000:])


if __name__ == "__main__":
    unittest.main()
