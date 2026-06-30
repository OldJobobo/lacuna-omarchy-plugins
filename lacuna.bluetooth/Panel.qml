import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "BluetoothModel.js" as Model

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null
  property bool closingFromHost: false

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "lacuna.bluetooth"
  readonly property var activeService: service || fallbackService
  readonly property color surfaceBackground: opaqueColor(Color.bar.background)
  readonly property color lacunaSurface: Qt.rgba(surfaceBackground.r, surfaceBackground.g, surfaceBackground.b, 0.98)
  readonly property color lacunaPanel: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.045)
  readonly property color lacunaPanelHover: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.11)
  readonly property color lacunaLine: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.14)
  readonly property color lacunaDim: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.60)

  function opaqueColor(colorValue) {
    var c = colorValue
    if (typeof c === "string") c = Qt.color(c)
    return Qt.rgba(c.r, c.g, c.b, 1)
  }

  function resolveService() {
    if (service) return
    if (shell && typeof shell.ensureService === "function") {
      var ensured = shell.ensureService("lacuna.bluetooth")
      if (ensured) {
        service = ensured
        return
      }
    }
    if (shell && typeof shell.serviceFor === "function") {
      var existing = shell.serviceFor("lacuna.bluetooth")
      if (existing) service = existing
    }
  }

  function open(payloadJson) {
    resolveService()
    closingFromHost = false
    window.visible = true
    if (activeService && activeService.enabled && typeof activeService.startDiscovery === "function")
      activeService.startDiscovery()
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  function deviceStatus(device, section) {
    var pending = activeService && typeof activeService.pendingAction === "function" ? activeService.pendingAction(device ? device.address : "") : ""
    return Model.deviceStatus(device, pending, section)
  }

  function activateDevice(device) {
    if (!activeService || !device) return
    if (device.connected) activeService.disconnectDevice(device)
    else activeService.connectDevice(device)
  }

  Component.onCompleted: resolveService()
  onShellChanged: resolveService()

  QtObject {
    id: fallbackService
    property bool available: false
    property bool enabled: false
    property bool discovering: false
    property bool connected: false
    property bool busy: false
    property string icon: "󰂲"
    property string statusText: "Loading"
    property var connectedDevices: []
    property var knownDevices: []
    property var discoveredDevices: []
    function startDiscovery() {}
    function toggleBluetooth() {}
    function connectDevice(device) {}
    function disconnectDevice(device) {}
    function forgetDevice(device) {}
    function deviceLabel(device) { return "" }
    function pendingAction(address) { return "" }
  }

  PanelWindow {
    id: window

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "lacuna-bluetooth-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide(root.pluginId)
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Rectangle {
      id: card

      width: Math.min(Style.space(500), Math.max(Style.space(380), window.width - Style.space(32)))
      height: Math.min(Style.space(650), Math.max(Style.space(420), window.height - Style.space(64)))
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(42)
      anchors.rightMargin: Style.space(14)
      radius: Math.max(2, Style.cornerRadius)
      color: root.lacunaSurface
      border.width: 1
      border.color: root.lacunaLine
      clip: true

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Rectangle {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.space(58)
        color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.035)

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(22)
          spacing: Style.space(8)

          Repeater {
            model: 8
            Rectangle {
              width: index % 3 === 0 ? Style.space(12) : Style.space(6)
              height: Style.space(2)
              radius: 1
              color: index < 4 ? Color.accent : Color.foreground
              opacity: index < 4 ? 0.8 : 0.22
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(28)
          text: "RADIO"
          color: root.lacunaDim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          rotation: -90
        }
      }

      Item {
        id: content
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Style.space(18)
        anchors.leftMargin: Style.space(16)

        Rectangle {
          id: hero
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: Style.space(142)
          radius: Style.cornerRadius
          color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.07)
          border.width: 1
          border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.20)

          Text {
            id: eyebrow
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Style.space(16)
            anchors.topMargin: Style.space(14)
            text: "LACUNA BLUETOOTH PROVIDER"
            color: root.lacunaDim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            id: heroIcon
            anchors.left: parent.left
            anchors.top: eyebrow.bottom
            anchors.leftMargin: Style.space(16)
            anchors.topMargin: Style.space(12)
            text: activeService.icon
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.display
          }

          Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(16)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(16)
            anchors.verticalCenter: heroIcon.verticalCenter
            spacing: Style.space(3)

            Text {
              text: activeService.available ? (activeService.enabled ? "Bluetooth radio" : "Radio disabled") : "No adapter"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              width: parent.width
              elide: Text.ElideRight
            }

            Text {
              text: activeService.statusText.toUpperCase()
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              width: parent.width
              elide: Text.ElideRight
            }
          }

          Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Style.space(16)
            anchors.rightMargin: Style.space(16)
            anchors.bottomMargin: Style.space(14)
            spacing: Style.space(10)

            ActionChip {
              label: activeService.enabled ? "POWER OFF" : "POWER ON"
              enabled: activeService.available
              onTriggered: activeService.toggleBluetooth()
            }

            ActionChip {
              label: activeService.discovering ? "SCANNING" : "SCAN"
              enabled: activeService.available && activeService.enabled
              onTriggered: activeService.startDiscovery()
            }
          }
        }

        Flickable {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: hero.bottom
          anchors.topMargin: Style.space(16)
          anchors.bottom: parent.bottom
          contentWidth: width
          contentHeight: deviceStack.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Column {
            id: deviceStack
            width: parent.width
            spacing: Style.space(12)

            Text {
              visible: activeService.connectedDevices.length > 0
              text: "CONNECTED"
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: activeService.connectedDevices
              DeviceSlat {
                required property var modelData
                width: deviceStack.width
                device: modelData
                sectionName: "connected"
              }
            }

            Text {
              visible: activeService.knownDevices.length > 0
              text: "PAIRED DEVICES"
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: activeService.knownDevices
              DeviceSlat {
                required property var modelData
                width: deviceStack.width
                device: modelData
                sectionName: "known"
              }
            }

            Text {
              visible: activeService.enabled && activeService.discoveredDevices.length > 0
              text: "DISCOVERED"
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: activeService.enabled ? activeService.discoveredDevices : []
              DeviceSlat {
                required property var modelData
                width: deviceStack.width
                device: modelData
                sectionName: "discovered"
              }
            }

            Rectangle {
              visible: activeService.connectedDevices.length === 0
                       && activeService.knownDevices.length === 0
                       && (!activeService.enabled || activeService.discoveredDevices.length === 0)
              width: parent.width
              height: Style.space(92)
              radius: Style.cornerRadius
              color: root.lacunaPanel
              border.width: 1
              border.color: root.lacunaLine

              Text {
                anchors.centerIn: parent
                width: parent.width - Style.space(36)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: !activeService.available ? "No Bluetooth adapter"
                    : !activeService.enabled ? "Power on Bluetooth to scan"
                    : activeService.discovering ? "Scanning for devices..."
                    : "No paired devices"
                color: root.lacunaDim
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
        }
      }
    }
  }

  component ActionChip: Rectangle {
    id: chip
    property string label: ""
    signal triggered()

    width: Math.max(labelText.implicitWidth + Style.space(24), Style.space(92))
    height: Style.space(30)
    radius: Style.space(3)
    color: chipMouse.containsMouse ? root.lacunaPanelHover : root.lacunaPanel
    border.width: 1
    border.color: chip.enabled ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.35) : root.lacunaLine
    opacity: chip.enabled ? 1 : 0.45

    Text {
      id: labelText
      anchors.centerIn: parent
      text: chip.label
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    MouseArea {
      id: chipMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: chip.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (chip.enabled) chip.triggered()
    }
  }

  component DeviceSlat: Rectangle {
    id: slat
    required property var device
    required property string sectionName

    readonly property bool connected: device && device.connected
    readonly property string label: activeService.deviceLabel(device) || "Bluetooth device"
    readonly property string status: root.deviceStatus(device, sectionName)

    height: Style.space(68)
    radius: Style.cornerRadius
    color: slatMouse.containsMouse ? root.lacunaPanelHover : root.lacunaPanel
    border.width: 1
    border.color: connected ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.38) : root.lacunaLine

    MouseArea {
      id: slatMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (!slat.device) return
        if (mouse.button === Qt.RightButton && slat.sectionName !== "discovered")
          activeService.forgetDevice(slat.device)
        else root.activateDevice(slat.device)
      }
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: Style.space(14)
      anchors.verticalCenter: parent.verticalCenter
      text: connected ? "󰂱" : "󰂯"
      color: connected ? Color.accent : root.lacunaDim
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Style.space(50)
      anchors.right: action.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: slat.label
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: slat.status
        color: root.lacunaDim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        elide: Text.ElideRight
      }
    }

    ActionChip {
      id: action
      anchors.right: parent.right
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      label: connected ? "DROP" : sectionName === "discovered" ? "PAIR" : "LINK"
      onTriggered: root.activateDevice(slat.device)
    }
  }
}
