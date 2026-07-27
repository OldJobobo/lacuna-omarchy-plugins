import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var consumers: []
  property var snapshot: ({})
  property int cpuPercent: 0
  property int memoryPercent: 0
  property string diskText: "--"
  property int diskPercent: 0
  property real previousCpuTotal: 0
  property real previousCpuIdle: 0
  property var cpuHistory: []
  property var memoryHistory: []
  property var diskHistory: []
  property int snapshotLaunchCount: 0
  property int snapshotCompletionCount: 0
  readonly property int historyLimit: 60
  readonly property int consumerCount: consumers.length
  readonly property bool polling: consumerCount > 0
  readonly property int intervalMs: requestedInterval()
  readonly property string pluginPath: manifest && manifest.__sourceDir
    ? String(manifest.__sourceDir)
    : localPath(Qt.resolvedUrl("."))

  function localPath(url) {
    var value = String(url || "")
    return value.indexOf("file://") === 0 ? decodeURIComponent(value.slice(7)) : value
  }

  function requestedInterval() {
    var interval = 5000
    for (var i = 0; i < consumers.length; i++) {
      var candidate = Number(consumers[i] && consumers[i].intervalMs)
      if (isFinite(candidate) && candidate >= 1000) interval = Math.min(interval, Math.round(candidate))
    }
    return interval
  }

  function subscribe(consumer) {
    if (!consumer || consumers.indexOf(consumer) >= 0) return
    consumers = consumers.concat([consumer])
    refresh()
  }

  function unsubscribe(consumer) {
    var index = consumers.indexOf(consumer)
    if (index < 0) return
    var next = consumers.slice()
    next.splice(index, 1)
    consumers = next
  }

  function refresh() {
    if (!polling) return
    cpuFile.reload()
    memFile.reload()
    if (!snapshotProc.running) {
      snapshotLaunchCount += 1
      snapshotProc.running = true
    }
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

  function parseSnapshot(raw) {
    var next
    try { next = JSON.parse(String(raw || "{}")) }
    catch (error) { next = ({}) }
    snapshot = next
    var disk = next && next.rootFilesystem ? next.rootFilesystem : null
    if (!disk || !isFinite(Number(disk.percent))) {
      diskText = "??"
      diskPercent = 0
      return
    }
    diskPercent = Math.max(0, Math.min(100, Math.round(Number(disk.percent))))
    diskText = diskPercent + "%"
    diskHistory = diskHistory.concat([diskPercent]).slice(-historyLimit)
  }

  Timer {
    interval: root.intervalMs
    running: root.polling
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
    id: snapshotProc
    command: ["python3", root.pluginPath + "/scripts/system-stats-snapshot.py"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseSnapshot(text)
    }
    onExited: root.snapshotCompletionCount += 1
  }

  IpcHandler {
    target: "lacuna-system-stats"

    function status(): string {
      return JSON.stringify({
        consumers: root.consumerCount,
        polling: root.polling,
        intervalMs: root.intervalMs,
        launches: root.snapshotLaunchCount,
        completions: root.snapshotCompletionCount,
        processRunning: snapshotProc.running,
        disk: root.diskText
      })
    }

    function refresh(): string {
      root.refresh()
      return status()
    }
  }
}
