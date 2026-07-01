import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property int panelWidth: 360
  property int panelHeight: 420
  property int joinRadius: 13
  property int cornerRadius: 14
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

      startX: 0
      startY: 0

      PathLine { x: root.fullWidth; y: 0 }

      PathCubic {
        x: root.panelRight
        y: root.panelTop
        control1X: root.fullWidth - root.joinRadius * root.curveKappa
        control1Y: 0
        control2X: root.panelRight
        control2Y: root.joinRadius * (1 - root.curveKappa)
      }

      PathLine { x: root.panelRight; y: root.panelBottom - root.cornerRadius }

      PathCubic {
        x: root.panelRight - root.cornerRadius
        y: root.panelBottom
        control1X: root.panelRight
        control1Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
        control2X: root.panelRight - root.cornerRadius * (1 - root.curveKappa)
        control2Y: root.panelBottom
      }

      PathLine { x: root.panelLeft + root.cornerRadius; y: root.panelBottom }

      PathCubic {
        x: root.panelLeft
        y: root.panelBottom - root.cornerRadius
        control1X: root.panelLeft + root.cornerRadius * (1 - root.curveKappa)
        control1Y: root.panelBottom
        control2X: root.panelLeft
        control2Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
      }

      PathLine { x: root.panelLeft; y: root.panelTop }

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
