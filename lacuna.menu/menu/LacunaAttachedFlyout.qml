import QtQuick
import "../components"
import "../services"

Item {
  id: root

  default property alias content: contentHost.data

  property bool open: false
  property bool renderable: open
  property bool interactive: open
  property real progress: open ? 1 : 0
  property real contentProgress: Math.max(0, Math.min(1, (progress - 0.45) / 0.55))
  property bool openToLeft: false
  property real openX: 0
  property real openY: 0
  property int panelWidth: 300
  property int panelHeight: 420
  property int panelRadius: 14
  property color panelColor: "#101315"
  property color foreground: "#d8dee9"
  property var designTokens: fallbackDesignTokens

  readonly property real curveKappa: lacunaGeometry.curveKappa

  LacunaGeometry { id: lacunaGeometry }
  readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
  readonly property real currentWidth: Math.max(0, panelWidth * clampedProgress)
  readonly property real contentOpacity: Math.max(0, Math.min(1, contentProgress))

  visible: renderable && clampedProgress > 0.001
  enabled: interactive
  x: openX
  y: openY
  width: panelWidth
  height: panelHeight
  clip: true

  Item {
    id: panelBody

    x: root.openToLeft ? root.panelWidth - root.currentWidth : 0
    y: 0
    width: root.currentWidth
    height: root.panelHeight
    clip: true

    LacunaShapeSurface {
      anchors.fill: parent
      panelColor: root.panelColor
      panelRadius: root.panelRadius
      topLeftCornerState: root.openToLeft ? 0 : -1
      bottomLeftCornerState: root.openToLeft ? 0 : -1
      topRightCornerState: root.openToLeft ? -1 : 0
      bottomRightCornerState: root.openToLeft ? -1 : 0
    }

    Item {
      id: contentHost
      width: root.panelWidth
      height: root.panelHeight
      x: root.openToLeft ? -panelBody.x : 0
      opacity: root.contentOpacity
      enabled: root.interactive && root.contentOpacity > 0.98
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    foreground: root.foreground
    background: root.panelColor
  }
}
