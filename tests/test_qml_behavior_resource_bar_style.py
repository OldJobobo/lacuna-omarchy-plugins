import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlResourceBarStyleBehaviorTests(unittest.TestCase):
    def test_resource_metrics_match_and_history_no_longer_expands_the_bar(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var stats: null
  property var temperature: null
  property real widthBeforeHistory: 0
  property real statsWidthAtMinimum: 0
  property real temperatureWidthAtMinimum: 0

  QtObject {{
    id: mockBar
    property bool vertical: false
    property int barSize: 30
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#aaaa00"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
  }}

  Component.onCompleted: {{
    var statsComponent = Qt.createComponent("{qml_url('lacuna.system-stats/Widget.qml')}", Component.PreferSynchronous)
    var temperatureComponent = Qt.createComponent("{qml_url('lacuna.temperature/Widget.qml')}", Component.PreferSynchronous)
    stats = statsComponent.createObject(root, {{
      bar: mockBar,
      settings: {{ showLabels: true, interval: 999999 }}
    }})
    temperature = temperatureComponent.createObject(root, {{
      bar: mockBar,
      settings: {{ showText: true, interval: 999999 }}
    }})
    stats.diskText = "9%"
    stats.memoryPercent = 9
    stats.cpuPercent = 9
    temperature.parseTemperature(JSON.stringify({{ primary: {{ fahrenheit: 9 }} }}))
    settle.restart()
  }}

  Timer {{
    id: settle
    interval: 150
    onTriggered: {{
      root.widthBeforeHistory = stats.implicitWidth
      root.statsWidthAtMinimum = stats.implicitWidth
      root.temperatureWidthAtMinimum = temperature.implicitWidth
      stats.cpuHistory = [5, 20, 40, 80]
      stats.memoryHistory = [20, 30, 40, 50]
      stats.diskHistory = [60, 61, 62, 63]
      stats.diskText = "100%"
      stats.memoryPercent = 100
      stats.cpuPercent = 100
      temperature.parseTemperature(JSON.stringify({{ primary: {{ fahrenheit: 100 }} }}))
      finish.restart()
    }}
  }}

  Timer {{
    id: finish
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        statsIconSize: stats.topbarIconSize,
        statsTextSize: stats.topbarTextSize,
        statsSpacing: stats.contentSpacing,
        statsPadding: stats.horizontalPadding,
        statsText: stats.foreground.toString(),
        temperatureIconSize: temperature.topbarIconSize,
        temperatureTextSize: temperature.topbarTextSize,
        temperatureSpacing: temperature.contentSpacing,
        temperaturePadding: temperature.horizontalPadding,
        temperatureText: temperature.foreground.toString(),
        statsValueWidth: stats.metricValueWidth,
        temperatureValueWidth: temperature.temperatureValueWidth,
        statsWidthAtMinimum: root.statsWidthAtMinimum,
        statsWidthAtMaximum: stats.implicitWidth,
        temperatureWidthAtMinimum: root.temperatureWidthAtMinimum,
        temperatureWidthAtMaximum: temperature.implicitWidth,
        widthBeforeHistory: root.widthBeforeHistory,
        widthAfterHistory: stats.implicitWidth
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        for prefix in ("stats", "temperature"):
            self.assertEqual(result[f"{prefix}IconSize"], 15)
            self.assertEqual(result[f"{prefix}TextSize"], 13)
            self.assertEqual(result[f"{prefix}Spacing"], 5)
            self.assertEqual(result[f"{prefix}Text"], "#eeeeee")

        self.assertEqual(result["statsPadding"], 0)
        self.assertEqual(result["temperaturePadding"], 2)
        self.assertGreater(result["statsValueWidth"], 0)
        self.assertGreater(result["temperatureValueWidth"], result["statsValueWidth"])
        self.assertEqual(result["statsWidthAtMaximum"], result["statsWidthAtMinimum"])
        self.assertEqual(result["temperatureWidthAtMaximum"], result["temperatureWidthAtMinimum"])
        self.assertEqual(result["widthAfterHistory"], result["widthBeforeHistory"])
