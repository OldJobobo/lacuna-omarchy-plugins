import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

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
  readonly property bool lacunaAuroraDriftEnabled: backgroundEffectEnabled("auroraDrift", true)
  readonly property bool effectVisible: configuredEnabled && lacunaAuroraDriftEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 0.95), 0, 1)
  readonly property real effectiveIntensity: runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity
  readonly property real speed: clamp(numberSetting("speed", 1.35), 0.15, 4)
  readonly property int ribbonCount: Math.max(1, Math.min(9, Math.round(numberSetting("ribbonCount", 6))))
  readonly property real blurSoftness: clamp(numberSetting("blurSoftness", 0.9), 0, 1)
  readonly property real accentBlend: clamp(numberSetting("accentBlend", 0.88), 0, 1)
  readonly property bool vignette: boolSetting("vignette", true)
  readonly property color themeBackground: themeColor("background", "#101315")
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color themeBright: themeColor("color15", themeForeground)
  readonly property color auroraPrimary: darkenColor(mixColor(themeColor("color12", themeAccent), themeAccent, accentBlend), 0.18)
  readonly property color auroraSecondary: darkenColor(mixColor(themeColor("color13", themeAccent), themeAccent, accentBlend * 0.35), 0.22)
  readonly property color auroraWarm: darkenColor(mixColor(themeColor("color11", themeAccent), themeAccent, accentBlend * 0.45), 0.26)
  readonly property color auroraDeep: darkenColor(mixColor(themeColor("color5", themeAccent), themeColor("color13", themeAccent), 0.35), 0.12)
  readonly property color auroraHighlight: darkenColor(mixColor(themeBright, themeAccent, accentBlend * 0.25), 0.28)

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
      if (!entry || entry.id !== "omarchy.lacuna-aurora-drift") continue
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
    if (!backgroundEffects) return fallbackValue
    if (backgroundEffects.enabled === false) return false
    if (backgroundEffects.activeEffect !== undefined || backgroundEffects.selectedEffect !== undefined || backgroundEffects.currentEffect !== undefined) {
      var activeEffect = String(backgroundEffects.activeEffect || backgroundEffects.selectedEffect || backgroundEffects.currentEffect || "trackingLines")
      return activeEffect === String(effectId || "")
    }

    var effects = backgroundEffects.effects && typeof backgroundEffects.effects === "object" ? backgroundEffects.effects : {}
    var effect = effects[String(effectId || "")]
    if (!effect || typeof effect !== "object") return fallbackValue
    return effect.enabled !== false
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

  function darkenColor(value, amount) {
    var base = resolvedColor(value)
    var factor = 1 - clamp(amount, 0, 0.92)
    return Qt.rgba(base.r * factor, base.g * factor, base.b * factor, base.a)
  }

  function colorForRibbon(index) {
    var paletteColors = [auroraPrimary, auroraSecondary, auroraWarm, auroraDeep, auroraHighlight]
    return paletteColors[index % paletteColors.length]
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
      id: auroraWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-aurora-drift"
      WlrLayershell.layer: WlrLayer.Bottom
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
          model: root.ribbonCount

          Item {
            id: ribbon

            readonly property real seed: index + 101
            readonly property real lane: index / Math.max(1, root.ribbonCount - 1)
            readonly property real phase: root.clamp(lane + (root.seededNoise(seed + 1) - 0.5) * 0.18, -0.04, 1.04)
            readonly property real widthScale: 0.82 + root.seededNoise(seed + 3) * 0.42
            readonly property real heightScale: 1.08 + root.seededNoise(seed + 5) * 0.28
            readonly property real xSwing: 0.055 + root.seededNoise(seed + 7) * 0.07
            readonly property real ySwing: 0.04 + root.seededNoise(seed + 11) * 0.035
            readonly property int initialDelay: Math.round(root.seededNoise(seed + 13) * 7600)
            readonly property bool reverseDrift: root.seededNoise(seed + 17) > 0.5
            readonly property int xA: Math.round(auroraWindow.width * (-0.08 + phase * 0.9 - xSwing * 0.5))
            readonly property int xB: Math.round(auroraWindow.width * (-0.08 + phase * 0.9 + xSwing))
            readonly property real yCenter: -height * (0.32 - root.seededNoise(seed + 19) * 0.06)
            readonly property real yA: yCenter - auroraWindow.height * ySwing
            readonly property real yB: yCenter + auroraWindow.height * ySwing
            readonly property int blurPad: Math.round(132 + root.blurSoftness * 168)
            readonly property int ribbonHeight: Math.max(980, Math.round(auroraWindow.height * (1.12 + root.blurSoftness * 0.28) * heightScale))
            readonly property int ribbonWidth: Math.max(150, Math.round(auroraWindow.width * (0.105 + root.blurSoftness * 0.054) * widthScale))
            readonly property real driftSpeed: 0.5 + root.seededNoise(seed + 23) * 0.58
            readonly property color ribbonColor: root.colorForRibbon(index)
            readonly property color companionColor: root.colorForRibbon(index + 1)

            x: reverseDrift ? xB : xA
            y: yA
            width: ribbonWidth + blurPad * 2
            height: ribbonHeight + blurPad * 2
            opacity: 0.57 + root.seededNoise(seed + 29) * 0.2
            rotation: -5 + root.seededNoise(seed + 31) * 10
            transformOrigin: Item.Center
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 96
              blur: 1
              autoPaddingEnabled: true
            }

            SequentialAnimation on x {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: ribbon.initialDelay
              }

              NumberAnimation {
                from: ribbon.reverseDrift ? ribbon.xB : ribbon.xA
                to: ribbon.reverseDrift ? ribbon.xA : ribbon.xB
                duration: Math.max(7200, (12800 + root.seededNoise(ribbon.seed + 37) * 8200) / (root.speed * ribbon.driftSpeed))
                easing.type: Easing.InOutSine
              }

              NumberAnimation {
                from: ribbon.reverseDrift ? ribbon.xA : ribbon.xB
                to: ribbon.reverseDrift ? ribbon.xB : ribbon.xA
                duration: Math.max(7600, (13600 + root.seededNoise(ribbon.seed + 41) * 8600) / (root.speed * ribbon.driftSpeed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(ribbon.initialDelay * 0.47)
              }

              NumberAnimation {
                from: ribbon.yA
                to: ribbon.yB
                duration: Math.max(7600, (13600 + root.seededNoise(ribbon.seed + 43) * 9400) / (root.speed * (0.82 + ribbon.driftSpeed * 0.45)))
                easing.type: Easing.InOutSine
              }

              NumberAnimation {
                from: ribbon.yB
                to: ribbon.yA
                duration: Math.max(8000, (14800 + root.seededNoise(ribbon.seed + 47) * 9600) / (root.speed * (0.78 + ribbon.driftSpeed * 0.48)))
                easing.type: Easing.InOutSine
              }
            }

            Rectangle {
              x: ribbon.blurPad
              y: ribbon.blurPad
              width: ribbon.ribbonWidth
              height: ribbon.ribbonHeight
              radius: width / 2
              opacity: 0.92
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                  position: 0
                  color: "#00000000"
                }
                GradientStop {
                  position: 0.12
                  color: Qt.rgba(ribbon.ribbonColor.r, ribbon.ribbonColor.g, ribbon.ribbonColor.b, 0.31)
                }
                GradientStop {
                  position: 0.28
                  color: Qt.rgba(ribbon.companionColor.r, ribbon.companionColor.g, ribbon.companionColor.b, 0.39)
                }
                GradientStop {
                  position: 0.48
                  color: Qt.rgba(ribbon.ribbonColor.r, ribbon.ribbonColor.g, ribbon.ribbonColor.b, 0.2)
                }
                GradientStop {
                  position: 0.72
                  color: Qt.rgba(ribbon.ribbonColor.r, ribbon.ribbonColor.g, ribbon.ribbonColor.b, 0.07)
                }
                GradientStop {
                  position: 1
                  color: "#00000000"
                }
              }
            }

            Rectangle {
              x: ribbon.blurPad + Math.round(ribbon.ribbonWidth * 0.2)
              y: ribbon.blurPad + Math.round(ribbon.ribbonHeight * 0.08)
              width: Math.round(ribbon.ribbonWidth * 0.58)
              height: Math.round(ribbon.ribbonHeight * 0.58)
              radius: width / 2
              color: Qt.rgba(ribbon.companionColor.r, ribbon.companionColor.g, ribbon.companionColor.b, 0.17)
            }

            Rectangle {
              x: ribbon.blurPad + Math.round(ribbon.ribbonWidth * 0.36)
              y: ribbon.blurPad + Math.round(ribbon.ribbonHeight * 0.22)
              width: Math.round(ribbon.ribbonWidth * 0.5)
              height: Math.round(ribbon.ribbonHeight * 0.42)
              radius: width / 2
              color: Qt.rgba(ribbon.ribbonColor.r, ribbon.ribbonColor.g, ribbon.ribbonColor.b, 0.12)
            }
          }
        }

        Repeater {
          model: Math.max(2, Math.round(root.ribbonCount * 0.75))

          Item {
            id: glow

            readonly property color glowColor: root.colorForRibbon(index + 2)
            readonly property real seed: index + 401
            readonly property real lane: (index + root.seededNoise(seed + 1) * 0.9) / Math.max(1, Math.round(root.ribbonCount * 0.75))
            readonly property int initialDelay: Math.round(root.seededNoise(seed + 3) * 6800)
            readonly property real driftSpeed: 0.62 + root.seededNoise(seed + 5) * 0.7
            readonly property real xSwing: 0.052 + root.seededNoise(seed + 7) * 0.064
            readonly property real ySwing: 0.032 + root.seededNoise(seed + 11) * 0.031
            readonly property int xA: Math.round(auroraWindow.width * (0.04 + lane * 0.82 - xSwing * 0.48))
            readonly property int xB: Math.round(auroraWindow.width * (0.04 + lane * 0.82 + xSwing))
            readonly property real yCenter: -height * (0.26 - root.seededNoise(seed + 13) * 0.05)
            readonly property real yA: yCenter - auroraWindow.height * ySwing
            readonly property real yB: yCenter + auroraWindow.height * ySwing
            readonly property int blurPad: Math.round(124 + root.blurSoftness * 154)
            readonly property int glowWidth: Math.max(170, Math.round(auroraWindow.width * (0.096 + root.blurSoftness * 0.068) * (0.86 + root.seededNoise(seed + 19) * 0.36)))
            readonly property int glowHeight: Math.max(760, Math.round(auroraWindow.height * (0.9 + root.blurSoftness * 0.24) * (0.92 + root.seededNoise(seed + 23) * 0.3)))

            x: xA
            y: yA
            width: glowWidth + blurPad * 2
            height: glowHeight + blurPad * 2
            rotation: -6 + root.seededNoise(seed + 29) * 12
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 96
              blur: 1
              autoPaddingEnabled: true
            }

            Rectangle {
              x: glow.blurPad
              y: glow.blurPad
              width: glow.glowWidth
              height: glow.glowHeight
              radius: width / 2
              color: Qt.rgba(glow.glowColor.r, glow.glowColor.g, glow.glowColor.b, 0.09 + root.blurSoftness * 0.055)
            }

            SequentialAnimation on x {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: glow.initialDelay
              }

              NumberAnimation {
                from: glow.xA
                to: glow.xB
                duration: Math.max(7200, (11600 + root.seededNoise(glow.seed + 31) * 7600) / (root.speed * glow.driftSpeed))
                easing.type: Easing.InOutSine
              }

              NumberAnimation {
                from: glow.xB
                to: glow.xA
                duration: Math.max(7800, (12800 + root.seededNoise(glow.seed + 37) * 8200) / (root.speed * glow.driftSpeed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(glow.initialDelay * 0.56)
              }

              NumberAnimation {
                from: glow.yA
                to: glow.yB
                duration: Math.max(7600, (12400 + root.seededNoise(glow.seed + 41) * 9200) / (root.speed * (0.82 + glow.driftSpeed * 0.4)))
                easing.type: Easing.InOutSine
              }

              NumberAnimation {
                from: glow.yB
                to: glow.yA
                duration: Math.max(8200, (13600 + root.seededNoise(glow.seed + 43) * 9800) / (root.speed * (0.8 + glow.driftSpeed * 0.42)))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: Math.round(glow.initialDelay * 0.32)
              }

              NumberAnimation {
                from: 0.12 + root.seededNoise(glow.seed + 47) * 0.14
                to: 0.42 + root.seededNoise(glow.seed + 53) * 0.26
                duration: Math.max(7200, (11200 + root.seededNoise(glow.seed + 59) * 8400) / root.speed)
                easing.type: Easing.InOutSine
              }

              NumberAnimation {
                from: 0.42 + root.seededNoise(glow.seed + 53) * 0.26
                to: 0.12 + root.seededNoise(glow.seed + 47) * 0.14
                duration: Math.max(7600, (12400 + root.seededNoise(glow.seed + 61) * 8800) / root.speed)
                easing.type: Easing.InOutSine
              }
            }
          }
        }

        Item {
          anchors.fill: parent
          visible: root.vignette
          opacity: 0.46

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
            height: Math.round(parent.height * 0.24)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 1
                color: "#38000000"
              }
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-aurora-drift"

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
        ribbonCount: root.ribbonCount,
        blurSoftness: root.blurSoftness,
        accentBlend: root.accentBlend,
        vignette: root.vignette
      })
    }
  }
}
