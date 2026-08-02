import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})
  property bool updateAvailable: false
  property int intervalMs: 21600000

  function refresh() {
    if (!updateProc.running) updateProc.running = true
  }

  function setIntervalMs(value) {
    intervalMs = Math.max(60000, Math.round(Number(value) || 21600000))
  }

  function clear() {
    updateAvailable = false
  }

  function statusJson() {
    return JSON.stringify({ updateAvailable: updateAvailable })
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: updateProc
    command: ["omarchy", "update", "available"]
    onExited: function(exitCode) { root.updateAvailable = exitCode === 0 }
  }

  IpcHandler {
    target: "lacuna-system-update"

    function refresh(): string {
      root.refresh()
      return root.statusJson()
    }

    function clear(): string {
      root.clear()
      return root.statusJson()
    }

    function status(): string {
      return root.statusJson()
    }
  }
}
