import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-system-stats"
  property var settings: ({})
  property int cpuPercent: 0
  property int memoryPercent: 0
  property string diskText: "--"
  property real previousCpuTotal: 0
  property real previousCpuIdle: 0

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))
  readonly property int buttonSpacing: 2

  visible: true
  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() {
    if (!cpuProc.running) cpuProc.running = true
    if (!memProc.running) memProc.running = true
    if (!diskProc.running) diskProc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "cpu"
  }

  MotionTokens {
    id: motionTokens
  }

  function parseCpu(raw) {
    var fields = String(raw || "").trim().split(/\s+/)
    if (fields.length < 8 || fields[0] !== "cpu") return
    var idle = Number(fields[4] || 0) + Number(fields[5] || 0)
    var total = 0
    for (var i = 1; i < fields.length; i++) total += Number(fields[i] || 0)
    if (previousCpuTotal > 0) {
      var totalDelta = total - previousCpuTotal
      var idleDelta = idle - previousCpuIdle
      if (totalDelta > 0) cpuPercent = Math.max(0, Math.min(100, Math.round((1 - idleDelta / totalDelta) * 100)))
    }
    previousCpuTotal = total
    previousCpuIdle = idle
  }

  function parseMemory(raw) {
    var lines = String(raw || "").split("\n")
    var total = 0
    var available = 0
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split(/\s+/)
      if (parts[0] === "MemTotal:") total = Number(parts[1] || 0)
      else if (parts[0] === "MemAvailable:") available = Number(parts[1] || 0)
    }
    if (total > 0) memoryPercent = Math.max(0, Math.min(100, Math.round((1 - available / total) * 100)))
  }

  function parseDisk(raw) {
    var lines = String(raw || "").trim().split(/\n/)
    if (lines.length < 2) {
      diskText = "??"
      return
    }
    var fields = lines[1].trim().split(/\s+/)
    diskText = fields.length >= 5 ? fields[4] : "??"
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: cpuProc
    command: ["bash", "-lc", "head -n1 /proc/stat"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseCpu(text)
    }
  }

  Process {
    id: memProc
    command: ["bash", "-lc", "head -n3 /proc/meminfo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseMemory(text)
    }
  }

  Process {
    id: diskProc
    command: ["df", "-P", "/"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseDisk(text)
    }
  }

  Row {
    id: content
    spacing: root.buttonSpacing

    StatButton {
      id: diskButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/database-filled.svg")
      label: root.diskText
      tooltip: "<b>Disk usage</b><br/>Root filesystem: " + root.diskText
      accent: colorProfile.roleColor("disk", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
    }

    StatButton {
      id: memButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/stack-3-filled.svg")
      label: root.memoryPercent + "%"
      tooltip: "<b>Memory usage</b><br/>" + root.memoryPercent + "% used"
      accent: root.memoryPercent >= 90 ? root.urgent : colorProfile.roleColor("memory", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
    }

    StatButton {
      id: cpuButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/assembly-filled.svg")
      label: root.cpuPercent + "%"
      tooltip: "<b>CPU usage</b><br/>" + root.cpuPercent + "% used"
      accent: root.cpuPercent >= 90 ? root.urgent : colorProfile.roleColor("cpu", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
    }
  }

  component StatButton: Item {
    property var bar: null
    property url iconSource: ""
    property string label: ""
    property string tooltip: ""
    property color accent: "#d8dee9"
    property bool vertical: false
    property int barSize: 26
    property int hoverDuration: 150
    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    width: vertical ? barSize : Math.max(36, content.implicitWidth + 12)
    height: vertical ? Math.max(barSize, content.implicitHeight + 10) : barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: parent.accent
      opacity: parent.hoverReveal * 0.06
    }

    Row {
      id: content
      anchors.centerIn: parent
      rotation: parent.vertical ? -90 : 0
      spacing: 4

      Image {
        anchors.verticalCenter: parent.verticalCenter
        source: content.parent.iconSource
        width: 14
        height: 14
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        mipmap: true
        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1.0
          colorizationColor: content.parent.accent
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: content.parent.label
        color: content.parent.accent
        font.family: content.parent.bar ? content.parent.bar.fontFamily : "monospace"
        font.pixelSize: 12
        maximumLineCount: 1
      }
    }

    Behavior on hoverReveal {
      NumberAnimation {
        duration: hoverDuration
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      onEntered: if (parent.bar && parent.tooltip) parent.bar.showTooltip(parent, parent.tooltip)
      onExited: if (parent.bar) parent.bar.hideTooltip(parent)
      onClicked: if (parent.bar) parent.bar.run("omarchy launch or focus tui btop")
    }
  }
}
