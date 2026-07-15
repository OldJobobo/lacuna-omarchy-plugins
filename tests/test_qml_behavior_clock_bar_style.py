import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlClockBarStyleBehaviorTests(unittest.TestCase):
    def test_clock_splits_format_and_keeps_time_foreground(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var clockWidget: null
  property string normalDate: ""
  property string normalTime: ""
  property string customDate: ""
  property string customTime: ""

  QtObject {{
    id: mockBar
    property bool vertical: false
    property int barSize: 26
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#2979ff"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
    function run(command) {{}}
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.clock/Widget.qml')}", Component.PreferSynchronous)
    clockWidget = component.createObject(root, {{
      bar: mockBar,
      settings: {{
        format: "ddd d h:mm AP",
        verticalFormat: "HH\\n—\\nmm"
      }},
      displayDate: new Date(2026, 6, 12, 22, 48, 0)
    }})
    normalDate = clockWidget.dateText
    normalTime = clockWidget.timeText
    clockWidget.settings = {{
      format: "ddd d h:mm AP",
      dateFormat: "MMM d",
      timeFormat: "HH:mm",
      formatAlt: "ignored legacy value",
      verticalFormat: "HH\\n—\\nmm"
    }}
    customDate = clockWidget.dateText
    customTime = clockWidget.timeText
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        normalDate: root.normalDate,
        normalTime: root.normalTime,
        customDate: root.customDate,
        customTime: root.customTime,
        opened: clockWidget.opened,
        textSize: clockWidget.topbarTextSize,
        spacing: clockWidget.contentSpacing,
        padding: clockWidget.horizontalPadding,
        timeColor: clockWidget.timeColor.toString()
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["normalDate"], "Sun 12")
        self.assertEqual(result["normalTime"], "10:48 PM")
        self.assertEqual(result["customDate"], "Jul 12")
        self.assertEqual(result["customTime"], "22:48")
        self.assertFalse(result["opened"])
        self.assertEqual(result["textSize"], 12)
        self.assertEqual(result["spacing"], 5)
        self.assertEqual(result["padding"], 5)
        self.assertEqual(result["timeColor"], "#eeeeee")
