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
  property bool settingsLoaded: false
  property var productionStacks: []
  readonly property bool hostReady: true

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string settingsFile: configHome + "/omarchy/lacuna/settings.json"
  readonly property var lacunaState: resolveLacunaState()
  readonly property var backgroundEffects: lacunaSettings && typeof lacunaSettings === "object"
    && lacunaSettings.backgroundEffects && typeof lacunaSettings.backgroundEffects === "object"
    ? lacunaSettings.backgroundEffects : ({})
  readonly property bool effectsEnabled: settingsLoaded && backgroundEffects.enabled !== false
  readonly property bool foregroundOverlay: backgroundEffects.foregroundOverlay === true
  readonly property string mappingMode: !effectsEnabled ? "none" : (foregroundOverlay ? "overlay" : "bottom")
  readonly property var activeEffects: Array.isArray(backgroundEffects.activeEffects)
    ? backgroundEffects.activeEffects
    : [String(backgroundEffects.activeEffect || backgroundEffects.selectedEffect || backgroundEffects.currentEffect || "trackingLines")]

  function resolveLacunaState() {
    if (root.shell && typeof root.shell.ensureService === "function") {
      var ensured = root.shell.ensureService("lacuna.state")
      if (ensured) return ensured
    }
    if (root.shell && typeof root.shell.serviceFor === "function")
      return root.shell.serviceFor("lacuna.state")
    return null
  }

  function loadSettings(raw) {
    try {
      lacunaSettings = JSON.parse(raw || "{}")
    } catch (error) {
      lacunaSettings = {}
    }
    settingsLoaded = true
  }

  function normalizedOrder() {
    return orderProbe.normalizeActiveEffects(activeEffects)
  }

  function registerProductionStack(stack) {
    if (productionStacks.indexOf(stack) < 0) productionStacks.push(stack)
  }

  function unregisterProductionStack(stack) {
    var index = productionStacks.indexOf(stack)
    if (index >= 0) productionStacks.splice(index, 1)
  }

  function loadedEffectCount() {
    var count = 0
    for (var i = 0; i < productionStacks.length; i++) {
      var stack = productionStacks[i]
      if (stack) count += Number(stack.activeProductionEffectCount || 0)
    }
    return count
  }

  function zMap() {
    var result = {}
    var order = normalizedOrder()
    for (var i = 0; i < order.length; i++) result[order[i]] = orderProbe.zForEffect(order[i])
    return result
  }

  FileView {
    id: settingsWatcher
    path: root.settingsFile
    watchChanges: true
    printErrors: false
    onLoaded: root.loadSettings(text())
    onFileChanged: reload()
    onLoadFailed: {
      root.lacunaSettings = {}
      root.settingsLoaded = true
    }
  }

  FullscreenGuard { id: fullscreenGuard }

  AmbienceStack {
    id: orderProbe
    visible: false
    width: 0
    height: 0
    activeEffects: root.activeEffects
    paintEnabled: false
    productionEffectsEnabled: false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bottomWindow
      required property var modelData

      screen: modelData
      visible: root.mappingMode === "bottom"
      color: "transparent"
      WlrLayershell.namespace: "lacuna-ambience-host-bottom"
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

      AmbienceStack {
        anchors.fill: parent
        shell: root.shell
        targetScreen: bottomWindow.modelData
        activeEffects: root.activeEffects
        paintEnabled: root.mappingMode === "bottom"
        Component.onCompleted: root.registerProductionStack(this)
        Component.onDestruction: root.unregisterProductionStack(this)
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: overlayWindow
      required property var modelData
      readonly property bool fullscreenSuppressed: fullscreenGuard.activeOnScreen(modelData)
      readonly property string outputName: modelData && modelData.name !== undefined
        ? String(modelData.name) : ""
      readonly property var foregroundFrameBridge: root.lacunaState
        && typeof root.lacunaState.foregroundFrameSource === "function"
        ? root.lacunaState.foregroundFrameSource(outputName) : null

      screen: modelData
      // True foreground mode: this dynamically mapped Overlay may paint above
      // Overlay UI that was already mapped. Its empty mask remains pass-through.
      visible: root.mappingMode === "overlay"
      color: "transparent"
      WlrLayershell.namespace: "lacuna-ambience-host-overlay"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      AmbienceStack {
        anchors.fill: parent
        shell: root.shell
        targetScreen: overlayWindow.modelData
        activeEffects: root.activeEffects
        paintEnabled: root.mappingMode === "overlay" && !overlayWindow.fullscreenSuppressed
        Component.onCompleted: root.registerProductionStack(this)
        Component.onDestruction: root.unregisterProductionStack(this)
      }

      ForegroundFrameBorder {
        anchors.fill: parent
        z: 10000
        bridge: overlayWindow.foregroundFrameBridge
        paintEnabled: root.mappingMode === "overlay" && !overlayWindow.fullscreenSuppressed
      }
    }
  }

  IpcHandler {
    target: "lacuna-ambience-host"

    function status(): string {
      return JSON.stringify({
        enabled: root.effectsEnabled,
        foregroundOverlay: root.foregroundOverlay,
        activeEffects: root.normalizedOrder(),
        loadedEffectCount: root.loadedEffectCount(),
        mappingMode: root.mappingMode,
        mappedSurfaceCount: root.mappingMode === "none" ? 0 : Quickshell.screens.length,
        z: root.zMap(),
        bottomRenderable: root.mappingMode === "bottom",
        overlayRenderable: root.mappingMode === "overlay"
      })
    }
  }
}
