import QtQuick
import "effects"

Item {
  id: root

  property var shell: null
  property var targetScreen: null
  property var activeEffects: []
  property bool paintEnabled: true
  property bool productionEffectsEnabled: true
  property Component testFrontComponent: null
  property Component testBackComponent: null
  readonly property var supportedEffects: [
    "auroraDrift",
    "cinematicLight",
    "crt",
    "dustMotes",
    "filmGrain",
    "godRays",
    "rainfall",
    "trackingLines"
  ]
  readonly property var normalizedActiveEffects: normalizeActiveEffects(activeEffects)
  readonly property var testFrontObject: testFrontLoader
  readonly property var testBackObject: testBackLoader

  function normalizeActiveEffects(source) {
    var result = []
    var seen = {}
    var values = Array.isArray(source) ? source : []
    for (var i = 0; i < values.length; i++) {
      var effectId = String(values[i] || "")
      if (supportedEffects.indexOf(effectId) < 0 || seen[effectId]) continue
      seen[effectId] = true
      result.push(effectId)
    }
    return result
  }

  function stackIndex(effectId) {
    return normalizedActiveEffects.indexOf(String(effectId || ""))
  }

  function zForEffect(effectId) {
    var index = stackIndex(effectId)
    return index < 0 ? -1 : normalizedActiveEffects.length - index
  }

  AuroraDriftEffect {
    id: auroraDriftEffect
    objectName: "auroraDriftEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, intensity: 0.95, speed: 1.35, ribbonCount: 6, blurSoftness: 0.9, accentBlend: 0.88, vignette: true })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("auroraDrift")
  }

  CinematicLightEffect {
    id: cinematicLightEffect
    objectName: "cinematicLightEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, intensity: 1, speed: 1, stylePreset: "lightLeak", slowDrift: true, occasionalSweeps: false, activeShimmer: false, flareCount: 4, accentBlend: 0.5, vignette: true })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("cinematicLight")
  }

  CrtEffect {
    id: crtEffect
    objectName: "crtEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, foregroundOverlay: false, intensity: 0.58, speed: 1, scanlineSpacing: 3, staticBandHeight: 150, staticAmount: 0.24, glowAmount: 0.22, bloomPulse: true, bloomPulseAmount: 0.52, bloomPulseInterval: 18000, distortion: true, distortionAmount: 0.45, vignette: true })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("crt")
  }

  DustMotesEffect {
    id: dustMotesEffect
    objectName: "dustMotesEffect"
    anchors.fill: parent
    shell: root.shell
    targetScreen: root.targetScreen
    defaultSettings: ({ effectEnabled: true, intensity: 0.5, speed: 0.7, moteCount: 72, moteSize: 2.6, accentBlend: 0.42, mouseReactive: true, mouseInfluence: 0.28 })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("dustMotes")
  }

  FilmGrainEffect {
    id: filmGrainEffect
    objectName: "filmGrainEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, intensity: 0.28, speed: 1, grainCount: 180, grainSize: 1.35, accentBlend: 0.18 })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("filmGrain")
  }

  GodRaysEffect {
    id: godRaysEffect
    objectName: "godRaysEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, intensity: 0.82, speed: 0.85, rayCount: 7, raySpread: 0.72, blurSoftness: 0.88, accentBlend: 0.58, shimmer: true, vignette: true, origin: "top-left" })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("godRays")
  }

  RainfallEffect {
    id: rainfallEffect
    objectName: "rainfallEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, intensity: 0.72, speed: 0.62, dropCount: 180, slant: 0.08, mistAmount: 0.34, splashAmount: 0.38, accentBlend: 0.42, vignette: true })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("rainfall")
  }

  VhsEffect {
    id: vhsEffect
    objectName: "vhsEffect"
    anchors.fill: parent
    shell: root.shell
    defaultSettings: ({ effectEnabled: true, foregroundOverlay: false, intensity: 0.68, speed: 1, lineSpacing: 4, trackingBands: 4, noiseAmount: 0.42, glitchAmount: 0.34, chromaBleed: true, vignette: true })
    runtimeEnabled: root.paintEnabled && root.productionEffectsEnabled
    z: root.zForEffect("trackingLines")
  }

  Loader {
    id: testFrontLoader
    objectName: "testFrontLoader"
    anchors.fill: parent
    active: root.testFrontComponent !== null
    sourceComponent: root.testFrontComponent
    z: root.zForEffect("auroraDrift")
  }

  Loader {
    id: testBackLoader
    objectName: "testBackLoader"
    anchors.fill: parent
    active: root.testBackComponent !== null
    sourceComponent: root.testBackComponent
    z: root.zForEffect("filmGrain")
  }
}
