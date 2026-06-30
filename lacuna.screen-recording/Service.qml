import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})
  property bool recording: false

  readonly property string icon: "󰻂"
  readonly property string statusText: recording ? "Recording" : "Idle"

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function startRecording() {
    Quickshell.execDetached(["omarchy", "capture", "screenrecording"])
    refreshDelay.restart()
  }

  function stopRecording() {
    Quickshell.execDetached(["omarchy", "capture", "screenrecording", "--stop-recording"])
    refreshDelay.restart()
  }

  function toggleRecording() {
    if (recording) stopRecording()
    else startRecording()
  }

  function tooltip() {
    return recording ? "Screen recording active<br/>Click to stop" : "Screen recording<br/>Click to start"
  }

  function statusJson() {
    return JSON.stringify({
      recording: recording,
      statusText: statusText
    })
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 1500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay
    interval: 1500
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(exitCode) { root.recording = exitCode === 0 }
  }

  IpcHandler {
    target: "lacuna-screen-recording"

    function status(): string {
      return root.statusJson()
    }

    function toggle(): string {
      root.toggleRecording()
      return root.statusJson()
    }
  }
}
