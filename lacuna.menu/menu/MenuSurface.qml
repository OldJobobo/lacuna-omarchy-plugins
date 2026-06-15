import QtQuick
import QtQuick.Shapes
import "../components"
import "../services"

Item {
  id: root

  default property alias content: contentHost.data
  readonly property alias surfaceX: surface.x

  property bool open: false
  property int panelWidth: 340
  property int barHeight: 32
  // Position of the bar's bottom edge inside this surface's coordinate space.
  // Defaults to barHeight (overlay mode, where the surface starts at the screen top
  // and the bar covers our top barHeight pixels). In exclusive mode the parent window
  // is already pushed below the bar, so the caller passes 0.
  property int barBottomY: barHeight
  property int joinRadius: 18
  property int connectorOverlap: 33
  property int bodyRightInset: joinRadius
  property bool fullFrame: false
  property bool backgroundVisible: true
  property int frameThickness: 8
  property bool cornerPieces: true
  property bool openFromRight: false
  property color panelColor: "#101315"
  property color foreground: "#d8dee9"
  property var designTokens: fallbackDesignTokens
  property real progress: open ? 1 : 0

  readonly property int bodyTop: barBottomY
  readonly property int joinTop: bodyTop - 1
  readonly property int bottomJoinTop: Math.max(0, surface.height - frameThickness - bodyRightInset)
  readonly property color solidPanelColor: Qt.rgba(panelColor.r, panelColor.g, panelColor.b, 1)
  readonly property real curveKappa: lacunaGeometry.curveKappa

  LacunaGeometry { id: lacunaGeometry }

  width: panelWidth + bodyRightInset

  LacunaRect {
    id: surface

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.panelWidth + root.bodyRightInset
    x: (root.openFromRight ? 1 : -1) * surface.width * (1 - Math.max(0, Math.min(1, root.progress)))

    LacunaShapeSurface {
      visible: root.backgroundVisible
      x: 0
      y: 0
      width: root.panelWidth
      height: surface.height
      panelColor: root.panelColor
      panelRadius: 0
      topLeftCornerState: -1
      topRightCornerState: -1
      bottomRightCornerState: -1
      bottomLeftCornerState: -1
    }

    Shape {
      id: barJoinShape

      visible: root.backgroundVisible && root.cornerPieces && root.bodyRightInset > 0
      width: root.bodyRightInset
      height: Math.max(0, (root.fullFrame ? root.bottomJoinTop : surface.height) - root.joinTop)
      x: root.panelWidth
      y: root.joinTop
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidPanelColor
        strokeWidth: 0
        startX: 0
        startY: 0

        PathLine {
          x: root.bodyRightInset
          y: 0
        }
        PathCubic {
          x: 0
          y: root.bodyRightInset
          control1X: root.bodyRightInset * (1 - root.curveKappa)
          control1Y: 0
          control2X: 0
          control2Y: root.bodyRightInset * (1 - root.curveKappa)
        }
        PathLine {
          x: 0
          y: barJoinShape.height
        }
        PathLine {
          x: 0
          y: 0
        }
      }
    }

    Shape {
      id: bottomFrameJoinShape

      visible: root.backgroundVisible && root.fullFrame && root.cornerPieces && root.bodyRightInset > 0
      width: root.bodyRightInset
      height: root.bodyRightInset
      x: root.panelWidth
      y: Math.max(0, surface.height - root.frameThickness - root.bodyRightInset)
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidPanelColor
        strokeWidth: 0
        startX: 0
        startY: root.bodyRightInset

        PathLine {
          x: root.bodyRightInset
          y: root.bodyRightInset
        }
        PathCubic {
          x: 0
          y: 0
          control1X: root.bodyRightInset * (1 - root.curveKappa)
          control1Y: root.bodyRightInset
          control2X: 0
          control2Y: root.bodyRightInset * (1 - root.curveKappa)
        }
        PathLine {
          x: 0
          y: root.bodyRightInset
        }
      }
    }

    MouseArea {
      x: 0
      y: 0
      width: root.panelWidth
      height: surface.height
      onClicked: function(mouse) {
        mouse.accepted = true
      }
    }

    MouseArea {
      enabled: root.cornerPieces && root.bodyRightInset > 0
      x: root.panelWidth
      y: root.bodyTop
      width: root.bodyRightInset
      height: root.bodyRightInset
      onClicked: function(mouse) {
        mouse.accepted = true
      }
    }

    Item {
      id: contentHost

      x: 0
      y: 0
      width: root.panelWidth
      height: surface.height
    }

  }

  DesignTokens {
    id: fallbackDesignTokens
    foreground: root.foreground
    background: root.panelColor
  }
}
