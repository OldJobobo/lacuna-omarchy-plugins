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
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaCinematicLightEnabled: backgroundEffectEnabled("cinematicLight", true)
  readonly property bool effectVisible: configuredEnabled && lacunaCinematicLightEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 1), 0, 1)
  readonly property real effectiveIntensity: runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity
  readonly property real speed: clamp(numberSetting("speed", 1), 0.15, 4)
  readonly property string stylePreset: normalizeStylePreset(settingValue("stylePreset", "lightLeak"))
  readonly property var motionModes: normalizedMotionModes()
  readonly property bool slowDriftEnabled: motionModes.slowDrift === true
  readonly property bool occasionalSweepsEnabled: motionModes.occasionalSweeps === true
  readonly property bool activeShimmerEnabled: motionModes.activeShimmer === true
  readonly property string motionMode: motionModeSummary()
  readonly property int flareCount: Math.max(1, Math.min(9, Math.round(numberSetting("flareCount", 4))))
  readonly property real accentBlend: clamp(numberSetting("accentBlend", 0.5), 0, 1)
  readonly property bool vignette: boolSetting("vignette", true)
  readonly property real motionFactor: activeShimmerEnabled ? 1.75 : occasionalSweepsEnabled && !slowDriftEnabled ? 0.78 : 0.45
  readonly property real shimmerAmount: activeShimmerEnabled ? 1 : occasionalSweepsEnabled ? 0.38 : 0.16
  readonly property real sweepAmount: occasionalSweepsEnabled ? 0.86 : 0
  readonly property real leakWeight: stylePreset === "lightLeak" ? 1 : stylePreset === "cinematicFlare" ? 0.76 : 0.48
  readonly property real lineWeight: stylePreset === "anamorphicGlow" ? 1 : stylePreset === "cinematicFlare" ? 0.94 : 0.72
  readonly property real ghostWeight: stylePreset === "cinematicFlare" ? 1 : stylePreset === "anamorphicGlow" ? 0.86 : 0.68
  readonly property color themeBackground: themeColor("background", "#101315")
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color themeWarm: themeColor("color11", "#ebcb8b")
  readonly property color themeBright: themeColor("color15", themeForeground)
  readonly property color filmGold: mixColor(themeWarm, themeBright, 0.36)
  readonly property color flareAccent: mixColor(filmGold, themeAccent, accentBlend * 0.44)
  readonly property color flareBlue: mixColor(themeColor("color12", themeAccent), themeBright, 0.32)
  readonly property color flareCore: mixColor(themeBright, "#fff6df", 0.52)
  readonly property color leakShadow: mixColor(themeBackground, flareAccent, 0.32)
  readonly property real ambientWashOpacity: (slowDriftEnabled ? 0.18 : 0.06) * leakWeight
  readonly property real ambientBandOpacity: (slowDriftEnabled ? 0.28 : 0.1) * lineWeight

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
      if (!entry || entry.id !== "lacuna.cinematic-light-overlay") continue
      for (var entryKey in entry) {
        if (entryKey !== "id") merged[entryKey] = entry[entryKey]
      }
      if (!entryHasMotionToggles(entry) && entry.motionMode !== undefined) {
        var legacyMode = normalizeMotionMode(entry.motionMode)
        merged.slowDrift = legacyMode === "slowDrift"
        merged.occasionalSweeps = legacyMode === "occasionalSweeps"
        merged.activeShimmer = legacyMode === "activeShimmer"
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

  function entryHasMotionToggles(entry) {
    return entry
      && (entry.slowDrift !== undefined || entry.occasionalSweeps !== undefined || entry.activeShimmer !== undefined)
  }

  function normalizeStylePreset(value) {
    var preset = String(value || "").trim()
    if (preset === "cinematicFlare" || preset === "anamorphicGlow") return preset
    return "lightLeak"
  }

  function normalizeMotionMode(value) {
    var mode = String(value || "").trim()
    if (mode === "occasionalSweeps" || mode === "activeShimmer") return mode
    return "slowDrift"
  }

  function normalizedMotionModes() {
    var modes = {
      slowDrift: boolSetting("slowDrift", true),
      occasionalSweeps: boolSetting("occasionalSweeps", false),
      activeShimmer: boolSetting("activeShimmer", false)
    }

    if (!modes.slowDrift && !modes.occasionalSweeps && !modes.activeShimmer) modes.slowDrift = true
    return modes
  }

  function motionModeSummary() {
    var selected = []
    if (slowDriftEnabled) selected.push("slowDrift")
    if (occasionalSweepsEnabled) selected.push("occasionalSweeps")
    if (activeShimmerEnabled) selected.push("activeShimmer")
    return selected.join(",")
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
      id: flareWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-cinematic-light-overlay"
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
        property real ambientPulse: 0.65

        SequentialAnimation on ambientPulse {
          loops: Animation.Infinite
          running: root.effectVisible && root.slowDriftEnabled
          NumberAnimation {
            from: 0.55
            to: 1
            duration: Math.max(4800, 9000 / root.speed)
            easing.type: Easing.InOutSine
          }
          NumberAnimation {
            from: 1
            to: 0.55
            duration: Math.max(5200, 11000 / root.speed)
            easing.type: Easing.InOutSine
          }
        }

        Item {
          id: ambientLight

          anchors.fill: parent
          visible: root.slowDriftEnabled || root.stylePreset === "lightLeak"
          opacity: effect.ambientPulse

          Rectangle {
            anchors.fill: parent
            opacity: root.ambientWashOpacity
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop { position: 0; color: "#00000000" }
              GradientStop { position: 0.34; color: Qt.rgba(root.leakShadow.r, root.leakShadow.g, root.leakShadow.b, 0.18) }
              GradientStop { position: 0.52; color: Qt.rgba(root.flareAccent.r, root.flareAccent.g, root.flareAccent.b, 0.24) }
              GradientStop { position: 0.72; color: Qt.rgba(root.themeBackground.r, root.themeBackground.g, root.themeBackground.b, 0.08) }
              GradientStop { position: 1; color: "#00000000" }
            }
          }

          Rectangle {
            x: -Math.round(width * 0.12)
            y: Math.round(parent.height * 0.42 - height * 0.5)
            width: Math.round(parent.width * 1.24)
            height: Math.round(parent.height * (root.stylePreset === "anamorphicGlow" ? 0.11 : 0.18))
            radius: Math.max(1, height / 2)
            rotation: root.stylePreset === "anamorphicGlow" ? -0.4 : -1.1
            opacity: root.ambientBandOpacity
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 96
              blur: 1
              autoPaddingEnabled: true
            }
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: "#00000000" }
              GradientStop { position: 0.2; color: Qt.rgba(root.flareAccent.r, root.flareAccent.g, root.flareAccent.b, 0.16) }
              GradientStop { position: 0.5; color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 0.42) }
              GradientStop { position: 0.8; color: Qt.rgba(root.filmGold.r, root.filmGold.g, root.filmGold.b, 0.16) }
              GradientStop { position: 1; color: "#00000000" }
            }
          }
        }

        Repeater {
          model: root.stylePreset === "lightLeak" ? 4 : 2

          Rectangle {
            id: leak

            readonly property real seed: index + 31
            readonly property bool leftSide: index % 2 === 0
            readonly property int leakWidth: Math.round(flareWindow.width * (0.28 + root.seededNoise(seed + 3) * 0.22))
            readonly property real yBase: root.seededNoise(seed + 5) * flareWindow.height
            readonly property real leakFloor: root.leakWeight * (0.01 + root.seededNoise(seed + 9) * 0.018)
            readonly property real leakPeak: root.leakWeight * (0.34 + root.seededNoise(seed + 11) * 0.22)
            readonly property int initialDelay: Math.round(root.seededNoise(seed + 13) * 9000)
            readonly property int glowHold: Math.round((900 + root.seededNoise(seed + 15) * 1600) / Math.max(0.25, root.speed))
            readonly property int hiddenPause: root.slowDriftEnabled
              ? Math.round((900 + root.seededNoise(seed + 17) * 1700) / Math.max(0.25, root.speed))
              : Math.round((5200 + root.seededNoise(seed + 17) * 9000) / Math.max(0.25, root.speed * root.motionFactor))
            property int cycle: 0
            readonly property real cycleSeed: seed + cycle * 97
            readonly property bool cycleLeftSide: root.seededNoise(cycleSeed + 1) > 0.42
            readonly property real cycleY: root.seededNoise(cycleSeed + 5) * flareWindow.height
            readonly property int cycleWidth: Math.round(flareWindow.width * (0.24 + root.seededNoise(cycleSeed + 7) * 0.32))

            x: cycleLeftSide ? -Math.round(width * (0.34 + root.seededNoise(cycleSeed + 11) * 0.28)) : flareWindow.width - Math.round(width * (0.38 + root.seededNoise(cycleSeed + 13) * 0.24))
            y: Math.round(cycleY - height * 0.5)
            width: cycleWidth
            height: Math.round(flareWindow.height * (0.34 + root.seededNoise(seed + 7) * 0.24))
            opacity: leakFloor
            rotation: cycleLeftSide ? -2 : 2
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 96
              blur: 1
              autoPaddingEnabled: true
            }
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: cycleLeftSide ? Qt.rgba(root.flareAccent.r, root.flareAccent.g, root.flareAccent.b, 0.78) : "#00000000" }
              GradientStop { position: 0.44; color: Qt.rgba(root.filmGold.r, root.filmGold.g, root.filmGold.b, 0.42) }
              GradientStop { position: 1; color: cycleLeftSide ? "#00000000" : Qt.rgba(root.flareAccent.r, root.flareAccent.g, root.flareAccent.b, 0.78) }
            }

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: root.effectVisible
              PauseAnimation {
                duration: leak.initialDelay
              }
              NumberAnimation {
                from: leak.leakFloor
                to: leak.leakPeak
                duration: Math.max(1800, (3600 + root.seededNoise(leak.seed + 19) * 4200) / (root.speed * root.motionFactor))
                easing.type: Easing.InOutSine
              }
              PauseAnimation {
                duration: leak.glowHold
              }
              NumberAnimation {
                from: leak.leakPeak
                to: leak.leakFloor
                duration: Math.max(2200, (4200 + root.seededNoise(leak.seed + 23) * 5200) / (root.speed * root.motionFactor))
                easing.type: Easing.InOutSine
              }
              PauseAnimation {
                duration: leak.hiddenPause
              }
              ScriptAction {
                script: leak.cycle += 1
              }
            }
          }
        }

        Repeater {
          model: root.flareCount

          Item {
            id: flare

            readonly property real seed: index + 101
            readonly property real lane: (index + 1) / (root.flareCount + 1)
            readonly property real yDrift: flareWindow.height * (0.035 + root.seededNoise(seed + 3) * 0.045)
            readonly property int baseY: Math.round(flareWindow.height * (0.18 + lane * 0.58 + (root.seededNoise(seed + 5) - 0.5) * 0.12))
            readonly property int travel: Math.round(flareWindow.width * (0.05 + root.seededNoise(seed + 7) * 0.09))
            readonly property int xA: -Math.round(width * (0.18 + root.seededNoise(seed + 11) * 0.08))
            readonly property int xB: -Math.round(width * 0.12) + travel
            readonly property real baseOpacity: root.stylePreset === "lightLeak" ? 0.56 : root.stylePreset === "cinematicFlare" ? 0.68 : 0.78
            readonly property real pulseHigh: Math.min(1, baseOpacity + root.shimmerAmount * (0.18 + root.seededNoise(seed + 13) * 0.22))
            readonly property real flareFloor: 0
            readonly property real flarePeak: pulseHigh
            readonly property int fadeDelay: Math.round(root.seededNoise(seed + 21) * 11000)
            readonly property int visibleHold: Math.round((1200 + root.seededNoise(seed + 25) * 2400) / Math.max(0.25, root.speed))
            readonly property int darkPause: root.slowDriftEnabled
              ? Math.round((1800 + root.seededNoise(seed + 27) * 3600) / Math.max(0.25, root.speed))
              : Math.round((4200 + root.seededNoise(seed + 27) * 10500) / Math.max(0.25, root.speed * root.motionFactor))
            readonly property int fadeInDuration: Math.max(1600, (3200 + root.seededNoise(cycleSeed + 47) * 4200) / (root.speed * (0.5 + root.shimmerAmount)))
            readonly property int fadeOutDuration: Math.max(1800, (3600 + root.seededNoise(cycleSeed + 53) * 5200) / (root.speed * (0.5 + root.shimmerAmount)))
            readonly property int driftDuration: fadeInDuration + visibleHold + fadeOutDuration
            readonly property int lineHeight: root.stylePreset === "anamorphicGlow" ? Math.max(2, Math.round(2 + root.seededNoise(seed + 17) * 3)) : Math.round(5 + root.seededNoise(seed + 19) * 7)
            readonly property int coreHeight: Math.max(1, Math.round(lineHeight * (root.stylePreset === "lightLeak" ? 0.38 : 0.54)))
            readonly property color edgeColor: root.stylePreset === "anamorphicGlow" ? root.flareBlue : root.flareAccent
            readonly property color warmColor: root.stylePreset === "anamorphicGlow" ? root.mixColor(root.flareAccent, root.flareBlue, 0.42) : root.filmGold
            readonly property int initialDelay: Math.round(root.seededNoise(seed + 23) * 4800)
            property int cycle: 0
            readonly property real cycleSeed: seed + cycle * 113
            readonly property int cycleWidth: Math.round(flareWindow.width * (0.78 + root.seededNoise(cycleSeed + 3) * 0.84))
            readonly property int cycleBaseX: Math.round(-cycleWidth * (0.44 + root.seededNoise(cycleSeed + 5) * 0.18) + root.seededNoise(cycleSeed + 7) * flareWindow.width * 0.68)
            readonly property int cycleXDirection: root.seededNoise(cycleSeed + 9) > 0.5 ? 1 : -1
            readonly property int cycleTravel: Math.round(cycleXDirection * flareWindow.width * (0.1 + root.seededNoise(cycleSeed + 10) * 0.12))
            readonly property int cycleBaseY: Math.round(flareWindow.height * (0.08 + root.seededNoise(cycleSeed + 11) * 0.84))
            readonly property int cycleYDirection: root.seededNoise(cycleSeed + 13) > 0.5 ? 1 : -1
            readonly property real cycleYDrift: flareWindow.height * (0.024 + root.seededNoise(cycleSeed + 14) * 0.034)
            readonly property int cycleXA: cycleBaseX
            readonly property int cycleXB: cycleBaseX + cycleTravel
            readonly property int cycleYA: cycleBaseY - Math.round(height / 2) - cycleYDirection * Math.round(cycleYDrift * 0.5)
            readonly property int cycleYB: cycleBaseY - Math.round(height / 2) + cycleYDirection * Math.round(cycleYDrift * 0.5)

            x: cycleXA
            y: cycleYA
            width: cycleWidth
            height: root.stylePreset === "lightLeak" ? 230 : root.stylePreset === "cinematicFlare" ? 190 : 150
            opacity: flareFloor
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 48
              blur: root.stylePreset === "anamorphicGlow" ? 0.42 : 0.72
              autoPaddingEnabled: true
            }

            SequentialAnimation {
              loops: Animation.Infinite
              running: root.effectVisible
              PauseAnimation {
                duration: flare.fadeDelay
              }
              ScriptAction {
                script: {
                  flare.cycle += 1
                  flare.opacity = flare.flareFloor
                  flare.width = flare.cycleWidth
                  flare.x = flare.cycleXA
                  flare.y = flare.cycleYA
                }
              }
              ParallelAnimation {
                NumberAnimation {
                  target: flare
                  property: "x"
                  from: flare.cycleXA
                  to: flare.cycleXB
                  duration: flare.driftDuration
                  easing.type: Easing.InOutSine
                }
                NumberAnimation {
                  target: flare
                  property: "y"
                  from: flare.cycleYA
                  to: flare.cycleYB
                  duration: flare.driftDuration
                  easing.type: Easing.InOutSine
                }
                SequentialAnimation {
                  NumberAnimation {
                    target: flare
                    property: "opacity"
                    from: flare.flareFloor
                    to: flare.flarePeak
                    duration: flare.fadeInDuration
                    easing.type: Easing.InOutSine
                  }
                  PauseAnimation {
                    duration: flare.visibleHold
                  }
                  NumberAnimation {
                    target: flare
                    property: "opacity"
                    from: flare.flarePeak
                    to: flare.flareFloor
                    duration: flare.fadeOutDuration
                    easing.type: Easing.InOutSine
                  }
                }
              }
              PauseAnimation {
                duration: flare.darkPause
              }
            }

            Rectangle {
              x: 0
              y: Math.round(parent.height * 0.5 - height * 0.5)
              width: parent.width
              height: flare.lineHeight
              radius: Math.max(1, height / 2)
              opacity: root.lineWeight
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 0.22; color: Qt.rgba(flare.edgeColor.r, flare.edgeColor.g, flare.edgeColor.b, 0.26) }
                GradientStop { position: 0.46; color: Qt.rgba(flare.warmColor.r, flare.warmColor.g, flare.warmColor.b, 0.68) }
                GradientStop { position: 0.5; color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 1) }
                GradientStop { position: 0.54; color: Qt.rgba(flare.warmColor.r, flare.warmColor.g, flare.warmColor.b, 0.68) }
                GradientStop { position: 0.78; color: Qt.rgba(flare.edgeColor.r, flare.edgeColor.g, flare.edgeColor.b, 0.26) }
                GradientStop { position: 1; color: "#00000000" }
              }
            }

            Rectangle {
              x: Math.round(parent.width * 0.2)
              y: Math.round(parent.height * 0.5 - height * 0.5)
              width: Math.round(parent.width * 0.6)
              height: flare.coreHeight
              radius: Math.max(1, height / 2)
              opacity: root.lineWeight
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 0.46; color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 0.64) }
                GradientStop { position: 0.5; color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 1) }
                GradientStop { position: 0.54; color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 0.64) }
                GradientStop { position: 1; color: "#00000000" }
              }
            }

            Repeater {
              model: 3

              Rectangle {
                readonly property real ghostSeed: flare.seed + index * 13
                readonly property real offset: (index - 1) * (0.13 + root.seededNoise(ghostSeed + 1) * 0.08)

                x: Math.round(parent.width * (0.18 + root.seededNoise(ghostSeed + 3) * 0.5))
                y: Math.round(parent.height * (0.5 + offset))
                width: Math.round(parent.width * (0.12 + root.seededNoise(ghostSeed + 5) * 0.22))
                height: Math.max(1, Math.round(flare.lineHeight * (0.34 + root.seededNoise(ghostSeed + 7) * 0.36)))
                radius: Math.max(1, height / 2)
                opacity: root.ghostWeight * (0.28 + root.seededNoise(ghostSeed + 11) * 0.22)
                gradient: Gradient {
                  orientation: Gradient.Horizontal
                  GradientStop { position: 0; color: "#00000000" }
                  GradientStop { position: 0.5; color: Qt.rgba(flare.edgeColor.r, flare.edgeColor.g, flare.edgeColor.b, 0.82) }
                  GradientStop { position: 1; color: "#00000000" }
                }
              }
            }

            Rectangle {
              x: Math.round(parent.width * (0.47 + root.seededNoise(flare.seed + 61) * 0.06))
              y: Math.round(parent.height * 0.5 - height * 0.5)
              width: root.stylePreset === "anamorphicGlow" ? 18 : 26
              height: width
              radius: width / 2
              opacity: root.ghostWeight * (0.48 + root.shimmerAmount * 0.22)
              color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 1)
              layer.enabled: true
              layer.smooth: true
              layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 40
                blur: 1
                autoPaddingEnabled: true
              }
            }
          }
        }

        Repeater {
          model: root.sweepAmount > 0.05 ? 2 : 0

          Item {
            id: sweep

            readonly property real seed: index + 301
            readonly property int sweepWidth: Math.round(flareWindow.width * (0.44 + root.seededNoise(seed + 3) * 0.22))
            readonly property int sweepY: Math.round(flareWindow.height * (0.24 + root.seededNoise(seed + 5) * 0.52))
            readonly property int travelDuration: Math.max(2600, (5200 + root.seededNoise(seed + 7) * 3600) / (root.speed * (0.65 + root.motionFactor)))
            readonly property real sweepFloor: 0.002
            readonly property real sweepPeak: root.sweepAmount * (0.22 + root.seededNoise(seed + 17) * 0.16)
            readonly property int initialDelay: Math.round(root.seededNoise(seed + 11) * 14000)
            readonly property int pauseDuration: root.occasionalSweepsEnabled
              ? Math.round((16000 + root.seededNoise(seed + 13) * 18000) / root.speed)
              : root.activeShimmerEnabled
                ? Math.round((8200 + root.seededNoise(seed + 19) * 11000) / root.speed)
                : Math.round((22000 + root.seededNoise(seed + 23) * 26000) / root.speed)

            x: -sweepWidth
            y: sweepY
            width: sweepWidth
            height: root.stylePreset === "anamorphicGlow" ? 34 : 58
            opacity: sweepFloor
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              blurEnabled: true
              blurMax: 72
              blur: 0.86
              autoPaddingEnabled: true
            }

            SequentialAnimation on x {
              loops: Animation.Infinite
              running: root.effectVisible
              PauseAnimation { duration: sweep.initialDelay }
              NumberAnimation {
                from: -sweep.sweepWidth
                to: flareWindow.width
                duration: sweep.travelDuration
                easing.type: Easing.InOutCubic
              }
              PauseAnimation { duration: sweep.pauseDuration }
            }

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: root.effectVisible
              PauseAnimation { duration: sweep.initialDelay }
              NumberAnimation {
                from: sweep.sweepFloor
                to: sweep.sweepPeak
                duration: Math.max(650, Math.round(sweep.travelDuration * 0.22))
                easing.type: Easing.InOutSine
              }
              PauseAnimation { duration: Math.max(450, Math.round(sweep.travelDuration * 0.28)) }
              NumberAnimation {
                from: sweep.sweepPeak
                to: sweep.sweepFloor
                duration: Math.max(900, Math.round(sweep.travelDuration * 0.36))
                easing.type: Easing.InOutSine
              }
              PauseAnimation { duration: sweep.pauseDuration }
            }

            Rectangle {
              anchors.fill: parent
              radius: Math.max(1, height / 2)
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 0.48; color: Qt.rgba(root.flareAccent.r, root.flareAccent.g, root.flareAccent.b, 0.28) }
                GradientStop { position: 0.52; color: Qt.rgba(root.flareCore.r, root.flareCore.g, root.flareCore.b, 0.68) }
                GradientStop { position: 1; color: "#00000000" }
              }
            }
          }
        }

        Rectangle {
          anchors.fill: parent
          visible: root.vignette
          opacity: 0.16
          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Qt.rgba(root.leakShadow.r, root.leakShadow.g, root.leakShadow.b, 0.28) }
            GradientStop { position: 0.32; color: "#00000000" }
            GradientStop { position: 0.72; color: "#00000000" }
            GradientStop { position: 1; color: Qt.rgba(root.themeBackground.r, root.themeBackground.g, root.themeBackground.b, 0.48) }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-cinematic-light-overlay"

    function enable(): string {
      root.runtimeEnabled = true
      return status()
    }

    function disable(): string {
      root.runtimeEnabled = false
      return status()
    }

    function toggle(): string {
      root.runtimeEnabled = !root.runtimeEnabled
      return status()
    }

    function intensity(value: string): string {
      root.runtimeIntensity = root.clamp(Number(value), 0, 1)
      return status()
    }

    function status(): string {
      return JSON.stringify({
        enabled: root.effectVisible,
        runtimeEnabled: root.runtimeEnabled,
        configuredEnabled: root.configuredEnabled,
        selected: root.lacunaCinematicLightEnabled,
        intensity: root.effectiveIntensity,
        stylePreset: root.stylePreset,
        motionMode: root.motionMode,
        motionModes: {
          slowDrift: root.slowDriftEnabled,
          occasionalSweeps: root.occasionalSweepsEnabled,
          activeShimmer: root.activeShimmerEnabled
        }
      })
    }
  }
}
