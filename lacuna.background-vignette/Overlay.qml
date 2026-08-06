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
  readonly property string frameGeometryKey: resolveFrameGeometryKey()
  readonly property int frameGeometryRevision: resolveFrameGeometryRevision()

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

  function resolveFrameGeometryRevision() {
    if (root.shell && root.shell.bar && root.shell.bar.lacunaFrameGeometryRevision !== undefined)
      return Number(root.shell.bar.lacunaFrameGeometryRevision) || 0
    return 0
  }

  function resolveFrameGeometryKey() {
    if (root.shell && root.shell.bar && root.shell.bar.lacunaFrameGeometryKey !== undefined) {
      return String(root.shell.bar.lacunaFrameGeometryKey || "")
    }
    return ""
  }

  function resolveFrameRect(screen) {
    if (root.shell && root.shell.bar && typeof root.shell.bar.lacunaFrameContentRect === "function") {
      var rect = root.shell.bar.lacunaFrameContentRect(screen)
      if (rect && rect.width > 0 && rect.height > 0) return rect
    }
    return {
      x: 0,
      y: 0,
      width: screen && screen.width !== undefined ? Math.max(1, Number(screen.width) || 1) : 1,
      height: screen && screen.height !== undefined ? Math.max(1, Number(screen.height) || 1) : 1,
      radius: 0,
      bleed: 0,
      framed: false
    }
  }

  // FileView can observe the transient empty/partial state while another
  // service rewrites settings.json. Keep the last known-good snapshot so an
  // unrelated setting save cannot unmap and remap the vignette surface.
  function loadLacunaSettings(raw) {
    var text = String(raw || "").trim()
    if (text.length === 0) return false

    try {
      var parsed = JSON.parse(text)
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return false
      lacunaSettings = parsed
      return true
    } catch (error) {
      return false
    }
  }

  FileView {
    id: lacunaSettingsWatcher

    path: root.settingsFile
    watchChanges: true
    printErrors: false
    onLoaded: root.loadLacunaSettings(text())
    onFileChanged: reload()
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: vignetteWindow

      required property var modelData
      readonly property real outputScale: modelData && modelData.devicePixelRatio !== undefined
        ? Math.max(1, Number(modelData.devicePixelRatio) || 1) : 1
      readonly property var frameRect: {
        root.frameGeometryKey
        root.frameGeometryRevision
        modelData.width
        modelData.height
        return root.resolveFrameRect(modelData)
      }

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

      Rectangle {
        x: Math.round(vignetteWindow.frameRect.x)
        y: Math.round(vignetteWindow.frameRect.y)
        width: Math.round(vignetteWindow.frameRect.width)
        height: Math.round(vignetteWindow.frameRect.height)
        radius: Math.max(0, Number(vignetteWindow.frameRect.radius || 0))
        color: "transparent"
        enabled: false
        opacity: root.vignetteIntensity
        clip: true

        Image {
          anchors.fill: parent
          source: Qt.resolvedUrl("assets/vignette.svg")
          // Rasterize once per output size. Frame/sidebar geometry can then
          // scale the cached texture in the scene graph instead of asking the
          // SVG provider to rebuild it on every transition frame.
          sourceSize.width: Math.max(1, Math.round((Number(vignetteWindow.modelData.width) || 1)
            * vignetteWindow.outputScale))
          sourceSize.height: Math.max(1, Math.round((Number(vignetteWindow.modelData.height) || 1)
            * vignetteWindow.outputScale))
          fillMode: Image.Stretch
          smooth: true
          asynchronous: true
          cache: true
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
        ignoreBackgroundAnimationLayer: root.ignoreBackgroundAnimationLayer,
        frameGeometryKey: root.frameGeometryKey,
        frameGeometryRevision: root.frameGeometryRevision
      })
    }
  }
}
