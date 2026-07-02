import Quickshell
import Quickshell.Hyprland
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
  property real cursorX: -1
  property real cursorY: -1
  property real lastCursorX: -1
  property real lastCursorY: -1
  property real cursorVelocityX: 0
  property real cursorVelocityY: 0
  property real cursorKick: 0
  property real cursorDecayAccumulator: 0
  property real cursorPollAccumulator: 0
  property var lacunaSettings: ({})
  property var palette: ({})

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: configHome + "/omarchy/current/theme.name"
  readonly property var overlaySettings: pluginSettings()
  readonly property var dustMotesSettings: backgroundEffectSettings("dustMotes")
  readonly property bool configuredEnabled: boolSetting("effectEnabled", true)
  readonly property bool foregroundOverlay: backgroundForegroundOverlayEnabled()
  readonly property bool lacunaDustMotesEnabled: backgroundEffectEnabled("dustMotes", true)
  readonly property bool effectVisible: configuredEnabled && lacunaDustMotesEnabled && runtimeEnabled && effectiveIntensity > 0.001
  readonly property real configuredIntensity: clamp(effectNumberSetting("intensity", "intensity", 0.5), 0, 1)
  readonly property real effectiveIntensity: (runtimeIntensity >= 0 ? clamp(runtimeIntensity, 0, 1) : configuredIntensity) * backgroundAnimationOpacity()
  readonly property real speed: clamp(effectNumberSetting("speed", "speed", 0.7), 0.15, 4)
  readonly property int moteCount: Math.max(12, Math.min(180, Math.round(effectNumberSetting("moteCount", "moteCount", 72))))
  readonly property real moteSize: clamp(effectNumberSetting("moteSize", "moteSize", 2.6), 1, 8)
  readonly property real accentBlend: clamp(effectNumberSetting("accentBlend", "accentBlend", 0.42), 0, 1)
  readonly property bool mouseReactive: effectBoolSetting("mouseReactive", "mouseReactive", true)
  readonly property real mouseInfluence: clamp(effectNumberSetting("mouseInfluence", "mouseInfluence", 0.28), 0, 1)
  readonly property real cursorInfluenceRadius: 220 + mouseInfluence * 320
  readonly property real cursorInfluenceRadiusSquared: cursorInfluenceRadius * cursorInfluenceRadius
  readonly property real cursorSpeed: Math.sqrt(cursorVelocityX * cursorVelocityX + cursorVelocityY * cursorVelocityY)
  readonly property int maxTransientMotes: Math.round(22 + mouseInfluence * 52)
  readonly property color themeForeground: themeColor("foreground", "#d8dee9")
  readonly property color themeAccent: themeColor("accent", themeColor("color14", "#88c0d0"))
  readonly property color moteColor: mixColor(themeForeground, themeAccent, accentBlend)

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
      if (!entry || entry.id !== "lacuna.dust-motes-overlay") continue
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

  function effectNumberSetting(effectKey, pluginKey, fallbackValue) {
    var value = dustMotesSettings && dustMotesSettings[effectKey] !== undefined
      ? Number(dustMotesSettings[effectKey])
      : numberSetting(pluginKey, fallbackValue)
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

  function effectBoolSetting(effectKey, pluginKey, fallbackValue) {
    if (dustMotesSettings && dustMotesSettings[effectKey] !== undefined) {
      return boolValue(dustMotesSettings[effectKey], fallbackValue)
    }
    return boolSetting(pluginKey, fallbackValue)
  }

  function boolValue(value, fallbackValue) {
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

  function backgroundEffectSettings(effectId) {
    var settings = lacunaSettings && typeof lacunaSettings === "object" ? lacunaSettings : {}
    var backgroundEffects = settings.backgroundEffects && typeof settings.backgroundEffects === "object" ? settings.backgroundEffects : null
    var effects = backgroundEffects && backgroundEffects.effects && typeof backgroundEffects.effects === "object" ? backgroundEffects.effects : {}
    var effect = effects[String(effectId || "")]
    return effect && typeof effect === "object" ? effect : ({})
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

  function screenOrigin(screen, axis) {
    var value = screen && screen[axis] !== undefined ? Number(screen[axis]) : 0
    return isNaN(value) ? 0 : value
  }

  function pollCursor() {
    if (!mouseReactive || !effectVisible || cursorSocket.connected) return
    cursorSocket.path = Hyprland.requestSocketPath
    cursorSocket.connected = true
  }

  function applyCursorPayload(raw) {
    try {
      var parsed = JSON.parse(raw || "{}")
      var nextX = Number(parsed.x)
      var nextY = Number(parsed.y)
      if (isNaN(nextX) || isNaN(nextY)) return

      if (lastCursorX >= 0 && lastCursorY >= 0) {
        var dx = nextX - lastCursorX
        var dy = nextY - lastCursorY
        var distance = Math.sqrt(dx * dx + dy * dy)
        if (distance > 0.5) {
          cursorVelocityX = Math.max(-90, Math.min(90, dx))
          cursorVelocityY = Math.max(-90, Math.min(90, dy))
          cursorKick = Math.max(cursorKick, Math.min(1, 0.35 + distance / 180))
          cursorDecayAccumulator = 0
        }
      }

      cursorX = nextX
      cursorY = nextY
      lastCursorX = nextX
      lastCursorY = nextY
    } catch (error) {
    }
  }

  function open(payloadJson) {
    var payload = parsePayload(payloadJson)
    runtimeEnabled = true
    if (payload.intensity !== undefined) runtimeIntensity = clamp(payload.intensity, 0, 1)
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

  FrameAnimation {
    id: cursorFrameClock

    running: root.effectVisible && root.mouseReactive
    onTriggered: {
      root.cursorPollAccumulator += frameTime * 1000
      if (root.cursorPollAccumulator >= 120 || currentFrame === 1) {
        root.cursorPollAccumulator = 0
        root.pollCursor()
      }

      if (root.cursorKick > 0 || root.cursorVelocityX !== 0 || root.cursorVelocityY !== 0) {
        root.cursorDecayAccumulator += frameTime * 1000
        if (root.cursorDecayAccumulator >= 520) {
          root.cursorVelocityX = 0
          root.cursorVelocityY = 0
          root.cursorKick = 0
          root.cursorDecayAccumulator = 0
        }
      }
    }
  }

  Socket {
    id: cursorSocket

    connected: false
    parser: SplitParser {
      onRead: function(data) {
        root.applyCursorPayload(data)
        cursorSocket.connected = false
      }
    }

    onConnectionStateChanged: {
      if (connected) {
        write("j/cursorpos")
        flush()
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: dustWindow

      required property var modelData
      readonly property real screenOriginX: root.screenOrigin(modelData, "x")
      readonly property real screenOriginY: root.screenOrigin(modelData, "y")
      readonly property real cursorLocalX: root.cursorX - screenOriginX
      readonly property real cursorLocalY: root.cursorY - screenOriginY

      screen: modelData
      visible: root.effectVisible
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-dust-motes-overlay"
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
        id: dustLayer

        anchors.fill: parent
        enabled: false
        opacity: root.effectiveIntensity

        function updatePersistentMotes(deltaMs) {
          for (var i = 0; i < persistentMoteRepeater.count; i++) {
            var item = persistentMoteRepeater.itemAt(i)
            if (item) item.applyAirDisturbance(deltaMs)
          }
        }

        function updateTransientMotes(deltaMs) {
          for (var i = transientMoteRepeater.count - 1; i >= 0; i--) {
            var item = transientMoteRepeater.itemAt(i)
            if (item && item.active) item.advanceFrame(deltaMs)
          }
        }

        function firstReusableTransientMote() {
          var oldestItem = null
          for (var i = 0; i < transientMoteRepeater.count; i++) {
            var item = transientMoteRepeater.itemAt(i)
            if (!item) continue
            if (!item.active) return item
            if (!oldestItem || item.age > oldestItem.age) oldestItem = item
          }
          return oldestItem
        }

        function cursorInsideWindow() {
          return dustWindow.cursorLocalX >= 0
            && dustWindow.cursorLocalY >= 0
            && dustWindow.cursorLocalX <= dustWindow.width
            && dustWindow.cursorLocalY <= dustWindow.height
        }

        function spawnTransientMote() {
          if (!root.mouseReactive || root.mouseInfluence <= 0 || !cursorInsideWindow()) return

          var speed = root.cursorSpeed
          if (speed < 2) return

          var spawnChance = Math.min(0.92, 0.52 + speed / 460) * Math.max(0.72, root.mouseInfluence)
          if (Math.random() > spawnChance) return

          var burstCount = 1 + (Math.random() < Math.min(0.42, speed / 430) ? 1 : 0)
          for (var i = 0; i < burstCount; i++) {
            var mote = firstReusableTransientMote()
            if (!mote) return
            var angle = Math.random() * Math.PI * 2
            var radius = Math.sqrt(Math.random()) * (14 + root.moteSize * 3.4)
            var originX = Math.cos(angle) * radius
            var originY = Math.sin(angle) * radius
            var outwardX = radius > 0 ? originX / radius : Math.cos(angle)
            var outwardY = radius > 0 ? originY / radius : Math.sin(angle)
            var sideX = -outwardY
            var sideY = outwardX
            var lift = 0.48 + Math.random() * 1.10
            var size = Math.max(1.5, root.moteSize * (0.72 + Math.random() * 0.58))

            mote.spawn(
              dustWindow.cursorLocalX - size / 2 + originX,
              dustWindow.cursorLocalY - size / 2 + originY,
              outwardX * lift + sideX * (Math.random() - 0.5) * 0.7 + root.cursorVelocityX * (0.0015 + Math.random() * 0.0035),
              outwardY * lift + sideY * (Math.random() - 0.5) * 0.7 + root.cursorVelocityY * (0.0015 + Math.random() * 0.0035),
              size,
              0.46 + Math.random() * 0.28,
              5000 + Math.random() * 4000
            )
          }
        }

        FrameAnimation {
          id: dustFrameClock

          property real spawnAccumulator: 0

          running: root.effectVisible
          onTriggered: {
            var deltaMs = Math.min(50, frameTime * 1000)
            dustLayer.updatePersistentMotes(deltaMs)
            dustLayer.updateTransientMotes(deltaMs)
            if (root.mouseReactive) {
              spawnAccumulator += deltaMs
              if (spawnAccumulator >= 58) {
                dustLayer.spawnTransientMote()
                spawnAccumulator = 0
              }
            } else {
              spawnAccumulator = 0
            }
          }
        }

        Repeater {
          id: persistentMoteRepeater

          model: root.moteCount

          Rectangle {
            id: mote

            required property int index

            readonly property real seed: index + 1
            readonly property real sizeNoise: root.seededNoise(seed + 2)
            readonly property real moteVariance: 0.65 + root.seededNoise(seed + 83) * 0.7
            readonly property real wakeVariance: 0.86 + root.seededNoise(seed + 89) * 0.28
            readonly property real damping: 0.865 + root.seededNoise(seed + 97) * 0.035
            readonly property real spring: 0.0025 + root.seededNoise(seed + 101) * 0.004
            readonly property real swirlDirection: root.seededNoise(seed + 107) > 0.5 ? 1 : -1
            property real airOffsetX: 0
            property real airOffsetY: 0
            property real airVelocityX: 0
            property real airVelocityY: 0
            property real airAge: 0
            width: Math.max(1, Math.round(root.moteSize * (0.5 + sizeNoise * 1.4)))
            height: width
            radius: width / 2
            color: root.moteColor
            opacity: 0.16 + root.seededNoise(seed + 7) * 0.50
            x: Math.round(root.seededNoise(seed + 11) * Math.max(1, dustWindow.width))
            y: Math.round(root.seededNoise(seed + 17) * Math.max(1, dustWindow.height))

            function clampAir(value) {
              return root.clamp(value, -180, 180)
            }

            function applyAirDisturbance(deltaMs) {
              var deltaScale = Math.max(0.25, Math.min(2.5, deltaMs / 33))
              airAge += deltaMs / 1000
              if (root.mouseReactive && root.mouseInfluence > 0 && root.cursorX >= 0 && root.cursorKick > 0) {
                var cursorDx = x + width / 2 + airOffsetX - dustWindow.cursorLocalX
                var cursorDy = y + height / 2 + airOffsetY - dustWindow.cursorLocalY
                var distanceSquared = cursorDx * cursorDx + cursorDy * cursorDy

                if (distanceSquared < root.cursorInfluenceRadiusSquared) {
                  var cursorDistance = Math.max(1, Math.sqrt(distanceSquared))
                  var cursorFalloff = Math.pow(1 - cursorDistance / root.cursorInfluenceRadius, 1.35)
                  var radialStrength = 10 + root.cursorSpeed * (0.07 + root.seededNoise(seed + 113) * 0.045)
                  var wakeStrength = 0.18 + root.cursorKick * (0.12 + root.seededNoise(seed + 127) * 0.10)
                  var swirlStrength = (1.8 + root.cursorSpeed * 0.012) * swirlDirection
                  var noiseX = Math.sin(airAge * (0.8 + root.seededNoise(seed + 131) * 0.5) + seed) * 1.1
                  var noiseY = Math.cos(airAge * (0.7 + root.seededNoise(seed + 137) * 0.5) + seed * 0.7) * 1.1
                  var forceScale = root.mouseInfluence * cursorFalloff * moteVariance * wakeVariance
                  var radialX = cursorDx / cursorDistance
                  var radialY = cursorDy / cursorDistance
                  var swirlX = -radialY * swirlStrength
                  var swirlY = radialX * swirlStrength
                  airVelocityX += (radialX * radialStrength + root.cursorVelocityX * wakeStrength + swirlX + noiseX) * forceScale * 0.062 * deltaScale
                  airVelocityY += (radialY * radialStrength + root.cursorVelocityY * wakeStrength + swirlY + noiseY) * forceScale * 0.062 * deltaScale
                }
              }

              airVelocityX = root.clamp((airVelocityX - airOffsetX * spring) * damping, -10, 10)
              airVelocityY = root.clamp((airVelocityY - airOffsetY * spring) * damping, -10, 10)
              airOffsetX = clampAir(airOffsetX + airVelocityX)
              airOffsetY = clampAir(airOffsetY + airVelocityY)

              if (Math.abs(airOffsetX) < 0.05 && Math.abs(airVelocityX) < 0.05) {
                airOffsetX = 0
                airVelocityX = 0
              }
              if (Math.abs(airOffsetY) < 0.05 && Math.abs(airVelocityY) < 0.05) {
                airOffsetY = 0
                airVelocityY = 0
              }
            }

            transform: [
              Translate {
                x: mote.airOffsetX
                y: mote.airOffsetY
              }
            ]

            SequentialAnimation on x {
              running: root.effectVisible
              loops: Animation.Infinite
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 23) * Math.max(1, dustWindow.width))
                duration: Math.max(8000, Math.round((22000 + root.seededNoise(seed + 29) * 18000) / root.speed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 31) * Math.max(1, dustWindow.width))
                duration: Math.max(8000, Math.round((24000 + root.seededNoise(seed + 37) * 16000) / root.speed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on y {
              running: root.effectVisible
              loops: Animation.Infinite
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 41) * Math.max(1, dustWindow.height))
                duration: Math.max(9000, Math.round((26000 + root.seededNoise(seed + 43) * 20000) / root.speed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                to: Math.round(root.seededNoise(seed + 47) * Math.max(1, dustWindow.height))
                duration: Math.max(9000, Math.round((28000 + root.seededNoise(seed + 53) * 18000) / root.speed))
                easing.type: Easing.InOutSine
              }
            }

            SequentialAnimation on opacity {
              running: root.effectVisible
              loops: Animation.Infinite
              NumberAnimation {
                to: 0.12 + root.seededNoise(seed + 59) * 0.42
                duration: Math.max(3000, Math.round((6500 + root.seededNoise(seed + 61) * 5500) / root.speed))
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                to: 0.18 + root.seededNoise(seed + 67) * 0.52
                duration: Math.max(3000, Math.round((7000 + root.seededNoise(seed + 71) * 5000) / root.speed))
                easing.type: Easing.InOutSine
              }
            }
          }
        }

        Repeater {
          id: transientMoteRepeater

          model: root.maxTransientMotes

          Rectangle {
            id: transientMote

            required property int index
            property bool active: false
            property real px: 0
            property real py: 0
            property real vx: 0
            property real vy: 0
            property real particleSize: 1
            property real alpha: 0
            property real age: 0
            property real life: 1

            width: Math.max(1, particleSize)
            height: width
            radius: width / 2
            x: px
            y: py
            visible: active
            color: root.moteColor
            opacity: alpha * Math.min(1, age / 220) * Math.pow(Math.max(0, 1 - age / life), 0.95)

            function spawn(nextX, nextY, nextVx, nextVy, nextSize, nextAlpha, nextLife) {
              px = nextX
              py = nextY
              vx = nextVx
              vy = nextVy
              particleSize = nextSize
              alpha = nextAlpha
              age = 0
              life = nextLife
              active = true
            }

            function applyCursorInfluence() {
              if (!root.mouseReactive || root.mouseInfluence <= 0 || root.cursorX < 0) return

              var centerX = px + width / 2
              var centerY = py + height / 2
              var dx = centerX - dustWindow.cursorLocalX
              var dy = centerY - dustWindow.cursorLocalY
              var distanceSquared = dx * dx + dy * dy
              if (distanceSquared >= root.cursorInfluenceRadiusSquared) return

              var distance = Math.max(1, Math.sqrt(distanceSquared))
              var falloff = Math.pow(1 - distance / root.cursorInfluenceRadius, 1.2)
              var radialForce = (0.20 + root.cursorSpeed * 0.0025) * root.mouseInfluence * falloff
              var wakeForce = 0.012 * root.mouseInfluence * falloff
              transientMote.vx += dx / distance * radialForce + root.cursorVelocityX * wakeForce
              transientMote.vy += dy / distance * radialForce + root.cursorVelocityY * wakeForce
            }

            function advanceFrame(deltaMs) {
              transientMote.age += deltaMs
              if (transientMote.age >= transientMote.life) {
                transientMote.active = false
                return
              }

              transientMote.applyCursorInfluence()
              var deltaScale = Math.max(0.25, Math.min(2.5, deltaMs / 33))
              transientMote.vx = root.clamp(transientMote.vx * Math.pow(0.968, deltaScale), -7.5, 7.5)
              transientMote.vy = root.clamp(transientMote.vy * Math.pow(0.968, deltaScale), -7.5, 7.5)
              transientMote.px += transientMote.vx * deltaScale
              transientMote.py += transientMote.vy * deltaScale
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "lacuna-dust-motes-overlay"

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
        foregroundOverlay: root.foregroundOverlay,
        intensity: root.effectiveIntensity,
        speed: root.speed,
        moteCount: root.moteCount,
        moteSize: root.moteSize,
        accentBlend: root.accentBlend,
        mouseReactive: root.mouseReactive,
        mouseInfluence: root.mouseInfluence,
        cursorKick: root.cursorKick
      })
    }
  }
}
