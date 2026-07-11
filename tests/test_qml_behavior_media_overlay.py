import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


ROOT = Path(__file__).resolve().parents[1]


def read_overlay() -> str:
    return (ROOT / "lacuna.media-player-video/Overlay.qml").read_text(encoding="utf-8")


class MediaOverlayContractTests(unittest.TestCase):
    def test_presentation_handoff_keeps_background_during_transition_states(self):
        overlay = read_overlay()

        self.assertIn('presentationState === "promoting"', overlay)
        self.assertIn('presentationState === "demoting"', overlay)
        self.assertIn('presentationState === "recovering"', overlay)
        self.assertIn('if (presentationState === "inline" && service && service.desiredBackgroundVideo !== undefined)', overlay)
        self.assertIn('if (presentationState === "inline") return false', overlay)
        self.assertIn('service.reportVideoReady("background", playbackSessionRevision, surfacePosition)', overlay)
        self.assertIn('service.reportVideoFailure("background", playbackSessionRevision, normalizedReason)', overlay)

    def test_transition_timing_and_source_swap_are_bounded(self):
        overlay = read_overlay()

        for timing in [
            "normalFadeCoverRiseDuration: 300",
            "normalSourceHoldDuration: 150",
            "normalFadeInDuration: 750",
            "normalExitFadeToBlackDuration: 350",
            "normalExitFadeFromBlackDuration: 600",
            "reducedMotionDuration: 75",
            "handoffTimeoutDuration: 5000",
        ]:
            self.assertIn(timing, overlay)
        self.assertIn("activeSource = videoSource", overlay)
        self.assertIn("root.finishGiveUpWallpaper()", overlay)
        self.assertIn("visible: true", overlay)
        self.assertIn("readonly property bool renderable: targetMatched && root.wallpaperLayerVisible", overlay)

    def test_adaptive_fallback_and_drift_policy_are_explicit(self):
        overlay = read_overlay()

        self.assertIn("adaptiveReadinessTimeoutDuration: 4000", overlay)
        self.assertIn('switchToProgressive("adaptive-readiness-timeout")', overlay)
        self.assertIn('switchToProgressive("adaptive-error")', overlay)
        self.assertIn('switchToProgressive("adaptive-seek-correction")', overlay)
        self.assertIn("if (absoluteDrift < 400)", overlay)
        self.assertIn("if (absoluteDrift <= 1500)", overlay)
        self.assertIn("player.playbackRate = drift > 0 ? 1.03 : 0.97", overlay)
        self.assertIn("var hardSeekAllowed = force || now - lastHardSeekAt >= hardSeekCooldownDuration", overlay)
        self.assertIn("if (!hardSeekAllowed) continue", overlay)
        self.assertIn("if (hardSeekFailureCount < 2) return", overlay)
        self.assertIn('if (activeCandidateKind === "adaptive" && usingProgressiveFallback) return', overlay)
        self.assertIn("failureWatchdog.stop()", overlay)
        self.assertIn("waitingForPlayerReady = false", overlay)
        self.assertIn("if (!root.wallpaperDesired || root.exitTransitionActive) return", overlay)


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class MediaOverlayRuntimeTests(unittest.TestCase):
    def test_optional_v1_service_contract_and_legacy_fallback_coexist(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var overlay: null
  property string retainedDuringResolve: ""

  QtObject {{
    id: mediaService
    property string presentationMode: "auto"
    property string presentationState: "inline"
    property bool desiredBackgroundVideo: false
    property string videoQuality: "adaptive"
    property string adaptiveBackgroundStreamUrl: ""
    property string progressiveBackgroundStreamUrl: ""
    property string backgroundStreamUrl: ""
    property bool backgroundVideoEnabled: false
    property int backgroundRequestRevision: 3
    property int playbackSessionRevision: 7
    property bool backgroundResolveFailed: false
    property bool resolvingBackground: false
    property bool playing: true
    property bool paused: false
    property real playbackPosition: 12
    property string previewStreamUrl: ""
    property string currentTrackUrl: "https://example.test/watch"
    property var lacunaSettings: ({{ reduceMotion: true }})
    property int failureReports: 0
    property string failureReason: ""
    function reportVideoReady(surface, revision, position) {{}}
    function reportVideoFailure(surface, revision, reason) {{
      failureReports += 1
      failureReason = reason
    }}
    function updatePlaybackPosition() {{}}
    function refreshBackgroundStream() {{}}
  }}

  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('lacuna.media-player-video/Overlay.qml')}", Component.PreferSynchronous)
    if (c.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + c.errorString())
      Qt.quit()
      return
    }}
    overlay = c.createObject(root, {{
      service: mediaService,
      manifest: {{ defaults: {{ targetOutput: "__test_no_output__" }} }}
    }})
    overlay.activeSource = "https://example.test/previous.mp4"
    mediaService.presentationState = "promoting"
    mediaService.desiredBackgroundVideo = true
    root.retainedDuringResolve = overlay.activeSource
    mediaService.progressiveBackgroundStreamUrl = "https://example.test/video-360.mp4"
    mediaService.adaptiveBackgroundStreamUrl = "https://example.test/video-720.m3u8"
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 20
    onTriggered: {{
      var adaptive = overlay.preferredVideoSource
      overlay.activeCandidateKind = "adaptive"
      overlay.switchToProgressive("runtime-test")
      overlay.notePlayerError("duplicate-adaptive-error")
      var duplicateErrorSuppressed = mediaService.failureReports === 1
      overlay.waitingForPlayerReady = true
      mediaService.presentationState = "demoting"
      mediaService.desiredBackgroundVideo = false
      var heldDuringDemotion = overlay.desiredBackgroundVideo
      overlay.beginWallpaperExit()
      overlay.notePlayerError("exit-error")
      var exitFailureSuppressed = mediaService.failureReports === 1
      var exitReadinessCleared = !overlay.waitingForPlayerReady
      mediaService.presentationState = "inline"
      console.log("BEHAVE " + JSON.stringify({{
        adaptive: adaptive,
        fallback: overlay.preferredVideoSource,
        retainedDuringResolve: root.retainedDuringResolve,
        heldDuringDemotion: heldDuringDemotion,
        inlineDesired: overlay.desiredBackgroundVideo,
        fadeCoverRiseDuration: overlay.fadeCoverRiseDuration,
        fadeInDuration: overlay.fadeInDuration,
        failureReports: mediaService.failureReports,
        failureReason: mediaService.failureReason,
        duplicateErrorSuppressed: duplicateErrorSuppressed,
        exitFailureSuppressed: exitFailureSuppressed,
        exitReadinessCleared: exitReadinessCleared
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        final = parse_behave(output)[-1]
        self.assertEqual(final["adaptive"], "https://example.test/video-720.m3u8")
        self.assertEqual(final["fallback"], "https://example.test/video-360.mp4")
        self.assertEqual(final["retainedDuringResolve"], "https://example.test/previous.mp4")
        self.assertTrue(final["heldDuringDemotion"])
        self.assertFalse(final["inlineDesired"])
        self.assertEqual(final["fadeCoverRiseDuration"], 75)
        self.assertEqual(final["fadeInDuration"], 75)
        self.assertEqual(final["failureReports"], 1)
        self.assertEqual(final["failureReason"], "runtime-test")
        self.assertTrue(final["duplicateErrorSuppressed"])
        self.assertTrue(final["exitFailureSuppressed"])
        self.assertTrue(final["exitReadinessCleared"])


if __name__ == "__main__":
    unittest.main()
