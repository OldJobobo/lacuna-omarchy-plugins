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
  property real sidebarMaskX: 0
  property real sidebarMaskY: 0
  property real sidebarMaskWidth: panelWidth + surfaceRightInset
  property real sidebarMaskHeight: height
  property real connectorMaskX: 0
  property real connectorMaskY: 0
  property real connectorMaskWidth: 0
  property real connectorMaskHeight: 0
  property real flyoutMaskX: 0
  property real flyoutMaskY: 0
  property real flyoutMaskWidth: 0
  property real flyoutMaskHeight: 0
  property bool flyoutInteractive: false
  property string layerNamespace: "lacuna-menu"

  visible: panelVisible
  screen: targetScreen
  color: "transparent"
  implicitWidth: panelWidth + surfaceRightInset + flyoutLaneWidth
  exclusiveZone: exclusive && menuOpen ? panelWidth : 0
  exclusionMode: exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
  WlrLayershell.namespace: layerNamespace
  WlrLayershell.layer: exclusive ? WlrLayer.Top : WlrLayer.Overlay
  WlrLayershell.keyboardFocus: flyoutInteractive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  mask: Region {
    Region {
      x: Math.round(root.sidebarMaskX)
      y: Math.round(root.sidebarMaskY)
      width: Math.round(Math.max(0, root.sidebarMaskWidth))
      height: Math.round(Math.max(0, root.sidebarMaskHeight))
    }

    Region {
      x: Math.round(root.connectorMaskX)
      y: Math.round(root.connectorMaskY)
      width: Math.round(Math.max(0, root.connectorMaskWidth))
      height: Math.round(Math.max(0, root.connectorMaskHeight))
    }

    Region {
      x: Math.round(root.flyoutMaskX)
      y: Math.round(root.flyoutMaskY)
      width: Math.round(Math.max(0, root.flyoutMaskWidth))
      height: Math.round(Math.max(0, root.flyoutMaskHeight))
    }
  }

  HyprlandFocusGrab {
    active: root.menuOpen && root.flyoutInteractive
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
