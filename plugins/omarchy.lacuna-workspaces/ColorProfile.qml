import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var bar: null
  property var widgetSettings: ({})
  property string role: "workspaces"
  property string settingsProfile: "semantic"
  property string designStyle: "carbon"
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string settingsPath: configHome + "/omarchy/lacuna/settings.json"
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: configHome + "/omarchy/current/theme.name"
  readonly property string profile: normalizeProfile(widgetSetting("colorProfile", settingsProfile))
  readonly property color themeBackground: themeColor("background", "#101315")
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color foreground: bar ? bar.foreground : themeColor("foreground", "#d8dee9")
  readonly property color urgent: bar ? bar.urgent : themeColor("color9", "#d42b5b")
  readonly property color accent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color occupied: themeColor("color10", foreground)
  readonly property color empty: mix(themeBackground, themeForeground, 0.34)
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
    if (style === "omarchy" || style === "material") return style
    return "carbon"
  }

  function themeColor(name, fallbackColor) {
    return palette[name] || fallbackColor
  }

  function roleColor(roleName, semanticColor) {
    if (profile !== "colorful") return semanticColor

    var map = {
      active: "accent",
      occupied: "color10",
      urgent: "color9",
      workspaces: "accent"
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
    palette = next
  }

  function loadSettings(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      settingsProfile = normalizeProfile(data.colorProfile || "semantic")
      designStyle = normalizeDesignStyle(data.designStyle || "carbon")
    } catch (e) {
      settingsProfile = "semantic"
      designStyle = "carbon"
    }
  }

  FileView {
    id: colorsFile
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadTheme(text())
    onFileChanged: reload()
    onLoadFailed: retry.restart()
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
    onLoadFailed: retry.restart()
  }

  Timer {
    id: retry
    interval: 500
    repeat: false
    onTriggered: {
      colorsFile.reload()
      lacunaSettingsFile.reload()
    }
  }
}
