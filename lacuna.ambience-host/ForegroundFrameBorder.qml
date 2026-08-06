import QtQuick
import QtQuick.Shapes

// Repaints the authoritative frame border after foreground ambience. The
// source is the live border item owned by the bar or hosted menu, so sidebar
// motion, flyout gaps, output scale, and frame transitions share one clock.
Item {
  id: root

  property var bridge: null
  property bool paintEnabled: false
  readonly property var source: bridge && bridge.borderSource ? bridge.borderSource : null
  readonly property real offsetX: bridge ? Number(bridge.offsetX || 0) : 0
  readonly property real offsetY: bridge ? Number(bridge.offsetY || 0) : 0
  readonly property bool renderable: paintEnabled && source && source.visible === true
  readonly property real edgeLeft: offsetX + (source ? Number(source.borderLeft || 0) : 0)
  readonly property real edgeTop: offsetY + (source ? Number(source.borderTop || 0) : 0)
  readonly property real edgeRight: offsetX + (source ? Number(source.borderRight || 0) : 0)
  readonly property real edgeBottom: offsetY + (source ? Number(source.borderBottom || 0) : 0)
  readonly property real radius: source ? Number(source.borderRadius || 0.01) : 0.01
  readonly property real upperRightEnd: offsetY + (source ? Number(source.rightVerticalUpperEndY || 0) : 0)
  readonly property real lowerRightStart: offsetY + (source ? Number(source.rightVerticalLowerStartY || 0) : 0)
  readonly property real lowerLeftEnd: offsetY + (source ? Number(source.leftVerticalLowerEndY || 0) : 0)
  readonly property real upperLeftStart: offsetY + (source ? Number(source.leftVerticalUpperStartY || 0) : 0)
  readonly property real kappa: source ? Number(source.curveKappa || 0) : 0

  visible: renderable
  enabled: false

  Shape {
    id: frameBorderSource

    anchors.fill: parent
    visible: root.renderable
    asynchronous: false
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.source ? root.source.borderColor : "transparent"
      strokeWidth: root.source ? root.source.borderWidth : 1
      capStyle: ShapePath.FlatCap
      joinStyle: ShapePath.RoundJoin
      startX: root.edgeLeft + root.radius
      startY: root.edgeTop

      PathLine { x: root.edgeRight - root.radius; y: root.edgeTop }
      PathCubic {
        x: root.edgeRight; y: root.edgeTop + root.radius
        control1X: root.edgeRight - root.radius * (1 - root.kappa); control1Y: root.edgeTop
        control2X: root.edgeRight; control2Y: root.edgeTop + root.radius * (1 - root.kappa)
      }
      PathLine { x: root.edgeRight; y: root.upperRightEnd }
      PathMove { x: root.edgeRight; y: root.lowerRightStart }
      PathLine { x: root.edgeRight; y: root.edgeBottom - root.radius }
      PathCubic {
        x: root.edgeRight - root.radius; y: root.edgeBottom
        control1X: root.edgeRight; control1Y: root.edgeBottom - root.radius * (1 - root.kappa)
        control2X: root.edgeRight - root.radius * (1 - root.kappa); control2Y: root.edgeBottom
      }
      PathLine { x: root.edgeLeft + root.radius; y: root.edgeBottom }
      PathCubic {
        x: root.edgeLeft; y: root.edgeBottom - root.radius
        control1X: root.edgeLeft + root.radius * (1 - root.kappa); control1Y: root.edgeBottom
        control2X: root.edgeLeft; control2Y: root.edgeBottom - root.radius * (1 - root.kappa)
      }
      PathLine { x: root.edgeLeft; y: root.lowerLeftEnd }
      PathMove { x: root.edgeLeft; y: root.upperLeftStart }
      PathLine { x: root.edgeLeft; y: root.edgeTop + root.radius }
      PathCubic {
        x: root.edgeLeft + root.radius; y: root.edgeTop
        control1X: root.edgeLeft; control1Y: root.edgeTop + root.radius * (1 - root.kappa)
        control2X: root.edgeLeft + root.radius * (1 - root.kappa); control2Y: root.edgeTop
      }
    }

    // Match the source renderer's optical allowance on curved corners.
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.source ? root.source.borderColor : "transparent"
      strokeWidth: root.source ? root.source.moldingBorderWidth : 1
      capStyle: ShapePath.FlatCap

      startX: root.edgeRight - root.radius; startY: root.edgeTop
      PathCubic {
        x: root.edgeRight; y: root.edgeTop + root.radius
        control1X: root.edgeRight - root.radius * (1 - root.kappa); control1Y: root.edgeTop
        control2X: root.edgeRight; control2Y: root.edgeTop + root.radius * (1 - root.kappa)
      }
      PathMove { x: root.edgeRight; y: root.edgeBottom - root.radius }
      PathCubic {
        x: root.edgeRight - root.radius; y: root.edgeBottom
        control1X: root.edgeRight; control1Y: root.edgeBottom - root.radius * (1 - root.kappa)
        control2X: root.edgeRight - root.radius * (1 - root.kappa); control2Y: root.edgeBottom
      }
      PathMove { x: root.edgeLeft + root.radius; y: root.edgeBottom }
      PathCubic {
        x: root.edgeLeft; y: root.edgeBottom - root.radius
        control1X: root.edgeLeft + root.radius * (1 - root.kappa); control1Y: root.edgeBottom
        control2X: root.edgeLeft; control2Y: root.edgeBottom - root.radius * (1 - root.kappa)
      }
      PathMove { x: root.edgeLeft; y: root.edgeTop + root.radius }
      PathCubic {
        x: root.edgeLeft + root.radius; y: root.edgeTop
        control1X: root.edgeLeft; control1Y: root.edgeTop + root.radius * (1 - root.kappa)
        control2X: root.edgeLeft + root.radius * (1 - root.kappa); control2Y: root.edgeTop
      }
    }
  }
}
