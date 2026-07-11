import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlMediaUiBehaviorTests(unittest.TestCase):
    def test_flyout_filters_progressive_results_and_changes_presentation(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var flyout: null

  QtObject {{
    id: service
    property bool available: true
    property bool hasTrack: true
    property bool playing: true
    property bool paused: false
    property bool backgroundVideoEnabled: false
    property string displayTitle: "Track"
    property bool youtubeLoginEnabled: false
    property bool currentFavorite: false
    property var currentTrack: ({{ title: "Track" }})
    property var queue: []
    property var favorites: []
    property int favoritesRevision: 0
    property int favoritesLength: 0
    property string repeatMode: "none"
    property string searchFilter: "all"
    property string providerFilter: "all"
    property string presentationMode: "auto"
    property string presentationState: "inline"
    property var providerStates: ({{
      youtube: {{ loading: false, complete: true, error: "", count: 1 }},
      jellyfin: {{ loading: true, complete: false, error: "", count: 1 }}
    }})
    property var results: [
      {{ title: "YouTube result", provider: "youtube", uploader: "Channel", duration: "3:00" }},
      {{ title: "Jellyfin result", provider: "jellyfin", artist: "Artist", duration: "4:00" }}
    ]
    property bool searching: true
    property bool canLoadMore: false
    property string errorText: ""
    property int defaultSuggestionCalls: 0
    property int draftCalls: 0

    function statusText() {{ return "Playing" }}
    function isYoutubeUrl(value) {{ return false }}
    function isFavorite(track) {{ return false }}
    function loadDefaultSuggestions() {{ defaultSuggestionCalls += 1 }}
    function previewSearch(value) {{ draftCalls += 1 }}
    function setVisibleLimit(value) {{}}
    function setProviderFilter(value) {{ providerFilter = value }}
    function setPresentationMode(value) {{ presentationMode = value }}
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/menu/FlyoutMediaPlayerContent.qml')}")
    if (component.status === Component.Error) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    flyout = component.createObject(root, {{
      service: service,
      width: 520,
      height: 480,
      open: true,
      contentVisible: true
    }})
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 50
    repeat: false
    onTriggered: {{
      var initial = root.flyout.visibleSearchResults.length
      root.flyout.setProviderFilter("youtube")
      var filtered = root.flyout.visibleSearchResults.length
      root.flyout.setPresentationMode("background")
      console.log("BEHAVE " + JSON.stringify({{
        initial: initial,
        filtered: filtered,
        providerFilter: service.providerFilter,
        presentationMode: service.presentationMode,
        jellyfinLoading: root.flyout.providerStatus("jellyfin").loading
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        row = parse_behave(output)[0]
        self.assertEqual(row["initial"], 2, output[-2000:])
        self.assertEqual(row["filtered"], 1, output[-2000:])
        self.assertEqual(row["providerFilter"], "youtube", output[-2000:])
        self.assertEqual(row["presentationMode"], "background", output[-2000:])
        self.assertTrue(row["jellyfinLoading"], output[-2000:])

    def test_inline_adaptive_timeout_ignores_hidden_and_paused_renderer(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var tile: null

  QtObject {{
    id: service
    property bool available: true
    property bool hasTrack: true
    property bool playing: true
    property bool paused: false
    property string presentationState: "background"
    property bool backgroundVideoEnabled: true
    property string displayTitle: "Track"
    property string thumbnail: ""
    property string previewStreamUrl: "file:///dev/null?adaptive"
    property string adaptivePreviewStreamUrl: "file:///dev/null?adaptive"
    property string progressivePreviewStreamUrl: "file:///dev/null?stable"
    property real playbackPosition: 0
    property int playbackSessionRevision: 2
    property int favoritesRevision: 0
    property bool currentFavorite: false
    property string repeatMode: "none"
    property int volume: 70
    property var currentTrack: ({{ title: "Track" }})
    property var lacunaSettings: ({{ reduceMotion: true }})
    property int failureReports: 0
    function statusText() {{ return "Playing" }}
    function setInlineSurfaceAvailable(value) {{}}
    function updatePreviewTelemetry(value) {{}}
    function reportVideoReady(surface, revision, position) {{}}
    function reportVideoFailure(surface, revision, reason) {{ failureReports += 1 }}
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/menu/MediaPlayerTile.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    tile = component.createObject(root, {{ service: service, width: 300 }})
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 20
    repeat: false
    onTriggered: {{
    tile.handleAdaptiveReadinessTimeout()
    var hiddenCount = service.failureReports
    service.presentationState = "inline"
    service.paused = true
    tile.handleAdaptiveReadinessTimeout()
    var pausedCount = service.failureReports
    service.paused = false
    tile.handleAdaptiveReadinessTimeout()
    console.log("BEHAVE " + JSON.stringify({{
      hiddenCount: hiddenCount,
      pausedCount: pausedCount,
      visibleCount: service.failureReports
    }}))
    Qt.quit()
  }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(row["hiddenCount"], 0, output[-2000:])
        self.assertEqual(row["pausedCount"], 0, output[-2000:])
        self.assertEqual(row["visibleCount"], 1, output[-2000:])


if __name__ == "__main__":
    unittest.main()
