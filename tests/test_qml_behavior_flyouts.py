import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class RichFlyoutFourEdgeBehaviorTests(unittest.TestCase):
    def test_representative_surface_geometry_tracks_attachment_edge(self):
        cases = [
            ("simple", "lacuna.audio/BarFlyoutSurface.qml"),
            ("usage", "lacuna.claude-usage/BarFlyoutSurface.qml"),
            ("shadowed", "lacuna.theme/BarFlyoutSurface.qml"),
        ]
        for label, relative in cases:
            with self.subTest(label=label):
                qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var measuredRows: []
  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url(relative)}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    var rows = []
    var edges = ["top", "bottom", "left", "right"]
    for (var i = 0; i < edges.length; i++) {{
      var surface = component.createObject(null, {{
        attachmentEdge: edges[i], panelWidth: 300, panelHeight: 400,
        joinRadius: 13, cornerRadius: 14
      }})
      rows.push({{
        edge: edges[i], width: surface.fullWidth, height: surface.fullHeight,
        left: surface.panelLeft, top: surface.panelTop,
        right: surface.panelRight, bottom: surface.panelBottom
      }})
      surface.destroy()
    }}
    root.measuredRows = rows
    finish.start()
  }}
  Timer {{
    id: finish
    interval: 20
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{ rows: root.measuredRows }}))
      Qt.quit()
    }}
  }}
}}
"""
                output = run_quickshell(qml)
                require_no_qml_errors(output)
                rows = parse_behave(output)[-1]["rows"]
                by_edge = {row["edge"]: row for row in rows}
                self.assertEqual(326, by_edge["top"]["width"])
                self.assertEqual(413, by_edge["top"]["height"])
                self.assertEqual(13, by_edge["top"]["top"])
                self.assertEqual(0, by_edge["bottom"]["top"])
                self.assertEqual(313, by_edge["left"]["width"])
                self.assertEqual(426, by_edge["left"]["height"])
                self.assertEqual(13, by_edge["left"]["left"])
                self.assertEqual(0, by_edge["right"]["left"])


if __name__ == "__main__":
    unittest.main()
