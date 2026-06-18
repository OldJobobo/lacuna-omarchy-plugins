import QtQuick
import Quickshell.Bluetooth

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.bluetooth"
  property var settings: ({})

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var connectedDevices: connectedBluetoothDevices()
  readonly property bool enabled: adapter && adapter.enabled
  readonly property color moduleColor: colorProfile.statusColor(!adapter || !enabled ? "warning" : connectedDevices.length > 0 ? "active" : "normal", "bluetooth")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string icon: {
    if (!adapter) return "󰂲"
    if (!adapter.enabled) return "󰂲"
    if (connectedDevices.length > 0) return "󰂱"
    return "󰂯"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function deviceLabel(device) {
    if (!device) return ""
    return String(device.deviceName || device.name || "").trim()
  }

  function connectedBluetoothDevices() {
    var list = []
    for (var i = 0; i < devices.length; i++) {
      var d = devices[i]
      if (d && d.connected) list.push(d)
    }
    return list
  }

  function tooltip() {
    if (!adapter) return "No Bluetooth adapter"
    if (!adapter.enabled) return "Bluetooth off<br/>Right click to turn on"
    if (connectedDevices.length === 0) return "Bluetooth on<br/>No connected devices"

    var names = []
    for (var i = 0; i < connectedDevices.length; i++) {
      var label = deviceLabel(connectedDevices[i])
      if (label) names.push(label)
    }
    return "Bluetooth connected<br/>" + (names.length > 0 ? names.join("<br/>") : connectedDevices.length + " devices")
  }

  function toggleBluetooth() {
    if (!adapter) return
    adapter.enabled = !adapter.enabled
    if (adapter.enabled) Qt.callLater(function() {
      if (root.adapter) root.adapter.discovering = true
    })
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "bluetooth"
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
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) root.toggleBluetooth()
        else if (root.bar) root.bar.run("omarchy notification send -g 󰂯 \"Bluetooth\" \"$(bluetoothctl show 2>/dev/null; bluetoothctl devices Connected 2>/dev/null)\"")
      }
    }
  }
}
