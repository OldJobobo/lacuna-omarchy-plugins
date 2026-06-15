import QtQuick
import "../components"
import "../services"

Item {
  id: root

  property bool sidebarVisible: false
  property bool flyoutOpen: false
  property bool flyoutRenderable: false
  property bool connectorRenderable: false
  property bool shadowEnabled: false
  property real menuProgress: 1
  property real flyoutProgress: 0
  property real contentProgress: Math.max(0, Math.min(1, flyoutProgress))
  property real sidebarX: 0
  property real panelWidth: 0
  property real surfaceRightInset: 0
  property real barHeight: 32
  property real barBottomY: barHeight
  property real joinRadius: 18
  property real connectorOverlap: 33
  property bool fullFrame: false
  property real frameThickness: 8
  property bool cornerPieces: true
  property bool openFromRight: false
  property real connectorX: 0
  property real connectorY: 0
  property real connectorWidth: 0
  property real connectorHeight: 0
  property real flyoutX: 0
  property real flyoutY: 0
  property real flyoutWidth: 0
  property real flyoutHeight: 0
  property int panelRadius: 14
  property color panelColor: "#101315"
  property color foreground: "#d8dee9"
  property var designTokens: fallbackDesignTokens
  property color shadowColor: "black"
  property real shadowOpacity: 0.62
  property real shadowBlur: 0.85
  property int shadowBlurMax: 28
  property real shadowOffsetX: 2
  property real shadowOffsetY: 3

  readonly property bool hasVisibleSurface: sidebarVisible || (flyoutRenderable && flyoutWidth > 0 && flyoutHeight > 0)
  readonly property real shadowBottomClipInset: fullFrame
    ? Math.max(0, frameThickness + shadowBlurMax + Math.abs(shadowOffsetY))
    : 0

  visible: hasVisibleSurface
  enabled: false

  Item {
    id: shadowClip

    x: 0
    y: 0
    width: parent.width
    height: Math.max(0, parent.height - root.shadowBottomClipInset)
    clip: root.shadowBottomClipInset > 0
    z: 0

    Item {
      id: shadowRenderLayer

      x: 0
      y: 0
      width: root.width
      height: root.height

      LacunaDropShadow {
        source: surfaceSource
        shadowEnabled: root.shadowEnabled && root.hasVisibleSurface
        shadowColor: root.shadowColor
        shadowOpacity: root.shadowOpacity
        shadowBlur: root.shadowBlur
        blurMax: root.shadowBlurMax
        shadowHorizontalOffset: root.shadowOffsetX
        shadowVerticalOffset: root.shadowOffsetY
      }
    }
  }

  Item {
    id: surfaceSource

    anchors.fill: parent
    z: 1

    MenuSurface {
      visible: root.sidebarVisible
      enabled: false
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      x: root.sidebarX
      panelWidth: Math.max(0, root.panelWidth)
      open: root.sidebarVisible
      progress: root.menuProgress
      barHeight: root.barHeight
      barBottomY: root.barBottomY
      joinRadius: root.joinRadius
      connectorOverlap: root.connectorOverlap
      bodyRightInset: root.surfaceRightInset
      fullFrame: root.fullFrame
      frameThickness: root.frameThickness
      cornerPieces: root.cornerPieces
      openFromRight: root.openFromRight
      panelColor: root.panelColor
      foreground: root.foreground
      designTokens: root.designTokens
      backgroundVisible: true
    }

    LacunaPanelConnector {
      open: root.flyoutOpen
      renderable: root.connectorRenderable
      progress: root.flyoutProgress
      x: root.connectorX
      y: root.connectorY
      connectorWidth: root.connectorWidth
      contentHeight: Math.max(0, root.connectorHeight - root.connectorWidth * 2)
      panelColor: root.panelColor
      backgroundVisible: true
    }

    LacunaAttachedFlyout {
      open: root.flyoutOpen
      renderable: root.flyoutRenderable
      interactive: false
      progress: root.flyoutRenderable ? root.flyoutProgress : 0
      contentProgress: root.contentProgress
      openX: root.flyoutX
      openY: root.flyoutY
      openToLeft: root.openFromRight
      panelWidth: root.flyoutWidth
      panelHeight: root.flyoutHeight
      panelRadius: root.panelRadius
      panelColor: root.panelColor
      foreground: root.foreground
      designTokens: root.designTokens
      backgroundVisible: true
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    foreground: root.foreground
    background: root.panelColor
  }
}
