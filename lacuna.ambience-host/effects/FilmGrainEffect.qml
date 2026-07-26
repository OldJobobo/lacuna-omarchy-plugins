import Quickshell
import Quickshell.Io
import QtQuick
import qs.Commons

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var defaultSettings: ({})
  property bool runtimeEnabled: true
  property real runtimeIntensity: -1
  property int grainTick: 0
  property real grainAccumulator: 0
  property var lacunaSettings: ({})
  readonly property bool reducedMotion: lacunaSettings && lacunaSettings.reduceMotion === true
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string configDir: configHome + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  readonly property string colorsPath: stateHome + "/omarchy/current/theme/colors.toml"
  readonly property var overlaySettings: pluginSettings()
  readonly property var filmGrainSettings: backgroundEffectSettings("filmGrain")
  readonly property bool configuredEnabled: boolSetting("effectEnabled", true)
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaFilmGrainEnabled: backgroundEffectEnabled("filmGrain", true)
  readonly property bool effectVisible: configuredEnabled && lacunaFilmGrainEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(effectNumberSetting("intensity", "intensity", 0.28), 0, 1)
  readonly property real effectiveIntensity: (runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity) * backgroundAnimationOpacity()
  readonly property real speed: clamp(effectNumberSetting("speed", "speed", 1), 0.2, 5)
  readonly property int grainCount: Math.max(32, Math.min(520, Math.round(effectNumberSetting("grainCount", "grainCount", 180))))
  readonly property real grainSize: clamp(effectNumberSetting("grainSize", "grainSize", 1.35), 0.6, 3.5)
  readonly property real accentBlend: clamp(effectNumberSetting("accentBlend", "accentBlend", 0.18), 0, 1)
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color grainColor: mixColor(themeForeground, themeAccent, accentBlend)

  function clamp(value, minimum, maximum) {
    var numeric = Number(value)
    if (isNaN(numeric)) return minimum
    return Math.max(minimum, Math.min(maximum, numeric))
  }

  function pluginSettings() {
    var merged = {}
    var defaults = defaultSettings && typeof defaultSettings === "object"
      ? defaultSettings : (manifest && manifest.defaults ? manifest.defaults : {})
    for (var key in defaults) merged[key] = defaults[key]
    var config = shell && shell.shellConfig ? shell.shellConfig : null
    var plugins = config && config.plugins && Array.isArray(config.plugins) ? config.plugins : []
    for (var i = 0; i < plugins.length; i++) {
      var entry = plugins[i]
      if (!entry || entry.id !== "lacuna.film-grain-overlay") continue
      for (var entryKey in entry) {
        if (entryKey !== "id") merged[entryKey] = entry[entryKey]
      }
      break
    }
    return merged
  }

  function settingValue(key, fallbackValue) {
    return overlaySettings && overlaySettings[key] !== undefined ? overlaySettings[key] : fallbackValue
  }

  function numberSetting(key, fallbackValue) {
    var value = Number(settingValue(key, fallbackValue))
    return isNaN(value) ? fallbackValue : value
  }

  function effectNumberSetting(effectKey, pluginKey, fallbackValue) {
    var value = filmGrainSettings && filmGrainSettings[effectKey] !== undefined
      ? Number(filmGrainSettings[effectKey])
      : numberSetting(pluginKey, fallbackValue)
    return isNaN(value) ? fallbackValue : value
  }

  function boolSetting(key, fallbackValue) {
    var value = settingValue(key, fallbackValue)
    if (value === true || value === false) return value
    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallbackValue
  }

  function backgroundEffectEnabled(effectId, fallbackValue) {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : {}
    var backgroundEffects = settings.backgroundEffects && typeof settings.backgroundEffects === "object" ? settings.backgroundEffects : null
    var id = String(effectId || "")
    if (!backgroundEffects) return fallbackValue
    if (backgroundEffects.enabled === false) return false

    var effects = backgroundEffects.effects && typeof backgroundEffects.effects === "object" ? backgroundEffects.effects : {}
    var effect = effects[id]
    if (effect && typeof effect === "object" && effect.enabled === false) return false

    if (Array.isArray(backgroundEffects.activeEffects)) {
      for (var i = 0; i < backgroundEffects.activeEffects.length; i++) {
        if (String(backgroundEffects.activeEffects[i] || "") === id) return true
      }
      return false
    }

    if (backgroundEffects.activeEffect !== undefined || backgroundEffects.selectedEffect !== undefined || backgroundEffects.currentEffect !== undefined) {
      var activeEffect = String(backgroundEffects.activeEffect || backgroundEffects.selectedEffect || backgroundEffects.currentEffect || "trackingLines")
      return activeEffect === id
    }

    if (!effect || typeof effect !== "object") return fallbackValue
    return effect.enabled !== false
  }

  function backgroundEffectSettings(effectId) {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : {}
    var backgroundEffects = settings.backgroundEffects && typeof settings.backgroundEffects === "object" ? settings.backgroundEffects : null
    var effects = backgroundEffects && backgroundEffects.effects && typeof backgroundEffects.effects === "object" ? backgroundEffects.effects : {}
    var effect = effects[String(effectId || "")]
    return effect && typeof effect === "object" ? effect : ({})
  }

  function backgroundAnimationOpacity() {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : {}
    var backgroundEffects = settings.backgroundEffects && typeof settings.backgroundEffects === "object" ? settings.backgroundEffects : null
    if (!backgroundEffects || backgroundEffects.opacity === undefined) return 1
    return clamp(Number(backgroundEffects.opacity), 0, 1)
  }

  function backgroundForegroundOverlayEnabled() {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : {}
    var backgroundEffects = settings.backgroundEffects && typeof settings.backgroundEffects === "object" ? settings.backgroundEffects : null
    return backgroundEffects && backgroundEffects.foregroundOverlay === true
  }

  function loadLacunaSettings(raw) {
    try {
      lacunaSettings = JSON.parse(raw || "{}")
    } catch (error) {
      lacunaSettings = {}
    }
  }

  function loadTheme(raw) {
    var next = {}
    var lines = String(raw || "").split(/\n/)
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?([^"'\s]+)["']?/)
      if (match) next[match[1]] = match[2].trim()
    }
    if (Object.keys(next).length === 0) return false
    palette = next
    return true
  }

  function scheduleThemeReload() {
    themeReloadTimer.restart()
  }

  function themeColor(name, fallbackColor) {
    if (name === "background" || name === "bg") return Color.background
    if (name === "foreground" || name === "fg") return Color.foreground
    if (name === "accent") return Color.accent
    return palette[name] || fallbackColor
  }

  function resolvedColor(value) {
    return value && value.r !== undefined ? value : Qt.color(value)
  }

  function mixColor(a, b, amount) {
    var first = resolvedColor(a)
    var second = resolvedColor(b)
    var mix = clamp(amount, 0, 1)
    return Qt.rgba(
      first.r + (second.r - first.r) * mix,
      first.g + (second.g - first.g) * mix,
      first.b + (second.b - first.b) * mix,
      first.a + (second.a - first.a) * mix
    )
  }

  function seededNoise(seed) {
    var value = Math.sin(seed * 12.9898 + grainTick * 78.233) * 43758.5453
    return value - Math.floor(value)
  }

  function parsePayload(payloadJson) {
    try {
      return payloadJson ? JSON.parse(payloadJson) : {}
    } catch (error) {
      return {}
    }
  }

  function open(payloadJson) {
    var payload = parsePayload(payloadJson)
    runtimeEnabled = true
    if (payload.intensity !== undefined) runtimeIntensity = clamp(payload.intensity, 0, 1)
  }

  function close() {
    runtimeEnabled = false
  }

  FileView {
    id: lacunaSettingsWatcher
    path: root.settingsFile
    watchChanges: true
    printErrors: false
    onLoaded: root.loadLacunaSettings(text())
    onFileChanged: reload()
    onLoadFailed: root.lacunaSettings = {}
  }

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
    onTriggered: colorsFile.reload()
  }

  Timer {
    id: themeRetryTimer
    interval: 120
    repeat: false
    onTriggered: colorsFile.reload()
  }

  FileView {
    id: colorsFile
    path: root.colorsPath
    watchChanges: false
    printErrors: false
    onLoaded: root.loadTheme(text())
    onLoadFailed: themeRetryTimer.restart()
  }

  FrameAnimation {
    id: grainFrameClock

    running: root.effectVisible && !root.reducedMotion
    onTriggered: {
      root.grainAccumulator += frameTime * 1000
      var interval = Math.max(28, Math.round(88 / root.speed))
      while (root.grainAccumulator >= interval) {
        root.grainTick += 1
        root.grainAccumulator -= interval
      }
    }
  }

  Item {
    id: grainWindow

    anchors.fill: parent
    visible: root.effectVisible


    Item {
      anchors.fill: parent
      enabled: false
      opacity: root.effectiveIntensity

      Repeater {
        model: root.grainCount

        Rectangle {
          required property int index

          readonly property real sizeNoise: root.seededNoise(index + 31)
          x: Math.round(root.seededNoise(index + 3) * Math.max(1, grainWindow.width))
          y: Math.round(root.seededNoise(index + 7) * Math.max(1, grainWindow.height))
          width: Math.max(1, Math.round(root.grainSize + sizeNoise * root.grainSize))
          height: width
          radius: width > 1 ? width / 2 : 0
          color: root.grainColor
          opacity: 0.12 + root.seededNoise(index + 13) * 0.58
        }
      }
    }
  }


}
