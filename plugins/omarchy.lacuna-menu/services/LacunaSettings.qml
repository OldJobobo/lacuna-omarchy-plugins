import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  signal loaded()

  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  property var data: defaultData()

  function defaultData() {
    return {
      version: 1,
      colorProfile: "semantic",
      compact: false,
      sidebar: {
        collapsed: false,
        exclusive: true,
        cornerPieces: true
      }
    }
  }

  function normalize(value) {
    var next = defaultData()
    if (value && typeof value === "object") {
      next.version = Number(value.version || 1)
      next.colorProfile = String(value.colorProfile || "").toLowerCase() === "colorful" ? "colorful" : "semantic"
      next.compact = value.compact === true
      if (value.sidebar && typeof value.sidebar === "object") {
        next.sidebar.collapsed = value.sidebar.collapsed === true
        next.sidebar.exclusive = value.sidebar.exclusive !== false
        next.sidebar.cornerPieces = value.sidebar.cornerPieces !== false
      }
    }
    return next
  }

  function load() {
    if (!loadProc.running) {
      loadProc.output = ""
      loadProc.running = true
    }
  }

  function save(next) {
    data = normalize(next)
    var json = JSON.stringify(data, null, 2) + "\n"
    saveProc.command = ["bash", "-lc", "mkdir -p " + quote(configDir) + "; tmp=$(mktemp); printf %s " + quote(json) + " > \"$tmp\"; mv \"$tmp\" " + quote(settingsFile)]
    saveProc.running = true
  }

  function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  Component.onCompleted: load()

  Process {
    id: loadProc
    property string output: ""
    command: ["bash", "-lc", "cat " + root.quote(root.settingsFile) + " 2>/dev/null || true"]

    stdout: SplitParser {
      onRead: function(chunk) {
        loadProc.output += chunk
      }
    }

    onExited: {
      try {
        root.data = root.normalize(JSON.parse(loadProc.output || "{}"))
      } catch (e) {
        root.data = root.defaultData()
      }
      root.loaded()
    }
  }

  Process {
    id: saveProc
  }
}
