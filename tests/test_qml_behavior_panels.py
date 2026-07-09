import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlPanelBehaviorTests(unittest.TestCase):
    def test_panel_controller_rapid_menu_and_flyout_transitions_settle(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var controller: null

  QtObject {{
    id: menuState
    property bool open: false
    function show() {{ open = true }}
    function close() {{ open = false }}
  }}

  function emitState(label) {{
    console.log("BEHAVE " + JSON.stringify({{
      label: label,
      menuStateName: controller.menuStateName,
      flyoutStateName: controller.flyoutStateName,
      menuProgress: controller.menuProgress,
      flyoutProgress: controller.flyoutProgress,
      activeFlyout: controller.activeFlyout,
      visibleFlyout: controller.visibleFlyout,
      panelVisible: controller.panelVisible,
      menuAnimationRevision: controller.menuAnimationRevision,
      flyoutAnimationRevision: controller.flyoutAnimationRevision
    }}))
  }}

  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('lacuna.menu/services/PanelController.qml')}")
    if (c.status === Component.Error) {{
      console.log("BEHAVE_ERR " + c.errorString())
      Qt.quit()
      return
    }}
    controller = c.createObject(root, {{ menuState: menuState, animationDuration: 1 }})
    controller.openMenu()
    firstProbe.restart()
  }}

  Timer {{
    id: firstProbe
    interval: 30
    repeat: false
    onTriggered: {{
      root.emitState("opened")
      root.controller.openFlyout("music")
      secondProbe.restart()
    }}
  }}

  Timer {{
    id: secondProbe
    interval: 30
    repeat: false
    onTriggered: {{
      root.emitState("flyout-open")
      root.controller.toggleFlyout("music")
      root.controller.openFlyout("settings")
      root.controller.closeMenu()
      root.controller.openMenu()
      finalProbe.restart()
    }}
  }}

  Timer {{
    id: finalProbe
    interval: 80
    repeat: false
    onTriggered: {{
      root.emitState("final")
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        rows = parse_behave(output)
        self.assertGreaterEqual(len(rows), 3, output[-2000:])
        opened = next(row for row in rows if row["label"] == "opened")
        flyout = next(row for row in rows if row["label"] == "flyout-open")
        final = next(row for row in rows if row["label"] == "final")

        self.assertEqual(opened["menuStateName"], "menuOpen")
        self.assertEqual(opened["menuProgress"], 1)
        self.assertEqual(flyout["flyoutStateName"], "flyoutOpen")
        self.assertEqual(flyout["activeFlyout"], "music")
        self.assertEqual(final["menuStateName"], "menuOpen")
        self.assertEqual(final["flyoutStateName"], "closed")
        self.assertEqual(final["activeFlyout"], "")
        self.assertEqual(final["visibleFlyout"], "")
        self.assertEqual(final["menuAnimationRevision"], -1)
        self.assertEqual(final["flyoutAnimationRevision"], -1)

    def test_flyout_swap_cancels_in_flight_close_animation(self):
        # Regression: closeActiveFlyout() starts an animation to 0; opening
        # another flyout while progress is still ~1 takes the fast-path swap.
        # Without cancelling the in-flight close, its completion cleared
        # visibleFlyout under the freshly opened flyout (open but invisible).
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var controller: null

  QtObject {{
    id: menuState
    property bool open: false
    function show() {{ open = true }}
    function close() {{ open = false }}
  }}

  function emitState(label) {{
    console.log("BEHAVE " + JSON.stringify({{
      label: label,
      flyoutStateName: controller.flyoutStateName,
      flyoutProgress: controller.flyoutProgress,
      activeFlyout: controller.activeFlyout,
      visibleFlyout: controller.visibleFlyout,
      flyoutAnimationRevision: controller.flyoutAnimationRevision
    }}))
  }}

  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('lacuna.menu/services/PanelController.qml')}")
    if (c.status === Component.Error) {{
      console.log("BEHAVE_ERR " + c.errorString())
      Qt.quit()
      return
    }}
    controller = c.createObject(root, {{ menuState: menuState, animationDuration: 1 }})
    controller.openMenu()
    controller.openFlyout("music")
    swapProbe.restart()
  }}

  Timer {{
    id: swapProbe
    interval: 40
    repeat: false
    onTriggered: {{
      root.emitState("music-open")
      // Same-turn close-then-open: the close animation is in flight when
      // the fast-path swap runs.
      root.controller.closeActiveFlyout()
      root.controller.openFlyout("settings")
      settleProbe.restart()
    }}
  }}

  Timer {{
    id: settleProbe
    interval: 60
    repeat: false
    onTriggered: {{
      root.emitState("after-swap")
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        rows = parse_behave(output)
        music = next(row for row in rows if row["label"] == "music-open")
        after = next(row for row in rows if row["label"] == "after-swap")

        self.assertEqual(music["activeFlyout"], "music")
        self.assertEqual(music["flyoutProgress"], 1)
        self.assertEqual(after["activeFlyout"], "settings", output[-2000:])
        self.assertEqual(after["visibleFlyout"], "settings", output[-2000:])
        self.assertEqual(after["flyoutStateName"], "flyoutOpen", output[-2000:])
        self.assertEqual(after["flyoutProgress"], 1, output[-2000:])

    def test_youtube_music_tile_unsuppresses_preview_on_sidebar_handoff(self):
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
    property bool backgroundVideoEnabled: false
    property string displayTitle: "Track"
    property string previewStreamUrl: "file:///tmp/lacuna-preview-placeholder.mp4"
    property string thumbnail: ""
    property real playbackPosition: 120
    property int favoritesRevision: 0
    property bool currentFavorite: false
    property string repeatMode: "none"
    property int volume: 70
    function statusText() {{ return "Ready" }}
    function updatePreviewTelemetry(payload) {{}}
    function setVolume(value) {{ volume = value }}
  }}

  function emitState(label) {{
    console.log("BEHAVE " + JSON.stringify({{
      label: label,
      localPreviewVisible: tile.localPreviewVisible,
      previewSuppressed: tile.previewSuppressed,
      previewVideoActive: tile.previewVideoActive,
      previewPositionPending: tile.previewPositionPending
    }}))
  }}

  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('lacuna.menu/menu/MediaPlayerTile.qml')}")
    if (c.status === Component.Error) {{
      console.log("BEHAVE_ERR " + c.errorString())
      Qt.quit()
      return
    }}
    tile = c.createObject(root, {{ service: service, width: 320 }})
    tile.previewSuppressed = true
    root.emitState("suppressed-desktop")
    service.backgroundVideoEnabled = true
    hiddenProbe.restart()
  }}

  Timer {{
    id: hiddenProbe
    interval: 20
    repeat: false
    onTriggered: {{
      root.emitState("sent-to-background")
      service.backgroundVideoEnabled = false
      finalProbe.restart()
    }}
  }}

  Timer {{
    id: finalProbe
    interval: 40
    repeat: false
    onTriggered: {{
      root.emitState("returned-to-sidebar")
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        rows = parse_behave(output)
        final = next(row for row in rows if row["label"] == "returned-to-sidebar")
        self.assertTrue(final["localPreviewVisible"], output[-2000:])
        self.assertFalse(final["previewSuppressed"], output[-2000:])
        self.assertTrue(final["previewVideoActive"], output[-2000:])


if __name__ == "__main__":
    unittest.main()
