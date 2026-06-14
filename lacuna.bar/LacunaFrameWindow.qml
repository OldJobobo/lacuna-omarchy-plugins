import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

PanelWindow {
  id: root

  property var targetScreen: null
  property bool active: false
  property string barPosition: "top"
  property int barSize: 0
  property int frameThickness: 8
  property int frameRadius: 14
  property bool cornerPieces: true
  property color frameColor: "#17105a"
  property bool leftEdgeOccupied: false
  property bool rightEdgeOccupied: false
  property real leftOccupiedWidth: 0
  property real rightOccupiedWidth: 0
  property bool shadowEnabled: false
  property int shadowOffsetX: 2
  property int shadowOffsetY: 3
  property real shadowOpacity: 0.32

  readonly property int t: Math.max(1, frameThickness)
  readonly property int r: Math.max(t, frameRadius)
  readonly property real leftOcclusion: leftEdgeOccupied ? Math.max(0, leftOccupiedWidth) : 0
  readonly property real rightOcclusion: rightEdgeOccupied ? Math.max(0, rightOccupiedWidth) : 0
  readonly property real horizontalFrameX: leftOcclusion
  readonly property real horizontalFrameWidth: Math.max(0, width - leftOcclusion - rightOcclusion)
  readonly property int topInset: topBar ? Math.max(0, barSize) : t
  readonly property int bottomInset: bottomBar ? Math.max(0, barSize) : t
  readonly property int leftInset: leftBar ? Math.max(0, barSize) : t
  readonly property int rightInset: rightBar ? Math.max(0, barSize) : t
  readonly property real frameAlpha: Math.max(0, Math.min(1, frameColor.a === undefined ? 1 : frameColor.a))
  readonly property color solidFrameColor: Qt.rgba(frameColor.r, frameColor.g, frameColor.b, 1)
  readonly property bool topBar: barPosition === "top"
  readonly property bool bottomBar: barPosition === "bottom"
  readonly property bool leftBar: barPosition === "left"
  readonly property bool rightBar: barPosition === "right"
  readonly property real curveKappa: 0.5522847498

  visible: active
  screen: targetScreen
  color: "transparent"
  WlrLayershell.namespace: "lacuna-bar-frame"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: Region {}

  Item {
    anchors.fill: parent

    Rectangle {
      visible: !root.topBar
      x: root.horizontalFrameX
      y: 0
      width: root.horizontalFrameWidth
      height: root.t
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Rectangle {
      visible: !root.bottomBar
      x: root.horizontalFrameX
      y: parent.height - root.t
      width: root.horizontalFrameWidth
      height: root.t
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Rectangle {
      visible: !root.leftBar && !root.leftEdgeOccupied
      x: 0
      y: 0
      width: root.t
      height: parent.height
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Rectangle {
      visible: !root.rightBar && !root.rightEdgeOccupied
      x: parent.width - root.t
      y: 0
      width: root.t
      height: parent.height
      color: root.solidFrameColor
      opacity: root.frameAlpha
    }

    Rectangle {
      visible: root.shadowEnabled && !root.topBar
      x: root.horizontalFrameX
      y: root.t
      width: root.horizontalFrameWidth
      height: Math.max(8, root.t * 2)
      opacity: root.shadowOpacity
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
      }
    }

    Rectangle {
      visible: root.shadowEnabled && !root.bottomBar
      x: root.horizontalFrameX
      y: parent.height - root.t - height
      width: root.horizontalFrameWidth
      height: Math.max(8, root.t * 2)
      opacity: root.shadowOpacity
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
      }
    }

    Shape {
      visible: root.cornerPieces && !root.leftEdgeOccupied && root.r > 0
      x: root.leftInset
      y: root.topInset
      width: root.r
      height: root.r
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
        strokeWidth: 0
        startX: 0
        startY: 0
        PathLine { x: 0; y: root.r }
        PathCubic {
          x: root.r
          y: 0
          control1X: 0
          control1Y: root.r * (1 - root.curveKappa)
          control2X: root.r * root.curveKappa
          control2Y: 0
        }
        PathLine { x: 0; y: 0 }
      }
    }

    Shape {
      visible: root.cornerPieces && !root.rightEdgeOccupied && root.r > 0
      x: parent.width - root.rightInset - root.r
      y: root.topInset
      width: root.r
      height: root.r
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
        strokeWidth: 0
        startX: root.r
        startY: 0
        PathLine { x: root.r; y: root.r }
        PathCubic {
          x: 0
          y: 0
          control1X: root.r
          control1Y: root.r * (1 - root.curveKappa)
          control2X: root.r * (1 - root.curveKappa)
          control2Y: 0
        }
        PathLine { x: root.r; y: 0 }
      }
    }

    Shape {
      visible: root.cornerPieces && !root.leftEdgeOccupied && root.r > 0
      x: root.leftInset
      y: parent.height - root.bottomInset - root.r
      width: root.r
      height: root.r
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
        strokeWidth: 0
        startX: 0
        startY: root.r
        PathLine { x: root.r; y: root.r }
        PathCubic {
          x: 0
          y: 0
          control1X: root.r * (1 - root.curveKappa)
          control1Y: root.r
          control2X: 0
          control2Y: root.r * (1 - root.curveKappa)
        }
        PathLine { x: 0; y: root.r }
      }
    }

    Shape {
      visible: root.cornerPieces && !root.rightEdgeOccupied && root.r > 0
      x: parent.width - root.rightInset - root.r
      y: parent.height - root.bottomInset - root.r
      width: root.r
      height: root.r
      asynchronous: false
      antialiasing: true
      opacity: root.frameAlpha
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.solidFrameColor
        strokeWidth: 0
        startX: root.r
        startY: root.r
        PathLine { x: 0; y: root.r }
        PathCubic {
          x: root.r
          y: 0
          control1X: root.r * (1 - root.curveKappa)
          control1Y: root.r
          control2X: root.r
          control2Y: root.r * (1 - root.curveKappa)
        }
        PathLine { x: root.r; y: root.r }
      }
    }
  }
}
