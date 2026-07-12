import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


ROOT = Path(__file__).resolve().parents[1]


class QmlAccessibilitySourceContracts(unittest.TestCase):
    def test_media_flyout_exposes_keyboard_and_semantic_controls(self):
        qml = (ROOT / "lacuna.menu/menu/FlyoutMediaPlayerContent.qml").read_text(encoding="utf-8")
        sidebar_tile = (ROOT / "lacuna.menu/menu/MediaPlayerTile.qml").read_text(encoding="utf-8")
        rail = (ROOT / "lacuna.menu/settings/SettingsRail.qml").read_text(encoding="utf-8")

        for snippet in [
            'Accessible.name: "Search media"',
            "Keys.onDownPressed",
            "Keys.onUpPressed",
            "activateSelectedResult((event.modifiers & Qt.ShiftModifier) !== 0)",
            'Accessible.description: "Press Enter to play, Alt Up or Alt Down to reorder, Delete to remove"',
            'Accessible.name: "Filter favorites"',
            'Accessible.name: "Sort favorites by " + root.favoritesSortLabel()',
            'accessibleName: "Remove from favorites"',
            'text: root.pendingClearKind === root.activeTab ? "Confirm" : "Clear"',
        ]:
            self.assertIn(snippet, qml)

        self.assertIn("activeFocusOnTab: true", rail)
        self.assertIn("Accessible.role: Accessible.Button", rail)
        self.assertIn("Keys.onReturnPressed: root.sectionSelected(sectionId)", rail)
        self.assertNotIn("id: transportControls", qml)
        self.assertIn("service.togglePause()", sidebar_tile)
        self.assertIn("service.previousOrRestart()", sidebar_tile)
        self.assertIn("service.next()", sidebar_tile)

    def test_media_search_alone_enables_panel_keyboard_input(self):
        panel = (ROOT / "lacuna.menu/menu/LacunaPanelWindow.qml").read_text(encoding="utf-8")
        menu = (ROOT / "lacuna.menu/menu/MenuWindow.qml").read_text(encoding="utf-8")

        self.assertIn(
            "? WlrKeyboardFocus.Exclusive",
            panel,
        )
        self.assertIn("root.dismissActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None", panel)
        self.assertIn(
            "keyboardInputActive: root.lacunaEnabled && root.activeFlyoutMediaPlayer && root.flyoutInteractiveOnScreen(modelData)",
            menu,
        )
        self.assertIn("active: root.focusGrabActive", panel)
        self.assertIn("if (root.dismissActive) root.focusGrabActive = true", panel)
        self.assertIn('sequence: "Escape"', panel)
        self.assertIn("onActivated: root.dismissRequested()", panel)

    def test_shared_buttons_are_keyboard_focusable_and_accessible(self):
        for relative in [
            "lacuna.menu/components/LacunaIconButton.qml",
            "lacuna.menu/menu/MenuRailButton.qml",
        ]:
            qml = (ROOT / relative).read_text(encoding="utf-8")
            self.assertIn("activeFocusOnTab: !disabled", qml, relative)
            self.assertIn("Accessible.role: Accessible.Button", qml, relative)
            self.assertIn("Accessible.name: accessibleName", qml, relative)
            self.assertIn("Accessible.onPressAction: root.activate()", qml, relative)
            self.assertIn("Keys.onReturnPressed", qml, relative)
            self.assertIn("Keys.onEnterPressed", qml, relative)
            self.assertIn("Keys.onSpacePressed", qml, relative)


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlAccessibilityBehaviorTests(unittest.TestCase):
    def test_media_favorites_filter_and_sort_behavior(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: shell

  QtObject {{
    id: fakeService
    property var favorites: [
      ({{ title: "Zulu", uploader: "Beta", source: "YouTube" }}),
      ({{ title: "Alpha", uploader: "Gamma", source: "Jellyfin" }}),
      ({{ title: "Middle", uploader: "Needle Artist", source: "YouTube" }})
    ]
    property int favoritesRevision: 1
    property int favoritesLength: favorites.length
    property var queue: []
    property var results: []
    property var allResults: []
    property bool searching: false
    property bool canLoadMore: false
    property string errorText: ""
    property string searchFilter: "all"
    property string repeatMode: "none"
    function isYoutubeUrl(value) {{ return false }}
    function isFavorite(track) {{ return true }}
    function setVisibleLimit(limit) {{}}
    function statusText() {{ return "Ready" }}
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/menu/FlyoutMediaPlayerContent.qml')}")
    var flyout = component.createObject(shell, {{
      service: fakeService,
      width: 420,
      height: 600,
      contentVisible: true
    }})
    flyout.favoritesSort = "title"
    var byTitle = flyout.filteredFavorites().map(function(track) {{ return track.title }})
    flyout.favoritesFilter = "needle"
    var filtered = flyout.filteredFavorites().map(function(track) {{ return track.title }})
    flyout.favoritesFilter = ""
    flyout.favoritesSort = "recent"
    var recent = flyout.filteredFavorites().map(function(track) {{ return track.title }})
    console.log("BEHAVE " + JSON.stringify({{ byTitle: byTitle, filtered: filtered, recent: recent }}))
    quitTimer.start()
  }}

  Timer {{ id: quitTimer; interval: 20; onTriggered: Qt.quit() }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        row = parse_behave(output)[0]
        self.assertEqual(row["byTitle"], ["Alpha", "Middle", "Zulu"])
        self.assertEqual(row["filtered"], ["Middle"])
        self.assertEqual(row["recent"], ["Middle", "Alpha", "Zulu"])

    def test_shared_icon_button_exposes_focus_and_accessibility_contract(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: shell
  property var button: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/components/LacunaIconButton.qml')}")
    button = component.createObject(shell, {{ accessibleName: "Close settings", icon: "x" }})
    button.forceActiveFocus()
    console.log("BEHAVE " + JSON.stringify({{
      name: button.Accessible.name,
      focusable: button.Accessible.focusable,
      tab: button.activeFocusOnTab
    }}))
    quitTimer.start()
  }}

  Timer {{ id: quitTimer; interval: 20; onTriggered: Qt.quit() }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        row = parse_behave(output)[0]
        self.assertEqual(row["name"], "Close settings")
        self.assertTrue(row["focusable"])
        self.assertTrue(row["tab"])


if __name__ == "__main__":
    unittest.main()
