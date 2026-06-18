import QtQuick
import QtQuick.Shapes

// Self-contained Lacuna molded flyout surface for a top-bar attachment.
//
// The top edge is square and flush with the bar; two Omarchy-style molding
// coves flare the panel outward at the top corners so it reads as growing out
// of the bar rather than floating. Only the exposed (bottom) corners are
// rounded. Fill-only (strokeWidth: 0) per the Flyout Surface Geometry rules in
// AGENTS.md. curveKappa is vendored here because self-contained plugins cannot
// import lacuna.menu/components/LacunaGeometry.qml.
Item {
  id: root

  property int panelWidth: 320
  property int panelHeight: 240
  property int joinRadius: 13      // molding cove reach / top-corner flare
  property int cornerRadius: 14    // exposed bottom corners
  property color panelColor: "#0e1113"

  LacunaGeometry { id: lacunaGeometry }
  readonly property real curveKappa: lacunaGeometry.curveKappa
  readonly property color solidColor: Qt.rgba(panelColor.r, panelColor.g, panelColor.b, 1)
  readonly property int fullWidth: panelWidth + joinRadius * 2
  readonly property int panelLeft: joinRadius
  readonly property int panelRight: joinRadius + panelWidth
  readonly property int panelTop: joinRadius
  readonly property int panelBottom: joinRadius + panelHeight

  implicitWidth: fullWidth
  implicitHeight: joinRadius + panelHeight

  Shape {
    anchors.fill: parent
    asynchronous: false
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.solidColor
      strokeWidth: 0

      // Top-left outer point, on the bar line.
      startX: 0
      startY: 0

      // Flat top edge, flush under the bar.
      PathLine { x: root.fullWidth; y: 0 }

      // Right molding cove: bar-wide edge down into the panel's right edge.
      PathCubic {
        x: root.panelRight
        y: root.panelTop
        control1X: root.fullWidth - root.joinRadius * root.curveKappa
        control1Y: 0
        control2X: root.panelRight
        control2Y: root.joinRadius * (1 - root.curveKappa)
      }

      // Right edge down to the bottom corner.
      PathLine { x: root.panelRight; y: root.panelBottom - root.cornerRadius }

      // Bottom-right rounded corner.
      PathCubic {
        x: root.panelRight - root.cornerRadius
        y: root.panelBottom
        control1X: root.panelRight
        control1Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
        control2X: root.panelRight - root.cornerRadius * (1 - root.curveKappa)
        control2Y: root.panelBottom
      }

      // Bottom edge.
      PathLine { x: root.panelLeft + root.cornerRadius; y: root.panelBottom }

      // Bottom-left rounded corner.
      PathCubic {
        x: root.panelLeft
        y: root.panelBottom - root.cornerRadius
        control1X: root.panelLeft + root.cornerRadius * (1 - root.curveKappa)
        control1Y: root.panelBottom
        control2X: root.panelLeft
        control2Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
      }

      // Left edge up to the molding cove.
      PathLine { x: root.panelLeft; y: root.panelTop }

      // Left molding cove: panel's left edge out to the bar-wide edge.
      PathCubic {
        x: 0
        y: 0
        control1X: root.panelLeft
        control1Y: root.joinRadius * (1 - root.curveKappa)
        control2X: root.joinRadius * root.curveKappa
        control2Y: 0
      }
    }
  }
}
