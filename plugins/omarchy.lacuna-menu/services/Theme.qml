import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  readonly property string colorsPath: Quickshell.env("XDG_CONFIG_HOME") ? Quickshell.env("XDG_CONFIG_HOME") + "/omarchy/current/theme/colors.toml" : Quickshell.env("HOME") + "/.config/omarchy/current/theme/colors.toml"
  readonly property string shellPath: Quickshell.env("XDG_CONFIG_HOME") ? Quickshell.env("XDG_CONFIG_HOME") + "/omarchy/current/theme/shell.toml" : Quickshell.env("HOME") + "/.config/omarchy/current/theme/shell.toml"
  readonly property string themeNamePath: Quickshell.env("XDG_CONFIG_HOME") ? Quickshell.env("XDG_CONFIG_HOME") + "/omarchy/current/theme.name" : Quickshell.env("HOME") + "/.config/omarchy/current/theme.name"
  property var palette: ({})
  property var shellValues: ({})
  property string themeName: ""
  property string themeTitle: formatTitle(themeName)
  property color foreground: shellColor("menu.text", color("foreground"))
  property color background: color("background")
  property color accent: shellColor("menu.selected", color("accent"))
  property color voidColor: withAlpha(background, 0.18)
  property color border: withAlpha(foreground, 0.18)
  property color muted: withAlpha(foreground, 0.48)
  property color soft: withAlpha(foreground, 0.78)

  function withAlpha(value, alpha) {
    return Qt.rgba(value.r, value.g, value.b, alpha)
  }

  function color(name) {
    return rawColor(name)
  }

  function rawColor(name) {
    return palette[name] || fallback(name)
  }

  function shellColor(name, fallbackColor) {
    var value = shellValues[name]
    if (typeof value !== "string" || value.length === 0) return fallbackColor

    var role = value.toLowerCase()
    if (role === "foreground" || role === "text") return color("foreground")
    if (role === "background") return color("background")
    if (role === "accent") return color("accent")
    if (role === "urgent") return color("color1")
    if (role === "transparent") return "transparent"
    return value
  }

  function fallback(name) {
    var fallbacks = {
      foreground: "#d8dee9",
      background: "#101315",
      accent: "#8fbcbb",
      color4: "#81a1c1",
      color5: "#b48ead",
      color6: "#88c0d0",
      color7: "#e5e9f0",
      color9: "#bf616a",
      color10: "#a3be8c",
      color11: "#ebcb8b",
      color12: "#81a1c1",
      color13: "#b48ead",
      color14: "#8fbcbb",
      color15: "#eceff4"
    }

    return fallbacks[name] || "#d8dee9"
  }

  function load(raw) {
    var next = {}
    var lines = String(raw || "").split(/\n/)

    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?([^"'\s]+)["']?/)
      if (match) next[match[1]] = match[2].trim()
    }

    palette = next
  }

  function loadShell(raw) {
    var next = {}
    var section = ""
    var lines = String(raw || "").split(/\n/)

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].replace(/^\s+|\s+$/g, "")
      if (line === "" || line.charAt(0) === "#") continue

      var sectionMatch = line.match(/^\[([A-Za-z0-9_-]+)\]\s*(#.*)?$/)
      if (sectionMatch) {
        section = sectionMatch[1]
        continue
      }

      var match = line.match(/^([A-Za-z0-9_-]+)\s*=\s*["']([^"']+)["']\s*(#.*)?$/)
      if (match && section) next[section + "." + match[1]] = match[2]
    }

    shellValues = next
  }

  function loadThemeName(raw) {
    themeName = String(raw || "").trim()
  }

  function formatTitle(value) {
    return String(value || "")
      .replace(/[-_]/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
  }

  FileView {
    id: themeFile

    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.load(text())
    onFileChanged: {
      reload()
    }
    onLoadFailed: themeRetry.restart()
  }

  FileView {
    id: shellFile

    path: root.shellPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadShell(text())
    onFileChanged: reload()
    onLoadFailed: {
      root.loadShell("")
      themeRetry.restart()
    }
  }

  FileView {
    id: themeNameFile

    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadThemeName(text())
    onFileChanged: reload()
    onLoadFailed: themeRetry.restart()
  }

  Timer {
    id: themeRetry

    interval: 500
    repeat: false
    onTriggered: {
      themeFile.reload()
      shellFile.reload()
      themeNameFile.reload()
    }
  }
}
