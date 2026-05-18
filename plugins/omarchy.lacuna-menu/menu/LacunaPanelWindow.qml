import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  default property alias content: contentLayer.data

  signal focusGrabCleared()

  property var targetScreen: null
  property bool menuOpen: false
  property bool panelVisible: false
  property bool flyoutOpen: false
  property bool exclusive: false
  property int panelWidth: 0
  property int surfaceRightInset: 0
  property int flyoutLaneWidth: 0
  property real sidebarSurfaceX: 0
  property Item activeFlyoutItem: null
  property Item activeConnectorItem: null
  property string layerNamespace: "lacuna-menu"

  function itemX(item) {
    return item ? Math.round(item.x) : 0
  }

  function itemY(item) {
    return item ? Math.round(item.y) : 0
  }

  function itemWidth(item) {
    if (!item || !item.visible) return 0
    return Math.round(item.width)
  }

  function itemHeight(item) {
    if (!item || !item.visible) return 0
    return Math.round(item.height)
  }

  visible: panelVisible
  screen: targetScreen
  color: "transparent"
  implicitWidth: panelWidth + surfaceRightInset + flyoutLaneWidth
  exclusiveZone: exclusive && menuOpen ? panelWidth : 0
  exclusionMode: exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
  WlrLayershell.namespace: layerNamespace
  WlrLayershell.layer: exclusive ? WlrLayer.Top : WlrLayer.Overlay
  WlrLayershell.keyboardFocus: flyoutOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  mask: Region {
    Region {
      x: Math.round(root.sidebarSurfaceX)
      y: 0
      width: root.panelWidth + root.surfaceRightInset
      height: root.height
    }

    Region {
      x: root.itemX(root.activeConnectorItem)
      y: root.itemY(root.activeConnectorItem)
      width: root.itemWidth(root.activeConnectorItem)
      height: root.itemHeight(root.activeConnectorItem)
    }

    Region {
      x: root.itemX(root.activeFlyoutItem)
      y: root.itemY(root.activeFlyoutItem)
      width: root.itemWidth(root.activeFlyoutItem)
      height: root.itemHeight(root.activeFlyoutItem)
    }
  }

  HyprlandFocusGrab {
    active: root.menuOpen && root.flyoutOpen
    windows: [root]
    onCleared: root.focusGrabCleared()
  }

  anchors {
    top: true
    bottom: true
    left: true
  }

  Item {
    id: contentLayer
    anchors.fill: parent
  }
}
