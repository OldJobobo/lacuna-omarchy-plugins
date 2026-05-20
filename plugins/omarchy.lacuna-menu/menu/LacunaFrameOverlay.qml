import QtQuick
import QtQuick.Shapes
import "../components"

Item {
  id: root

  property string mode: "off"
  property bool shadowEnabled: false
  property string barPosition: "top"
  property int barSize: 0
  property int barBottomY: 0
  property real frameWidth: 0
  property int frameThickness: 8
  property int frameRadius: 14
  property real progress: 1
  property color frameColor: "#101315"
  property color shadowColor: "black"
  property real shadowOpacity: 0.55
  property real shadowBlur: 1.0
  property int shadowBlurMax: 22
  property real shadowOffsetX: 2
  property real shadowOffsetY: 3

  property real sidebarX: 0
  property real sidebarY: 0
  property real sidebarWidth: 0
  property real sidebarHeight: 0
  property real sidebarCornerWidth: 0
  property bool sidebarCornerVisible: false
  property bool leftEdgeOccupied: true
  property bool rightEdgeOccupied: false

  property real connectorX: 0
  property real connectorY: 0
  property real connectorWidth: 0
  property real connectorHeight: 0
  property bool connectorVisible: false

  property real flyoutX: 0
  property real flyoutY: 0
  property real flyoutWidth: 0
  property real flyoutHeight: 0
  property bool flyoutVisible: false

  readonly property bool frameEnabled: mode === "sidebar" || mode === "fullframe"
  readonly property bool fullFrame: mode === "fullframe"
  readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
  readonly property int t: Math.max(1, frameThickness)
  readonly property int effectiveBarSize: Math.max(0, barSize)
  readonly property real effectiveFrameWidth: frameWidth > 0 ? frameWidth : width
  readonly property bool topBar: barPosition === "top"
  readonly property bool bottomBar: barPosition === "bottom"
  readonly property bool leftBar: barPosition === "left"
  readonly property bool rightBar: barPosition === "right"
  readonly property real curveKappa: 0.5522847498
  readonly property real cornerSize: Math.max(t, sidebarCornerWidth)
  readonly property real shadowExtent: Math.max(14, shadowBlurMax + Math.max(Math.abs(shadowOffsetX), Math.abs(shadowOffsetY)))
  readonly property real barEdgeCasterSize: 3
  readonly property real barEdgeCasterOverrun: 100
  readonly property real topOccupiedInset: shadowEnabled && topBar ? barEdgeCasterSize : 0
  readonly property real barEdgeShadowOpacity: Math.min(1, shadowOpacity * 1.55)
  readonly property real sidebarJoinTop: Math.max(-sidebarCornerWidth, barBottomY + topOccupiedInset - 1)
  readonly property real sidebarJoinHeight: Math.max(0, sidebarHeight - sidebarJoinTop)

  visible: frameEnabled && clampedProgress > 0.001
  enabled: false
  opacity: clampedProgress

    Item {
      id: frameSource

      anchors.fill: parent
      z: 1

      Rectangle {
        visible: root.shadowEnabled && root.topBar && root.effectiveBarSize > 0
        x: 0
        y: root.barBottomY - root.effectiveBarSize
        width: root.effectiveFrameWidth
        height: root.effectiveBarSize
        color: root.frameColor
      }

      Rectangle {
        visible: root.shadowEnabled && root.bottomBar && root.effectiveBarSize > 0
        x: 0
        y: parent.height - root.barBottomY
        width: root.effectiveFrameWidth
        height: root.effectiveBarSize
        color: root.frameColor
      }

      Rectangle {
        visible: root.shadowEnabled && root.leftBar && root.effectiveBarSize > 0
        x: -root.effectiveBarSize
        y: 0
        width: root.effectiveBarSize
        height: parent.height
        color: root.frameColor
      }

      Rectangle {
        visible: root.shadowEnabled && root.rightBar && root.effectiveBarSize > 0
        x: root.effectiveFrameWidth
        y: 0
        width: root.effectiveBarSize
        height: parent.height
        color: root.frameColor
      }

      Rectangle {
        visible: root.fullFrame && !root.topBar
      x: 0
      y: 0
      width: root.effectiveFrameWidth
      height: root.t
      color: root.frameColor
    }

    Rectangle {
      visible: root.fullFrame && !root.bottomBar
      x: 0
      y: Math.max(0, parent.height - root.t)
      width: root.effectiveFrameWidth
      height: root.t
      color: root.frameColor
    }

    Rectangle {
      visible: root.fullFrame && !root.leftBar && !root.leftEdgeOccupied
      x: 0
      y: 0
      width: root.t
      height: parent.height
      color: root.frameColor
    }

    Rectangle {
      visible: root.fullFrame && !root.rightBar && !root.rightEdgeOccupied
      x: Math.max(0, root.effectiveFrameWidth - root.t)
      y: 0
      width: root.t
      height: parent.height
      color: root.frameColor
    }

    Shape {
      id: fullFrameTopRightCorner

      visible: root.fullFrame && root.topBar && !root.rightBar && !root.rightEdgeOccupied && root.cornerSize > 0
      x: root.effectiveFrameWidth - root.t - root.cornerSize
      y: root.topOccupiedInset
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.frameColor
        strokeWidth: 0
        startX: root.cornerSize
        startY: 0

        PathLine {
          x: root.cornerSize
          y: root.cornerSize
        }
        PathCubic {
          x: 0
          y: 0
          control1X: root.cornerSize
          control1Y: root.cornerSize * (1 - root.curveKappa)
          control2X: root.cornerSize * (1 - root.curveKappa)
          control2Y: 0
        }
        PathLine {
          x: root.cornerSize
          y: 0
        }
      }
    }

    Shape {
      id: fullFrameBottomRightCorner

      visible: root.fullFrame && !root.bottomBar && !root.rightBar && !root.rightEdgeOccupied && root.cornerSize > 0
      x: root.effectiveFrameWidth - root.t - root.cornerSize
      y: parent.height - root.t - root.cornerSize
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.frameColor
        strokeWidth: 0
        startX: root.cornerSize
        startY: root.cornerSize

        PathLine {
          x: 0
          y: root.cornerSize
        }
        PathCubic {
          x: root.cornerSize
          y: 0
          control1X: root.cornerSize * (1 - root.curveKappa)
          control1Y: root.cornerSize
          control2X: root.cornerSize
          control2Y: root.cornerSize * (1 - root.curveKappa)
        }
        PathLine {
          x: root.cornerSize
          y: root.cornerSize
        }
      }
    }

    Shape {
      id: fullFrameBottomLeftCorner

      visible: root.fullFrame && !root.bottomBar && root.leftEdgeOccupied && root.sidebarCornerVisible && root.cornerSize > 0
      x: root.sidebarX + root.sidebarWidth
      y: parent.height - root.t - root.cornerSize
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.frameColor
        strokeWidth: 0
        startX: 0
        startY: root.cornerSize

        PathLine {
          x: root.cornerSize
          y: root.cornerSize
        }
        PathCubic {
          x: 0
          y: 0
          control1X: root.cornerSize * (1 - root.curveKappa)
          control1Y: root.cornerSize
          control2X: 0
          control2Y: root.cornerSize * (1 - root.curveKappa)
        }
        PathLine {
          x: 0
          y: root.cornerSize
        }
      }
    }

    Rectangle {
      id: sidebarSilhouette

      x: root.sidebarX
      y: root.sidebarY
      width: Math.max(0, root.sidebarWidth)
      height: Math.max(0, root.sidebarHeight)
      color: root.frameColor
    }

    Shape {
      id: sidebarCornerPiece

      visible: root.sidebarCornerVisible && root.sidebarCornerWidth > 0 && root.sidebarJoinHeight > 0
      x: root.sidebarX + root.sidebarWidth
      y: root.sidebarY + root.sidebarJoinTop
      width: root.sidebarCornerWidth
      height: root.sidebarJoinHeight
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.frameColor
        strokeWidth: 0
        startX: 0
        startY: 0

        PathLine {
          x: root.sidebarCornerWidth
          y: 0
        }
        PathCubic {
          x: 0
          y: root.sidebarCornerWidth
          control1X: root.sidebarCornerWidth * (1 - root.curveKappa)
          control1Y: 0
          control2X: 0
          control2Y: root.sidebarCornerWidth * (1 - root.curveKappa)
        }
        PathLine {
          x: 0
          y: sidebarCornerPiece.height
        }
        PathLine {
          x: 0
          y: 0
        }
      }
    }

    Item {
      id: connectorSilhouette

      visible: root.connectorVisible
      x: root.connectorX
      y: root.connectorY
      width: Math.max(0, root.connectorWidth)
      height: Math.max(0, root.connectorHeight)

      Rectangle {
        x: 0
        y: root.connectorWidth
        width: parent.width + 1
        height: Math.max(0, parent.height - root.connectorWidth * 2)
        color: root.frameColor
      }

      Shape {
        width: root.connectorWidth
        height: root.connectorWidth
        asynchronous: false
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          fillColor: root.frameColor
          strokeWidth: 0
          startX: 0
          startY: root.connectorWidth

          PathLine {
            x: root.connectorWidth
            y: root.connectorWidth
          }
          PathCubic {
            x: 0
            y: 0
            control1X: root.connectorWidth * (1 - root.curveKappa)
            control1Y: root.connectorWidth
            control2X: 0
            control2Y: root.connectorWidth * root.curveKappa
          }
          PathLine {
            x: 0
            y: root.connectorWidth
          }
        }
      }

      Shape {
        y: parent.height - root.connectorWidth
        width: root.connectorWidth
        height: root.connectorWidth
        asynchronous: false
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          fillColor: root.frameColor
          strokeWidth: 0
          startX: 0
          startY: 0

          PathLine {
            x: root.connectorWidth
            y: 0
          }
          PathCubic {
            x: 0
            y: root.connectorWidth
            control1X: root.connectorWidth * (1 - root.curveKappa)
            control1Y: 0
            control2X: 0
            control2Y: root.connectorWidth * (1 - root.curveKappa)
          }
          PathLine {
            x: 0
            y: 0
          }
        }
      }
    }

    LacunaShapeSurface {
      id: flyoutSilhouette

      visible: root.flyoutVisible
      x: root.flyoutX
      y: root.flyoutY
      width: Math.max(0, root.flyoutWidth)
      height: Math.max(0, root.flyoutHeight)
      panelColor: root.frameColor
      panelRadius: Math.max(0, root.frameRadius)
      topLeftCornerState: -1
      bottomLeftCornerState: -1
      topRightCornerState: 0
      bottomRightCornerState: 0
    }
  }

  LacunaDropShadow {
    source: frameSource
    shadowEnabled: root.shadowEnabled
    shadowColor: root.shadowColor
    shadowOpacity: root.shadowOpacity
    shadowBlur: root.shadowBlur
    blurMax: root.shadowBlurMax
    shadowHorizontalOffset: root.shadowOffsetX
    shadowVerticalOffset: root.shadowOffsetY
    z: -2
  }

  Item {
    id: barEdgeShadowSource

    anchors.fill: parent
    visible: root.shadowEnabled
    z: -3

    Rectangle {
      visible: root.topBar
      x: 0
      y: Math.max(0, root.barBottomY)
      width: root.effectiveFrameWidth + root.barEdgeCasterOverrun
      height: root.barEdgeCasterSize
      color: root.frameColor
    }

    Rectangle {
      visible: root.bottomBar
      x: 0
      y: Math.max(0, parent.height - root.barEdgeCasterSize)
      width: root.effectiveFrameWidth + root.barEdgeCasterOverrun
      height: root.barEdgeCasterSize
      color: root.frameColor
    }

    Rectangle {
      visible: root.leftBar
      x: 0
      y: 0
      width: root.barEdgeCasterSize
      height: parent.height
      color: root.frameColor
    }

    Rectangle {
      visible: root.rightBar
      x: Math.max(0, root.effectiveFrameWidth - root.barEdgeCasterSize)
      y: 0
      width: root.barEdgeCasterSize
      height: parent.height
      color: root.frameColor
    }
  }

  LacunaDropShadow {
    source: barEdgeShadowSource
    shadowEnabled: root.shadowEnabled
    shadowColor: root.shadowColor
    shadowOpacity: root.barEdgeShadowOpacity
    shadowBlur: root.shadowBlur
    blurMax: root.shadowBlurMax
    shadowHorizontalOffset: root.shadowOffsetX
    shadowVerticalOffset: root.shadowOffsetY
    z: -1
  }
}
