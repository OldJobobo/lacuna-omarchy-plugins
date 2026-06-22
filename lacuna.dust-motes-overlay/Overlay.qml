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
  property real cursorX: -1
  property real cursorY: -1
  property real lastCursorX: -1
  property real lastCursorY: -1
  property real cursorVelocityX: 0
  property real cursorVelocityY: 0
  property real cursorKick: 0
  property var lacunaSettings: ({})
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: configHome + "/omarchy/current/theme.name"
  readonly property var overlaySettings: pluginSettings()
  readonly property bool configuredEnabled: boolSetting("effectEnabled", true)
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaDustMotesEnabled: backgroundEffectEnabled("dustMotes", true)
  readonly property bool effectVisible: configuredEnabled && lacunaDustMotesEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 0.5), 0, 1)
  readonly property real effectiveIntensity: runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity
  readonly property real speed: clamp(numberSetting("speed", 0.7), 0.15, 4)
  readonly property int moteCount: Math.max(12, Math.min(180, Math.round(numberSetting("moteCount", 72))))
  readonly property real moteSize: clamp(numberSetting("moteSize", 2.6), 1, 8)
  readonly property real accentBlend: clamp(numberSetting("accentBlend", 0.42), 0, 1)
  readonly property bool mouseReactive: boolSetting("mouseReactive", true)
  readonly property real mouseInfluence: clamp(numberSetting("mouseInfluence", 0.28), 0, 1)
  readonly property real cursorInfluenceRadius: 180 + mouseInfluence * 220
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color moteColor: mixColor(themeForeground, themeAccent, accentBlend)

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
      if (!entry || entry.id !== "lacuna.dust-motes-overlay") continue
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

  function seededNoise(seed) {
    var value = Math.sin(seed * 12.9898) * 43758.5453
    return value - Math.floor(value)
  }

  function parsePayload(payloadJson) {
    try {
      return payloadJson ? JSON.parse(payloadJson) : {}
    } catch (error) {
      return {}
    }
  }

  function screenOrigin(screen, axis) {
    var value = screen && screen[axis] !== undefined ? Number(screen[axis]) : 0
    return isNaN(value) ? 0 : value
  }

  function pollCursor() {
    if (!mouseReactive || !effectVisible || cursorProc.running) return
    cursorProc.output = ""
    cursorProc.command = ["hyprctl", "cursorpos", "-j"]
    cursorProc.running = true
  }

  function applyCursorPayload(raw) {
    try {
      var parsed = JSON.parse(raw || "{}")
      var nextX = Number(parsed.x)
      var nextY = Number(parsed.y)
      if (isNaN(nextX) || isNaN(nextY)) return

      if (lastCursorX >= 0 && lastCursorY >= 0) {
        var dx = nextX - lastCursorX
        var dy = nextY - lastCursorY
        var distance = Math.sqrt(dx * dx + dy * dy)
        if (distance > 1) {
          cursorVelocityX = Math.max(-90, Math.min(90, dx))
          cursorVelocityY = Math.max(-90, Math.min(90, dy))
          cursorKick = Math.min(1, distance / 150) * mouseInfluence
          cursorDecayTimer.restart()
        }
      }

      cursorX = nextX
      cursorY = nextY
      lastCursorX = nextX
      lastCursorY = nextY
    } catch (error) {
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

  Timer {
    id: cursorPollTimer

    interval: 120
    repeat: true
    running: root.effectVisible && root.mouseReactive
    triggeredOnStart: true
    onTriggered: root.pollCursor()
  }

  Timer {
    id: cursorDecayTimer

    interval: 150
    repeat: false
    onTriggered: {
      root.cursorVelocityX = 0
      root.cursorVelocityY = 0
      root.cursorKick = 0
    }
  }

  Behavior on cursorVelocityX {
    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
  }

  Behavior on cursorVelocityY {
    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
  }

  Behavior on cursorKick {
    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
  }

  Process {
    id: cursorProc

    property string output: ""

    stdout: SplitParser {
      onRead: function(data) {
        cursorProc.output += data
      }
    }

    onExited: function(exitCode) {
      if (exitCode === 0) root.applyCursorPayload(cursorProc.output)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: dustWindow

      required property var modelData
      readonly property real screenOriginX: root.screenOrigin(modelData, "x")
      readonly property real screenOriginY: root.screenOrigin(modelData, "y")
      readonly property real cursorLocalX: root.cursorX - screenOriginX
      readonly property real cursorLocalY: root.cursorY - screenOriginY

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-dust-motes-overlay"
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
        opacity: root.effectiveIntensity

        Repeater {
          model: root.moteCount

          Rectangle {
            id: mote

            required property int index

            readonly property real seed: index + 1
            readonly property real sizeNoise: root.seededNoise(seed + 2)
            readonly property real centerX: x + width / 2
            readonly property real centerY: y + height / 2
            readonly property real cursorDx: centerX - dustWindow.cursorLocalX
            readonly property real cursorDy: centerY - dustWindow.cursorLocalY
            readonly property real cursorDistance: Math.max(1, Math.sqrt(cursorDx * cursorDx + cursorDy * cursorDy))
            readonly property real cursorFalloff: root.cursorKick > 0 && root.cursorX >= 0 && cursorDistance < root.cursorInfluenceRadius
              ? Math.pow(1 - cursorDistance / root.cursorInfluenceRadius, 2)
              : 0
            readonly property real moteVariance: 0.65 + root.seededNoise(seed + 83) * 0.7
            readonly property real radialPush: 18 * root.cursorKick * cursorFalloff * moteVariance
            readonly property real windScale: 0.16 * cursorFalloff * moteVariance
            readonly property real gustX: cursorDx / cursorDistance * radialPush + root.cursorVelocityX * windScale
            readonly property real gustY: cursorDy / cursorDistance * radialPush + root.cursorVelocityY * windScale
            property real gustOffsetX: gustX
            property real gustOffsetY: gustY
            width: Math.max(1, Math.round(root.moteSize * (0.5 + sizeNoise * 1.4)))
            height: width
            radius: width / 2
            color: root.moteColor
            opacity: 0.16 + root.seededNoise(seed + 7) * 0.50
            scale: 1 + cursorFalloff * root.cursorKick * 0.75
            x: Math.round(root.seededNoise(seed + 11) * Math.max(1, dustWindow.width))
            y: Math.round(root.seededNoise(seed + 17) * Math.max(1, dustWindow.height))

            Behavior on gustOffsetX {
              NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
            }

            Behavior on gustOffsetY {
              NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
              NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Rectangle {
              anchors.centerIn: parent
              width: parent.width * (2.1 + root.cursorKick)
              height: width
              radius: width / 2
              color: root.moteColor
              opacity: mote.cursorFalloff * root.cursorKick * 0.24
            }

            transform: [
              Translate {
                x: mote.gustOffsetX
                y: mote.gustOffsetY
              }
            ]

            SequentialAnimation on x {
              running: root.effectVisible
              loops: Animation.Infinite
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 23) * Math.max(1, dustWindow.width))
                duration: Math.max(8000, Math.round((22000 + root.seededNoise(seed + 29) * 18000) / root.speed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 31) * Math.max(1, dustWindow.width))
                duration: Math.max(8000, Math.round((24000 + root.seededNoise(seed + 37) * 16000) / root.speed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on y {
              running: root.effectVisible
              loops: Animation.Infinite
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 41) * Math.max(1, dustWindow.height))
                duration: Math.max(9000, Math.round((26000 + root.seededNoise(seed + 43) * 20000) / root.speed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 47) * Math.max(1, dustWindow.height))
                duration: Math.max(9000, Math.round((28000 + root.seededNoise(seed + 53) * 18000) / root.speed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on opacity {
              running: root.effectVisible
              loops: Animation.Infinite
              NumberAnimation {
                to: 0.12 + root.seededNoise(seed + 59) * 0.42
                duration: Math.max(3000, Math.round((6500 + root.seededNoise(seed + 61) * 5500) / root.speed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                to: 0.18 + root.seededNoise(seed + 67) * 0.52
                duration: Math.max(3000, Math.round((7000 + root.seededNoise(seed + 71) * 5000) / root.speed))
                easing.type: Easing.InOutSine
              }
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-dust-motes-overlay"

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
        moteCount: root.moteCount,
        moteSize: root.moteSize,
        accentBlend: root.accentBlend,
        mouseReactive: root.mouseReactive,
        mouseInfluence: root.mouseInfluence,
        cursorKick: root.cursorKick
      })
    }
  }
}
