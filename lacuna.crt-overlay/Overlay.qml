import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property bool runtimeEnabled: true
  property real runtimeIntensity: -1
  property int noiseTick: 0
  property real bloomPulse: 0
  property int bloomPulseCycle: 0
  property int bloomPulseDelay: 14000
  property var lacunaSettings: ({})

  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  readonly property var overlaySettings: pluginSettings()
  readonly property bool configuredEnabled: boolSetting("effectEnabled", true)
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaCrtEnabled: backgroundEffectEnabled("crt", true)
  readonly property bool effectVisible: configuredEnabled && lacunaCrtEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 0.58), 0, 1)
  readonly property real effectiveIntensity: (runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity) * backgroundAnimationOpacity()
  readonly property real speed: clamp(numberSetting("speed", 1), 0.15, 4)
  readonly property int scanlineSpacing: Math.max(2, Math.min(9, Math.round(numberSetting("scanlineSpacing", 3))))
  readonly property int staticBandHeight: Math.max(60, Math.min(320, Math.round(numberSetting("staticBandHeight", 150))))
  readonly property real staticAmount: clamp(numberSetting("staticAmount", 0.24), 0, 1)
  readonly property real glowAmount: clamp(numberSetting("glowAmount", 0.22), 0, 1)
  readonly property bool bloomPulseEnabled: boolSetting("bloomPulse", true)
  readonly property real bloomPulseAmount: clamp(numberSetting("bloomPulseAmount", 0.52), 0, 1)
  readonly property int bloomPulseInterval: Math.max(7000, Math.min(60000, Math.round(numberSetting("bloomPulseInterval", 18000))))
  readonly property real bloomPulseOpacity: bloomPulseEnabled ? bloomPulse * bloomPulseAmount : 0
  readonly property bool distortion: boolSetting("distortion", true)
  readonly property real distortionAmount: clamp(numberSetting("distortionAmount", 0.45), 0, 1)
  readonly property bool vignette: boolSetting("vignette", true)

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
      if (!entry || entry.id !== "lacuna.crt-overlay") continue
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

  function parsePayload(payloadJson) {
    try {
      return payloadJson ? JSON.parse(payloadJson) : {}
    } catch (error) {
      return {}
    }
  }

  function seededNoise(seed) {
    var value = Math.sin(seed * 12.9898 + root.noiseTick * 78.233) * 43758.5453
    return value - Math.floor(value)
  }

  function stableNoise(seed) {
    var value = Math.sin(seed * 12.9898) * 43758.5453
    return value - Math.floor(value)
  }

  function bloomPulseDelayForCycle(cycle) {
    return Math.round(bloomPulseInterval * (0.72 + stableNoise(cycle + 503) * 0.82))
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

  Timer {
    interval: Math.max(70, 180 / root.speed)
    repeat: true
    running: root.effectVisible && root.staticAmount > 0
    onTriggered: root.noiseTick += 1
  }

  SequentialAnimation {
    id: bloomPulseAnimation

    loops: Animation.Infinite
    running: root.effectVisible && root.bloomPulseEnabled && root.bloomPulseAmount > 0.001
    onRunningChanged: if (!running) root.bloomPulse = 0

    PauseAnimation {
      duration: root.bloomPulseDelay
    }
    NumberAnimation {
      target: root
      property: "bloomPulse"
      from: 0
      to: 0.42
      duration: Math.max(1900, 3600 / root.speed)
      easing.type: Easing.InSine
    }
    NumberAnimation {
      target: root
      property: "bloomPulse"
      from: 0.42
      to: 1
      duration: Math.max(480, 940 / root.speed)
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      target: root
      property: "bloomPulse"
      from: 1
      to: 0
      duration: Math.max(2600, 5000 / root.speed)
      easing.type: Easing.OutSine
    }
    ScriptAction {
      script: {
        root.bloomPulse = 0
        root.bloomPulseCycle += 1
        root.bloomPulseDelay = root.bloomPulseDelayForCycle(root.bloomPulseCycle)
      }
    }
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: crtWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-crt-overlay"
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

        Rectangle {
          anchors.fill: parent
          color: "#c8f4ff"
          opacity: root.glowAmount * 0.035 + root.bloomPulseOpacity * 0.052
        }

        Item {
          id: bloomPulseWash

          anchors.fill: parent
          visible: root.bloomPulseOpacity > 0.001
          opacity: root.bloomPulseOpacity
          layer.enabled: visible
          layer.smooth: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 72
            blur: 0.82
            autoPaddingEnabled: true
          }

          Rectangle {
            anchors.fill: parent
            color: "#78f7ff"
            opacity: 0.105
          }

          Rectangle {
            x: Math.round(parent.width * 0.04)
            y: 0
            width: Math.round(parent.width * 0.92)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 0.5
                color: "#6878f7ff"
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }
          }

          Rectangle {
            x: 0
            y: Math.round(parent.height * 0.22)
            width: parent.width
            height: Math.round(parent.height * 0.56)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 0.46
                color: "#4f78f7ff"
              }
              GradientStop {
                position: 0.62
                color: "#1effd56a"
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }
          }
        }

        Item {
          id: scanlineCrawl

          anchors.fill: parent
          y: -root.scanlineSpacing

          NumberAnimation on y {
            from: -root.scanlineSpacing
            to: 0
            duration: Math.max(420, 1500 / root.speed)
            loops: Animation.Infinite
            running: root.effectVisible
          }

          Repeater {
            model: Math.max(0, Math.ceil(crtWindow.height / root.scanlineSpacing) + 3)

            Rectangle {
              x: 0
              y: index * root.scanlineSpacing
              width: crtWindow.width
              height: 1
              color: index % 2 === 0 ? "#dff8ff" : "#020406"
              opacity: index % 2 === 0 ? 0.13 : 0.16
            }
          }
        }

        Item {
          id: staticBand

          x: 0
          y: -height
          width: crtWindow.width
          height: root.staticBandHeight
          opacity: root.staticAmount

          SequentialAnimation on y {
            loops: Animation.Infinite
            running: root.effectVisible

            PauseAnimation {
              duration: Math.max(1000, 5200 / root.speed)
            }

            NumberAnimation {
              from: -staticBand.height
              to: crtWindow.height + staticBand.height
              duration: Math.max(2600, 9000 / root.speed)
              easing.type: Easing.InOutSine
            }
          }

          Rectangle {
            anchors.fill: parent
            color: "transparent"
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 0.18
                color: "#10000000"
              }
              GradientStop {
                position: 0.42
                color: "#18ffffff"
              }
              GradientStop {
                position: 0.58
                color: "#20ffffff"
              }
              GradientStop {
                position: 0.82
                color: "#16000000"
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }
          }

          Repeater {
            model: 34

            Rectangle {
              readonly property real seed: index + 71

              x: Math.round(root.seededNoise(seed) * staticBand.width)
              y: Math.round(root.seededNoise(seed + 13) * staticBand.height)
              width: Math.round(36 + root.seededNoise(seed + 23) * 220)
              height: root.seededNoise(seed + 31) > 0.78 ? 2 : 1
              color: root.seededNoise(seed + 43) > 0.48 ? "#ffffff" : "#080b0f"
              opacity: 0.05 + root.seededNoise(seed + 53) * 0.18
            }
          }

          Rectangle {
            x: 0
            y: Math.round(parent.height * 0.5)
            width: parent.width
            height: 2
            color: "#ffffff"
            opacity: 0.14
          }
        }

        Repeater {
          model: Math.round(22 + root.staticAmount * 68)

          Rectangle {
            readonly property real seed: index + 211

            x: Math.round(root.seededNoise(seed + 1) * crtWindow.width)
            y: Math.round(root.seededNoise(seed + 2) * crtWindow.height)
            width: root.seededNoise(seed + 3) > 0.86 ? 10 : 2
            height: 1
            color: root.seededNoise(seed + 5) > 0.55 ? "#ffffff" : "#030507"
            opacity: root.staticAmount * root.seededNoise(seed + 7) * 0.22
          }
        }

        Repeater {
          model: 3

          Rectangle {
            readonly property bool cyanLayer: index === 0
            readonly property bool warmLayer: index === 1

            x: cyanLayer ? -1 : warmLayer ? 1 : 0
            y: 0
            width: crtWindow.width + 2
            height: crtWindow.height
            color: cyanLayer ? "#70f8ff" : warmLayer ? "#ffd66a" : "#ffffff"
            opacity: root.glowAmount * (cyanLayer || warmLayer ? 0.018 : 0.012) + root.bloomPulseOpacity * (cyanLayer ? 0.13 : warmLayer ? 0.032 : 0.022)
          }
        }

        Item {
          id: curvedGlassDistortion

          anchors.fill: parent
          visible: root.foregroundOverlay && root.distortion && root.distortionAmount > 0.001
          opacity: root.distortionAmount

          Rectangle {
            x: 0
            y: 0
            width: Math.round(parent.width * 0.16)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: "#26000000"
              }
              GradientStop {
                position: 0.42
                color: "#10000000"
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }
          }

          Rectangle {
            x: parent.width - width
            y: 0
            width: Math.round(parent.width * 0.16)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 0.58
                color: "#10000000"
              }
              GradientStop {
                position: 1
                color: "#26000000"
              }
            }
          }

          Repeater {
            model: 6

            Item {
              id: bowLine

              readonly property real seed: index + 1
              readonly property real baseY: crtWindow.height * (0.12 + index * 0.152)
              readonly property real bow: (index % 2 === 0 ? 1 : -1) * crtWindow.height * (0.006 + index * 0.0015)
              property real phase: 0

              anchors.fill: parent
              opacity: 0.2 + index * 0.025

              NumberAnimation on phase {
                from: -1
                to: 1
                duration: Math.max(2600, (6200 + index * 900) / root.speed)
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
                running: root.effectVisible && curvedGlassDistortion.visible
              }

              Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                  fillColor: "transparent"
                  strokeColor: index % 2 === 0 ? "#55d7fbff" : "#2a000000"
                  strokeWidth: index % 2 === 0 ? 1 : 2
                  capStyle: ShapePath.RoundCap
                  startX: -16
                  startY: bowLine.baseY + bowLine.phase * 2

                  PathCubic {
                    control1X: crtWindow.width * 0.25
                    control1Y: bowLine.baseY + bowLine.bow + bowLine.phase * 5
                    control2X: crtWindow.width * 0.75
                    control2Y: bowLine.baseY + bowLine.bow - bowLine.phase * 5
                    x: crtWindow.width + 16
                    y: bowLine.baseY - bowLine.phase * 2
                  }
                }
              }
            }
          }

          Rectangle {
            x: Math.round(parent.width * 0.5 - width * 0.5)
            y: 0
            width: Math.round(parent.width * 0.58)
            height: parent.height
            color: "#e8fbff"
            opacity: 0.018
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
            height: Math.round(parent.height * 0.18)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#42000000"
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
                color: "#52000000"
              }
            }
          }

          Rectangle {
            x: 0
            y: 0
            width: Math.round(parent.width * 0.12)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: "#42000000"
              }
              GradientStop {
                position: 1
                color: "#00000000"
              }
            }
          }

          Rectangle {
            x: parent.width - width
            y: 0
            width: Math.round(parent.width * 0.12)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 1
                color: "#42000000"
              }
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-crt-overlay"

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
        foregroundOverlay: root.foregroundOverlay,
        runtimeEnabled: root.runtimeEnabled,
        visible: root.effectVisible,
        intensity: root.effectiveIntensity,
        speed: root.speed,
        scanlineSpacing: root.scanlineSpacing,
        staticBandHeight: root.staticBandHeight,
        staticAmount: root.staticAmount,
        glowAmount: root.glowAmount,
        bloomPulse: root.bloomPulseEnabled,
        bloomPulseAmount: root.bloomPulseAmount,
        bloomPulseInterval: root.bloomPulseInterval,
        distortion: root.distortion,
        distortionAmount: root.distortionAmount,
        vignette: root.vignette
      })
    }
  }
}
