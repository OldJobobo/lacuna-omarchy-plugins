import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.bluetooth"
  property var settings: ({})
  property var bluetoothService: null
  property bool flyoutOpen: false
  readonly property bool opened: flyoutOpen

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool available: bluetoothService ? bluetoothService.available : false
  readonly property bool enabled: bluetoothService ? bluetoothService.enabled : false
  readonly property bool connected: bluetoothService ? bluetoothService.connected : false
  readonly property color moduleColor: colorProfile.statusColor(!available || !enabled ? "warning" : connected ? "active" : "normal", "bluetooth")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string icon: bluetoothService ? bluetoothService.icon : "󰂲"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function tooltip() {
    if (bluetoothService && typeof bluetoothService.tooltip === "function") return bluetoothService.tooltip()
    return available ? "Bluetooth" : "No Bluetooth adapter"
  }

  function resolveService() {
    if (bluetoothService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("lacuna.bluetooth")
      if (ensured) {
        bluetoothService = ensured
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("lacuna.bluetooth")
      if (existing) bluetoothService = existing
    }
  }

  function toggleBluetooth() {
    if (bluetoothService && typeof bluetoothService.toggleBluetooth === "function")
      bluetoothService.toggleBluetooth()
  }

  function close() {
    flyoutOpen = false
  }

  function open() {
    flyoutOpen = true
  }

  function togglePanel() {
    flyoutOpen = !flyoutOpen
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

  Component.onCompleted: resolveService()
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.bluetoothService === null
    repeat: true
    onTriggered: root.resolveService()
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
        if (!root.bar) return
        if (mouse.button === Qt.RightButton) root.toggleBluetooth()
        else {
          root.bar.hideTooltip(root)
          root.togglePanel()
        }
      }
    }
  }

  BluetoothFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    service: root.bluetoothService
    accentColor: root.moduleColor
    open: root.flyoutOpen
  }
}
