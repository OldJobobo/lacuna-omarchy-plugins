import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var settings: ({})
  property string dictationState: "idle"

  readonly property bool active: dictationState === "recording" || dictationState === "transcribing"

  function parseData(raw) {
    try { return JSON.parse(String(raw || "{}")) } catch (e) { return {} }
  }

  function handleStatus(raw) {
    var parsed = parseData(raw)
    dictationState = String(parsed.alt || parsed.class || "idle")
  }

  function statusJson() {
    return JSON.stringify({
      dictationState: dictationState,
      active: active
    })
  }

  Process {
    command: ["omarchy", "voxtype", "status"]
    running: true
    stdout: SplitParser {
      onRead: function(data) { root.handleStatus(data) }
    }
    onExited: root.dictationState = "idle"
  }

  IpcHandler {
    target: "lacuna-voxtype"

    function status(): string {
      return root.statusJson()
    }
  }
}
