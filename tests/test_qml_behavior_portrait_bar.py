import json
import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "requires a live Wayland Quickshell session")
class PortraitBarBehaviorTests(unittest.TestCase):
    def test_mixed_orientation_activation_and_routed_bands_update_together(self):
        qml = f'''
import Quickshell
import QtQuick
import "{qml_url("lacuna.bar/PortraitBarModel.js")}" as PortraitBarModel
import "{qml_url("lacuna.bar/ScreenModel.js")}" as ScreenModel

ShellRoot {{
  QtObject {{
    id: probe
    property bool enabled: true
    property var landscape: ({{ name: "DP-1", width: 1920, height: 1080 }})
    property var portrait: ({{ name: "DP-3", width: 1080, height: 1920 }})
    property var layout: ({{
      left: ["lacuna.menu-button", "lacuna.codex-usage"],
      center: ["lacuna.clock", "lacuna.system-stats"],
      right: ["lacuna.power", "lacuna.wallpaper"]
    }})

    function effective(screen, position) {{
      return enabled && (position === "top" || position === "bottom") && ScreenModel.isPortrait(screen)
    }}

    function snapshot(label, position) {{
      var routed = PortraitBarModel.routeLayout(layout, function(value) {{ return value }})
      console.log("BEHAVE " + JSON.stringify({{
        label: label,
        landscape: effective(landscape, position),
        portrait: effective(portrait, position),
        primaryEdge: position,
        companionEdge: position === "top" ? "bottom" : "top",
        primary: routed.primary,
        companion: routed.companion
      }}))
    }}

    Component.onCompleted: {{
      snapshot("top", "top")
      snapshot("bottom", "bottom")
      enabled = false
      snapshot("disabled", "top")
      Qt.callLater(Qt.quit)
    }}
  }}
}}
'''
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        rows = parse_behave(output)
        self.assertEqual(["top", "bottom", "disabled"], [row["label"] for row in rows])
        self.assertFalse(rows[0]["landscape"])
        self.assertTrue(rows[0]["portrait"])
        self.assertEqual(("top", "bottom"), (rows[0]["primaryEdge"], rows[0]["companionEdge"]))
        self.assertEqual(("bottom", "top"), (rows[1]["primaryEdge"], rows[1]["companionEdge"]))
        self.assertFalse(rows[2]["portrait"])
        self.assertEqual(["lacuna.menu-button"], rows[0]["primary"]["left"])
        self.assertEqual(["lacuna.codex-usage"], rows[0]["companion"]["left"])
        self.assertEqual(["lacuna.system-stats"], rows[0]["companion"]["center"])
        self.assertEqual(["lacuna.wallpaper"], rows[0]["companion"]["right"])


if __name__ == "__main__":
    unittest.main()
