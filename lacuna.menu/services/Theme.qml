import Quickshell
import Quickshell.Io
import QtQuick
import qs.Commons
import "../components"

Item {
  id: root

  LacunaLog {
    id: log
    prefix: "Lacuna Theme"
  }

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"
  readonly property string colorsPath: stateHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: stateHome + "/omarchy/current/theme.name"
  property var palette: ({})
  property string themeName: ""
  property string themeTitle: formatTitle(themeName)
  property color foreground: Color.menu.text
  property color background: Color.background
  // Structural Lacuna surfaces attach to the Omarchy bar. Consume the same
  // IPC-updated singleton instead of independently watching shell.toml.
  property color panelBackground: opaqueColor(Color.bar.background)
  property color accent: Color.menu.selectedText
  property color voidColor: withAlpha(background, 0.18)
  property color border: withAlpha(foreground, 0.18)
  property color muted: contrastAwareText(foreground, panelBackground, 4.5)
  property color soft: withAlpha(foreground, 0.78)

  // Design-language color roles (docs/lacuna-design-system/01-color.md).
  // Named, theme-derived aliases over the canonical derivations above: Lacuna
  // owns form, the active Omarchy theme owns hue. The void family keeps the
  // name voidColor ('void' is a reserved word); 'soft' and 'accent' already
  // use their design-language names. danger/warning expose the destructive and
  // caution roles for the unified color model.
  readonly property color field: background
  readonly property color plate: panelBackground
  readonly property color ink: foreground
  readonly property color whisper: muted
  readonly property color seam: border
  readonly property color danger: color("color9")
  readonly property color warning: color("color11")
  readonly property color urgent: contrastAwareRole(palette.red || palette.color9 || fallback("providerYoutube"), panelBackground, 3.0)
  readonly property color providerYoutube: contrastAwareRole(palette.red || palette.color9 || fallback("providerYoutube"), panelBackground, 3.0)
  readonly property color providerJellyfin: contrastAwareRole(palette.magenta || palette.color13 || fallback("providerJellyfin"), panelBackground, 3.0)

  function linearChannel(value) {
    return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4)
  }

  function relativeLuminance(value) {
    return 0.2126 * linearChannel(value.r) + 0.7152 * linearChannel(value.g) + 0.0722 * linearChannel(value.b)
  }

  function contrastRatio(first, second) {
    var firstLuminance = relativeLuminance(first)
    var secondLuminance = relativeLuminance(second)
    return (Math.max(firstLuminance, secondLuminance) + 0.05) / (Math.min(firstLuminance, secondLuminance) + 0.05)
  }

  function mixOpaque(backgroundColor, foregroundColor, amount) {
    var ratio = Math.max(0, Math.min(1, Number(amount)))
    return Qt.rgba(
      backgroundColor.r + (foregroundColor.r - backgroundColor.r) * ratio,
      backgroundColor.g + (foregroundColor.g - backgroundColor.g) * ratio,
      backgroundColor.b + (foregroundColor.b - backgroundColor.b) * ratio,
      1
    )
  }

  function contrastEndpoint(surfaceColor) {
    var black = Qt.rgba(0, 0, 0, 1)
    var white = Qt.rgba(1, 1, 1, 1)
    return contrastRatio(white, surfaceColor) >= contrastRatio(black, surfaceColor) ? white : black
  }

  function contrastAwareRole(roleColor, surfaceColor, targetRatio) {
    var target = Math.max(1, Number(targetRatio) || 3.0)
    var role = opaqueColor(roleColor)
    if (contrastRatio(role, surfaceColor) >= target) return role

    var endpoint = contrastEndpoint(surfaceColor)
    var low = 0
    var high = 1
    for (var i = 0; i < 12; i++) {
      var middle = (low + high) / 2
      var candidate = mixOpaque(role, endpoint, middle)
      if (contrastRatio(candidate, surfaceColor) >= target) high = middle
      else low = middle
    }
    return mixOpaque(role, endpoint, high)
  }

  function contrastAwareText(foregroundColor, surfaceColor, targetRatio) {
    var target = Math.max(1, Number(targetRatio) || 4.5)
    var minimumMix = 0.48
    var candidate = mixOpaque(surfaceColor, foregroundColor, minimumMix)
    if (contrastRatio(candidate, surfaceColor) >= target) return candidate

    var foreground = opaqueColor(foregroundColor)
    if (contrastRatio(foreground, surfaceColor) < target)
      return contrastAwareRole(foreground, surfaceColor, target)

    var low = minimumMix
    var high = 1
    for (var i = 0; i < 12; i++) {
      var middle = (low + high) / 2
      candidate = mixOpaque(surfaceColor, foreground, middle)
      if (contrastRatio(candidate, surfaceColor) >= target) high = middle
      else low = middle
    }
    return mixOpaque(surfaceColor, foreground, high)
  }

  function withAlpha(value, alpha) {
    return Qt.rgba(value.r, value.g, value.b, alpha)
  }

  function opaqueColor(value) {
    return Qt.rgba(value.r, value.g, value.b, 1)
  }

  function color(name) {
    return rawColor(name)
  }

  function rawColor(name) {
    // Omarchy's Color singleton is updated transactionally by shell.applyTheme.
    // Keep colors.toml parsing only for extended Quattro hues Color does not expose.
    if (name === "background" || name === "bg") return Color.background
    if (name === "foreground" || name === "fg") return Color.foreground
    if (name === "accent") return Color.accent
    return palette[name] || fallback(name)
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
      log.warn("could not parse color value '" + raw + "'; using fallback")
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
      color15: "#eceff4",
      providerYoutube: "#e05252",
      providerJellyfin: "#9b7bd7"
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

    if (Object.keys(next).length === 0) {
      if (String(raw || "").trim().length > 0)
        log.warn("colors.toml has content but produced no parseable entries; retaining last palette")
      return false
    }
    palette = next
    return true
  }

  function loadThemeName(raw) {
    var next = String(raw || "").trim()
    if (next.length === 0) return false
    themeName = next
    return true
  }

  function scheduleThemeReload() {
    themeReloadTimer.restart()
  }

  function formatTitle(value) {
    return String(value || "")
      .replace(/[-_]/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
  }

  // Color changes only after Omarchy has atomically installed the new theme
  // and applied its payload over IPC. Debounce the related property signals,
  // then reload the extended palette/name from their settled paths.
  Connections {
    target: Color
    function onBackgroundChanged() { root.scheduleThemeReload() }
    function onForegroundChanged() { root.scheduleThemeReload() }
    function onAccentChanged() { root.scheduleThemeReload() }
    function onUrgentChanged() { root.scheduleThemeReload() }
    function onShellValuesChanged() { root.scheduleThemeReload() }
  }

  Timer {
    id: themeReloadTimer
    interval: 40
    repeat: false
    onTriggered: {
      themeFile.reload()
      themeNameFile.reload()
    }
  }

  Timer {
    id: retryTimer
    interval: 120
    repeat: false
    onTriggered: {
      themeFile.reload()
      themeNameFile.reload()
    }
  }

  FileView {
    id: themeFile
    path: root.colorsPath
    watchChanges: false
    printErrors: false
    onLoaded: root.load(text())
    onLoadFailed: retryTimer.restart()
  }

  FileView {
    id: themeNameFile
    path: root.themeNamePath
    watchChanges: false
    printErrors: false
    onLoaded: root.loadThemeName(text())
    onLoadFailed: retryTimer.restart()
  }
}
