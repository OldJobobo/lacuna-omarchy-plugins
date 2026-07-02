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
  property int noiseTick: 0
  property real noiseAccumulator: 0
  property var lacunaSettings: ({})

  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  readonly property var overlaySettings: pluginSettings()
  readonly property bool configuredEnabled: boolSetting("effectEnabled", true)
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaTrackingLinesEnabled: backgroundEffectEnabled("trackingLines", true)
  readonly property bool effectVisible: configuredEnabled && lacunaTrackingLinesEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(numberSetting("intensity", 0.68), 0, 1)
  readonly property real effectiveIntensity: (runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity) * backgroundAnimationOpacity()
  readonly property real speed: clamp(numberSetting("speed", 1), 0.15, 4)
  readonly property int lineSpacing: Math.max(2, Math.min(12, Math.round(numberSetting("lineSpacing", 4))))
  readonly property int trackingBands: Math.max(0, Math.min(7, Math.round(numberSetting("trackingBands", 2))))
  readonly property real noiseAmount: clamp(numberSetting("noiseAmount", 0.42), 0, 1)
  readonly property real glitchAmount: clamp(numberSetting("glitchAmount", 0.34), 0, 1)
  readonly property bool chromaBleed: boolSetting("chromaBleed", true)
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
      if (!entry || entry.id !== "lacuna.vhs-overlay") continue
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

  FrameAnimation {
    id: noiseFrameClock

    running: root.effectVisible && root.noiseAmount > 0
    onTriggered: {
      root.noiseAccumulator += frameTime * 1000
      var interval = Math.max(45, 120 / root.speed)
      while (root.noiseAccumulator >= interval) {
        root.noiseTick += 1
        root.noiseAccumulator -= interval
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
      id: vhsWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-vhs-overlay"
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

        Item {
          id: scanlineCrawl

          anchors.fill: parent
          y: -root.lineSpacing

          NumberAnimation on y {
            from: -root.lineSpacing
            to: 0
            duration: Math.max(180, 950 / root.speed)
            loops: Animation.Infinite
            running: root.effectVisible
          }

          Repeater {
            model: Math.max(0, Math.ceil(vhsWindow.height / root.lineSpacing) + 3)

            Rectangle {
              x: 0
              y: index * root.lineSpacing
              width: vhsWindow.width
              height: 1
              color: index % 2 === 0 ? "#eef7ff" : "#05070a"
              opacity: index % 2 === 0 ? 0.13 : 0.1
            }
          }
        }

        Repeater {
          model: root.chromaBleed ? 2 : 0

          Rectangle {
            readonly property bool cyanLayer: index === 0

            x: cyanLayer ? -2 : 2
            y: 0
            width: vhsWindow.width + 4
            height: vhsWindow.height
            color: cyanLayer ? "#39e7ff" : "#ff3d63"
            opacity: 0.035
          }
        }

        Repeater {
          model: root.trackingBands

          Item {
            id: band

            readonly property real seed: index + 1
            readonly property real bandSpeed: 0.75 + (index % 3) * 0.28
            readonly property int bandHeight: Math.round(34 + (index % 4) * 17)

            x: 0
            y: -bandHeight
            width: vhsWindow.width
            height: bandHeight
            opacity: 0.18

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: root.effectVisible

              PauseAnimation {
                duration: 7200 + index * 5200
              }

              NumberAnimation {
                from: -band.bandHeight
                to: vhsWindow.height + band.bandHeight
                duration: Math.max(1400, (7600 + index * 1900) / (root.speed * band.bandSpeed))
                easing.type: Easing.InOutSine
              }
            }

            Rectangle {
              anchors.fill: parent
              color: "transparent"
              opacity: 0.24
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                  position: 0
                  color: "#00000000"
                }
                GradientStop {
                  position: 0.26
                  color: "#08ffffff"
                }
                GradientStop {
                  position: 0.5
                  color: "#10ffffff"
                }
                GradientStop {
                  position: 0.74
                  color: "#08000000"
                }
                GradientStop {
                  position: 1
                  color: "#00000000"
                }
              }
            }

            Rectangle {
              x: -24
              y: Math.round(band.height * 0.34)
              width: parent.width + 48
              height: 2
              color: "#ffffff"
              opacity: 0.12
            }

            Rectangle {
              x: 18
              y: Math.round(band.height * 0.34) + 3
              width: parent.width - 36
              height: 1
              color: "#06080b"
              opacity: 0.1
            }

            Rectangle {
              visible: root.chromaBleed
              x: -10
              y: Math.round(band.height * 0.55)
              width: parent.width + 10
              height: 1
              color: "#48f1ff"
              opacity: 0.09
            }

            Rectangle {
              visible: root.chromaBleed
              x: 12
              y: Math.round(band.height * 0.55) + 2
              width: parent.width - 12
              height: 1
              color: "#ff4568"
              opacity: 0.08
            }
          }
        }

        Repeater {
          model: Math.round(80 + root.noiseAmount * 160)

          Rectangle {
            readonly property real seed: index + 11

            x: Math.round(root.seededNoise(seed) * vhsWindow.width)
            y: Math.round(root.seededNoise(seed + 31) * vhsWindow.height)
            width: root.seededNoise(seed + 7) > 0.84 ? 12 : 2
            height: root.seededNoise(seed + 23) > 0.94 ? 2 : 1
            color: root.seededNoise(seed + 13) > 0.5 ? "#ffffff" : "#0a0d11"
            opacity: root.noiseAmount * root.seededNoise(seed + 19) * 0.54
          }
        }

        Repeater {
          model: Math.round(2 + root.glitchAmount * 5)

          Item {
            id: glitchSlice

            readonly property real seed: index + 101
            readonly property int sliceHeight: Math.round(3 + root.seededNoise(seed + 3) * 9)
            readonly property int sliceWidth: Math.round(vhsWindow.width * (0.18 + root.seededNoise(seed + 5) * 0.62))
            readonly property int sliceX: Math.round(root.seededNoise(seed + 7) * Math.max(1, vhsWindow.width - sliceWidth))
            readonly property real glitchOpacity: root.glitchAmount * (0.08 + root.seededNoise(seed + 13) * 0.16)

            x: sliceX + Math.round((root.seededNoise(seed + 17) - 0.5) * 18 * root.glitchAmount)
            y: Math.round(root.seededNoise(seed + 19) * vhsWindow.height)
            width: sliceWidth
            height: sliceHeight
            opacity: glitchOpacity
            visible: root.seededNoise(seed + 29) > 0.22

            Rectangle {
              anchors.fill: parent
              color: root.seededNoise(glitchSlice.seed + 31) > 0.5 ? "#ffffff" : "#000000"
            }

            Rectangle {
              visible: root.chromaBleed
              x: -4
              y: Math.max(0, Math.round(parent.height / 2) - 1)
              width: parent.width + 8
              height: 1
              color: "#5ef8ff"
              opacity: 0.9
            }

            Rectangle {
              visible: root.chromaBleed
              x: 5
              y: Math.min(parent.height - 1, Math.round(parent.height / 2) + 1)
              width: parent.width
              height: 1
              color: "#ff3b6a"
              opacity: 0.75
            }
          }
        }

        Repeater {
          model: Math.round(root.glitchAmount * 5)

          Rectangle {
            readonly property real seed: index + 211

            x: Math.round(root.seededNoise(seed + 1) * vhsWindow.width)
            y: Math.round(root.seededNoise(seed + 2) * vhsWindow.height)
            width: Math.round(80 + root.seededNoise(seed + 3) * 280)
            height: 1
            color: "#ffffff"
            opacity: root.glitchAmount * (root.seededNoise(seed + 4) > 0.5 ? 0.24 : 0.11)
          }
        }

        Rectangle {
          id: rollingTear

          x: 0
          y: -8
          width: parent.width
          height: 8
          color: "transparent"
          opacity: 0.74

          SequentialAnimation on y {
            loops: Animation.Infinite
            running: root.effectVisible

            PauseAnimation {
              duration: Math.max(400, 2800 / root.speed)
            }

            NumberAnimation {
              from: -8
              to: vhsWindow.height + 8
              duration: Math.max(520, 1500 / root.speed)
              easing.type: Easing.OutCubic
            }
          }

          Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: 1
            color: "#ffffff"
            opacity: 0.58
          }

          Rectangle {
            x: 0
            y: 2
            width: parent.width
            height: 2
            color: "#000000"
            opacity: 0.38
          }
        }

        Item {
          anchors.fill: parent
          visible: root.vignette
          opacity: 0.55

          Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: Math.round(parent.height * 0.2)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#3a000000"
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
            height: Math.round(parent.height * 0.22)
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop {
                position: 0
                color: "#00000000"
              }
              GradientStop {
                position: 1
                color: "#44000000"
              }
            }
          }

          Rectangle {
            x: 0
            y: 0
            width: Math.round(parent.width * 0.11)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: "#38000000"
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
            width: Math.round(parent.width * 0.11)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
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
    target: "lacuna-vhs-overlay"

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
        lineSpacing: root.lineSpacing,
        trackingBands: root.trackingBands,
        noiseAmount: root.noiseAmount,
        glitchAmount: root.glitchAmount,
        chromaBleed: root.chromaBleed,
        vignette: root.vignette
      })
    }
  }
}
