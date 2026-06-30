import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null
  property bool closingFromHost: false

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "lacuna.power"
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
      var ensured = shell.ensureService("lacuna.power")
      if (ensured) {
        service = ensured
        return
      }
    }
    if (shell && typeof shell.serviceFor === "function") {
      var existing = shell.serviceFor("lacuna.power")
      if (existing) service = existing
    }
  }

  function open(payloadJson) {
    resolveService()
    closingFromHost = false
    window.visible = true
    if (activeService && typeof activeService.refresh === "function") activeService.refresh()
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  Component.onCompleted: resolveService()
  onShellChanged: resolveService()

  QtObject {
    id: fallbackService
    property bool hasBattery: false
    property bool low: false
    property bool charging: false
    property bool discharging: false
    property bool full: false
    property int percent: 0
    property real fraction: 0
    property string icon: ""
    property string modeLabel: "Loading"
    property string activeProfile: ""
    property string activeProfileLabel: ""
    property string activeProfileIcon: "󰂄"
    property var profiles: []
    property var batteryInfo: ({})
    property var systemInfo: ({})
    function refresh() {}
    function setProfile(profile) {}
    function profileIcon(name) { return "󰂄" }
    function profileLabel(name) { return name || "Profile" }
  }

  PanelWindow {
    id: window

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "lacuna-power-panel"
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
      height: Math.min(Style.space(610), Math.max(Style.space(410), window.height - Style.space(64)))
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

        Rectangle {
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          width: Style.space(4)
          height: Math.max(Style.space(18), parent.height * activeService.fraction)
          color: activeService.low ? Color.error : Color.accent
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(30)
          text: "WATTS"
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
          height: Style.space(170)
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
            text: "LACUNA POWER PROVIDER"
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
            anchors.topMargin: Style.space(14)
            text: activeService.icon
            color: activeService.low ? Color.error : Color.accent
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
              width: parent.width
              text: activeService.hasBattery ? activeService.percent + "% reserve" : "AC power"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: activeService.modeLabel.toUpperCase()
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              elide: Text.ElideRight
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Style.space(16)
            anchors.rightMargin: Style.space(16)
            anchors.bottomMargin: Style.space(16)
            height: Style.space(10)
            radius: Style.space(2)
            color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10)

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Math.max(parent.height, parent.width * activeService.fraction)
              radius: Style.space(2)
              color: activeService.low ? Color.error : Color.accent
            }
          }
        }

        Column {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: hero.bottom
          anchors.topMargin: Style.space(16)
          spacing: Style.space(14)

          Rectangle {
            width: parent.width
            height: Style.space(74)
            radius: Style.cornerRadius
            color: root.lacunaPanel
            border.width: 1
            border.color: root.lacunaLine

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(14)
              anchors.verticalCenter: parent.verticalCenter
              text: activeService.activeProfileIcon
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
            }

            Column {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(52)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(14)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                width: parent.width
                text: "Power profile"
                color: root.lacunaDim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Text {
                width: parent.width
                text: activeService.activeProfileLabel || "Unknown"
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.bold: true
                elide: Text.ElideRight
              }
            }
          }

          Flow {
            width: parent.width
            spacing: Style.space(10)

            Repeater {
              model: activeService.profiles
              ActionChip {
                required property string modelData
                label: activeService.profileIcon(modelData) + " " + activeService.profileLabel(modelData).toUpperCase()
                selected: modelData === activeService.activeProfile
                onTriggered: activeService.setProfile(modelData)
              }
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(10)

            StatTile {
              width: (parent.width - Style.space(10)) / 2
              label: "TIME LEFT"
              value: activeService.batteryInfo.time || activeService.batteryInfo.remaining || "Unknown"
            }

            StatTile {
              width: (parent.width - Style.space(10)) / 2
              label: "DRAW"
              value: activeService.batteryInfo.rate || activeService.systemInfo.power || "Unknown"
            }
          }
        }
      }
    }
  }

  component ActionChip: Rectangle {
    id: chip
    property string label: ""
    property bool selected: false
    signal triggered()

    width: Math.max(labelText.implicitWidth + Style.space(24), Style.space(122))
    height: Style.space(32)
    radius: Style.space(3)
    color: selected ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
                    : chipMouse.containsMouse ? root.lacunaPanelHover : root.lacunaPanel
    border.width: 1
    border.color: selected ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.50) : root.lacunaLine

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
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.triggered()
    }
  }

  component StatTile: Rectangle {
    id: tile
    property string label: ""
    property string value: ""

    height: Style.space(70)
    radius: Style.cornerRadius
    color: root.lacunaPanel
    border.width: 1
    border.color: root.lacunaLine

    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: Style.space(12)
      spacing: Style.space(3)

      Text {
        width: parent.width
        text: tile.label
        color: root.lacunaDim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: tile.value
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }
    }
  }
}
