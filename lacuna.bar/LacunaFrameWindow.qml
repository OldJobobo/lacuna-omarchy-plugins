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
  property color frameColor: "#17105a"
  property bool shadowEnabled: false
  property int shadowOffsetX: 2
  property int shadowOffsetY: 3
  property real shadowOpacity: 0.62
  property real shadowBlur: 0.85
  property int shadowBlurMax: 28
  property bool topEdgeOccupied: false
  property bool bottomEdgeOccupied: false
  property bool leftEdgeOccupied: false
  property bool rightEdgeOccupied: false
  property real leftOccupiedWidth: 0
  property real rightOccupiedWidth: 0

  readonly property int t: Math.max(1, frameThickness)
  readonly property int r: Math.max(t, frameRadius)
  readonly property real leftOcclusion: leftEdgeOccupied ? Math.max(0, leftOccupiedWidth) : 0
  readonly property real rightOcclusion: rightEdgeOccupied ? Math.max(0, rightOccupiedWidth) : 0
  readonly property bool topBar: barPosition === "top"
  readonly property bool bottomBar: barPosition === "bottom"
  readonly property bool leftBar: barPosition === "left"
  readonly property bool rightBar: barPosition === "right"
  readonly property int topInset: topBar || topEdgeOccupied ? Math.max(0, barSize) : t
  readonly property int bottomInset: bottomBar || bottomEdgeOccupied ? Math.max(0, barSize) : t
  readonly property int leftInset: leftBar ? Math.max(0, barSize) : t
  readonly property int rightInset: rightBar ? Math.max(0, barSize) : t
  // The frame never paints the strip occupied by the bar: the bar itself is
  // the frame edge on its side. Map order of the vendored bar window is not
  // ours to control, so bar-over-frame correctness must come from geometry,
  // not stacking.
  readonly property real outerX: leftBar ? Math.max(0, barSize) : 0
  readonly property real outerY: topBar || topEdgeOccupied ? Math.max(0, barSize) : 0
  readonly property real outerRight: rightBar ? Math.max(outerX + 1, width - Math.max(0, barSize)) : width
  readonly property real outerBottom: bottomBar || bottomEdgeOccupied ? Math.max(outerY + 1, height - Math.max(0, barSize)) : height
  readonly property real holeX: Math.max(0, leftEdgeOccupied ? leftOcclusion : leftInset)
  readonly property real holeY: Math.max(0, topInset)
  readonly property real holeRight: Math.max(holeX + 1, width - (rightEdgeOccupied ? rightOcclusion : rightInset))
  readonly property real holeBottom: Math.max(holeY + 1, height - bottomInset)
  readonly property real holeWidth: Math.max(1, holeRight - holeX)
  readonly property real holeHeight: Math.max(1, holeBottom - holeY)
  // Shadow caster hole. With the frame active it matches the paint hole so
  // the shadow rings the whole content area (bar, rails, molding, sidebar
  // occlusion edge). With the frame off it collapses to the bar edge alone,
  // so the bar still casts its shadow — the bar's shadow must not depend on
  // the frame or on the menu being open.
  readonly property real casterHoleX: isRenderable ? holeX : (leftBar ? Math.max(0, barSize) : 0)
  readonly property real casterHoleY: isRenderable ? holeY : (topBar || topEdgeOccupied ? Math.max(0, barSize) : 0)
  readonly property real casterHoleRight: isRenderable ? holeRight : (rightBar ? Math.max(casterHoleX + 1, width - Math.max(0, barSize)) : width)
  readonly property real casterHoleBottom: isRenderable ? holeBottom : (bottomBar || bottomEdgeOccupied ? Math.max(casterHoleY + 1, height - Math.max(0, barSize)) : height)
  readonly property real casterHoleRadius: isRenderable ? holeRadius : minArcRadius
  readonly property real minArcRadius: 0.01
  readonly property real holeRadius: cornerPieces ? Math.max(minArcRadius, Math.min(r, holeWidth / 2, holeHeight / 2)) : minArcRadius
  readonly property bool isRenderable: active && width > 0 && height > 0 && holeWidth > 0 && holeHeight > 0
  readonly property real curveKappa: lacunaGeometry.curveKappa
  readonly property color effectiveFrameColor: isRenderable
    ? Qt.rgba(frameColor.r, frameColor.g, frameColor.b, 1)
    : "transparent"

  LacunaGeometry { id: lacunaGeometry }

  // Always mapped: within a Wayland layer, stacking is map order only.
  // Mapping this surface when the user enables the frame would stack it
  // above the bar and sidebar (mapped at startup) and paint the frame over
  // them. It stays mapped with fully transparent, click-through content
  // while inactive; isRenderable gates all paint.
  visible: true
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

    // Hidden silhouette for the drop shadow. Unlike the painted frame it
    // covers the bar strip too, so the blur is cast from the bar's inner
    // edge; the clip below keeps the rendered shadow off the bar itself.
    Shape {
      id: frameShadowCaster

      visible: false
      anchors.fill: parent
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeWidth: -1
        fillColor: "#000000"
        fillRule: ShapePath.OddEvenFill
        startX: 0
        startY: 0

        PathLine { x: frameShadowCaster.width; y: 0 }
        PathLine { x: frameShadowCaster.width; y: frameShadowCaster.height }
        PathLine { x: 0; y: frameShadowCaster.height }
        PathLine { x: 0; y: 0 }

        PathMove {
          x: root.casterHoleX + root.casterHoleRadius
          y: root.casterHoleY
        }
        PathLine {
          x: root.casterHoleRight - root.casterHoleRadius
          y: root.casterHoleY
        }
        PathArc {
          x: root.casterHoleRight
          y: root.casterHoleY + root.casterHoleRadius
          radiusX: root.casterHoleRadius
          radiusY: root.casterHoleRadius
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.casterHoleRight
          y: root.casterHoleBottom - root.casterHoleRadius
        }
        PathArc {
          x: root.casterHoleRight - root.casterHoleRadius
          y: root.casterHoleBottom
          radiusX: root.casterHoleRadius
          radiusY: root.casterHoleRadius
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.casterHoleX + root.casterHoleRadius
          y: root.casterHoleBottom
        }
        PathArc {
          x: root.casterHoleX
          y: root.casterHoleBottom - root.casterHoleRadius
          radiusX: root.casterHoleRadius
          radiusY: root.casterHoleRadius
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.casterHoleX
          y: root.casterHoleY + root.casterHoleRadius
        }
        PathArc {
          x: root.casterHoleX + root.casterHoleRadius
          y: root.casterHoleY
          radiusX: root.casterHoleRadius
          radiusY: root.casterHoleRadius
          direction: PathArc.Clockwise
        }
      }
    }

    Item {
      id: shadowClip

      // Only the content side of the chrome shows the cast shadow; the bar
      // strip is excluded because the frame must never draw over the bar.
      x: root.outerX
      y: root.outerY
      width: Math.max(0, root.outerRight - root.outerX)
      height: Math.max(0, root.outerBottom - root.outerY)
      clip: true
      z: 0

      Item {
        x: -root.outerX
        y: -root.outerY
        width: root.width
        height: root.height

        LacunaDropShadow {
          source: frameShadowCaster
          shadowEnabled: root.shadowEnabled && root.width > 0 && root.height > 0
          shadowOpacity: root.shadowOpacity
          shadowBlur: root.shadowBlur
          blurMax: root.shadowBlurMax
          shadowHorizontalOffset: root.shadowOffsetX
          shadowVerticalOffset: root.shadowOffsetY
        }
      }
    }

    Shape {
      id: frameSource

      anchors.fill: parent
      asynchronous: false
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer
      z: 1

      ShapePath {
        strokeWidth: -1
        fillColor: root.effectiveFrameColor
        fillRule: ShapePath.OddEvenFill
        startX: root.isRenderable ? (root.outerX + root.minArcRadius) : -0.75
        startY: root.isRenderable ? root.outerY : -1

        PathLine {
          x: root.isRenderable ? (root.outerRight - root.minArcRadius) : 0
          y: root.isRenderable ? root.outerY : -1
        }
        PathArc {
          x: root.isRenderable ? root.outerRight : 0
          y: root.isRenderable ? (root.outerY + root.minArcRadius) : -0.75
          radiusX: root.isRenderable ? root.minArcRadius : 0
          radiusY: root.isRenderable ? root.minArcRadius : 0
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.isRenderable ? root.outerRight : 0
          y: root.isRenderable ? (root.outerBottom - root.minArcRadius) : 0
        }
        PathArc {
          x: root.isRenderable ? (root.outerRight - root.minArcRadius) : -0.25
          y: root.isRenderable ? root.outerBottom : 0
          radiusX: root.isRenderable ? root.minArcRadius : 0
          radiusY: root.isRenderable ? root.minArcRadius : 0
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.isRenderable ? (root.outerX + root.minArcRadius) : -1
          y: root.isRenderable ? root.outerBottom : 0
        }
        PathArc {
          x: root.isRenderable ? root.outerX : -1
          y: root.isRenderable ? (root.outerBottom - root.minArcRadius) : -0.25
          radiusX: root.isRenderable ? root.minArcRadius : 0
          radiusY: root.isRenderable ? root.minArcRadius : 0
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.isRenderable ? root.outerX : -1
          y: root.isRenderable ? (root.outerY + root.minArcRadius) : -1
        }
        PathArc {
          x: root.isRenderable ? (root.outerX + root.minArcRadius) : -0.75
          y: root.isRenderable ? root.outerY : -1
          radiusX: root.isRenderable ? root.minArcRadius : 0
          radiusY: root.isRenderable ? root.minArcRadius : 0
          direction: PathArc.Clockwise
        }

        PathMove {
          x: root.isRenderable ? (root.holeX + root.holeRadius) : -2.75
          y: root.isRenderable ? root.holeY : -3
        }
        PathLine {
          x: root.isRenderable ? (root.holeRight - root.holeRadius) : -2
          y: root.isRenderable ? root.holeY : -3
        }
        PathArc {
          x: root.isRenderable ? root.holeRight : -2
          y: root.isRenderable ? (root.holeY + root.holeRadius) : -2.75
          radiusX: root.isRenderable ? root.holeRadius : 0
          radiusY: root.isRenderable ? root.holeRadius : 0
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.isRenderable ? root.holeRight : -2
          y: root.isRenderable ? (root.holeBottom - root.holeRadius) : -2
        }
        PathArc {
          x: root.isRenderable ? (root.holeRight - root.holeRadius) : -2.25
          y: root.isRenderable ? root.holeBottom : -2
          radiusX: root.isRenderable ? root.holeRadius : 0
          radiusY: root.isRenderable ? root.holeRadius : 0
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.isRenderable ? (root.holeX + root.holeRadius) : -3
          y: root.isRenderable ? root.holeBottom : -2
        }
        PathArc {
          x: root.isRenderable ? root.holeX : -3
          y: root.isRenderable ? (root.holeBottom - root.holeRadius) : -2.25
          radiusX: root.isRenderable ? root.holeRadius : 0
          radiusY: root.isRenderable ? root.holeRadius : 0
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.isRenderable ? root.holeX : -3
          y: root.isRenderable ? (root.holeY + root.holeRadius) : -3
        }
        PathArc {
          x: root.isRenderable ? (root.holeX + root.holeRadius) : -2.75
          y: root.isRenderable ? root.holeY : -3
          radiusX: root.isRenderable ? root.holeRadius : 0
          radiusY: root.isRenderable ? root.holeRadius : 0
          direction: PathArc.Clockwise
        }
      }
    }

  }
}
