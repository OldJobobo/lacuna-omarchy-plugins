import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  default property alias content: contentLayer.data

  signal focusGrabCleared(string reason)
  signal dismissRequested(string reason)
  signal focusSessionReleased(string reason, int revision)
  signal hotZoneEntered()
  signal hotZoneExited()

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
  property bool shortcutInhibitionActive: false
  property bool dismissActive: false
  property bool focusGrabActive: false
  property string dismissReason: "transition"
  property int focusSessionRevision: 0
  property bool anchorRight: false
  property bool hotZoneEnabled: false
  property real hotZoneX: 0
  property real hotZoneY: 0
  property real hotZoneWidth: 3
  property real hotZoneHeight: height
  readonly property bool textEditingActive: focusedItemEditsText()
  property string layerNamespace: "lacuna-menu"
  readonly property bool inputActive: panelVisible

  function focusedItemEditsText() {
    var item = root.activeFocusItem
    if (!item) return false
    // TextInput/TextEdit expose this combination; pointer controls do not.
    return item.cursorPosition !== undefined
      && item.readOnly !== undefined
      && typeof item.select === "function"
  }

  function requestDismiss(reason) {
    dismissReason = String(reason || "explicit-close")
    dismissRequested(dismissReason)
  }

  function releaseFocusSession() {
    focusGrabArmTimer.stop()
    if (!focusGrabActive) return
    focusGrabActive = false
    focusSessionReleased(dismissReason, focusSessionRevision)
  }

  onDismissActiveChanged: {
    if (dismissActive) focusGrabArmTimer.restart()
    else releaseFocusSession()
  }

  Timer {
    id: focusGrabArmTimer
    interval: 240
    repeat: false
    onTriggered: {
      if (root.dismissActive) {
        root.focusSessionRevision += 1
        root.focusGrabActive = true
      }
    }
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.WindowShortcut
    enabled: root.dismissActive
    onActivated: root.requestDismiss("escape")
  }

  Shortcut {
    sequence: "Backspace"
    context: Qt.WindowShortcut
    // Text editors own Backspace. Only an otherwise unconsumed Backspace
    // dismisses the interactive flyout.
    enabled: root.dismissActive && !root.textEditingActive
    onActivated: root.requestDismiss("backspace")
  }

  visible: panelVisible || keepMapped
  screen: targetScreen
  color: "transparent"
  implicitWidth: Math.max(panelWidth + surfaceRightInset + flyoutLaneWidth, visualWidth,
    hotZoneEnabled ? hotZoneX + hotZoneWidth : 0)
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
  // layer-shell surfaces. Inhibit compositor shortcuts only while the media
  // Search input itself owns focus; Queue and Favorites keep shortcuts active.
  ShortcutInhibitor {
    window: root
    enabled: root.shortcutInhibitionActive
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

    Region {
      x: Math.round(root.hotZoneX)
      y: Math.round(root.hotZoneY)
      width: Math.round(root.hotZoneEnabled ? Math.max(0, root.hotZoneWidth) : 0)
      height: Math.round(root.hotZoneEnabled ? Math.max(0, root.hotZoneHeight) : 0)
    }
  }

  HyprlandFocusGrab {
    // Ordinary sidebar flyouts remain pointer-driven. Media Player is the
    // explicit keyboard surface; its grab supplies outside-click dismissal.
    active: root.focusGrabActive
    windows: [root]
    onCleared: {
      if (root.focusGrabActive && root.dismissActive) {
        root.dismissReason = "click-away"
        root.focusGrabCleared("click-away")
      }
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

  Item {
    id: hotZoneTarget

    x: root.hotZoneX
    y: root.hotZoneY
    width: root.hotZoneEnabled ? Math.max(0, root.hotZoneWidth) : 0
    height: root.hotZoneEnabled ? Math.max(0, root.hotZoneHeight) : 0
    visible: root.hotZoneEnabled
    z: 10000

    HoverHandler {
      id: hotZoneHover
      onHoveredChanged: {
        if (hovered) root.hotZoneEntered()
        else root.hotZoneExited()
      }
    }
  }
}
