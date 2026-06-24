import QtQuick
import QtQuick.Shapes
import "../components"

Item {
  id: root

  property bool active: false
  property bool connectorVisible: false
  property bool flyoutVisible: false
  property bool openToLeft: false
  property real connectorX: 0
  property real connectorY: 0
  property real connectorWidth: 0
  property real flyoutX: 0
  property real flyoutY: 0
  property real flyoutWidth: 0
  property real flyoutHeight: 0
  property real panelRadius: 14
  property color borderColor: Qt.rgba(1, 1, 1, 0.18)
  property real borderWidth: 1

  readonly property real curveKappa: lacunaGeometry.curveKappa
  readonly property real borderInset: Math.max(0, borderWidth / 2)
  readonly property real visibleFlyoutWidth: Math.max(0, flyoutWidth)
  readonly property real visibleFlyoutHeight: Math.max(0, flyoutHeight)
  readonly property real strokeLeft: flyoutX + borderInset
  readonly property real strokeTop: flyoutY + borderInset
  readonly property real strokeRight: flyoutX + visibleFlyoutWidth - borderInset
  readonly property real strokeBottom: flyoutY + visibleFlyoutHeight - borderInset
  readonly property real strokeRadius: Math.max(0.01, Math.min(panelRadius, visibleFlyoutWidth / 2, visibleFlyoutHeight / 2) - borderInset)
  readonly property real effectiveConnectorWidth: connectorVisible ? Math.max(0, connectorWidth) : 0
  readonly property real outlineLeft: connectorVisible ? flyoutX : strokeLeft
  readonly property real outlineTop: connectorVisible ? flyoutY : strokeTop
  readonly property real outlineRight: connectorVisible ? flyoutX + visibleFlyoutWidth : strokeRight
  readonly property real outlineBottom: connectorVisible ? flyoutY + visibleFlyoutHeight : strokeBottom
  readonly property real outlineRadius: connectorVisible
    ? Math.max(0.01, Math.min(panelRadius, visibleFlyoutWidth / 2, visibleFlyoutHeight / 2))
    : strokeRadius
  readonly property bool renderable: active && flyoutVisible && visibleFlyoutWidth > 0 && visibleFlyoutHeight > 0

  LacunaGeometry { id: lacunaGeometry }

  visible: renderable
  enabled: false

  Shape {
    anchors.fill: parent
    visible: root.renderable && !root.openToLeft
    asynchronous: false
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.borderColor
      strokeWidth: root.borderWidth
      capStyle: ShapePath.FlatCap
      joinStyle: ShapePath.RoundJoin
      startX: root.connectorVisible
        ? root.connectorX
        : root.strokeLeft
      startY: root.connectorVisible
        ? root.connectorY
        : root.strokeTop

      PathCubic {
        x: root.outlineLeft
        y: root.outlineTop
        control1X: root.connectorVisible ? root.connectorX : root.outlineLeft
        control1Y: root.connectorVisible ? root.connectorY + root.effectiveConnectorWidth * root.curveKappa : root.outlineTop
        control2X: root.connectorVisible ? root.connectorX + root.effectiveConnectorWidth * (1 - root.curveKappa) : root.outlineLeft
        control2Y: root.outlineTop
      }
      PathLine {
        x: root.outlineRight - root.outlineRadius
        y: root.outlineTop
      }
      PathCubic {
        x: root.outlineRight
        y: root.outlineTop + root.outlineRadius
        control1X: root.outlineRight - root.outlineRadius * (1 - root.curveKappa)
        control1Y: root.outlineTop
        control2X: root.outlineRight
        control2Y: root.outlineTop + root.outlineRadius * (1 - root.curveKappa)
      }
      PathLine {
        x: root.outlineRight
        y: root.outlineBottom - root.outlineRadius
      }
      PathCubic {
        x: root.outlineRight - root.outlineRadius
        y: root.outlineBottom
        control1X: root.outlineRight
        control1Y: root.outlineBottom - root.outlineRadius * (1 - root.curveKappa)
        control2X: root.outlineRight - root.outlineRadius * (1 - root.curveKappa)
        control2Y: root.outlineBottom
      }
      PathLine {
        x: root.outlineLeft
        y: root.outlineBottom
      }
      PathCubic {
        x: root.connectorVisible
          ? root.connectorX
          : root.outlineLeft
        y: root.connectorVisible
          ? root.connectorY + root.effectiveConnectorWidth + root.visibleFlyoutHeight
          : root.outlineBottom
        control1X: root.connectorVisible ? root.connectorX + root.effectiveConnectorWidth * (1 - root.curveKappa) : root.outlineLeft
        control1Y: root.outlineBottom
        control2X: root.connectorVisible ? root.connectorX : root.outlineLeft
        control2Y: root.connectorVisible ? root.connectorY + root.effectiveConnectorWidth + root.visibleFlyoutHeight + root.effectiveConnectorWidth * (1 - root.curveKappa) : root.outlineBottom
      }
    }
  }
}
