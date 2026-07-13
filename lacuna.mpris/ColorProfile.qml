import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var bar: null
  property var widgetSettings: ({})
  property string role: "mpris"
  property string settingsProfile: "semantic"
  property string designStyle: "lacuna"
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string settingsPath: configHome + "/omarchy/lacuna/settings.json"
  readonly property string colorsPath: stateHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: stateHome + "/omarchy/current/theme.name"
  readonly property string profile: normalizeProfile(widgetSetting("colorProfile", settingsProfile))
  readonly property color themeBackground: themeColor("background", "#101315")
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color foreground: bar ? bar.foreground : themeColor("foreground", "#d8dee9")
  readonly property color accent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color soft: themeColor("color7", foreground)
  readonly property color playing: themeColor("color10", accent)
  readonly property color paused: mix(themeBackground, themeForeground, 0.54)
  readonly property color hover: mix(themeBackground, themeForeground, 0.24)

  function widgetSetting(name, fallback) {
    var value = widgetSettings ? widgetSettings[name] : undefined
    return value === undefined || value === null || value === "" ? fallback : value
  }

  function normalizeProfile(value) {
    return String(value || "").toLowerCase() === "colorful" ? "colorful" : "semantic"
  }

  function normalizeDesignStyle(value) {
    var style = String(value || "").toLowerCase()
    if (style === "lacuna" || style === "carbon") return "lacuna"
    if (style === "omarchy" || style === "material") return style
    return "lacuna"
  }

  function themeColor(name, fallbackColor) {
    return palette[name] || fallbackColor
  }

  function roleColor(roleName, semanticColor) {
    if (profile !== "colorful") return semanticColor

    var map = {
      mpris: "magenta",
      playing: "green",
      paused: "muted",
      accent: "accent"
    }

    return themeColor(map[roleName] || roleName || role, semanticColor)
  }

  function mix(from, to, amount) {
    return Qt.rgba(
      from.r + (to.r - from.r) * amount,
      from.g + (to.g - from.g) * amount,
      from.b + (to.b - from.b) * amount,
      1
    )
  }

  function loadTheme(raw) {
    var next = {}
    var lines = String(raw || "").split(/\n/)
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?([^"'\s]+)["']?/)
      if (match) next[match[1]] = match[2].trim()
    }
    if (!next.background && next.bg) next.background = next.bg
    if (!next.foreground && next.fg) next.foreground = next.fg
    if (!next.magenta && next.color5) next.magenta = next.color5
    if (!next.green && next.color2) next.green = next.color2
    if (!next.muted && next.color8) next.muted = next.color8
    palette = next
  }

  function loadSettings(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      settingsProfile = normalizeProfile(data.colorProfile || "semantic")
      designStyle = normalizeDesignStyle(data.designStyle || "lacuna")
    } catch (e) {
      settingsProfile = "semantic"
      designStyle = "lacuna"
    }
  }

  FileView {
    id: colorsFile
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadTheme(text())
    onFileChanged: reload()
    onLoadFailed: root.loadTheme("")
  }

  FileView {
    id: themeNameFile
    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onFileChanged: colorsFile.reload()
  }

  FileView {
    id: lacunaSettingsFile
    path: root.settingsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadSettings(text())
    onFileChanged: reload()
    onLoadFailed: root.loadSettings("")
  }
}
