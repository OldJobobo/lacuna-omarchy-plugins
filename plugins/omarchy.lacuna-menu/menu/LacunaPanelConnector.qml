import QtQuick
import QtQuick.Shapes
import "../components"

Item {
  id: root

  property bool open: false
  property int connectorWidth: 18
  property int contentHeight: 0
  property color panelColor: "#101315"

  readonly property real curveKappa: 0.5522847498

  width: connectorWidth
  height: contentHeight + connectorWidth * 2
  visible: open

  LacunaRect {
    x: 0
    y: root.connectorWidth
    width: parent.width + 1
    height: root.contentHeight
    color: root.panelColor
  }

  Shape {
    width: root.connectorWidth
    height: root.connectorWidth
    asynchronous: true
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.panelColor
      strokeColor: root.panelColor
      strokeWidth: 1
      startX: 0
      startY: root.connectorWidth

      PathLine { x: root.connectorWidth; y: root.connectorWidth }
      PathCubic {
        x: 0
        y: 0
        control1X: root.connectorWidth * (1 - root.curveKappa)
        control1Y: root.connectorWidth
        control2X: 0
        control2Y: root.connectorWidth * root.curveKappa
      }
      PathLine { x: 0; y: root.connectorWidth }
    }
  }

  Shape {
    y: root.connectorWidth + root.contentHeight
    width: root.connectorWidth
    height: root.connectorWidth
    asynchronous: true
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.panelColor
      strokeColor: root.panelColor
      strokeWidth: 1
      startX: 0
      startY: 0

      PathLine { x: root.connectorWidth; y: 0 }
      PathCubic {
        x: 0
        y: root.connectorWidth
        control1X: root.connectorWidth * (1 - root.curveKappa)
        control1Y: 0
        control2X: 0
        control2Y: root.connectorWidth * (1 - root.curveKappa)
      }
      PathLine { x: 0; y: 0 }
    }
  }
}
