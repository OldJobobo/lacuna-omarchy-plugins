import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property bool runtimeEnabled: true
  property real runtimeIntensity: -1
  property var lacunaSettings: ({})
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: configHome + "/omarchy/current/theme.name"
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
    var defaults = manifest && manifest.defaults ? manifest.defaults : {}
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
    palette = next
  }

  function themeColor(name, fallbackColor) {
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

  FileView {
    id: colorsFile
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadTheme(text())
    onFileChanged: reload()
    onLoadFailed: root.palette = ({})
  }

  FileView {
    id: themeNameFile
    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onFileChanged: colorsFile.reload()
  }

  FrameAnimation {
    id: grainFrameClock

    running: root.effectVisible
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: grainWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-film-grain-overlay"
      WlrLayershell.layer: root.foregroundOverlay ? WlrLayer.Overlay : WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Item {
        anchors.fill: parent
        enabled: false
        opacity: 1

        ShaderEffect {
          anchors.fill: parent
          blending: true
          fragmentShader: Qt.resolvedUrl("shaders/film_grain.frag.qsb")
          property real time: grainFrameClock.elapsedTime * root.speed
          property real intensity: Math.min(1, 0.34 + root.grainCount / 520) * root.effectiveIntensity
          property real grainSize: root.grainSize
          property real accentBlend: root.accentBlend
          property color grainColor: root.grainColor
          property vector2d resolution: Qt.vector2d(Math.max(1, width), Math.max(1, height))
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-film-grain-overlay"

    function enable(): string {
      root.runtimeEnabled = true
      return "enabled"
    }

    function disable(): string {
      root.runtimeEnabled = false
      return "disabled"
    }

    function toggle(): string {
      root.runtimeEnabled = !root.runtimeEnabled
      return root.runtimeEnabled ? "enabled" : "disabled"
    }

    function intensity(value: string): string {
      root.runtimeIntensity = root.clamp(Number(value), 0, 1)
      return String(root.runtimeIntensity)
    }

    function resetIntensity(): string {
      root.runtimeIntensity = -1
      return "reset"
    }

    function status(): string {
      return JSON.stringify({
        configuredEnabled: root.configuredEnabled,
        runtimeEnabled: root.runtimeEnabled,
        visible: root.effectVisible,
        foregroundOverlay: root.foregroundOverlay,
        intensity: root.effectiveIntensity,
        speed: root.speed,
        grainCount: root.grainCount,
        grainSize: root.grainSize,
        accentBlend: root.accentBlend,
        animationOpacity: root.backgroundAnimationOpacity()
      })
    }
  }
}
