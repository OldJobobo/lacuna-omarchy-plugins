import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlMprisBarStyleBehaviorTests(unittest.TestCase):
    def test_foreground_text_metrics_and_playing_sweep_run_together(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var button: null
  property real initialSweep: 0

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.mpris/components/LacunaMprisButton.qml')}", Component.PreferSynchronous)
    button = component.createObject(root, {{
      text: "Artist - Track",
      iconName: "player-play",
      foreground: "#eeeeee",
      accent: "#12ab34",
      background: "#101010",
      accentText: false,
      active: true,
      sweepActive: true,
      barSize: 30,
      labelFontWeight: Font.DemiBold
    }})
    initialSweep = button.sweepPosition
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 120
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        textColor: button.baseTextColor().toString(),
        iconSize: button.iconSize,
        textSize: button.labelPixelSize,
        spacing: button.contentSpacing,
        padding: button.contentHorizontalPadding,
        sweepActive: button.sweepActive,
        initialSweep: root.initialSweep,
        currentSweep: button.sweepPosition
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["textColor"], "#eeeeee")
        self.assertEqual(result["iconSize"], 15)
        self.assertEqual(result["textSize"], 12)
        self.assertEqual(result["spacing"], 6)
        self.assertEqual(result["padding"], 14)
        self.assertTrue(result["sweepActive"])
        self.assertGreater(result["currentSweep"], result["initialSweep"])
