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
      barSizeMode: "theme",
      barSizeSnapshot: null,
      customQuickLaunchApps: [],
      customQuickLaunchNames: {},
      preferredApps: {
        files: "system",
        editor: "system",
        email: "system",
        discord: "system"
      },
      sidebar: {
        collapsed: false,
        exclusive: true,
        cornerPieces: true
      },
      frame: {
        mode: "off",
        shadow: false,
        thickness: 8,
        radius: 14,
        shadowDirection: "bottom_right",
        shadowOffsetX: 2,
        shadowOffsetY: 3
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
      next.barSizeMode = normalizeBarSizeMode(value.barSizeMode)
      next.barSizeSnapshot = normalizeBarSizeSnapshot(value.barSizeSnapshot)
      next.customQuickLaunchApps = normalizeCustomQuickLaunchApps(value.customQuickLaunchApps || value.quickLaunch)
      next.customQuickLaunchNames = normalizeCustomQuickLaunchNames(value.customQuickLaunchNames || value.quickLaunchNames, next.customQuickLaunchApps)
      next.preferredApps = normalizePreferredApps(value.preferredApps || value.defaultLaunchers || value.appDefaults)
      if (value.sidebar && typeof value.sidebar === "object") {
        next.sidebar.collapsed = value.sidebar.collapsed === true
        next.sidebar.exclusive = value.sidebar.exclusive !== false
        next.sidebar.cornerPieces = value.sidebar.cornerPieces !== false
      }
      if (value.frame && typeof value.frame === "object") {
        next.frame.mode = normalizeFrameMode(value.frame.mode)
        next.frame.shadow = value.frame.shadow === true
        next.frame.thickness = boundedInt(value.frame.thickness, 8, 2, 24)
        next.frame.radius = boundedInt(value.frame.radius, 14, 0, 32)
        next.frame.shadowDirection = normalizeShadowDirection(value.frame.shadowDirection)
        var offset = shadowOffsetFor(next.frame.shadowDirection)
        next.frame.shadowOffsetX = boundedInt(value.frame.shadowOffsetX, offset.x, -8, 8)
        next.frame.shadowOffsetY = boundedInt(value.frame.shadowOffsetY, offset.y, -8, 8)
      }
    }
    return next
  }

  function boundedInt(value, fallback, minimum, maximum) {
    var parsed = Math.round(Number(value))
    if (!isFinite(parsed)) return fallback
    return Math.max(minimum, Math.min(maximum, parsed))
  }

  function normalizeFrameMode(value) {
    var mode = String(value || "").toLowerCase()
    if (mode === "sidebar" || mode === "fullframe") return mode
    return "off"
  }

  function normalizeShadowDirection(value) {
    var direction = String(value || "").toLowerCase()
    var valid = {
      top_left: true,
      top: true,
      top_right: true,
      left: true,
      center: true,
      right: true,
      bottom_left: true,
      bottom: true,
      bottom_right: true
    }
    return valid[direction] ? direction : "bottom_right"
  }

  function shadowOffsetFor(value) {
    var direction = normalizeShadowDirection(value)
    if (direction === "top_left") return Qt.point(-2, -2)
    if (direction === "top") return Qt.point(0, -3)
    if (direction === "top_right") return Qt.point(2, -2)
    if (direction === "left") return Qt.point(-3, 0)
    if (direction === "center") return Qt.point(0, 0)
    if (direction === "right") return Qt.point(3, 0)
    if (direction === "bottom_left") return Qt.point(-2, 2)
    if (direction === "bottom") return Qt.point(0, 3)
    return Qt.point(2, 3)
  }

  function normalizeBarSizeMode(value) {
    var mode = String(value || "").toLowerCase()
    if (mode === "compact" || mode === "full") return mode
    return "theme"
  }

  function normalizeBarSizeSnapshot(value) {
    if (!value || typeof value !== "object") return null

    var themeName = String(value.themeName || "").trim()
    var sizeHorizontal = Math.round(Number(value.sizeHorizontal))
    var sizeVertical = Math.round(Number(value.sizeVertical))

    if (themeName === "" || !isFinite(sizeHorizontal) || !isFinite(sizeVertical)) return null
    if (sizeHorizontal <= 0 || sizeVertical <= 0) return null

    return {
      themeName: themeName,
      sizeHorizontal: sizeHorizontal,
      sizeVertical: sizeVertical
    }
  }

  function normalizeCustomQuickLaunchApps(value) {
    var list = []
    if (!value || !Array.isArray(value)) return list

    for (var i = 0; i < value.length; i++) {
      var id = String(value[i] || "").trim()
      if (id.indexOf("role:") === 0) continue
      if (id !== "" && list.indexOf(id) === -1) list.push(id)
    }

    return list.slice(0, 12)
  }

  function normalizeCustomQuickLaunchNames(value, ids) {
    var names = {}
    if (!value || typeof value !== "object") return names

    for (var i = 0; i < ids.length; i++) {
      var id = String(ids[i] || "")
      var name = String(value[id] || "").trim()
      if (id !== "" && name !== "") names[id] = name.slice(0, 48)
    }

    return names
  }

  function normalizePreferredApps(value) {
    var defaults = defaultData().preferredApps
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
