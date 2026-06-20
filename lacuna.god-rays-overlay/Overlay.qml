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
  readonly property bool lacunaGodRaysEnabled: backgroundEffectEnabled("godRays", true)
  readonly property bool effectVisible: configuredEnabled && lacunaGodRaysEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 0.82), 0, 1)
  readonly property real effectiveIntensity: runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity
  readonly property real speed: clamp(numberSetting("speed", 0.85), 0.15, 4)
  readonly property int rayCount: Math.max(1, Math.min(12, Math.round(numberSetting("rayCount", 7))))
  readonly property real raySpread: clamp(numberSetting("raySpread", 0.72), 0.2, 1)
  readonly property real blurSoftness: clamp(numberSetting("blurSoftness", 0.88), 0, 1)
  readonly property real accentBlend: clamp(numberSetting("accentBlend", 0.58), 0, 1)
  readonly property bool shimmer: boolSetting("shimmer", true)
  readonly property bool vignette: boolSetting("vignette", true)
  readonly property string origin: normalizeOrigin(settingValue("origin", "top-left"))
  readonly property bool originLeft: origin === "top-left" || origin === "bottom-left"
  readonly property bool originTop: origin === "top-left" || origin === "top-right"
  readonly property color themeBackground: themeColor("background", "#101315")
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color themeWarm: themeColor("color11", "#ebcb8b")
  readonly property color themeBright: themeColor("color15", themeForeground)
  readonly property color rayGold: mixColor(themeWarm, themeBright, 0.42)
  readonly property color rayAccent: mixColor(rayGold, themeAccent, accentBlend * 0.48)
  readonly property color rayCool: mixColor(themeColor("color12", themeAccent), themeBright, 0.24)
  readonly property color rayCore: mixColor(themeBright, "#fff8de", 0.48)
  readonly property color dustColor: mixColor(themeBackground, rayAccent, 0.5)
  readonly property real rayLowOpacity: 0.16
  readonly property real rayHighOpacity: 0.46

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
      if (!entry || entry.id !== "lacuna.god-rays-overlay") continue
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

  function normalizeOrigin(value) {
    var normalized = String(value || "").trim()
    if (normalized === "top-right" || normalized === "bottom-left" || normalized === "bottom-right") return normalized
    return "top-left"
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

  function colorForRay(index) {
    var paletteColors = [rayAccent, rayGold, rayCool, rayCore]
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
      id: raysWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-god-rays-overlay"
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
        property real ambientPulse: 0.7

        SequentialAnimation on ambientPulse {
          loops: Animation.Infinite
          running: root.effectVisible && root.shimmer
          NumberAnimation {
            from: 0.58
            to: 1
            duration: Math.max(5200, 11200 / root.speed)
            easing.type: Easing.InOutSine
          }
          NumberAnimation {
            from: 1
            to: 0.58
            duration: Math.max(5600, 12800 / root.speed)
            easing.type: Easing.InOutSine
          }
        }

        Rectangle {
          anchors.fill: parent
          opacity: 0.14 * effect.ambientPulse
          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: root.originTop ? Qt.rgba(root.rayAccent.r, root.rayAccent.g, root.rayAccent.b, 0.28) : "#00000000" }
            GradientStop { position: 0.26; color: Qt.rgba(root.dustColor.r, root.dustColor.g, root.dustColor.b, 0.08) }
            GradientStop { position: 0.62; color: Qt.rgba(root.rayGold.r, root.rayGold.g, root.rayGold.b, 0.035) }
            GradientStop { position: 1; color: root.originTop ? "#00000000" : Qt.rgba(root.rayAccent.r, root.rayAccent.g, root.rayAccent.b, 0.28) }
          }
        }

        Item {
          id: sourceBloom

          readonly property int sourceX: Math.round(raysWindow.width * (root.originLeft ? 0.15 : 0.85))
          readonly property int sourceY: Math.round(raysWindow.height * (root.originTop ? -0.03 : 1.03))
          readonly property int bloomSize: Math.round(Math.max(raysWindow.width, raysWindow.height) * 0.42)

          x: sourceX - bloomSize / 2
          y: sourceY - bloomSize / 2
          width: bloomSize
          height: bloomSize
          opacity: 0.72 * effect.ambientPulse
          layer.enabled: true
          layer.smooth: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 96
            blur: 1
            autoPaddingEnabled: true
          }

          Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: width / 2
            color: Qt.rgba(root.rayAccent.r, root.rayAccent.g, root.rayAccent.b, 0.13)
          }

          Rectangle {
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.46)
            height: width
            radius: width / 2
            color: Qt.rgba(root.rayCore.r, root.rayCore.g, root.rayCore.b, 0.18)
          }
        }

        Repeater {
          model: root.rayCount

          Item {
            id: ray

            readonly property real seed: index + 211
            readonly property real lane: index / Math.max(1, root.rayCount - 1)
            readonly property real fanLane: root.rayCount === 1 ? 0.5 : lane
            readonly property int blurPad: Math.round(120 + root.blurSoftness * 180)
            readonly property int rayWidth: Math.max(180, Math.round(raysWindow.width * (0.105 + root.seededNoise(seed + 3) * 0.07)))
            readonly property int rayLength: Math.max(1100, Math.round(Math.max(raysWindow.width, raysWindow.height) * (1.62 + root.seededNoise(seed + 5) * 0.34)))
            readonly property real direction: root.originTop ? (root.originLeft ? -1 : 1) : (root.originLeft ? 1 : -1)
            readonly property real angle: direction * (16 + fanLane * 42 * root.raySpread) + (root.seededNoise(seed + 7) - 0.5) * 3.5
            readonly property int sourceX: Math.round(raysWindow.width * (root.originLeft ? 0.15 : 0.85))
            readonly property int sourceY: Math.round(raysWindow.height * (root.originTop ? -0.03 : 1.03))
            readonly property int sourceJitterX: Math.round((root.seededNoise(seed + 9) - 0.5) * raysWindow.width * 0.035)
            readonly property int sourceJitterY: Math.round((root.seededNoise(seed + 10) - 0.5) * raysWindow.height * 0.018)
            readonly property int driftX: Math.round(raysWindow.width * (0.01 + root.seededNoise(seed + 11) * 0.024) * (root.originLeft ? 1 : -1))
            readonly property int driftY: Math.round(raysWindow.height * (0.014 + root.seededNoise(seed + 13) * 0.028) * (root.originTop ? 1 : -1))
            readonly property int xA: sourceX + sourceJitterX - Math.round(width * 0.5)
            readonly property int xB: xA + driftX
            readonly property int yA: root.originTop
              ? sourceY + sourceJitterY - blurPad
              : sourceY + sourceJitterY - height + blurPad
            readonly property int yB: yA + driftY
            readonly property real driftSpeed: 0.52 + root.seededNoise(seed + 19) * 0.72
            readonly property real baseOpacity: root.rayLowOpacity + root.seededNoise(seed + 23) * 0.18
            readonly property color rayColor: root.colorForRay(index)
            readonly property color companionColor: root.colorForRay(index + 1)
            readonly property int initialDelay: Math.round(root.seededNoise(seed + 29) * 8600)

            x: xA
            y: yA
            width: rayWidth + blurPad * 2
            height: rayLength + blurPad * 2
            opacity: baseOpacity
            rotation: angle
            transformOrigin: root.originTop ? Item.Top : Item.Bottom
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 96
              blur: 0.72 + root.blurSoftness * 0.28
              autoPaddingEnabled: true
            }

            SequentialAnimation on x {
              loops: Animation.Infinite
              running: root.effectVisible
              PauseAnimation { duration: ray.initialDelay }
              NumberAnimation {
                from: ray.xA
                to: ray.xB
                duration: Math.max(7600, (14600 + root.seededNoise(ray.seed + 31) * 9200) / (root.speed * ray.driftSpeed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                from: ray.xB
                to: ray.xA
                duration: Math.max(8200, (15400 + root.seededNoise(ray.seed + 37) * 9800) / (root.speed * ray.driftSpeed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: root.effectVisible
              PauseAnimation { duration: Math.round(ray.initialDelay * 0.41) }
              NumberAnimation {
                from: ray.yA
                to: ray.yB
                duration: Math.max(7600, (13200 + root.seededNoise(ray.seed + 41) * 8800) / (root.speed * (0.78 + ray.driftSpeed * 0.46)))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                from: ray.yB
                to: ray.yA
                duration: Math.max(8200, (14800 + root.seededNoise(ray.seed + 43) * 9600) / (root.speed * (0.74 + ray.driftSpeed * 0.5)))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: root.effectVisible && root.shimmer
              PauseAnimation { duration: Math.round(ray.initialDelay * 0.62) }
              NumberAnimation {
                from: ray.baseOpacity * 0.7
                to: Math.min(root.rayHighOpacity, ray.baseOpacity * 1.42)
                duration: Math.max(4200, (8400 + root.seededNoise(ray.seed + 47) * 6800) / root.speed)
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                from: Math.min(root.rayHighOpacity, ray.baseOpacity * 1.42)
                to: ray.baseOpacity * 0.7
                duration: Math.max(4800, (9600 + root.seededNoise(ray.seed + 53) * 7200) / root.speed)
                easing.type: Easing.InOutSine
              }
            }

            Rectangle {
              x: ray.blurPad
              y: ray.blurPad
              width: ray.rayWidth
              height: ray.rayLength
              radius: Math.max(1, width / 2)
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 0.18; color: Qt.rgba(ray.rayColor.r, ray.rayColor.g, ray.rayColor.b, 0.045) }
                GradientStop { position: 0.45; color: Qt.rgba(root.rayCore.r, root.rayCore.g, root.rayCore.b, 0.28) }
                GradientStop { position: 0.58; color: Qt.rgba(ray.companionColor.r, ray.companionColor.g, ray.companionColor.b, 0.11) }
                GradientStop { position: 0.84; color: Qt.rgba(ray.rayColor.r, ray.rayColor.g, ray.rayColor.b, 0.035) }
                GradientStop { position: 1; color: "#00000000" }
              }
            }

            Rectangle {
              x: ray.blurPad + Math.round(ray.rayWidth * 0.36)
              y: ray.blurPad
              width: Math.max(2, Math.round(ray.rayWidth * 0.18))
              height: Math.round(ray.rayLength * 0.72)
              radius: Math.max(1, width / 2)
              opacity: 0.42
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0; color: Qt.rgba(root.rayCore.r, root.rayCore.g, root.rayCore.b, 0.38) }
                GradientStop { position: 0.42; color: Qt.rgba(root.rayGold.r, root.rayGold.g, root.rayGold.b, 0.12) }
                GradientStop { position: 1; color: "#00000000" }
              }
            }
          }
        }

        Repeater {
          model: Math.max(3, Math.round(root.rayCount * 0.7))

          Rectangle {
            id: mote

            readonly property real seed: index + 701
            readonly property int moteSize: Math.round(3 + root.seededNoise(seed + 1) * 7)
            readonly property int xA: Math.round(root.seededNoise(seed + 3) * raysWindow.width)
            readonly property int xB: xA + Math.round((root.seededNoise(seed + 5) - 0.5) * raysWindow.width * 0.12)
            readonly property int yA: Math.round(root.seededNoise(seed + 7) * raysWindow.height)
            readonly property int yB: yA + Math.round((root.originTop ? 1 : -1) * raysWindow.height * (0.035 + root.seededNoise(seed + 11) * 0.055))
            readonly property real moteOpacity: 0.1 + root.seededNoise(seed + 13) * 0.16

            x: xA
            y: yA
            width: moteSize
            height: moteSize
            radius: width / 2
            color: Qt.rgba(root.rayCore.r, root.rayCore.g, root.rayCore.b, 0.8)
            opacity: moteOpacity
            visible: root.shimmer
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 12
              blur: 0.8
              autoPaddingEnabled: true
            }

            ParallelAnimation {
              loops: Animation.Infinite
              running: root.effectVisible && root.shimmer
              NumberAnimation {
                target: mote
                property: "x"
                from: mote.xA
                to: mote.xB
                duration: Math.max(9000, (16000 + root.seededNoise(mote.seed + 17) * 12000) / root.speed)
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                target: mote
                property: "y"
                from: mote.yA
                to: mote.yB
                duration: Math.max(9000, (16000 + root.seededNoise(mote.seed + 19) * 12000) / root.speed)
                easing.type: Easing.InOutSine
              }
              SequentialAnimation {
                NumberAnimation {
                  target: mote
                  property: "opacity"
                  from: mote.moteOpacity * 0.25
                  to: mote.moteOpacity
                  duration: Math.max(4400, (8600 + root.seededNoise(mote.seed + 23) * 6000) / root.speed)
                  easing.type: Easing.InOutSine
                }
                NumberAnimation {
                  target: mote
                  property: "opacity"
                  from: mote.moteOpacity
                  to: mote.moteOpacity * 0.25
                  duration: Math.max(4800, (9200 + root.seededNoise(mote.seed + 29) * 6200) / root.speed)
                  easing.type: Easing.InOutSine
                }
              }
            }
          }
        }

        Item {
          anchors.fill: parent
          visible: root.vignette
          opacity: 0.52

          Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: Math.round(parent.height * 0.2)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop { position: 0; color: "#26000000" }
              GradientStop { position: 1; color: "#00000000" }
            }
          }

          Rectangle {
            x: 0
            y: parent.height - height
            width: parent.width
            height: Math.round(parent.height * 0.28)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop { position: 0; color: "#00000000" }
              GradientStop { position: 1; color: "#42000000" }
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-god-rays-overlay"

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
        rayCount: root.rayCount,
        raySpread: root.raySpread,
        blurSoftness: root.blurSoftness,
        accentBlend: root.accentBlend,
        shimmer: root.shimmer,
        vignette: root.vignette,
        origin: root.origin
      })
    }
  }
}
