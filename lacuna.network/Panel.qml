import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "NetworkModel.js" as Model

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null
  property bool closingFromHost: false
  property string passwordSsid: ""
  property string passwordText: ""

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "lacuna.network"
  readonly property var activeService: service || fallbackService
  readonly property var wifiNetworks: activeService && activeService.wifiNetworks ? activeService.wifiNetworks : []
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
      var ensured = shell.ensureService("lacuna.network")
      if (ensured) {
        service = ensured
        return
      }
    }
    if (shell && typeof shell.serviceFor === "function") {
      var existing = shell.serviceFor("lacuna.network")
      if (existing) service = existing
    }
  }

  function open(payloadJson) {
    resolveService()
    closingFromHost = false
    window.visible = true
    if (activeService && typeof activeService.refresh === "function") activeService.refresh(true)
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  function rowTitle(index) {
    return Model.wifiSectionTitle(wifiNetworks, index)
  }

  function rowStatus(row) {
    if (!row) return ""
    if (activeService && activeService.actionSsid === row.ssid && activeService.actionKind === "connect") return "CONNECTING"
    if (activeService && activeService.actionSsid === row.ssid && activeService.actionKind === "disconnect") return "DISCONNECTING"
    if (activeService && activeService.actionSsid === row.ssid && activeService.actionKind === "forget") return "FORGETTING"
    if (row.connected) return "ONLINE"
    if (row.known) return "KNOWN"
    return activeService && activeService.isProtected(row.security) ? "LOCKED" : "OPEN"
  }

  function activateRow(row) {
    if (!activeService || !row || activeService.busy) return
    if (row.connected) {
      activeService.disconnect(row.network)
    } else if (activeService.isProtected(row.security) && !row.known) {
      passwordSsid = row.ssid
      passwordText = ""
    } else {
      activeService.connectKnown(row.ssid)
    }
  }

  Component.onCompleted: resolveService()
  onShellChanged: resolveService()

  QtObject {
    id: fallbackService
    property string displayTitle: "Network"
    property string displayLabel: "Loading"
    property string icon: "󰤮"
    property bool connected: false
    property bool wifiEnabled: false
    property bool networkManagerAvailable: false
    property bool wifiStationAvailable: false
    property bool scanning: false
    property bool busy: false
    property string lastError: ""
    property string actionSsid: ""
    property string actionKind: ""
    property var wifiNetworks: []
    function refresh(scanWifi) {}
    function toggleWifi() {}
    function isProtected(security) { return false }
    function canForgetNetwork(row) { return false }
  }

  PanelWindow {
    id: window

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "lacuna-network-panel"
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

      width: Math.min(Style.space(520), Math.max(Style.space(390), window.width - Style.space(32)))
      height: Math.min(Style.space(650), Math.max(Style.space(430), window.height - Style.space(64)))
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
        id: spine
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.space(54)
        color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.035)

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Style.space(3)
          color: Color.accent
        }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(22)
          spacing: Style.space(10)

          Repeater {
            model: 7
            Rectangle {
              width: index === 0 || index === 6 ? Style.space(8) : Style.space(5)
              height: width
              radius: width / 2
              color: index <= 2 ? Color.accent : Color.foreground
              opacity: index <= 2 ? 0.9 : 0.23
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(24)
          text: "LINK"
          color: root.lacunaDim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          rotation: -90
        }
      }

      Item {
        id: content
        anchors.left: spine.right
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
          color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.075)
          border.width: 1
          border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.20)

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Color.foreground
            opacity: 0.12
          }

          Text {
            id: eyebrow
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Style.space(16)
            anchors.topMargin: Style.space(14)
            text: "LACUNA NETWORK PROVIDER"
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
            anchors.topMargin: Style.space(10)
            text: activeService.icon
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.display
          }

          Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(15)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(16)
            anchors.verticalCenter: heroIcon.verticalCenter
            spacing: Style.space(3)

            Text {
              width: parent.width
              text: activeService.displayTitle
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: activeService.displayLabel
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
          }

          Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.space(12)
            spacing: Style.space(8)

            ActionChip {
              text: activeService.scanning ? "SCANNING" : "SCAN"
              enabled: !activeService.scanning
              accent: Color.accent
              onTriggered: activeService.refresh(true)
            }

            ActionChip {
              text: activeService.wifiEnabled ? "WIFI ON" : "WIFI OFF"
              accent: activeService.wifiEnabled ? Color.accent : root.lacunaDim
              onTriggered: activeService.toggleWifi()
            }

            ActionChip {
              text: "CLOSE"
              accent: root.lacunaDim
              onTriggered: root.close()
            }
          }
        }

        Rectangle {
          id: errorBanner
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: hero.bottom
          anchors.topMargin: Style.space(10)
          height: activeService.lastError !== "" ? Style.space(34) : 0
          radius: Style.cornerRadius
          color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.10)
          border.width: activeService.lastError !== "" ? 1 : 0
          border.color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.28)
          visible: height > 0

          Text {
            anchors.fill: parent
            anchors.margins: Style.space(9)
            text: activeService.lastError
            color: Color.urgent
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        Text {
          id: sectionTitle
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: errorBanner.visible ? errorBanner.bottom : hero.bottom
          anchors.topMargin: Style.space(16)
          text: activeService.networkManagerAvailable ? "SIGNALS IN RANGE" : "NETWORKMANAGER UNAVAILABLE"
          color: root.lacunaDim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Flickable {
          id: networkScroller
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: sectionTitle.bottom
          anchors.topMargin: Style.space(8)
          anchors.bottom: parent.bottom
          clip: true
          contentWidth: width
          contentHeight: networkColumn.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: networkColumn
            width: networkScroller.width
            spacing: Style.space(7)

            Repeater {
              model: root.wifiNetworks

              Column {
                required property int index
                required property var modelData

                width: parent ? parent.width : 0
                spacing: Style.space(5)

                Text {
                  width: parent.width
                  visible: root.rowTitle(index) !== ""
                  text: root.rowTitle(index).toUpperCase()
                  color: root.lacunaDim
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                NetworkSlat {
                  width: parent.width
                  row: modelData
                  statusText: root.rowStatus(modelData)
                  passwordOpen: root.passwordSsid === modelData.ssid
                }
              }
            }

            Text {
              width: parent.width
              visible: root.wifiNetworks.length === 0
              text: activeService.wifiStationAvailable ? "No signals found" : "No Wi-Fi adapter found"
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              topPadding: Style.space(42)
            }
          }
        }
      }
    }
  }

  component ActionChip: Rectangle {
    id: chip

    signal triggered()

    property string text: ""
    property color accent: Color.accent
    property bool enabled: true

    width: label.implicitWidth + Style.space(20)
    height: Style.space(28)
    radius: height / 2
    color: chipMouse.containsMouse && enabled
      ? Qt.rgba(accent.r, accent.g, accent.b, 0.18)
      : Qt.rgba(accent.r, accent.g, accent.b, 0.075)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, enabled ? 0.35 : 0.15)
    opacity: enabled ? 1 : 0.48

    Text {
      id: label
      anchors.centerIn: parent
      text: chip.text
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    MouseArea {
      id: chipMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: chip.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.triggered()
    }
  }

  component SignalBars: Row {
    id: bars

    property int strength: 0
    property color accent: Color.accent

    spacing: Style.space(3)
    height: Style.space(22)

    Repeater {
      model: 5
      Rectangle {
        width: Style.space(4)
        height: Style.space(6 + index * 3)
        anchors.bottom: parent.bottom
        radius: width / 2
        color: bars.accent
        opacity: bars.strength >= (index + 1) * 20 ? 0.95 : 0.18
      }
    }
  }

  component NetworkSlat: Rectangle {
    id: slat

    required property var row
    property string statusText: ""
    property bool passwordOpen: false

    height: passwordOpen ? Style.space(122) : Style.space(66)
    radius: Style.cornerRadius
    color: row && row.connected
      ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, slatMouse.containsMouse ? 0.18 : 0.11)
      : (slatMouse.containsMouse ? root.lacunaPanelHover : root.lacunaPanel)
    border.width: 1
    border.color: row && row.connected ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.42) : root.lacunaLine

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: row && row.connected ? Style.space(4) : 1
      radius: width / 2
      color: row && row.connected ? Color.accent : root.lacunaLine
      opacity: row && row.connected ? 1 : 0.55
    }

    Text {
      id: ssidText
      anchors.left: parent.left
      anchors.right: signalBars.left
      anchors.top: parent.top
      anchors.leftMargin: Style.space(15)
      anchors.rightMargin: Style.space(12)
      anchors.topMargin: Style.space(12)
      text: row ? (row.ssid || "Hidden network") : ""
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: row && row.connected
      elide: Text.ElideRight
    }

    Text {
      anchors.left: ssidText.left
      anchors.right: ssidText.right
      anchors.top: ssidText.bottom
      anchors.topMargin: Style.space(4)
      text: statusText + " / " + (row ? row.signal : 0) + "%"
      color: root.lacunaDim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    SignalBars {
      id: signalBars
      anchors.right: actionColumn.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: passwordOpen ? undefined : parent.verticalCenter
      anchors.top: passwordOpen ? parent.top : undefined
      anchors.topMargin: passwordOpen ? Style.space(16) : 0
      strength: row ? row.signal : 0
      accent: row && row.connected ? Color.accent : Color.foreground
    }

    Column {
      id: actionColumn
      anchors.right: parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: passwordOpen ? undefined : parent.verticalCenter
      anchors.top: passwordOpen ? parent.top : undefined
      anchors.topMargin: passwordOpen ? Style.space(10) : 0
      spacing: Style.space(6)

      ActionChip {
        text: row && row.connected ? "DROP" : "JOIN"
        accent: row && row.connected ? root.lacunaDim : Color.accent
        enabled: !activeService.busy
        onTriggered: root.activateRow(row)
      }

      ActionChip {
        visible: activeService.canForgetNetwork(row)
        text: "FORGET"
        accent: root.lacunaDim
        enabled: !activeService.busy
        onTriggered: activeService.forget(row)
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Style.space(10)
      height: passwordOpen ? Style.space(38) : 0
      visible: passwordOpen
      radius: Style.cornerRadius
      color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.055)
      border.width: 1
      border.color: root.lacunaLine

      TextField {
        id: passphraseField
        anchors.left: parent.left
        anchors.right: joinSecret.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.space(10)
        anchors.rightMargin: Style.space(8)
        placeholderText: "passphrase"
        echoMode: TextInput.Password
        text: root.passwordText
        background: null
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        onTextChanged: root.passwordText = text
        onAccepted: {
          activeService.connectWithPassphrase(row.ssid, root.passwordText)
          root.passwordSsid = ""
        }
      }

      ActionChip {
        id: joinSecret
        anchors.right: cancelSecret.left
        anchors.rightMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        text: "SEND"
        accent: Color.accent
        enabled: root.passwordText.length > 0 && !activeService.busy
        onTriggered: {
          activeService.connectWithPassphrase(row.ssid, root.passwordText)
          root.passwordSsid = ""
        }
      }

      ActionChip {
        id: cancelSecret
        anchors.right: parent.right
        anchors.rightMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        text: "X"
        accent: root.lacunaDim
        onTriggered: root.passwordSsid = ""
      }
    }

    MouseArea {
      id: slatMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    Connections {
      target: row && row.network ? row.network : null
      function onConnectionFailed(reason) {
        if (activeService && typeof activeService.failNetworkAction === "function")
          activeService.failNetworkAction(row.network, reason)
        if (activeService && reason === ConnectionFailReason.NoSecrets) {
          root.passwordSsid = row.ssid
          root.passwordText = ""
        }
      }
      function onConnectedChanged() {
        if (activeService && typeof activeService.checkActionCompletion === "function")
          activeService.checkActionCompletion(row.network)
      }
      function onKnownChanged() {
        if (activeService && typeof activeService.checkActionCompletion === "function")
          activeService.checkActionCompletion(row.network)
      }
    }
  }
}
