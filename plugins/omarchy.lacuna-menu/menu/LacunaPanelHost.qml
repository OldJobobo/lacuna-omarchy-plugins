import QtQuick

QtObject {
  id: root

  property real panelWidth: 0
  property real surfaceRightInset: 0
  property real surfaceX: 0
  property real sidebarHeight: 0
  property bool anchorRight: false

  property real connectorWidth: 0
  property bool connectorRenderable: false

  property real flyoutY: 0
  property real flyoutWidth: 0
  property real flyoutHeight: 0
  property real flyoutProgress: 0
  property bool flyoutRenderable: false
  property real cachedFlyoutY: 0
  property real cachedFlyoutWidth: 0
  property real cachedFlyoutHeight: 0
  property real cachedConnectorWidth: 0
  property bool cachedAnchorRight: false

  readonly property real clampedFlyoutProgress: Math.max(0, Math.min(1, flyoutProgress))
  readonly property real panelSurfaceWidth: panelWidth + surfaceRightInset
  readonly property bool transitioningFlyout: flyoutRenderable && clampedFlyoutProgress > 0.001 && clampedFlyoutProgress < 0.999
  readonly property real effectiveFlyoutY: transitioningFlyout ? cachedFlyoutY : flyoutY
  readonly property real effectiveFlyoutWidth: transitioningFlyout ? cachedFlyoutWidth : flyoutWidth
  readonly property real effectiveFlyoutHeight: transitioningFlyout ? cachedFlyoutHeight : flyoutHeight
  readonly property real effectiveConnectorWidth: transitioningFlyout ? cachedConnectorWidth : connectorWidth
  readonly property bool effectiveAnchorRight: transitioningFlyout ? cachedAnchorRight : anchorRight
  readonly property real sidebarX: effectiveAnchorRight ? effectiveFlyoutWidth + effectiveConnectorWidth : 0

  readonly property real sidebarMaskX: Math.max(0, surfaceX)
  readonly property real sidebarMaskY: 0
  readonly property real sidebarMaskWidth: anchorRight
    ? Math.max(0, sidebarX + panelSurfaceWidth - Math.max(0, surfaceX))
    : Math.max(0, panelSurfaceWidth + Math.min(0, surfaceX))
  readonly property real sidebarMaskHeight: sidebarHeight

  readonly property real connectorX: effectiveAnchorRight ? effectiveFlyoutWidth : panelWidth
  readonly property real connectorY: effectiveFlyoutY - effectiveConnectorWidth
  readonly property real connectorMaskX: connectorX
  readonly property real connectorMaskY: connectorY
  readonly property real connectorMaskWidth: connectorRenderable ? effectiveConnectorWidth : 0
  readonly property real connectorMaskHeight: connectorRenderable ? effectiveFlyoutHeight : 0

  readonly property real flyoutCurrentWidth: Math.max(0, effectiveFlyoutWidth * clampedFlyoutProgress)
  readonly property real flyoutX: effectiveAnchorRight ? 0 : panelWidth + effectiveConnectorWidth
  readonly property real flyoutMaskX: effectiveAnchorRight ? effectiveFlyoutWidth - flyoutCurrentWidth : flyoutX
  readonly property real flyoutMaskY: effectiveFlyoutY
  readonly property real flyoutMaskWidth: flyoutRenderable ? flyoutCurrentWidth : 0
  readonly property real flyoutMaskHeight: flyoutRenderable ? effectiveFlyoutHeight : 0

  function captureFlyoutGeometry() {
    cachedFlyoutY = flyoutY
    cachedFlyoutWidth = flyoutWidth
    cachedFlyoutHeight = flyoutHeight
    cachedConnectorWidth = connectorWidth
    cachedAnchorRight = anchorRight
  }

  onFlyoutRenderableChanged: {
    if (flyoutRenderable) captureFlyoutGeometry()
  }

  onFlyoutProgressChanged: {
    if (clampedFlyoutProgress <= 0.001 || clampedFlyoutProgress >= 0.999) captureFlyoutGeometry()
  }
}
