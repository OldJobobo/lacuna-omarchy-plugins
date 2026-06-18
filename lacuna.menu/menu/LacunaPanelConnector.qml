import QtQuick
import QtQuick.Shapes
import "../components"

Item {
  id: root

  property bool open: false
  property bool renderable: open
  property real progress: open ? 1 : 0
  property int connectorWidth: 18
  property int contentHeight: 0
  property color panelColor: "#101315"
  property color foreground: "#d8dee9"
  property bool backgroundVisible: true

  readonly property real curveKappa: lacunaGeometry.curveKappa
  readonly property int joinLineGap: Math.min(22, Math.max(0, Math.round(contentHeight * 0.35)))
  readonly property color joinLineColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)

  LacunaGeometry { id: lacunaGeometry }
  readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
  readonly property color solidPanelColor: Qt.rgba(panelColor.r, panelColor.g, panelColor.b, 1)
  readonly property real joinLineSegmentHeight: Math.max(0, Math.round((contentHeight - joinLineGap) / 2))

  width: connectorWidth
  height: contentHeight + connectorWidth * 2
  visible: renderable && clampedProgress > 0.001 && connectorWidth > 0 && contentHeight > 0
  opacity: backgroundVisible ? 1 : 0
  enabled: false

  LacunaRect {
    x: 0
    y: root.connectorWidth
    width: parent.width + 1
    height: root.contentHeight
    color: root.solidPanelColor
  }

  Shape {
    width: root.connectorWidth
    height: root.connectorWidth
    asynchronous: false
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.solidPanelColor
      strokeWidth: 0
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
    asynchronous: false
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.solidPanelColor
      strokeWidth: 0
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

  Item {
    id: joinLine

    visible: root.contentHeight > root.joinLineGap + 2
    x: Math.round(root.connectorWidth / 2)
    y: root.connectorWidth
    width: 1
    height: root.contentHeight
    opacity: root.clampedProgress * 0.58

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      width: 1
      height: root.joinLineSegmentHeight
      color: root.joinLineColor
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      width: 1
      height: root.joinLineSegmentHeight
      color: root.joinLineColor
    }
  }
}
