import QtQuick
import QtQuick.Shapes
import "../components"
import "../services"

Item {
  id: root

  default property alias content: contentHost.data

  property bool open: false
  property real openX: 0
  property real openY: 0
  property int panelWidth: 300
  property int panelHeight: 420
  property int panelRadius: 14
  property color panelColor: "#101315"
  property color foreground: "#d8dee9"
  property var designTokens: fallbackDesignTokens

  readonly property real curveKappa: 0.5522847498
  readonly property real closedOffset: panelWidth

  visible: open || panelBody.x > -closedOffset + 0.5
  enabled: open
  x: openX
  y: openY
  width: panelWidth
  height: panelHeight
  clip: true

  Item {
    id: panelBody

    x: root.open ? 0 : -root.closedOffset
    y: 0
    width: root.panelWidth
    height: root.panelHeight

    Behavior on x {
      LacunaAnim { motion: "normal" }
    }

    Shape {
      anchors.fill: parent
      asynchronous: true
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.panelColor
        strokeWidth: 0
        startX: 0
        startY: 0

        PathLine { x: root.width - root.panelRadius; y: 0 }
        PathCubic {
          x: root.width
          y: root.panelRadius
          control1X: root.width - root.panelRadius * (1 - root.curveKappa)
          control1Y: 0
          control2X: root.width
          control2Y: root.panelRadius * (1 - root.curveKappa)
        }
        PathLine { x: root.width; y: root.height - root.panelRadius }
        PathCubic {
          x: root.width - root.panelRadius
          y: root.height
          control1X: root.width
          control1Y: root.height - root.panelRadius * (1 - root.curveKappa)
          control2X: root.width - root.panelRadius * (1 - root.curveKappa)
          control2Y: root.height
        }
        PathLine { x: 0; y: root.height }
        PathLine { x: 0; y: 0 }
      }
    }

    Item {
      id: contentHost
      anchors.fill: parent
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    foreground: root.foreground
    background: root.panelColor
  }
}
