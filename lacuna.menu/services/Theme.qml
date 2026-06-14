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
  property color panelBackground: shellSurfaceColor("bar.background", color("background"))
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

    return parseColor(resolveColor(value, fallbackColor), fallbackColor)
  }

  function shellSurfaceColor(name, fallbackColor) {
    var base = shellColor(name, fallbackColor)
    var alphaValue = alphaFor(name)
    if (alphaValue < 0) return base
    return withAlpha(base, alphaValue)
  }

  function alphaFor(name) {
    var value = shellValues[name + "-alpha"]
    if (value === undefined || value === null || String(value).length === 0) return -1
    var parsed = Number(value)
    if (!isFinite(parsed)) return -1
    return Math.max(0, Math.min(1, parsed))
  }

  function stripInlineComment(value) {
    var text = String(value || "")
    var quote = ""
    for (var i = 0; i < text.length; i++) {
      var ch = text.charAt(i)
      if (quote !== "") {
        if (ch === quote && text.charAt(i - 1) !== "\\") quote = ""
        continue
      }
      if (ch === "\"" || ch === "'") {
        quote = ch
        continue
      }
      if (ch === "#" && i > 0 && /\s/.test(text.charAt(i - 1))) {
        return text.slice(0, i).trim()
      }
    }
    return text.trim()
  }

  function unquoteValue(value) {
    var text = stripInlineComment(value)
    if (text.length >= 2) {
      var first = text.charAt(0)
      var last = text.charAt(text.length - 1)
      if ((first === "\"" && last === "\"") || (first === "'" && last === "'"))
        return text.slice(1, -1)
    }
    return text
  }

  function resolveColor(value, fallbackColor) {
    var role = value.toLowerCase()
    if (role === "foreground" || role === "text") return color("foreground")
    if (role === "background") return color("background")
    if (role === "accent") return color("accent")
    if (role === "urgent") return color("color1")
    if (role === "transparent") return "transparent"
    return value
  }

  function parseColor(value, fallbackColor) {
    if (value && value.r !== undefined && value.g !== undefined && value.b !== undefined) return value

    var raw = String(value || "").trim()
    var lower = raw.toLowerCase()
    if (lower === "transparent") return Qt.rgba(0, 0, 0, 0)

    var hex = raw.match(/^#?([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$/)
    if (hex) {
      var body = hex[1]
      var alpha = hex[2] ? parseInt(hex[2], 16) / 255 : 1
      return Qt.rgba(
        parseInt(body.substring(0, 2), 16) / 255,
        parseInt(body.substring(2, 4), 16) / 255,
        parseInt(body.substring(4, 6), 16) / 255,
        alpha
      )
    }

    var rgbHexAlpha = lower.match(/^rgba\(\s*#?([0-9a-f]{6})([0-9a-f]{2})\s*\)$/)
    if (rgbHexAlpha) {
      return Qt.rgba(
        parseInt(rgbHexAlpha[1].substring(0, 2), 16) / 255,
        parseInt(rgbHexAlpha[1].substring(2, 4), 16) / 255,
        parseInt(rgbHexAlpha[1].substring(4, 6), 16) / 255,
        parseInt(rgbHexAlpha[2], 16) / 255
      )
    }

    var rgbHex = lower.match(/^rgba?\(\s*#?([0-9a-f]{6})\s*(?:,\s*([0-9.]+)\s*)?\)$/)
    if (rgbHex) {
      return Qt.rgba(
        parseInt(rgbHex[1].substring(0, 2), 16) / 255,
        parseInt(rgbHex[1].substring(2, 4), 16) / 255,
        parseInt(rgbHex[1].substring(4, 6), 16) / 255,
        rgbHex[2] === undefined ? 1 : Math.max(0, Math.min(1, Number(rgbHex[2])))
      )
    }

    var rgb = lower.match(/^rgba?\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*(?:,\s*([0-9.]+)\s*)?\)$/)
    if (rgb) {
      return Qt.rgba(
        Math.max(0, Math.min(255, Number(rgb[1]))) / 255,
        Math.max(0, Math.min(255, Number(rgb[2]))) / 255,
        Math.max(0, Math.min(255, Number(rgb[3]))) / 255,
        rgb[4] === undefined ? 1 : Math.max(0, Math.min(1, Number(rgb[4])))
      )
    }

    var hyprHex = lower.match(/^0x([0-9a-f]{2})([0-9a-f]{6})$/)
    if (hyprHex) {
      return Qt.rgba(
        parseInt(hyprHex[2].substring(0, 2), 16) / 255,
        parseInt(hyprHex[2].substring(2, 4), 16) / 255,
        parseInt(hyprHex[2].substring(4, 6), 16) / 255,
        parseInt(hyprHex[1], 16) / 255
      )
    }

    if (raw.length > 0)
      console.warn("Lacuna Theme: could not parse color value '" + raw + "'; using fallback")
    return fallbackColor
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

    if (String(raw || "").trim().length > 0 && Object.keys(next).length === 0)
      console.warn("Lacuna Theme: colors.toml has content but produced no parseable entries; check its syntax")
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

      var match = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(.+)$/)
      if (match && section) next[section + "." + match[1]] = unquoteValue(match[2])
    }

    if (String(raw || "").trim().length > 0 && Object.keys(next).length === 0)
      console.warn("Lacuna Theme: shell.toml has content but produced no parseable entries; check its syntax")
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
    onLoadFailed: root.load("")
  }

  FileView {
    id: shellFile

    path: root.shellPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadShell(text())
    onFileChanged: reload()
    onLoadFailed: root.loadShell("")
  }

  FileView {
    id: themeNameFile

    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadThemeName(text())
    onFileChanged: reload()
    onLoadFailed: root.loadThemeName("")
  }
}
