import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlUsageBarStyleBehaviorTests(unittest.TestCase):
    def test_usage_widgets_expose_theme_wallpaper_bar_metrics_and_foreground_text(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var codexWidget: null
  property var claudeWidget: null

  QtObject {{
    id: mockBar
    property bool vertical: false
    property int barSize: 26
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#aaaa00"
    property color urgent: "#ef1234"
    property string position: "top"
    property string fontFamily: "Hack Nerd Font Propo"
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
  }}

  Component.onCompleted: {{
    var codex = Qt.createComponent("{qml_url('lacuna.codex-usage/Widget.qml')}", Component.PreferSynchronous)
    var claude = Qt.createComponent("{qml_url('lacuna.claude-usage/Widget.qml')}", Component.PreferSynchronous)
    codexWidget = codex.createObject(root, {{
      bar: mockBar,
      settings: {{ showProgress: false, interval: 999999 }}
    }})
    claudeWidget = claude.createObject(root, {{
      bar: mockBar,
      settings: {{ showProgress: false, interval: 999999 }}
    }})
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        codexIconSize: codexWidget.topbarIconSize,
        codexTextSize: codexWidget.topbarTextSize,
        codexSpacing: codexWidget.contentSpacing,
        codexPadding: codexWidget.horizontalPadding,
        codexText: codexWidget.textColor.toString(),
        codexSeamAlpha: codexWidget.seamColor.a,
        claudeIconSize: claudeWidget.topbarIconSize,
        claudeTextSize: claudeWidget.topbarTextSize,
        claudeSpacing: claudeWidget.contentSpacing,
        claudePadding: claudeWidget.horizontalPadding,
        claudeText: claudeWidget.textColor.toString(),
        claudeSeamAlpha: claudeWidget.seamColor.a
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        for prefix in ("codex", "claude"):
            self.assertEqual(result[f"{prefix}IconSize"], 13)
            self.assertEqual(result[f"{prefix}TextSize"], 12)
            self.assertEqual(result[f"{prefix}Spacing"], 5)
            self.assertEqual(result[f"{prefix}Padding"], 5)
            self.assertEqual(result[f"{prefix}Text"], "#eeeeee")
            self.assertAlmostEqual(result[f"{prefix}SeamAlpha"], 0.18, places=2)
