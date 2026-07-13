import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.system-stats"
  property var settings: ({})
  property var manifest: null
  property int cpuPercent: 0
  property int memoryPercent: 0
  property string diskText: "--"
  property int diskPercent: 0
  property var snapshot: ({})
  property real previousCpuTotal: 0
  property real previousCpuIdle: 0
  property var cpuHistory: []
  property var memoryHistory: []
  property var diskHistory: []
  property bool flyoutOpen: false
  property string flyoutMode: "cpu"
  readonly property bool opened: flyoutOpen
  readonly property int historyLimit: 60

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))
  readonly property bool compact: !vertical && barSize <= 26
  readonly property int buttonSpacing: compact ? 0 : 2
  readonly property bool showLabels: setting("showLabels", compact ? false : true) === true

  visible: true
  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() {
    cpuFile.reload()
    memFile.reload()
    if (!diskProc.running) diskProc.running = true
    if (!snapshotProc.running) snapshotProc.running = true
  }

  function localPath(url) {
    var value = String(url || "")
    return value.indexOf("file://") === 0 ? decodeURIComponent(value.slice(7)) : value
  }

  function parseSnapshot(raw) {
    try { snapshot = JSON.parse(String(raw || "{}")) }
    catch (error) { snapshot = ({}) }
  }

  function openMetric(metric) {
    flyoutMode = metric
    flyoutOpen = true
    if (bar) bar.hideTooltip(root)
  }

  function open() { openMetric("cpu") }
  function close() { flyoutOpen = false }

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
    var firstLine = String(raw || "").split("\n")[0]
    var fields = firstLine.trim().split(/\s+/)
    if (fields.length < 8 || fields[0] !== "cpu") return
    var idle = Number(fields[4] || 0) + Number(fields[5] || 0)
    var total = 0
    for (var i = 1; i < fields.length; i++) total += Number(fields[i] || 0)
    if (previousCpuTotal > 0) {
      var totalDelta = total - previousCpuTotal
      var idleDelta = idle - previousCpuIdle
      if (totalDelta > 0) {
        cpuPercent = Math.max(0, Math.min(100, Math.round((1 - idleDelta / totalDelta) * 100)))
        cpuHistory = cpuHistory.concat([cpuPercent]).slice(-historyLimit)
      }
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
    if (total > 0) {
      memoryPercent = Math.max(0, Math.min(100, Math.round((1 - available / total) * 100)))
      memoryHistory = memoryHistory.concat([memoryPercent]).slice(-historyLimit)
    }
  }

  function parseDisk(raw) {
    var lines = String(raw || "").trim().split(/\n/)
    if (lines.length < 2) {
      diskText = "??"
      return
    }
    var fields = lines[1].trim().split(/\s+/)
    diskText = fields.length >= 5 ? fields[4] : "??"
    diskPercent = Math.max(0, Math.min(100, Number(diskText.replace("%", "")) || 0))
    diskHistory = diskHistory.concat([diskPercent]).slice(-historyLimit)
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  FileView {
    id: cpuFile
    path: "/proc/stat"
    watchChanges: false
    printErrors: false
    onLoaded: root.parseCpu(text())
  }

  FileView {
    id: memFile
    path: "/proc/meminfo"
    watchChanges: false
    printErrors: false
    onLoaded: root.parseMemory(text())
  }

  Process {
    id: diskProc
    command: ["df", "-P", "/"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseDisk(text)
    }
  }

  Process {
    id: snapshotProc
    command: ["python3", root.localPath(Qt.resolvedUrl("scripts/system-stats-snapshot.py"))]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseSnapshot(text)
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
      showLabel: root.showLabels
      history: root.diskHistory
      metric: "disk"
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
      showLabel: root.showLabels
      history: root.memoryHistory
      metric: "memory"
    }

    StatButton {
      id: cpuButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/cpu.svg")
      label: root.cpuPercent + "%"
      tooltip: "<b>CPU usage</b><br/>" + root.cpuPercent + "% used"
      accent: root.cpuPercent >= 90 ? root.urgent : colorProfile.roleColor("cpu", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
      showLabel: root.showLabels
      history: root.cpuHistory
      metric: "cpu"
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
    property bool showLabel: true
    property var history: []
    property string metric: "cpu"
    property bool compact: !vertical && barSize <= 26
    property int topbarIconSize: compact ? 12 : barSize >= 30 ? 16 : 14
    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    BarHoverSeam {
      anchors.fill: parent
      reveal: parent.hoverReveal
      seam: parent.bar ? Qt.rgba(parent.bar.foreground.r, parent.bar.foreground.g, parent.bar.foreground.b, 0.35) : "#888888"
      accent: parent.accent
    }

    width: vertical ? barSize : Math.max(compact ? barSize : 36, content.implicitWidth + (compact ? 8 : 12))
    height: vertical ? Math.max(barSize, content.implicitHeight + 10) : barSize
    implicitWidth: width
    implicitHeight: height
    readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

    Rectangle {
      anchors.fill: parent
      color: parent.accent
      opacity: parent.hoverReveal * 0.06
    }

    Row {
      id: content
      anchors.centerIn: parent
      rotation: parent.vertical ? -90 : 0
      spacing: content.parent.showLabel ? (content.parent.compact ? 3 : 4) : 0

      Canvas {
        id: trendCanvas
        visible: content.parent.history.length > 1 && content.parent.showLabel && !content.parent.vertical
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? 18 : 0
        height: 12

        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var values = content.parent.history
          if (values.length < 2) return
          ctx.strokeStyle = content.parent.accent
          ctx.lineWidth = 1
          ctx.beginPath()
          for (var i = 0; i < values.length; i++) {
            var x = i * (width - 1) / Math.max(1, values.length - 1)
            var y = height - 1 - Math.max(0, Math.min(100, Number(values[i]))) * (height - 2) / 100
            if (i === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
          }
          ctx.stroke()
        }

        onVisibleChanged: requestPaint()
        Connections {
          target: content.parent
          function onHistoryChanged() { trendCanvas.requestPaint() }
        }
      }

      Image {
        anchors.verticalCenter: parent.verticalCenter
        source: content.parent.iconSource
        width: content.parent.topbarIconSize
        height: content.parent.topbarIconSize
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
        visible: content.parent.showLabel
        anchors.verticalCenter: parent.verticalCenter
        text: content.parent.label
        color: content.parent.accent
        font.family: content.parent.bar ? content.parent.bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: 14
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
      onClicked: root.openMetric(parent.metric)
    }
  }

  TelemetryFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.flyoutOpen
    mode: root.flyoutMode
    cpuPercent: root.cpuPercent
    memoryPercent: root.memoryPercent
    diskPercent: root.diskPercent
    cpuHistory: root.cpuHistory
    memoryHistory: root.memoryHistory
    diskHistory: root.diskHistory
    snapshot: root.snapshot
    cpuAccent: colorProfile.roleColor("cpu", root.foreground)
    memoryAccent: colorProfile.roleColor("memory", root.foreground)
    diskAccent: colorProfile.roleColor("disk", root.foreground)
  }
}
