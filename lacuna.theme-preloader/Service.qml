import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property bool running: false
  property string lastReason: ""
  property string lastStartedAt: ""
  property string lastFinishedAt: ""
  property int lastExitCode: -1
  property string lastStatus: "idle"
  readonly property string sourceDir: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl("."))
  readonly property string script: sourceDir + "/scripts/preload-theme-switcher.sh"

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function timestamp() {
    return new Date().toISOString()
  }

  function warm(reason) {
    if (running) return "running"

    lastReason = String(reason || "manual")
    lastStartedAt = timestamp()
    lastStatus = "running"
    running = true
    preloadProc.command = [script, "--reason", lastReason]
    preloadProc.running = true
    return "started"
  }

  Component.onCompleted: startupWarm.start()

  Timer {
    id: startupWarm

    interval: 4000
    repeat: false
    onTriggered: root.warm("startup")
  }

  Timer {
    interval: 15 * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: root.warm("interval")
  }

  Process {
    id: preloadProc

    onExited: function(exitCode) {
      root.lastExitCode = exitCode
      root.lastFinishedAt = root.timestamp()
      root.lastStatus = exitCode === 0 ? "ok" : "failed"
      root.running = false
    }
  }

  IpcHandler {
    target: "lacuna-theme-preloader"

    function ping(): string {
      return "ok"
    }

    function warm(): string {
      return root.warm("ipc")
    }

    function status(): string {
      return JSON.stringify({
        running: root.running,
        status: root.lastStatus,
        reason: root.lastReason,
        startedAt: root.lastStartedAt,
        finishedAt: root.lastFinishedAt,
        exitCode: root.lastExitCode
      })
    }
  }
}
