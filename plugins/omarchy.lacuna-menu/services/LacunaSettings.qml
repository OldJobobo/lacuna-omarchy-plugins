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
      designStyle: "carbon",
      colorProfile: "semantic",
      compact: false,
      quickLaunch: [],
      appDefaults: {
        files: "system",
        editor: "system",
        email: "system",
        discord: "system"
      },
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
      next.designStyle = normalizeDesignStyle(value.designStyle)
      next.colorProfile = String(value.colorProfile || "").toLowerCase() === "colorful" ? "colorful" : "semantic"
      next.compact = value.compact === true
      next.quickLaunch = normalizeQuickLaunch(value.quickLaunch)
      next.appDefaults = normalizeAppDefaults(value.appDefaults)
      if (value.sidebar && typeof value.sidebar === "object") {
        next.sidebar.collapsed = value.sidebar.collapsed === true
        next.sidebar.exclusive = value.sidebar.exclusive !== false
        next.sidebar.cornerPieces = value.sidebar.cornerPieces !== false
      }
    }
    return next
  }

  function normalizeQuickLaunch(value) {
    var list = []
    if (!value || !Array.isArray(value)) return list

    for (var i = 0; i < value.length; i++) {
      var id = String(value[i] || "").trim()
      if (id !== "" && list.indexOf(id) === -1) list.push(id)
    }

    return list.slice(0, 12)
  }

  function normalizeAppDefaults(value) {
    var defaults = defaultData().appDefaults
    var next = {
      files: defaults.files,
      editor: defaults.editor,
      email: defaults.email,
      discord: defaults.discord
    }

    if (!value || typeof value !== "object") return next

    var roles = ["files", "editor", "email", "discord"]
    for (var i = 0; i < roles.length; i++) {
      var role = roles[i]
      var id = String(value[role] || "").trim()
      next[role] = id === "" ? "system" : id
    }

    return next
  }

  function normalizeDesignStyle(value) {
    var style = String(value || "").toLowerCase()
    if (style === "omarchy" || style === "material") return style
    return "carbon"
  }

  function nextDesignStyle(value) {
    var style = normalizeDesignStyle(value)
    if (style === "carbon") return "omarchy"
    if (style === "omarchy") return "material"
    return "carbon"
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
