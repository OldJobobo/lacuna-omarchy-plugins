import tempfile
import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell
from test_qml_behavior_video import make_media_player_source


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlMediaPlayerV1ServiceBehaviorTests(unittest.TestCase):
    def test_service_consumes_progressive_worker_events(self):
        source_owner, source = make_media_player_source("{}")
        worker = source / "scripts" / "media-player-worker"
        worker.write_text(
            "#!/usr/bin/env python3\n"
            "import json, sys\n"
            "def emit(value):\n"
            "    print(json.dumps(value), flush=True)\n"
            "emit({'type': 'ready', 'mpv': True, 'ytdlp': True})\n"
            "for raw in sys.stdin:\n"
            "    message = json.loads(raw)\n"
            "    kind = message.get('type')\n"
            "    if kind == 'configure': emit({'type': 'configured'})\n"
            "    elif kind == 'search':\n"
            "        request = message['requestId']\n"
            "        emit({'type': 'provider-results', 'requestId': request, 'provider': 'jellyfin', 'results': [{'provider': 'jellyfin', 'providerId': 'j1', 'title': 'Local', 'url': 'jellyfin://item/j1'}], 'error': ''})\n"
            "        emit({'type': 'provider-results', 'requestId': request, 'provider': 'youtube', 'results': [{'provider': 'youtube', 'id': 'y1', 'title': 'Remote', 'url': 'https://example.test/y1'}], 'error': ''})\n"
            "    elif kind == 'shutdown': break\n",
            encoding="utf-8",
        )
        worker.chmod(0o755)
        with source_owner, tempfile.TemporaryDirectory() as cfg:
            qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var svc: null
  property bool requested: false
  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.media-player/Service.qml')}", Component.PreferSynchronous)
    svc = component.createObject(root, {{ manifest: {{ __sourceDir: "{source}" }} }})
  }}
  Timer {{
    interval: 20
    repeat: true
    running: true
    onTriggered: {{
      if (!svc || !svc.workerReady || !svc.stateLoaded || requested) return
      requested = true
      svc.lacunaSettings = {{ mediaProviders: {{ jellyfin: {{ enabled: true, serverUrl: "https://example.test", apiKey: "secret" }} }} }}
      svc.search("demo")
      finish.start()
    }}
  }}
  Timer {{
    id: finish
    interval: 180
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        workerReady: svc.workerReady,
        workerConfigured: svc.workerConfigured,
        searching: svc.searching,
        titles: svc.allResults.map(function(row) {{ return row.title }}),
        youtubeCount: svc.providerStates.youtube.count,
        jellyfinCount: svc.providerStates.jellyfin.count
      }}))
      Qt.quit()
    }}
  }}
}}
"""
            output = run_quickshell(qml, config_home=Path(cfg), timeout=8)

        require_no_qml_errors(output)
        final = parse_behave(output)[-1]
        self.assertTrue(final["workerReady"])
        self.assertTrue(final["workerConfigured"])
        self.assertFalse(final["searching"])
        self.assertEqual(final["titles"], ["Remote", "Local"])
        self.assertEqual(final["youtubeCount"], 1)
        self.assertEqual(final["jellyfinCount"], 1)

    def test_presentation_handoff_and_smoothed_clock(self):
        source_owner, source = make_media_player_source("{}")
        with source_owner, tempfile.TemporaryDirectory() as cfg:
            qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var svc: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.media-player/Service.qml')}", Component.PreferSynchronous)
    svc = component.createObject(root, {{ manifest: {{ __sourceDir: "{source}" }} }})
    setup.start()
  }}

  Timer {{
    id: setup
    interval: 20
    repeat: true
    onTriggered: {{
      if (!svc || !svc.stateLoaded) return
      stop()
      var track = svc.normalizeTrack({{
        id: "video-one",
        provider: "youtube",
        title: "Video One",
        url: "https://example.test/video-one",
        mediaType: "video"
      }})
      svc.currentTrack = track
      svc.rememberStreamUrl(track, "https://cdn.example.test/video.mp4")
      svc.playbackSessionRevision = 10
      svc.playing = true
      svc.paused = false
      svc.inlineSurfaceAvailable = true
      svc.presentationMode = "auto"
      svc.reconcilePresentationState()
      var inlineState = svc.presentationState

      svc.inlineSurfaceAvailable = false
      svc.reconcilePresentationState()
      var promotingState = svc.presentationState
      svc.reportVideoReady("background", 10, 0)
      var backgroundState = svc.presentationState

      svc.inlineSurfaceAvailable = true
      svc.reconcilePresentationState()
      var demotingState = svc.presentationState
      svc.reportVideoReady("inline", 10, 0)
      var returnedState = svc.presentationState

      svc.handleWorkerPlayback({{ revision: 10, playing: false, paused: true, running: true, position: 12, duration: 120 }})
      var pauseKeepsTrackActive = svc.playing && svc.paused
      svc.paused = false
      svc.playbackSamplePosition = 12
      svc.playbackSampledAtMs = Date.now() - 600
      svc.playbackPosition = 12
      svc.smoothPlaybackClock()
      var smoothedPosition = svc.playbackPosition

      svc.workerPlayRecoveryPending = true
      svc.commandRunning = false
      svc.handleWorkerPlayback({{ revision: 10, playing: false, paused: false, running: true, idleActive: true }})
      var recoveryPreserved = svc.playing && svc.commandRunning && svc.status === "loading"
      svc.workerPlayRecoveryPending = false

      for (var i = 0; i < 30; i++)
        svc.rememberStreamUrl("https://example.test/watch?v=cache" + i, "https://cdn.example.test/stream" + i)
      var boundedStreamCache = Object.keys(svc.streamUrlCache).length

      svc.workerReady = true
      svc.workerConfigured = false
      var unconfiguredResolveRejected = !svc.requestWorkerVideoCandidates(track)
      console.log("BEHAVE " + JSON.stringify({{
        inlineState: inlineState,
        promotingState: promotingState,
        backgroundState: backgroundState,
        demotingState: demotingState,
        returnedState: returnedState,
        backgroundEnabled: svc.backgroundVideoEnabled,
        pauseKeepsTrackActive: pauseKeepsTrackActive,
        smoothedPosition: smoothedPosition,
        recoveryPreserved: recoveryPreserved,
        boundedStreamCache: boundedStreamCache,
        unconfiguredResolveRejected: unconfiguredResolveRejected
      }}))
      Qt.quit()
    }}
  }}
}}
"""
            output = run_quickshell(qml, config_home=Path(cfg), timeout=8)

        require_no_qml_errors(output)
        final = parse_behave(output)[-1]
        self.assertEqual(final["inlineState"], "inline")
        self.assertEqual(final["promotingState"], "promoting")
        self.assertEqual(final["backgroundState"], "background")
        self.assertEqual(final["demotingState"], "demoting")
        self.assertEqual(final["returnedState"], "inline")
        self.assertFalse(final["backgroundEnabled"])
        self.assertTrue(final["pauseKeepsTrackActive"])
        self.assertGreaterEqual(final["smoothedPosition"], 12.5)
        self.assertLess(final["smoothedPosition"], 13.2)
        self.assertTrue(final["recoveryPreserved"])
        self.assertEqual(final["boundedStreamCache"], 24)
        self.assertTrue(final["unconfiguredResolveRejected"])

    def test_v3_state_migrates_to_v4_defaults_without_losing_queue(self):
        source_owner, source = make_media_player_source("{}")
        with source_owner, tempfile.TemporaryDirectory() as cfg:
            qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var svc: null
  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.media-player/Service.qml')}", Component.PreferSynchronous)
    svc = component.createObject(root, {{ manifest: {{ __sourceDir: "{source}" }} }})
    finish.start()
  }}
  Timer {{
    id: finish
    interval: 20
    repeat: true
    onTriggered: {{
      if (!svc || !svc.stateLoaded) return
      stop()
      svc.applyLoadedState(JSON.stringify({{
        version: 3,
        queue: [{{ title: "Queued", url: "https://example.test/queued" }}],
        volume: 42,
        repeatMode: "all"
      }}))
      var payload = JSON.parse(svc.statePayload())
      console.log("BEHAVE " + JSON.stringify({{
        version: payload.version,
        queueLength: payload.queue.length,
        volume: payload.volume,
        repeatMode: payload.repeatMode,
        presentationMode: payload.presentationMode,
        videoQuality: payload.videoQuality,
        providerFilter: payload.providerFilter
      }}))
      Qt.quit()
    }}
  }}
}}
"""
            output = run_quickshell(qml, config_home=Path(cfg), timeout=8)

        require_no_qml_errors(output)
        final = parse_behave(output)[-1]
        self.assertEqual(final["version"], 4)
        self.assertEqual(final["queueLength"], 1)
        self.assertEqual(final["volume"], 42)
        self.assertEqual(final["repeatMode"], "all")
        self.assertEqual(final["presentationMode"], "auto")
        self.assertEqual(final["videoQuality"], "adaptive")
        self.assertEqual(final["providerFilter"], "all")


if __name__ == "__main__":
    unittest.main()
