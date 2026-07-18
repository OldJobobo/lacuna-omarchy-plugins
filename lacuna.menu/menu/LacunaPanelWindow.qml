import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  default property alias content: contentLayer.data

  signal focusGrabCleared()
  signal dismissRequested()

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
  property bool keyboardInputActive: false
  property bool dismissActive: false
  property bool focusGrabActive: false
  property bool anchorRight: false
  property string layerNamespace: "lacuna-menu"
  readonly property bool inputActive: panelVisible

  onDismissActiveChanged: {
    if (dismissActive) focusGrabArmTimer.restart()
    else {
      focusGrabArmTimer.stop()
      focusGrabActive = false
    }
  }

  Timer {
    id: focusGrabArmTimer
    interval: 240
    repeat: false
    onTriggered: {
      if (root.dismissActive) root.focusGrabActive = true
    }
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.WindowShortcut
    enabled: root.dismissActive
    onActivated: root.dismissRequested()
  }

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
  // The persistent sidebar and its flyouts share one layer-shell surface. Keep
  // ordinary menu use pointer-driven, but allow explicitly keyboard-driven
  // content (currently Media Player search) to receive compositor key events.
  WlrLayershell.keyboardFocus: root.keyboardInputActive
    ? WlrKeyboardFocus.Exclusive
    : root.dismissActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  // The system's Super+V binding normally consumes the key before it reaches
  // layer-shell surfaces. Inhibit compositor shortcuts while explicit keyboard
  // input is active so the focused search field can handle it directly.
  ShortcutInhibitor {
    window: root
    enabled: root.keyboardInputActive
  }

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
    // Ordinary sidebar flyouts remain pointer-driven. Media Player is the
    // explicit keyboard surface; its grab supplies outside-click dismissal.
    active: root.focusGrabActive
    windows: [root]
    onCleared: {
      if (root.focusGrabActive && root.dismissActive)
        root.focusGrabCleared()
    }
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
