import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.notifications"
  property var settings: ({})
  property bool flyoutOpen: false

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property var hostShell: bar && bar.shell ? bar.shell : null
  readonly property var notificationService: hostShell && typeof hostShell.firstPartyServiceFor === "function"
    ? hostShell.firstPartyServiceFor("omarchy.notifications")
    : null
  readonly property int pendingCount: notificationService ? notificationService.pendingModel.count : 0
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor(dnd ? "warning" : pendingCount > 0 ? "active" : "normal", "notifications")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string icon: dnd ? "󰂛" : pendingCount > 0 ? "󱅫" : "󰂚"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function tooltip() {
    if (dnd) return "Do Not Disturb<br/>Right click to allow notifications"
    if (pendingCount > 0) return pendingCount + " pending notification" + (pendingCount === 1 ? "" : "s")
    return "No notifications<br/>Right click to silence notifications"
  }

  function close() {
    flyoutOpen = false
  }

  function togglePanel() {
    flyoutOpen = !flyoutOpen
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "notifications"
  }

  MotionTokens {
    id: motionTokens
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    BarHoverSeam {
      anchors.fill: parent
      reveal: parent.hoverReveal
      seam: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
      accent: colorProfile.accent
    }

    width: root.barSize
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.07
    }

    Text {
      anchors.centerIn: parent
      text: root.icon
      color: root.moduleColor
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: root.topbarIconSize
      renderType: Text.NativeRendering
    }

    Rectangle {
      visible: root.pendingCount > 0 && !root.dnd
      anchors.right: parent.right
      anchors.rightMargin: 4
      anchors.top: parent.top
      anchors.topMargin: 4
      width: 5
      height: 5
      radius: 2.5
      color: root.moduleColor
    }

    Behavior on hoverReveal {
      NumberAnimation {
        duration: motionTokens.hoverDuration
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton) {
          if (root.notificationService) root.notificationService.setDoNotDisturb(!root.notificationService.doNotDisturb)
          else root.bar.run("omarchy toggle notification silencing")
        } else {
          root.bar.hideTooltip(root)
          root.togglePanel()
        }
      }
    }
  }

  Connections {
    target: root.notificationService
    ignoreUnknownSignals: true
    function onHistoryOpenRequested() {
      root.flyoutOpen = true
    }
  }

  NotificationsFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    service: root.notificationService
    accentColor: root.moduleColor
    open: root.flyoutOpen
  }
}
