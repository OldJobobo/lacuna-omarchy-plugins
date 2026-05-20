import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-temperature"
  property var settings: ({})
  property int temperatureF: 0
  property bool temperatureAvailable: false

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))
  readonly property int warmF: Math.max(1, Number(setting("warmF", 150)))
  readonly property int criticalF: Math.max(warmF + 1, Number(setting("criticalF", 185)))
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/temperature-plus-filled.svg")
  readonly property string status: temperatureF >= criticalF ? "Hot" : temperatureF >= warmF ? "Warm" : "Normal"
  readonly property color statusColor: colorProfile.statusColor(status.toLowerCase(), "temperature")
  readonly property string temperatureCommand: "for f in /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] || continue; v=$(cat \"$f\" 2>/dev/null) || continue; case \"$v\" in ''|*[!0-9]*) continue;; esac; [ \"$v\" -gt 0 ] && { printf '%s\\n' \"$v\"; exit 0; }; done; exit 1"

  visible: temperatureAvailable
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function parseTemperature(raw) {
    var milliC = Number(String(raw || "").trim())
    if (!isFinite(milliC) || milliC <= 0) {
      temperatureAvailable = false
      return
    }
    temperatureF = Math.round((milliC / 1000 * 9 / 5) + 32)
    temperatureAvailable = true
  }

  function refresh() {
    tempProc.command = ["bash", "-lc", temperatureCommand]
    if (!tempProc.running) tempProc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "temperature"
  }

  MotionTokens {
    id: motionTokens
  }

  function tooltip() {
    return "<b>CPU Temperature</b><br/>Current: " + temperatureF + " F<br/>Status: " + status + "<br/>Warm: " + warmF + " F<br/>Critical: " + criticalF + " F"
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: tempProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseTemperature(text)
    }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0
    readonly property int horizontalPadding: root.vertical ? 0 : 8

    width: root.vertical ? root.barSize : Math.max(36, content.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, content.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.statusColor
      opacity: button.hoverReveal * 0.06
    }

    Row {
      id: content
      anchors.centerIn: parent
      rotation: root.vertical ? -90 : 0
      spacing: 4

      Image {
        anchors.verticalCenter: parent.verticalCenter
        source: root.iconSource
        width: 14
        height: 14
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        mipmap: true
        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1.0
          colorizationColor: root.statusColor
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.temperatureF + " F"
        color: root.statusColor
        font.family: bar ? bar.fontFamily : "monospace"
        font.pixelSize: 12
        font.weight: root.status === "Hot" ? Font.DemiBold : Font.Normal
        maximumLineCount: 1
      }
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
      acceptedButtons: Qt.LeftButton
      onEntered: if (bar) bar.showTooltip(root, root.tooltip())
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: if (bar) bar.run("omarchy launch or focus tui btop")
    }
  }
}
