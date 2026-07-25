import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property int panelWidth: 344
  property int panelHeight: 420
  property int joinRadius: 13
  property int cornerRadius: 14
  property color panelColor: "#101315"
  property string attachmentEdge: "top"

  LacunaGeometry { id: lacunaGeometry }
  readonly property real curveKappa: lacunaGeometry.curveKappa
  readonly property bool horizontalAttachment: attachmentEdge === "top" || attachmentEdge === "bottom"
  readonly property int fullWidth: panelWidth + (horizontalAttachment ? joinRadius * 2 : joinRadius)
  readonly property int fullHeight: panelHeight + (horizontalAttachment ? joinRadius : joinRadius * 2)
  readonly property int panelLeft: attachmentEdge === "left" ? joinRadius : (horizontalAttachment ? joinRadius : 0)
  readonly property int panelTop: attachmentEdge === "top" ? joinRadius : (horizontalAttachment ? 0 : joinRadius)
  readonly property int panelRight: panelLeft + panelWidth
  readonly property int panelBottom: panelTop + panelHeight

  implicitWidth: fullWidth
  implicitHeight: fullHeight

  Shape {
    anchors.fill: parent
    visible: root.attachmentEdge === "top"
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: root.panelColor; strokeWidth: 0; startX: 0; startY: 0
      PathLine { x: root.fullWidth; y: 0 }
      PathCubic {
        x: root.panelRight; y: root.panelTop
        control1X: root.fullWidth - root.joinRadius * root.curveKappa; control1Y: 0
        control2X: root.panelRight; control2Y: root.joinRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.panelRight; y: root.panelBottom - root.cornerRadius }
      PathCubic {
        x: root.panelRight - root.cornerRadius; y: root.panelBottom
        control1X: root.panelRight; control1Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
        control2X: root.panelRight - root.cornerRadius * (1 - root.curveKappa); control2Y: root.panelBottom
      }
      PathLine { x: root.panelLeft + root.cornerRadius; y: root.panelBottom }
      PathCubic {
        x: root.panelLeft; y: root.panelBottom - root.cornerRadius
        control1X: root.panelLeft + root.cornerRadius * (1 - root.curveKappa); control1Y: root.panelBottom
        control2X: root.panelLeft; control2Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.panelLeft; y: root.panelTop }
      PathCubic {
        x: 0; y: 0
        control1X: root.panelLeft; control1Y: root.joinRadius * (1 - root.curveKappa)
        control2X: root.joinRadius * root.curveKappa; control2Y: 0
      }
    }
  }

  Shape {
    anchors.fill: parent
    visible: root.attachmentEdge === "bottom"
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: root.panelColor; strokeWidth: 0; startX: 0; startY: root.fullHeight
      PathLine { x: root.fullWidth; y: root.fullHeight }
      PathCubic {
        x: root.panelRight; y: root.panelBottom
        control1X: root.fullWidth - root.joinRadius * root.curveKappa; control1Y: root.fullHeight
        control2X: root.panelRight; control2Y: root.fullHeight - root.joinRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.panelRight; y: root.panelTop + root.cornerRadius }
      PathCubic {
        x: root.panelRight - root.cornerRadius; y: root.panelTop
        control1X: root.panelRight; control1Y: root.panelTop + root.cornerRadius * (1 - root.curveKappa)
        control2X: root.panelRight - root.cornerRadius * (1 - root.curveKappa); control2Y: root.panelTop
      }
      PathLine { x: root.panelLeft + root.cornerRadius; y: root.panelTop }
      PathCubic {
        x: root.panelLeft; y: root.panelTop + root.cornerRadius
        control1X: root.panelLeft + root.cornerRadius * (1 - root.curveKappa); control1Y: root.panelTop
        control2X: root.panelLeft; control2Y: root.panelTop + root.cornerRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.panelLeft; y: root.panelBottom }
      PathCubic {
        x: 0; y: root.fullHeight
        control1X: root.panelLeft; control1Y: root.fullHeight - root.joinRadius * (1 - root.curveKappa)
        control2X: root.joinRadius * root.curveKappa; control2Y: root.fullHeight
      }
    }
  }

  Shape {
    anchors.fill: parent
    visible: root.attachmentEdge === "left"
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: root.panelColor; strokeWidth: 0; startX: 0; startY: 0
      PathLine { x: 0; y: root.fullHeight }
      PathCubic {
        x: root.panelLeft; y: root.panelBottom
        control1X: 0; control1Y: root.fullHeight - root.joinRadius * root.curveKappa
        control2X: root.joinRadius * (1 - root.curveKappa); control2Y: root.panelBottom
      }
      PathLine { x: root.panelRight - root.cornerRadius; y: root.panelBottom }
      PathCubic {
        x: root.panelRight; y: root.panelBottom - root.cornerRadius
        control1X: root.panelRight - root.cornerRadius * (1 - root.curveKappa); control1Y: root.panelBottom
        control2X: root.panelRight; control2Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.panelRight; y: root.panelTop + root.cornerRadius }
      PathCubic {
        x: root.panelRight - root.cornerRadius; y: root.panelTop
        control1X: root.panelRight; control1Y: root.panelTop + root.cornerRadius * (1 - root.curveKappa)
        control2X: root.panelRight - root.cornerRadius * (1 - root.curveKappa); control2Y: root.panelTop
      }
      PathLine { x: root.panelLeft; y: root.panelTop }
      PathCubic {
        x: 0; y: 0
        control1X: root.joinRadius * (1 - root.curveKappa); control1Y: root.panelTop
        control2X: 0; control2Y: root.joinRadius * root.curveKappa
      }
    }
  }

  Shape {
    anchors.fill: parent
    visible: root.attachmentEdge === "right"
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: root.panelColor; strokeWidth: 0; startX: root.fullWidth; startY: 0
      PathLine { x: root.fullWidth; y: root.fullHeight }
      PathCubic {
        x: root.panelRight; y: root.panelBottom
        control1X: root.fullWidth; control1Y: root.fullHeight - root.joinRadius * root.curveKappa
        control2X: root.panelRight + root.joinRadius * root.curveKappa; control2Y: root.panelBottom
      }
      PathLine { x: root.panelLeft + root.cornerRadius; y: root.panelBottom }
      PathCubic {
        x: root.panelLeft; y: root.panelBottom - root.cornerRadius
        control1X: root.panelLeft + root.cornerRadius * (1 - root.curveKappa); control1Y: root.panelBottom
        control2X: root.panelLeft; control2Y: root.panelBottom - root.cornerRadius * (1 - root.curveKappa)
      }
      PathLine { x: root.panelLeft; y: root.panelTop + root.cornerRadius }
      PathCubic {
        x: root.panelLeft + root.cornerRadius; y: root.panelTop
        control1X: root.panelLeft; control1Y: root.panelTop + root.cornerRadius * (1 - root.curveKappa)
        control2X: root.panelLeft + root.cornerRadius * (1 - root.curveKappa); control2Y: root.panelTop
      }
      PathLine { x: root.panelRight; y: root.panelTop }
      PathCubic {
        x: root.fullWidth; y: 0
        control1X: root.panelRight + root.joinRadius * root.curveKappa; control1Y: root.panelTop
        control2X: root.fullWidth; control2Y: root.joinRadius * root.curveKappa
      }
    }
  }
}
