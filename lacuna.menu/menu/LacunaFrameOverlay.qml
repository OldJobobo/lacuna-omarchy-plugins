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
  property int joinRadius: frameRadius
  property bool cornerPieces: true
  property real progress: 1
  property color frameColor: "#101315"
  property color shadowColor: "black"
  property real shadowOpacity: 0.88
  property real shadowBlur: 0.85
  property int shadowBlurMax: 28
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

  readonly property bool frameEnabled: mode === "fullframe"
  readonly property bool fullFrame: mode === "fullframe"
  readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
  readonly property real edgeProgress: smoothEdgeProgress(clampedProgress)
  readonly property int t: Math.max(1, frameThickness)
  readonly property int effectiveBarSize: Math.max(0, barSize)
  readonly property real effectiveFrameWidth: frameWidth > 0 ? frameWidth : width
  readonly property bool topBar: barPosition === "top"
  readonly property bool bottomBar: barPosition === "bottom"
  readonly property bool leftBar: barPosition === "left"
  readonly property bool rightBar: barPosition === "right"
  readonly property real curveKappa: lacunaGeometry.curveKappa

  LacunaGeometry { id: lacunaGeometry }
  readonly property real cornerSize: Math.max(t, joinRadius)
  readonly property real frameAlpha: Math.max(0, Math.min(1, frameColor.a === undefined ? 1 : frameColor.a))
  readonly property color solidFrameColor: Qt.rgba(frameColor.r, frameColor.g, frameColor.b, 1)
  readonly property real shadowAlphaCompensation: frameAlpha > 0 ? Math.min(2.5, 1 / Math.max(0.4, frameAlpha)) : 1
  readonly property real shadowExtent: Math.max(14, shadowBlurMax + Math.max(Math.abs(shadowOffsetX), Math.abs(shadowOffsetY)))
  property real barEdgeCasterSize: frameThickness
  readonly property real barEdgeCasterOverrun: 100
  readonly property real barEdgeShadowOpacity: Math.min(1, shadowOpacity * 1.35)
  readonly property real surfaceShadowOpacity: Math.min(1, shadowOpacity * 0.42)
  readonly property real surfaceShadowSize: Math.max(12, Math.min(34, shadowExtent))
  readonly property bool sidebarOnRight: rightEdgeOccupied && !leftEdgeOccupied
  readonly property real sidebarOccupiedWidth: sidebarWidth + (sidebarCornerVisible ? sidebarCornerWidth : 0)
  readonly property real horizontalBarShadowX: leftEdgeOccupied ? Math.max(0, sidebarX + sidebarOccupiedWidth) : 0
  readonly property real horizontalBarShadowRightInset: rightEdgeOccupied ? Math.max(0, effectiveFrameWidth - sidebarX + (sidebarCornerVisible ? sidebarCornerWidth : 0)) : 0
  readonly property real horizontalBarShadowWidth: Math.max(0, effectiveFrameWidth - horizontalBarShadowX - horizontalBarShadowRightInset + barEdgeCasterOverrun)
  readonly property real sidebarJoinTop: Math.max(-sidebarCornerWidth, barBottomY - 1)
  readonly property real sidebarJoinHeight: Math.max(0, sidebarHeight - sidebarJoinTop)

  visible: frameEnabled && clampedProgress > 0.001
  enabled: false

  function smoothEdgeProgress(value) {
    var p = Math.max(0, Math.min(1, value))
    return p * p * p * (p * (p * 6 - 15) + 10)
  }

  Item {
    id: frameSource

    anchors.fill: parent
    z: 1

    Rectangle {
      visible: root.fullFrame && !root.topBar
      x: 0
      y: -root.t + root.t * root.edgeProgress
      width: root.effectiveFrameWidth
      height: root.t
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Rectangle {
      visible: root.fullFrame && !root.bottomBar
      x: 0
      y: parent.height - root.t * root.edgeProgress
      width: root.effectiveFrameWidth
      height: root.t
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Rectangle {
      visible: root.fullFrame && !root.leftBar && !root.leftEdgeOccupied
      x: -root.t + root.t * root.edgeProgress
      y: 0
      width: root.t
      height: parent.height
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Shape {
      id: fullFrameTopLeftCorner

      visible: root.fullFrame && root.cornerPieces && root.topBar && !root.leftBar && !root.leftEdgeOccupied && root.cornerSize > 0
      x: -root.cornerSize + (root.t + root.cornerSize) * root.edgeProgress
      y: root.barBottomY
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
        strokeWidth: 0
        startX: 0
        startY: 0

        PathLine {
          x: 0
          y: root.cornerSize
        }
        PathCubic {
          x: root.cornerSize
          y: 0
          control1X: 0
          control1Y: root.cornerSize * (1 - root.curveKappa)
          control2X: root.cornerSize * root.curveKappa
          control2Y: 0
        }
        PathLine {
          x: 0
          y: 0
        }
      }
    }

    Rectangle {
      visible: root.fullFrame && !root.rightBar && !root.rightEdgeOccupied
      x: root.effectiveFrameWidth - root.t * root.edgeProgress
      y: 0
      width: root.t
      height: parent.height
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Shape {
      id: fullFrameTopRightCorner

      visible: root.fullFrame && root.cornerPieces && root.topBar && !root.rightBar && !root.rightEdgeOccupied && root.cornerSize > 0
      x: root.effectiveFrameWidth - (root.t + root.cornerSize) * root.edgeProgress
      y: root.barBottomY
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
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

      visible: root.fullFrame && root.cornerPieces && !root.bottomBar && !root.rightBar && !root.rightEdgeOccupied && root.cornerSize > 0
      x: root.effectiveFrameWidth - (root.t + root.cornerSize) * root.edgeProgress
      y: parent.height - (root.t + root.cornerSize) * root.edgeProgress
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
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

      visible: root.fullFrame && root.cornerPieces && !root.bottomBar && root.leftEdgeOccupied && root.sidebarCornerVisible && root.cornerSize > 0
      x: root.sidebarX + root.sidebarWidth
      y: parent.height - (root.t + root.cornerSize) * root.edgeProgress
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
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

    Shape {
      id: fullFrameBottomLeftEdgeCorner

      visible: root.fullFrame && root.cornerPieces && !root.bottomBar && !root.leftBar && !root.leftEdgeOccupied && root.cornerSize > 0
      x: -root.cornerSize + (root.t + root.cornerSize) * root.edgeProgress
      y: parent.height - (root.t + root.cornerSize) * root.edgeProgress
      width: root.cornerSize
      height: root.cornerSize
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
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

  }

  LacunaDropShadow {
    source: frameSource
    shadowEnabled: root.shadowEnabled
    shadowColor: root.shadowColor
    shadowOpacity: root.shadowOpacity * root.shadowAlphaCompensation
    shadowBlur: root.shadowBlur
    blurMax: root.shadowBlurMax
    shadowHorizontalOffset: root.shadowOffsetX
    shadowVerticalOffset: root.shadowOffsetY
    z: -2
  }

  Item {
    id: surfaceShadowLayer

    anchors.fill: parent
    visible: root.shadowEnabled
    z: -1

    Rectangle {
      visible: root.sidebarWidth > 0 && root.sidebarHeight > 0 && !root.sidebarOnRight
      x: root.sidebarX + root.sidebarWidth - root.sidebarWidth * (1 - root.edgeProgress)
      y: root.sidebarY
      width: root.surfaceShadowSize
      height: root.sidebarHeight
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.surfaceShadowOpacity) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
      }
    }

    Rectangle {
      visible: root.sidebarWidth > 0 && root.sidebarHeight > 0 && root.sidebarOnRight
      x: root.sidebarX - root.surfaceShadowSize + root.sidebarWidth * (1 - root.edgeProgress)
      y: root.sidebarY
      width: root.surfaceShadowSize
      height: root.sidebarHeight
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.surfaceShadowOpacity) }
      }
    }

    Rectangle {
      visible: root.connectorVisible && root.connectorWidth > 0 && root.connectorHeight > 0 && !root.sidebarOnRight
      x: root.connectorX + root.connectorWidth
      y: root.connectorY
      width: root.surfaceShadowSize
      height: root.connectorHeight
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.surfaceShadowOpacity * 0.82) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
      }
    }

    Rectangle {
      visible: root.flyoutVisible && root.flyoutWidth > 0 && root.flyoutHeight > 0
      x: root.flyoutX + root.flyoutWidth
      y: root.flyoutY
      width: root.surfaceShadowSize
      height: root.flyoutHeight
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.surfaceShadowOpacity) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
      }
    }

    Rectangle {
      visible: root.flyoutVisible && root.flyoutWidth > 0 && root.flyoutHeight > 0
      x: root.flyoutX
      y: root.flyoutY + root.flyoutHeight
      width: root.flyoutWidth + root.surfaceShadowSize
      height: root.surfaceShadowSize
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.surfaceShadowOpacity * 0.86) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
      }
    }
  }

  Item {
    id: barEdgeShadowLayer

    anchors.fill: parent
    visible: root.shadowEnabled
    z: -1

    Rectangle {
      visible: root.topBar && root.horizontalBarShadowWidth > 0
      x: root.horizontalBarShadowX
      y: root.barBottomY
      width: root.horizontalBarShadowWidth
      height: root.barEdgeCasterSize * root.edgeProgress
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.66) }
        GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.32) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
      }
    }

    Rectangle {
      visible: root.bottomBar && root.horizontalBarShadowWidth > 0
      x: root.horizontalBarShadowX
      y: parent.height - root.barEdgeCasterSize * root.edgeProgress
      width: root.horizontalBarShadowWidth
      height: root.barEdgeCasterSize
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
        GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.24) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.52) }
      }
    }

    Rectangle {
      visible: root.leftBar
      x: -root.barEdgeCasterSize + root.barEdgeCasterSize * root.edgeProgress
      y: 0
      width: root.barEdgeCasterSize
      height: parent.height
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.52) }
        GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.24) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
      }
    }

    Rectangle {
      visible: root.rightBar
      x: root.effectiveFrameWidth - root.barEdgeCasterSize * root.edgeProgress
      y: 0
      width: root.barEdgeCasterSize
      height: parent.height
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
        GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.24) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.barEdgeShadowOpacity * 0.52) }
      }
    }
  }
}
