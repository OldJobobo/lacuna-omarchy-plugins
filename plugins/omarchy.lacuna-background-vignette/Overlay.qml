import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var lacunaSettings: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string settingsFile: configHome + "/omarchy/lacuna/settings.json"
  readonly property var vignetteSettings: backgroundVignetteSettings()
  readonly property bool vignetteEnabled: boolValue(vignetteSettings.enabled, false)
  readonly property real vignetteIntensity: clamp(numberValue(vignetteSettings.intensity, 0.85), 0, 1)
  readonly property bool ignoreBackgroundAnimationLayer: boolValue(vignetteSettings.ignoreBackgroundAnimationLayer, false)
  readonly property bool effectVisible: vignetteEnabled && vignetteIntensity > 0.001

  function clamp(value, minimum, maximum) {
    var numeric = Number(value)
    if (isNaN(numeric)) return minimum
    return Math.max(minimum, Math.min(maximum, numeric))
  }

  function numberValue(value, fallback) {
    var numeric = Number(value)
    return isNaN(numeric) ? fallback : numeric
  }

  function boolValue(value, fallback) {
    if (value === true || value === false) return value

    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallback
  }

  function backgroundVignetteSettings() {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : {}
    var vignette = settings.backgroundVignette || settings.bgVignette || settings.vignette

    if (vignette === true || vignette === false) {
      return {
        enabled: vignette === true,
        intensity: 0.85,
        ignoreBackgroundAnimationLayer: false
      }
    }

    return vignette && typeof vignette === "object" ? vignette : ({})
  }

  function loadLacunaSettings(raw) {
    try {
      lacunaSettings = JSON.parse(raw || "{}")
    } catch (error) {
      lacunaSettings = {}
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
      id: vignetteWindow

      required property var modelData

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-background-vignette"
      WlrLayershell.layer: root.ignoreBackgroundAnimationLayer ? WlrLayer.Background : WlrLayer.Bottom
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
        opacity: root.vignetteIntensity

        Rectangle {
          x: 0
          y: 0
          width: parent.width
          height: Math.round(parent.height * 0.24)
          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
              position: 0
              color: "#70000000"
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
              color: "#84000000"
            }
          }
        }

        Rectangle {
          x: 0
          y: 0
          width: Math.round(parent.width * 0.15)
          height: parent.height
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
              position: 0
              color: "#76000000"
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
          width: Math.round(parent.width * 0.15)
          height: parent.height
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
              position: 0
              color: "#00000000"
            }
            GradientStop {
              position: 1
              color: "#76000000"
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-background-vignette"

    function status(): string {
      return JSON.stringify({
        visible: root.effectVisible,
        enabled: root.vignetteEnabled,
        intensity: root.vignetteIntensity,
        ignoreBackgroundAnimationLayer: root.ignoreBackgroundAnimationLayer
      })
    }
  }
}
