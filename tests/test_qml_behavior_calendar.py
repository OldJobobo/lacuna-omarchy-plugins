import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlCalendarBehaviorTests(unittest.TestCase):
    def test_frame_shadow_settings_drive_edge_aware_padding(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var flyout: null

  Item {{ id: anchorItem; width: 100; height: 32 }}

  QtObject {{
    id: mockBar
    property string position: "top"
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property string fontFamily: "Hack Nerd Font Propo"
    property var activePopout: null
    function requestPopout(owner, anchor, moduleId) {{ activePopout = owner }}
    function releasePopout(owner) {{ if (activePopout === owner) activePopout = null }}
  }}

  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
      var component = Qt.createComponent("{qml_url('lacuna.clock/CalendarFlyout.qml')}", Component.PreferSynchronous)
      flyout = component.createObject(root, {{ anchorItem: anchorItem, bar: mockBar }})
      flyout.loadFrameSettings('{{"frame":{{"shadow":true,"shadowOffsetX":2,"shadowOffsetY":3}}}}')

      function margins() {{
        return {{
          left: flyout.shadowLeftMargin,
          right: flyout.shadowRightMargin,
          top: flyout.shadowTopMargin,
          bottom: flyout.shadowBottomMargin
        }}
      }}

      var top = margins()
      var displayFontFamily = flyout.displayFontFamily
      var displayHeroWeightIsNormal = flyout.displayHeroWeight === Font.Normal
      var displayTitleTracking = flyout.displayTitleTracking
      var contentFitsPanel = flyout.contentFitsPanel
      var contentBottom = flyout.contentPadding + flyout.calendarContentHeight
      var panelContentBottom = flyout.panelHeight - flyout.contentPadding
      mockBar.position = "bottom"
      var bottom = margins()
      mockBar.position = "left"
      var left = margins()
      mockBar.position = "right"
      var right = margins()
      flyout.loadFrameSettings("invalid json")

      console.log("BEHAVE " + JSON.stringify({{
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        displayFontFamily: displayFontFamily,
        displayHeroWeightIsNormal: displayHeroWeightIsNormal,
        displayTitleTracking: displayTitleTracking,
        contentFitsPanel: contentFitsPanel,
        contentBottom: contentBottom,
        panelContentBottom: panelContentBottom,
        invalidDisablesShadow: !flyout.shadowEnabled
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual({"left": 31, "right": 31, "top": 0, "bottom": 51}, result["top"])
        self.assertEqual({"left": 31, "right": 31, "top": 48, "bottom": 0}, result["bottom"])
        self.assertEqual({"left": 0, "right": 50, "top": 31, "bottom": 31}, result["left"])
        self.assertEqual({"left": 48, "right": 0, "top": 31, "bottom": 31}, result["right"])
        self.assertEqual("Tektur", result["displayFontFamily"])
        self.assertTrue(result["displayHeroWeightIsNormal"])
        self.assertEqual(2.0, result["displayTitleTracking"])
        self.assertTrue(result["contentFitsPanel"])
        self.assertLessEqual(result["contentBottom"], result["panelContentBottom"])
        self.assertTrue(result["invalidDisablesShadow"])

    def test_widget_open_close_and_popout_switch_use_owner_key(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var widget: null

  QtObject {{
    id: mockBar
    property bool vertical: false
    property string position: "top"
    property int barSize: 26
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#2979ff"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    property var activePopout: null
    property int requestCount: 0
    property int releaseCount: 0
    property string requestedModule: ""
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
    function run(command) {{}}
    function requestPopout(owner, anchorItem, moduleId) {{
      requestCount++
      requestedModule = moduleId
      if (activePopout && activePopout !== owner) activePopout.closeForPopoutSwitch()
      activePopout = owner
    }}
    function releasePopout(owner) {{
      if (activePopout === owner) {{
        releaseCount++
        activePopout = null
      }}
    }}
  }}

  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
      var component = Qt.createComponent("{qml_url('lacuna.clock/Widget.qml')}", Component.PreferSynchronous)
      widget = component.createObject(root, {{ bar: mockBar, moduleName: "lacuna.clock" }})
      widget.open()
      var opened = widget.opened
      var ownerWasWidget = mockBar.activePopout === widget
      mockBar.activePopout.closeForPopoutSwitch()
      var closedBySwitch = !widget.opened
      widget.open()
      widget.close()
      console.log("BEHAVE " + JSON.stringify({{
        opened: opened,
        ownerWasWidget: ownerWasWidget,
        closedBySwitch: closedBySwitch,
        requestCount: mockBar.requestCount,
        releaseCount: mockBar.releaseCount,
        requestedModule: mockBar.requestedModule,
        activeReleased: mockBar.activePopout === null
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertTrue(result["opened"])
        self.assertTrue(result["ownerWasWidget"])
        self.assertTrue(result["closedBySwitch"])
        self.assertEqual(2, result["requestCount"])
        self.assertEqual(2, result["releaseCount"])
        self.assertEqual("lacuna.clock", result["requestedModule"])
        self.assertTrue(result["activeReleased"])

    def test_month_grid_navigation_selection_and_midnight_rollover(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var state: null

  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
    var component = Qt.createComponent("{qml_url('lacuna.clock/CalendarState.qml')}", Component.PreferSynchronous)
    state = component.createObject(root, {{ liveDate: new Date(2026, 6, 12, 23, 59, 0) }})

    state.viewedMonth = new Date(2024, 1, 1, 12, 0, 0)
    var leapCells = state.cells
    var leapKeys = leapCells.map(function(cell) {{ return cell.key }})

    state.viewedMonth = new Date(2026, 2, 1, 12, 0, 0)
    var sundayStart = state.cells[0].key
    var dstHours = state.cells.map(function(cell) {{ return cell.date.getHours() }})

    state.viewedMonth = new Date(2026, 7, 1, 12, 0, 0)
    var sixWeekCells = state.cells
    var adjacent = state.cells[0]
    state.selectCell(adjacent)
    var adjacentSelection = state.selectedKey
    var adjacentMonth = state.viewedMonth.getMonth()

    state.showToday()
    for (var step = 0; step < 5; step++) state.showNextMonth()
    var decemberYear = state.viewedMonth.getFullYear()
    var decemberMonth = state.viewedMonth.getMonth()
    state.showNextMonth()
    var rolloverYear = state.viewedMonth.getFullYear()
    var rolloverMonth = state.viewedMonth.getMonth()

    state.showToday()
    state.liveDate = new Date(2026, 6, 13, 0, 1, 0)
    var followedToday = state.selectedKey
    state.viewedMonth = new Date(2026, 5, 1, 12, 0, 0)
    state.liveDate = new Date(2026, 6, 14, 0, 1, 0)
    var preservedSelection = state.selectedKey
    var preservedMonth = state.viewedMonth.getMonth()
    var expectedWeekdayLabels = []
    for (var weekday = 0; weekday < 7; weekday++)
      expectedWeekdayLabels.push(Qt.locale().toString(new Date(2026, 0, 4 + weekday, 12, 0, 0), "ddd"))

    console.log("BEHAVE " + JSON.stringify({{
      leapCount: leapCells.length,
      hasLeapDay: leapKeys.indexOf("2024-02-29") >= 0,
      sundayStart: sundayStart,
      sixWeekFirst: sixWeekCells[0].key,
      sixWeekLast: sixWeekCells[41].key,
      allLocalNoon: dstHours.every(function(hour) {{ return hour === 12 }}),
      adjacentSelection: adjacentSelection,
      adjacentMonth: adjacentMonth,
      decemberYear: decemberYear,
      decemberMonth: decemberMonth,
      rolloverYear: rolloverYear,
      rolloverMonth: rolloverMonth,
      followedToday: followedToday,
      preservedSelection: preservedSelection,
      preservedMonth: preservedMonth,
      weekdayLabels: state.weekdayLabels,
      expectedWeekdayLabels: expectedWeekdayLabels
    }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(42, result["leapCount"])
        self.assertTrue(result["hasLeapDay"])
        self.assertEqual("2026-03-01", result["sundayStart"])
        self.assertEqual("2026-07-26", result["sixWeekFirst"])
        self.assertEqual("2026-09-05", result["sixWeekLast"])
        self.assertTrue(result["allLocalNoon"])
        self.assertEqual("2026-07-26", result["adjacentSelection"])
        self.assertEqual(6, result["adjacentMonth"])
        self.assertEqual((2026, 11), (result["decemberYear"], result["decemberMonth"]))
        self.assertEqual((2027, 0), (result["rolloverYear"], result["rolloverMonth"]))
        self.assertEqual("2026-07-13", result["followedToday"])
        self.assertEqual("2026-07-13", result["preservedSelection"])
        self.assertEqual(5, result["preservedMonth"])
        self.assertEqual(7, len(result["weekdayLabels"]))
        self.assertEqual(result["expectedWeekdayLabels"], result["weekdayLabels"])
        self.assertTrue(all("," not in label for label in result["weekdayLabels"]))


if __name__ == "__main__":
    unittest.main()
