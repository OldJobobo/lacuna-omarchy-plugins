import QtQuick
import QtQuick.Shapes
import "../components"
import "../services"

Item {
  id: root

  default property alias content: contentHost.data

  property bool open: false
  property bool renderable: open
  property bool interactive: open
  property real progress: open ? 1 : 0
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
  readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
  readonly property real bodyMaskX: x + Math.max(0, panelBody.x)
  readonly property real bodyMaskY: y
  readonly property real bodyMaskWidth: Math.max(0, Math.min(width, panelWidth + panelBody.x))
  readonly property real bodyMaskHeight: height

  visible: renderable && clampedProgress > 0.001
  enabled: interactive
  x: openX
  y: openY
  width: panelWidth
  height: panelHeight
  clip: true

  Item {
    id: panelBody

    x: -root.closedOffset * (1 - root.clampedProgress)
    y: 0
    width: root.panelWidth
    height: root.panelHeight

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
