import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.temperature"
  property var settings: ({})
  property var manifest: null
  property int temperatureF: 0
  property bool temperatureAvailable: false
  property var thermalSnapshot: ({})
  property var temperatureHistory: []
  property bool flyoutOpen: false
  readonly property bool opened: flyoutOpen

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))
  readonly property int warmF: Math.max(1, Number(setting("warmF", 150)))
  readonly property int criticalF: Math.max(warmF + 1, Number(setting("criticalF", 185)))
  readonly property bool compact: !vertical && barSize <= 26
  readonly property bool showText: setting("showText", compact ? false : true) === true
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property int topbarTextSize: barSize <= 26 ? 12 : 13
  readonly property int contentSpacing: 6
  readonly property int horizontalPadding: vertical ? 0 : 7
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/temperature-plus-filled.svg")
  readonly property string status: temperatureF >= criticalF ? "Hot" : temperatureF >= warmF ? "Warm" : "Normal"
  readonly property color statusColor: colorProfile.statusColor(status.toLowerCase(), "temperature")

  visible: temperatureAvailable
  implicitWidth: temperatureAvailable ? button.implicitWidth : 0
  implicitHeight: temperatureAvailable ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function localPath(url) {
    var value = String(url || "")
    return value.indexOf("file://") === 0 ? decodeURIComponent(value.slice(7)) : value
  }

  function parseTemperature(raw) {
    var parsed = ({})
    try { parsed = JSON.parse(String(raw || "{}")) }
    catch (error) { parsed = ({}) }
    var primary = parsed.primary || {}
    var fahrenheit = Number(primary.fahrenheit || 0)
    if (!isFinite(fahrenheit) || fahrenheit <= 0) {
      temperatureAvailable = false
      return
    }
    thermalSnapshot = parsed
    temperatureF = Math.round(fahrenheit)
    temperatureHistory = temperatureHistory.concat([temperatureF]).slice(-60)
    temperatureAvailable = true
  }

  function refresh() {
    if (!tempProc.running) tempProc.running = true
  }

  function open() {
    flyoutOpen = true
    if (bar) bar.hideTooltip(root)
  }

  function close() { flyoutOpen = false }

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
    command: ["python3", root.localPath(Qt.resolvedUrl("scripts/thermal-snapshot.py"))]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseTemperature(text)
    }
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
    width: root.vertical ? root.barSize : Math.max(root.compact ? root.barSize : 36, content.implicitWidth + root.horizontalPadding * 2)
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
      spacing: root.contentSpacing

      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: root.topbarIconSize + 4
        height: root.topbarIconSize + 4

        Image {
          anchors.centerIn: parent
          source: root.iconSource
          width: root.topbarIconSize
          height: root.topbarIconSize
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
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showText
        width: 1
        height: Math.max(10, root.topbarIconSize - 1)
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
      }

      Text {
        visible: root.showText
        anchors.verticalCenter: parent.verticalCenter
        text: root.temperatureF + " F"
        color: root.foreground
        font.family: bar ? bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: root.topbarTextSize
        font.weight: Font.DemiBold
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
      onClicked: root.open()
    }
  }

  ThermalFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.flyoutOpen
    snapshot: root.thermalSnapshot
    history: root.temperatureHistory
    temperatureF: root.temperatureF
    warmF: root.warmF
    criticalF: root.criticalF
    accentColor: root.statusColor
    normalColor: root.bar && root.bar.accent ? root.bar.accent : root.foreground
    warningColor: colorProfile.statusColor("warning", "temperature")
  }
}
