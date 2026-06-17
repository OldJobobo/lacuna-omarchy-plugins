import QtQuick
import Quickshell.Services.UPower

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.power"
  property var settings: ({})

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property var device: UPower.displayDevice
  readonly property bool hasBattery: device && device.isPresent
  readonly property real fraction: hasBattery ? Math.max(0, Math.min(1, device.percentage)) : 0
  readonly property int percent: Math.round(fraction * 100)
  readonly property bool low: UPower.onBattery && fraction > 0 && fraction <= 0.2
  readonly property bool charging: hasBattery && device.state === UPowerDeviceState.Charging
  readonly property bool full: hasBattery && device.state === UPowerDeviceState.FullyCharged
  readonly property color moduleColor: colorProfile.statusColor(low ? "critical" : charging ? "active" : "normal", "power")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string icon: batteryIcon()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function batteryIcon() {
    if (!hasBattery) return ""
    var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    var defaultIcons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    var index = Math.max(0, Math.min(9, Math.floor(fraction * 10)))
    if (full) return "󰂅"
    if (charging) return chargingIcons[index]
    if (!UPower.onBattery) return ""
    return defaultIcons[index]
  }

  function tooltip() {
    if (!hasBattery) return "AC power"
    var state = full ? "Fully charged" : charging ? "Charging" : UPower.onBattery ? "On battery" : "Plugged in"
    return "Power<br/>" + state + "<br/>" + percent + "%"
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "power"
  }

  MotionTokens {
    id: motionTokens
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

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
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: root.topbarIconSize
      renderType: Text.NativeRendering
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
        if (mouse.button === Qt.RightButton) root.bar.run("omarchy notification send -g 󰓅 \"Power profile\" \"$(omarchy powerprofiles list --active-state 2>/dev/null || powerprofilesctl get 2>/dev/null)\"")
        else root.bar.run("omarchy notification battery")
      }
    }
  }
}
