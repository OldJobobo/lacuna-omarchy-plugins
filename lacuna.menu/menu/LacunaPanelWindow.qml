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
  property bool keepMapped: false
  property bool flyoutOpen: false
  property bool exclusive: false
  property int panelWidth: 0
  property int surfaceRightInset: 0
  property int flyoutLaneWidth: 0
  property int visualWidth: 0
  property int visualTopInset: 0
  property int visualBottomInset: 0
  property int visualLeftInset: 0
  property int visualRightInset: 0
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
  property bool anchorRight: false
  property string layerNamespace: "lacuna-menu"
  readonly property bool inputActive: panelVisible

  visible: panelVisible || keepMapped
  screen: targetScreen
  color: "transparent"
  implicitWidth: Math.max(panelWidth + surfaceRightInset + flyoutLaneWidth, visualWidth)
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: layerNamespace
  // The frame surface is always mapped at Top. Keep the sidebar at Overlay so
  // compositor map timing cannot place a primary-output sidebar underneath
  // the frame shadow while other output variants remain above it.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: flyoutInteractive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  margins {
    top: root.visualTopInset
    bottom: root.visualBottomInset
    left: root.visualLeftInset
    right: root.visualRightInset
  }

  mask: Region {
    Region {
      x: Math.round(root.sidebarMaskX)
      y: Math.round(root.sidebarMaskY)
      width: Math.round(root.inputActive ? Math.max(0, root.sidebarMaskWidth) : 0)
      height: Math.round(root.inputActive ? Math.max(0, root.sidebarMaskHeight) : 0)
    }

    Region {
      x: Math.round(root.connectorMaskX)
      y: Math.round(root.connectorMaskY)
      width: Math.round(root.inputActive ? Math.max(0, root.connectorMaskWidth) : 0)
      height: Math.round(root.inputActive ? Math.max(0, root.connectorMaskHeight) : 0)
    }

    Region {
      x: Math.round(root.flyoutMaskX)
      y: Math.round(root.flyoutMaskY)
      width: Math.round(root.inputActive ? Math.max(0, root.flyoutMaskWidth) : 0)
      height: Math.round(root.inputActive ? Math.max(0, root.flyoutMaskHeight) : 0)
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
    left: !root.anchorRight
    right: root.anchorRight
  }

  Item {
    id: contentLayer
    anchors.fill: parent
  }
}
