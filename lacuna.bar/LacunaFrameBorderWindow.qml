import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../lacuna.menu/components"

PanelWindow {
  id: root

  property var targetScreen: null
  property bool active: false
  property string barPosition: "top"
  property int barSize: 0
  property int frameThickness: 8
  property int frameRadius: 14
  property bool cornerPieces: true
  property color borderColor: Qt.rgba(1, 1, 1, 0.18)
  property real borderWidth: 1
  property bool leftEdgeOccupied: false
  property bool rightEdgeOccupied: false
  property real leftOccupiedWidth: 0
  property real rightOccupiedWidth: 0
  property bool attachedFlyoutVisible: false
  property real attachedFlyoutY: 0
  property real attachedFlyoutHeight: 0

  readonly property int t: Math.max(1, frameThickness)
  readonly property int r: Math.max(t, frameRadius)
  readonly property real leftOcclusion: leftEdgeOccupied ? Math.max(0, leftOccupiedWidth) : 0
  readonly property real rightOcclusion: rightEdgeOccupied ? Math.max(0, rightOccupiedWidth) : 0
  readonly property bool topBar: barPosition === "top"
  readonly property bool bottomBar: barPosition === "bottom"
  readonly property bool leftBar: barPosition === "left"
  readonly property bool rightBar: barPosition === "right"
  readonly property int topInset: topBar ? Math.max(0, barSize) : t
  readonly property int bottomInset: bottomBar ? Math.max(0, barSize) : t
  readonly property int leftInset: leftBar ? Math.max(0, barSize) : t
  readonly property int rightInset: rightBar ? Math.max(0, barSize) : t
  readonly property real holeX: Math.max(0, leftEdgeOccupied ? leftOcclusion : leftInset)
  readonly property real holeY: Math.max(0, topInset)
  readonly property real holeRight: Math.max(holeX + 1, width - (rightEdgeOccupied ? rightOcclusion : rightInset))
  readonly property real holeBottom: Math.max(holeY + 1, height - bottomInset)
  readonly property real holeWidth: Math.max(1, holeRight - holeX)
  readonly property real holeHeight: Math.max(1, holeBottom - holeY)
  readonly property real minArcRadius: 0.01
  readonly property real holeRadius: cornerPieces ? Math.max(minArcRadius, Math.min(r, holeWidth / 2, holeHeight / 2)) : minArcRadius
  readonly property real borderInset: Math.max(0, borderWidth / 2)
  readonly property real borderLeft: holeX + borderInset
  readonly property real borderTop: holeY + borderInset
  readonly property real borderRight: holeRight - borderInset
  readonly property real borderBottom: holeBottom - borderInset
  readonly property real borderRadius: Math.max(minArcRadius, holeRadius - borderInset)
  readonly property bool leftAttachmentGapVisible: leftEdgeOccupied && attachedFlyoutVisible && attachedFlyoutHeight > 0
  readonly property bool rightAttachmentGapVisible: rightEdgeOccupied && attachedFlyoutVisible && attachedFlyoutHeight > 0
  readonly property real attachmentGapTop: Math.max(borderTop + borderRadius, attachedFlyoutY - borderInset)
  readonly property real attachmentGapBottom: Math.min(borderBottom - borderRadius, attachedFlyoutY + attachedFlyoutHeight + borderInset)
  readonly property bool attachmentGapRenderable: attachmentGapBottom > attachmentGapTop + borderWidth
  readonly property real rightVerticalUpperEndY: rightAttachmentGapVisible && attachmentGapRenderable ? attachmentGapTop : borderBottom - borderRadius
  readonly property real rightVerticalLowerStartY: rightAttachmentGapVisible && attachmentGapRenderable ? attachmentGapBottom : borderBottom - borderRadius
  readonly property real leftVerticalLowerEndY: leftAttachmentGapVisible && attachmentGapRenderable ? attachmentGapBottom : borderTop + borderRadius
  readonly property real leftVerticalUpperStartY: leftAttachmentGapVisible && attachmentGapRenderable ? attachmentGapTop : borderTop + borderRadius
  readonly property bool isRenderable: active && width > 0 && height > 0 && holeWidth > 0 && holeHeight > 0
  readonly property real curveKappa: lacunaGeometry.curveKappa

  LacunaGeometry { id: lacunaGeometry }

  visible: active
  screen: targetScreen
  color: "transparent"
  WlrLayershell.namespace: "lacuna-bar-frame-border"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: Region {}

  Shape {
    id: frameBorderSource

    anchors.fill: parent
    visible: root.isRenderable
    asynchronous: false
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.borderColor
      strokeWidth: root.borderWidth
      capStyle: ShapePath.FlatCap
      joinStyle: ShapePath.RoundJoin
      startX: root.borderLeft + root.borderRadius
      startY: root.borderTop

      PathLine {
        x: root.borderRight - root.borderRadius
        y: root.borderTop
      }
      PathCubic {
        x: root.borderRight
        y: root.borderTop + root.borderRadius
        control1X: root.borderRight - root.borderRadius * (1 - root.curveKappa)
        control1Y: root.borderTop
        control2X: root.borderRight
        control2Y: root.borderTop + root.borderRadius * (1 - root.curveKappa)
      }
      PathLine {
        x: root.borderRight
        y: root.rightVerticalUpperEndY
      }
      PathMove {
        x: root.borderRight
        y: root.rightVerticalLowerStartY
      }
      PathCubic {
        x: root.borderRight - root.borderRadius
        y: root.borderBottom
        control1X: root.borderRight
        control1Y: root.borderBottom - root.borderRadius * (1 - root.curveKappa)
        control2X: root.borderRight - root.borderRadius * (1 - root.curveKappa)
        control2Y: root.borderBottom
      }
      PathLine {
        x: root.borderLeft + root.borderRadius
        y: root.borderBottom
      }
      PathCubic {
        x: root.borderLeft
        y: root.borderBottom - root.borderRadius
        control1X: root.borderLeft + root.borderRadius * (1 - root.curveKappa)
        control1Y: root.borderBottom
        control2X: root.borderLeft
        control2Y: root.borderBottom - root.borderRadius * (1 - root.curveKappa)
      }
      PathLine {
        x: root.borderLeft
        y: root.leftVerticalLowerEndY
      }
      PathMove {
        x: root.borderLeft
        y: root.leftVerticalUpperStartY
      }
      PathCubic {
        x: root.borderLeft + root.borderRadius
        y: root.borderTop
        control1X: root.borderLeft
        control1Y: root.borderTop + root.borderRadius * (1 - root.curveKappa)
        control2X: root.borderLeft + root.borderRadius * (1 - root.curveKappa)
        control2Y: root.borderTop
      }
    }
  }
}
