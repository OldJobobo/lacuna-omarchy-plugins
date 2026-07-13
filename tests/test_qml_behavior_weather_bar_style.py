import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlWeatherBarStyleBehaviorTests(unittest.TestCase):
    def test_weather_keeps_colored_icon_and_foreground_text_metrics(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var weather: null

  QtObject {{
    id: mockBar
    property bool vertical: false
    property int barSize: 26
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#aaaa00"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
    function shellQuote(value) {{ return "'" + value + "'" }}
    function run(command) {{}}
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.weather/Widget.qml')}", Component.PreferSynchronous)
    weather = component.createObject(root, {{
      bar: mockBar,
      settings: {{ showText: true, interval: 999999 }},
      weatherText: " 66 F"
    }})
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        icon: weather.weatherIcon,
        text: weather.displayText,
        iconSize: weather.topbarIconSize,
        textSize: weather.topbarTextSize,
        spacing: weather.contentSpacing,
        padding: weather.horizontalPadding,
        textColor: weather.textColor.toString()
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["icon"], "")
        self.assertEqual(result["text"], "66 F")
        self.assertEqual(result["iconSize"], 13)
        self.assertEqual(result["textSize"], 12)
        self.assertEqual(result["spacing"], 6)
        self.assertEqual(result["padding"], 7)
        self.assertEqual(result["textColor"], "#eeeeee")
