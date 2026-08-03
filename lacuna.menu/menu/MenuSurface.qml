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
  property string barPosition: "top"
  property bool frameMoldingPieces: true
  property bool frameBorder: false
  property color frameBorderColor: Qt.rgba(1, 1, 1, 1)
  property real frameBorderWidth: 1
  property bool attachedFlyoutVisible: false
  property real attachedFlyoutY: 0
  property real attachedFlyoutHeight: 0
  property real outputScale: 1
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
  readonly property real frameBorderInset: Math.max(0, frameBorderWidth / 2)
  readonly property real frameMoldingBorderWidth: frameBorderWidth + (outputScale <= 1.25 ? 0.5 : 0)
  readonly property real frameBorderRadius: Math.max(0.01, bodyRightInset - frameBorderInset)
  readonly property bool bottomFrameJoinVisible: backgroundVisible && fullFrame
    && barPosition !== "bottom" && frameMoldingPieces && bodyRightInset > 0
  readonly property bool bottomFrameJoinBorderVisible: bottomFrameJoinVisible && frameBorder
  readonly property bool standaloneSidebarBorderVisible: backgroundVisible && frameBorder && !fullFrame
  readonly property real standaloneBorderTop: Math.max(frameBorderInset, joinTop + frameBorderInset)
  readonly property real standaloneBorderRadius: frameMoldingPieces
    ? Math.max(0, bodyRightInset) : 0
  readonly property real standaloneBorderRight: panelWidth - frameBorderInset
  readonly property real standaloneBorderOuterTopX: standaloneBorderRight + standaloneBorderRadius
  readonly property real standaloneBorderBottom: Math.max(standaloneBorderTop, height - frameBorderInset)
  readonly property real standaloneBorderTangentY: standaloneBorderTop + standaloneBorderRadius
  readonly property real standaloneAttachmentGapTop: Math.max(standaloneBorderTangentY, attachedFlyoutY + frameBorderInset)
  readonly property real standaloneAttachmentGapBottom: Math.min(standaloneBorderBottom, attachedFlyoutY + attachedFlyoutHeight - frameBorderInset)
  readonly property bool standaloneAttachmentGapRenderable: attachedFlyoutVisible
    && attachedFlyoutHeight > 0
    && standaloneAttachmentGapBottom > standaloneAttachmentGapTop + frameBorderWidth
  readonly property real standaloneVerticalUpperEnd: standaloneAttachmentGapRenderable
    ? standaloneAttachmentGapTop : standaloneBorderBottom
  readonly property real standaloneVerticalLowerStart: standaloneAttachmentGapRenderable
    ? standaloneAttachmentGapBottom : standaloneBorderBottom

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

      visible: root.backgroundVisible && root.frameMoldingPieces && root.bodyRightInset > 0
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

    // With full-frame paint disabled, paint only the exposed seam owned by the
    // sidebar: its molding curve and vertical content edge. The bar stops at
    // the curve's outer tangent, so neither path continues behind the other.
    Shape {
      id: standaloneSidebarBorderShape

      visible: root.standaloneSidebarBorderVisible && !root.openFromRight
      anchors.fill: parent
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: "transparent"
        strokeColor: root.frameBorderColor
        strokeWidth: root.frameBorderWidth
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.RoundJoin
        startX: root.standaloneBorderOuterTopX
        startY: root.standaloneBorderTop

        PathCubic {
          x: root.standaloneBorderRight
          y: root.standaloneBorderTop + root.standaloneBorderRadius
          control1X: root.standaloneBorderOuterTopX - root.standaloneBorderRadius * root.curveKappa
          control1Y: root.standaloneBorderTop
          control2X: root.standaloneBorderRight
          control2Y: root.standaloneBorderTop + root.standaloneBorderRadius * (1 - root.curveKappa)
        }
        PathLine {
          x: root.standaloneBorderRight
          y: root.standaloneVerticalUpperEnd
        }
        PathMove {
          x: root.standaloneBorderRight
          y: root.standaloneVerticalLowerStart
        }
        PathLine {
          x: root.standaloneBorderRight
          y: root.standaloneBorderBottom
        }
      }
    }

    Shape {
      visible: root.standaloneSidebarBorderVisible && root.openFromRight
      anchors.fill: parent
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: "transparent"
        strokeColor: root.frameBorderColor
        strokeWidth: root.frameBorderWidth
        capStyle: ShapePath.FlatCap
        startX: root.frameBorderInset
        startY: root.standaloneBorderTop

        PathLine {
          x: root.frameBorderInset
          y: root.standaloneVerticalUpperEnd
        }
        PathMove {
          x: root.frameBorderInset
          y: root.standaloneVerticalLowerStart
        }
        PathLine {
          x: root.frameBorderInset
          y: root.standaloneBorderBottom
        }
      }
    }

    Shape {
      id: bottomFrameJoinShape

      visible: root.bottomFrameJoinVisible
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

    // The bar-owned frame border sits below this Overlay surface. Repaint the
    // exposed lower molding curve here so the opaque join fill cannot cover it.
    // Match LacunaFrameBorderWindow exactly: the canonical one-pixel base pass
    // first, followed by the scale-aware optical curve pass.
    Shape {
      id: bottomFrameJoinBorderShape

      visible: root.bottomFrameJoinBorderVisible
      width: root.bodyRightInset
      height: root.bodyRightInset
      x: root.panelWidth
      y: root.bottomJoinTop
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: "transparent"
        strokeColor: root.frameBorderColor
        strokeWidth: root.frameBorderWidth
        capStyle: ShapePath.FlatCap
        startX: root.bodyRightInset
        startY: root.frameBorderRadius

        PathCubic {
          x: root.frameBorderInset
          y: 0
          control1X: root.frameBorderInset + root.frameBorderRadius * (1 - root.curveKappa)
          control1Y: root.frameBorderRadius
          control2X: root.frameBorderInset
          control2Y: root.frameBorderRadius * root.curveKappa
        }
      }

      ShapePath {
        fillColor: "transparent"
        strokeColor: root.frameBorderColor
        strokeWidth: root.frameMoldingBorderWidth
        capStyle: ShapePath.FlatCap
        startX: root.bodyRightInset
        startY: root.frameBorderRadius

        PathCubic {
          x: root.frameBorderInset
          y: 0
          control1X: root.frameBorderInset + root.frameBorderRadius * (1 - root.curveKappa)
          control1Y: root.frameBorderRadius
          control2X: root.frameBorderInset
          control2Y: root.frameBorderRadius * root.curveKappa
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
      enabled: root.frameMoldingPieces && root.bodyRightInset > 0
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
