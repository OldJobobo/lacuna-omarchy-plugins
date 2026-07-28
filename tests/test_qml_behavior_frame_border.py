import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlFrameBorderBehaviorTests(unittest.TestCase):
    def test_border_consumes_authoritative_frame_geometry_record(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var border: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.bar/LacunaFrameBorderWindow.qml')}", Component.PreferSynchronous)
    border = component.createObject(root, {{
      width: 800,
      height: 600,
      active: true,
      frameThickness: 8,
      frameRadius: 14,
      leftEdgeOccupied: false,
      leftOccupiedWidth: 700,
      geometryRecord: {{
        framed: true,
        barPosition: "top",
        barSize: 30,
        thickness: 16,
        contentRadius: 31,
        topEdgeOccupied: false,
        bottomEdgeOccupied: false,
        leftEdgeOccupied: true,
        rightEdgeOccupied: false,
        leftOccupiedWidth: 159,
        rightOccupiedWidth: 0,
        holeX: 159,
        holeY: 30,
        holeRight: 784,
        holeBottom: 584
      }}
    }})
    settle.start()
  }}

  Timer {{
    id: settle
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        holeX: border.holeX,
        holeY: border.holeY,
        holeRight: border.holeRight,
        holeBottom: border.holeBottom,
        holeRadius: border.holeRadius,
        borderLeft: border.borderLeft,
        borderTop: border.borderTop,
        leftGap: border.leftAttachmentGapVisible,
        renderable: border.isRenderable
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["holeX"], 159)
        self.assertEqual(result["holeY"], 30)
        self.assertEqual(result["holeRight"], 784)
        self.assertEqual(result["holeBottom"], 584)
        self.assertEqual(result["holeRadius"], 31)
        self.assertEqual(result["borderLeft"], 159.5)
        self.assertEqual(result["borderTop"], 30.5)
        self.assertFalse(result["leftGap"])
        self.assertTrue(result["renderable"])

    def test_panel_border_lower_molding_reaches_connector_outer_edge(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var border: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/menu/LacunaPanelBorder.qml')}", Component.PreferSynchronous)
    border = component.createObject(root, {{
      width: 900,
      height: 700,
      active: true,
      connectorVisible: true,
      flyoutVisible: true,
      connectorX: 310,
      connectorY: 100,
      connectorWidth: 18,
      flyoutX: 328,
      flyoutY: 118,
      flyoutWidth: 420,
      flyoutHeight: 300,
      panelRadius: 14
    }})
    settle.start()
  }}

  Timer {{
    id: settle
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        flyoutBottom: border.outlineBottom,
        connectorBottom: border.connectorOutlineBottom,
        connectorWidth: border.effectiveConnectorWidth,
        renderable: border.renderable
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["flyoutBottom"], 417.5)
        self.assertEqual(result["connectorBottom"], 435.5)
        self.assertEqual(result["connectorBottom"] - result["flyoutBottom"], result["connectorWidth"])
        self.assertTrue(result["renderable"])
