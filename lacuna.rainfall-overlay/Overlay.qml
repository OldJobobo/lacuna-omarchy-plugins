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
  readonly property bool configuredEnabled: boolSetting("effectEnabled", true)
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaRainfallEnabled: backgroundEffectEnabled("rainfall", true)
  readonly property bool effectVisible: configuredEnabled && lacunaRainfallEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 0.92), 0, 1)
  readonly property real effectiveIntensity: runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity
  readonly property real speed: clamp(numberSetting("speed", 0.62), 0.15, 4)
  readonly property int dropCount: Math.max(16, Math.min(320, Math.round(numberSetting("dropCount", 180))))
  readonly property real slant: clamp(numberSetting("slant", 0.08), -0.2, 0.35)
  readonly property real mistAmount: clamp(numberSetting("mistAmount", 0.42), 0, 1)
  readonly property real splashAmount: clamp(numberSetting("splashAmount", 0.5), 0, 1)
  readonly property real accentBlend: clamp(numberSetting("accentBlend", 0.42), 0, 1)
  readonly property bool vignette: boolSetting("vignette", true)
  readonly property color themeBackground: themeColor("background", "#101315")
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color themeBright: themeColor("color15", themeForeground)
  readonly property color coolRainBase: mixColor("#abc8d6", themeBright, 0.2)
  readonly property color rainColor: mixColor(coolRainBase, themeAccent, accentBlend * 0.35)
  readonly property color shadowRainColor: mixColor(themeBackground, rainColor, 0.58)
  readonly property real windDrift: slant * 0.18
  readonly property real dropRotation: 2 + slant * 16

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
      if (!entry || entry.id !== "lacuna.rainfall-overlay") continue
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

  function parsePayload(payloadJson) {
    try {
      return payloadJson ? JSON.parse(payloadJson) : {}
    } catch (error) {
      return {}
    }
  }

  function seededNoise(seed) {
    var value = Math.sin(seed * 12.9898) * 43758.5453
    return value - Math.floor(value)
  }

  function open(payloadJson) {
    var payload = parsePayload(payloadJson)
    runtimeEnabled = true

    if (payload.intensity !== undefined) {
      runtimeIntensity = clamp(payload.intensity, 0, 1)
    }
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: rainWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-rainfall-overlay"
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
        id: effect

        anchors.fill: parent
        enabled: false
        opacity: root.effectiveIntensity

        Repeater {
          model: root.mistAmount > 0 ? 5 : 0

          Rectangle {
            readonly property real seed: index + 41
            readonly property int bandHeight: Math.round(rainWindow.height * (0.1 + root.seededNoise(seed) * 0.08))

            x: 0
            y: Math.round(rainWindow.height * (0.38 + index * 0.11))
            width: rainWindow.width
            height: bandHeight
            opacity: root.mistAmount * (0.12 + root.seededNoise(seed + 7) * 0.16)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 0.46
                color: Qt.rgba(root.shadowRainColor.r, root.shadowRainColor.g, root.shadowRainColor.b, 0.46)
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }

            SequentialAnimation on x {
              loops: Animation.Infinite
              running: root.effectVisible

              NumberAnimation {
                from: -Math.round(rainWindow.width * 0.04)
                to: Math.round(rainWindow.width * 0.04)
                duration: Math.max(6000, (11000 + index * 1300) / root.speed)
                easing.type: Easing.InOutSine
              }

              NumberAnimation {
                from: Math.round(rainWindow.width * 0.04)
                to: -Math.round(rainWindow.width * 0.04)
                duration: Math.max(6000, (12000 + index * 1200) / root.speed)
                easing.type: Easing.InOutSine
              }
            }
          }
        }

        Repeater {
          model: root.dropCount

          Item {
            id: drop

            readonly property real seed: index + 101
            readonly property int dropLength: Math.round(34 + root.seededNoise(seed + 3) * 70)
            readonly property int dropWidth: root.seededNoise(seed + 5) > 0.7 ? 2 : 1
            readonly property int baseX: Math.round(root.seededNoise(seed + 7) * (rainWindow.width + 420)) - 210
            readonly property int phaseOffset: Math.round(root.seededNoise(seed + 11) * rainWindow.height)
            readonly property real dropSpeed: 0.72 + root.seededNoise(seed + 13) * 0.72
            readonly property real dropOpacity: 0.34 + root.seededNoise(seed + 17) * 0.5

            x: Math.round(baseX + y * root.windDrift)
            y: -dropLength - phaseOffset
            width: dropWidth
            height: dropLength
            opacity: dropOpacity
            rotation: root.dropRotation
            transformOrigin: Item.Center

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(root.seededNoise(drop.seed + 19) * 900)
              }

              NumberAnimation {
                from: -drop.dropLength - drop.phaseOffset
                to: rainWindow.height + drop.dropLength
                duration: Math.max(1500, (2600 + root.seededNoise(drop.seed + 23) * 1200) / (root.speed * drop.dropSpeed))
                easing.type: Easing.Linear
              }
            }

            Rectangle {
              anchors.fill: parent
              radius: Math.max(0.5, width / 2)
              color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.62)
            }

            Rectangle {
              x: Math.max(0, parent.width - 1)
              y: Math.round(parent.height * 0.1)
              width: 1
              height: Math.round(parent.height * 0.56)
              radius: 0.5
              color: "#d7edf5"
              opacity: 0.14
            }

            Rectangle {
              anchors.fill: parent
              radius: Math.max(0.5, width / 2)
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                  position: 0
                  color: "#00000000"
                }
                GradientStop {
                  position: 0.24
                  color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.16)
                }
                GradientStop {
                  position: 0.78
                  color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.68)
                }
                GradientStop {
                  position: 1
                  color: "#00000000"
                }
              }
            }
          }
        }

        Repeater {
          model: Math.max(24, Math.round(rainWindow.width / 34))

          Item {
            id: rainSheet

            readonly property real seed: index + 2201
            readonly property int sheetLength: Math.round(86 + root.seededNoise(seed + 3) * 130)
            readonly property int baseX: Math.round(index * 34 + root.seededNoise(seed + 5) * 46) - 80
            readonly property real sheetSpeed: 0.72 + root.seededNoise(seed + 7) * 0.5

            x: Math.round(baseX + y * root.windDrift * 0.55)
            y: -sheetLength
            width: root.seededNoise(seed + 11) > 0.68 ? 2 : 1
            height: sheetLength
            opacity: 0.18 + root.seededNoise(seed + 13) * 0.16
            rotation: root.dropRotation
            transformOrigin: Item.Center

            NumberAnimation on y {
              from: -rainSheet.sheetLength
              to: rainWindow.height + rainSheet.sheetLength
              duration: Math.max(1900, (3600 + root.seededNoise(rainSheet.seed + 17) * 1500) / (root.speed * rainSheet.sheetSpeed))
              loops: Animation.Infinite
              running: root.effectVisible
              easing.type: Easing.Linear
            }

            Rectangle {
              anchors.fill: parent
              radius: Math.max(0.5, width / 2)
              color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.58)
            }
          }
        }

        Repeater {
          model: Math.max(12, Math.round(root.dropCount * 0.18))

          Item {
            id: foregroundDrop

            readonly property real seed: index + 1301
            readonly property int dropLength: Math.round(54 + root.seededNoise(seed + 3) * 92)
            readonly property int baseX: Math.round(root.seededNoise(seed + 7) * (rainWindow.width + 520)) - 260
            readonly property int phaseOffset: Math.round(root.seededNoise(seed + 11) * rainWindow.height)
            readonly property real dropSpeed: 1.08 + root.seededNoise(seed + 13) * 0.82

            x: Math.round(baseX + y * root.windDrift)
            y: -dropLength - phaseOffset
            width: 3
            height: dropLength
            opacity: 0.72
            rotation: root.dropRotation
            transformOrigin: Item.Center

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(root.seededNoise(foregroundDrop.seed + 19) * 650)
              }

              NumberAnimation {
                from: -foregroundDrop.dropLength - foregroundDrop.phaseOffset
                to: rainWindow.height + foregroundDrop.dropLength
                duration: Math.max(1300, (2200 + root.seededNoise(foregroundDrop.seed + 23) * 900) / (root.speed * foregroundDrop.dropSpeed))
                easing.type: Easing.Linear
              }
            }

            Rectangle {
              anchors.fill: parent
              radius: 1
              color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.7)
            }

            Rectangle {
              x: parent.width - 1
              y: Math.round(parent.height * 0.08)
              width: 1
              height: Math.round(parent.height * 0.58)
              radius: 0.5
              color: "#d7edf5"
              opacity: 0.18
            }

            Rectangle {
              anchors.fill: parent
              radius: 1
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                  position: 0
                  color: "#00000000"
                }
                GradientStop {
                  position: 0.18
                  color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.24)
                }
                GradientStop {
                  position: 0.82
                  color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 1)
                }
                GradientStop {
                  position: 1
                  color: "#00000000"
                }
              }
            }
          }
        }

        Repeater {
          model: Math.round(root.dropCount * root.splashAmount * 0.18)

          Item {
            id: splash

            readonly property real seed: index + 503
            readonly property int splashWidth: Math.round(10 + root.seededNoise(seed + 3) * 28)
            readonly property int baseY: Math.round(rainWindow.height * (0.76 + root.seededNoise(seed + 5) * 0.2))

            x: Math.round(root.seededNoise(seed + 7) * rainWindow.width)
            y: baseY
            width: splashWidth
            height: 6
            opacity: 0
            scale: 0.7

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(450 + root.seededNoise(splash.seed + 11) * 1900)
              }

              NumberAnimation {
                from: 0
                to: 0.34
                duration: Math.max(90, 150 / root.speed)
                easing.type: Easing.OutCubic
              }

              NumberAnimation {
                from: 0.34
                to: 0
                duration: Math.max(220, 520 / root.speed)
                easing.type: Easing.OutCubic
              }
            }

            SequentialAnimation on scale {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(450 + root.seededNoise(splash.seed + 11) * 1900)
              }

              NumberAnimation {
                from: 0.7
                to: 1.35
                duration: Math.max(310, 670 / root.speed)
                easing.type: Easing.OutCubic
              }
            }

            Rectangle {
              x: 0
              y: 2
              width: parent.width
              height: 1
              radius: 1
              color: Qt.rgba(root.rainColor.r, root.rainColor.g, root.rainColor.b, 0.72)
            }

            Rectangle {
              x: Math.round(parent.width * 0.18)
              y: 4
              width: Math.round(parent.width * 0.58)
              height: 1
              radius: 1
              color: Qt.rgba(root.shadowRainColor.r, root.shadowRainColor.g, root.shadowRainColor.b, 0.55)
            }
          }
        }

        Item {
          anchors.fill: parent
          visible: root.vignette
          opacity: 0.48

          Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: Math.round(parent.height * 0.18)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#30000000"
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }
          }

          Rectangle {
            x: 0
            y: parent.height - height
            width: parent.width
            height: Math.round(parent.height * 0.28)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 1
                color: "#46000000"
              }
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-rainfall-overlay"

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
        intensity: root.effectiveIntensity,
        speed: root.speed,
        dropCount: root.dropCount,
        slant: root.slant,
        mistAmount: root.mistAmount,
        splashAmount: root.splashAmount,
        accentBlend: root.accentBlend,
        vignette: root.vignette
      })
    }
  }
}
