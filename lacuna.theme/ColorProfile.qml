import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var bar: null
  property var widgetSettings: ({})
  property string role: "foreground"
  property string settingsProfile: "semantic"
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string settingsPath: configHome + "/omarchy/lacuna/settings.json"
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: configHome + "/omarchy/current/theme.name"
  readonly property string profile: normalizeProfile(widgetSetting("colorProfile", settingsProfile))
  readonly property color foreground: bar ? bar.foreground : themeColor("foreground", "#d8dee9")
  readonly property color urgent: bar ? bar.urgent : themeColor("color9", "#d42b5b")
  readonly property color warning: themeColor("color11", "#ebcb8b")

  function widgetSetting(name, fallback) {
    var value = widgetSettings ? widgetSettings[name] : undefined
    return value === undefined || value === null || value === "" ? fallback : value
  }

  function normalizeProfile(value) {
    return String(value || "").toLowerCase() === "colorful" ? "colorful" : "semantic"
  }

  function themeColor(name, fallbackColor) {
    return palette[name] || fallbackColor
  }

  function roleKey(roleName) {
    var map = {
      menu: "accent",
      codex: "color6",
      claude: "color13",
      script: "color14",
      density: "color5",
      disk: "color12",
      memory: "color10",
      cpu: "color11",
      temperature: "color9",
      theme: "color14",
      wallpaper: "color11"
    }
    return map[roleName] || roleName || "foreground"
  }

  function roleColor(roleName, semanticColor) {
    var fallback = semanticColor || foreground
    return profile === "colorful" ? themeColor(roleKey(roleName || role), fallback) : fallback
  }

  function statusColor(status, roleName) {
    if (status === "critical" || status === "hot" || status === "alert" || status === "over") return urgent
    if (status === "warning" || status === "warm" || status === "low") return warning
    return roleColor(roleName || role, foreground)
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
    } catch (e) {
      settingsProfile = "semantic"
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
