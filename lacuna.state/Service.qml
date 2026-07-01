import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  signal loaded()

  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/lacuna"
  readonly property string settingsFile: configDir + "/settings.json"
  property var data: defaultData()
  property var lastLoadedData: defaultData()
  property var pendingSave: null
  property bool pendingSaveTouchedQuickLaunch: false
  property bool pendingSaveTouchedSidebar: false
  property string queuedSavePayload: ""
  property string lastWrittenPayload: ""
  property bool writeInFlight: false
  property int suppressFileReloads: 0
  property bool hasLoaded: false
  property bool recoveredFromCorruptSettings: false

  function defaultData() {
    return {
      version: 1,
      designStyle: "lacuna",
      designStyles: {
        lacuna: {},
        omarchy: {},
        material: {}
      },
      colorProfile: "semantic",
      compact: false,
      reduceMotion: false,
      barSizeMode: "theme",
      quickLaunchLayout: "list",
      dailyLaunchLayout: "list",
      shortcutsLayout: "list",
      controlsLayout: "grid",
      barSizeSnapshot: null,
      sizeTransition: {
        holdCompact: false,
        holdUntil: 0
      },
      customQuickLaunchApps: [],
      customQuickLaunchNames: {},
      preferredApps: {
        files: "system",
        editor: "system",
        email: "system",
        discord: "system"
      },
      power: {
        instantRestart: false
      },
      shellSettings: {
        surface: "flyout"
      },
      mediaProviders: {
        youtube: {
          enabled: false,
          cookiesFromBrowser: "",
          cookiesFile: ""
        },
        jellyfin: {
          enabled: false,
          serverUrl: "",
          apiKey: "",
          userId: ""
        }
      },
      sidebar: {
        defaultMode: "off",
        collapsed: false,
        exclusive: true,
        cornerPieces: true
      },
      backgroundEffects: {
        enabled: true,
        foregroundOverlay: false,
        opacity: 1,
        activeEffect: "trackingLines",
        activeEffects: [
          "trackingLines"
        ],
        effects: {
          trackingLines: {
            enabled: true
          },
          filmGrain: {
            enabled: true,
            intensity: 0.28,
            speed: 1,
            grainCount: 180,
            grainSize: 1.35,
            accentBlend: 0.18
          },
          dustMotes: {
            enabled: true,
            intensity: 0.5,
            speed: 0.7,
            moteCount: 72,
            moteSize: 2.6,
            accentBlend: 0.42,
            mouseReactive: true,
            mouseInfluence: 0.28
          },
          auroraDrift: {
            enabled: true
          },
          rainfall: {
            enabled: true
          },
          cinematicLight: {
            enabled: true
          },
          godRays: {
            enabled: true
          },
          crt: {
            enabled: true
          }
        }
      },
      backgroundVignette: {
        enabled: false,
        intensity: 0.85,
        ignoreBackgroundAnimationLayer: false
      },
      frame: {
        mode: "off",
        reserveMode: "auto",
        shadow: false,
        border: false,
        thickness: 8,
        radius: 14,
        shadowDirection: "bottom_right",
        shadowOffsetX: 2,
        shadowOffsetY: 3
      }
    }
  }

  function normalize(value) {
    var next = defaultData()
    if (value && typeof value === "object") {
      next.version = Number(value.version || 1)
      next.designStyle = normalizeDesignStyle(value.designStyle)
      next.designStyles = normalizeDesignStyles(value.designStyles || value.stylePresets || value.designStylePresets)
      next.colorProfile = String(value.colorProfile || "").toLowerCase() === "colorful" ? "colorful" : "semantic"
      next.quickLaunchLayout = normalizeLayoutMode(value.quickLaunchLayout || value.quickLaunchView, "list")
      next.dailyLaunchLayout = normalizeLayoutMode(value.dailyLaunchLayout || value.launchLayout || value.dailyLaunchView, "list")
      next.shortcutsLayout = normalizeLayoutMode(value.shortcutsLayout || value.shortcutLayout || value.shortcutsView, "list")
      next.controlsLayout = normalizeControlsLayout(value.controlsLayout || value.controlLayout || value.controlsView)
      next.barSizeMode = normalizeBarSizeMode(value.barSizeMode, value.compact === true)
      next.compact = next.barSizeMode === "compact"
      next.reduceMotion = value.reduceMotion === true
      next.barSizeSnapshot = normalizeBarSizeSnapshot(value.barSizeSnapshot)
      next.sizeTransition = normalizeSizeTransition(value.sizeTransition)
      next.customQuickLaunchApps = normalizeCustomQuickLaunchApps(value.customQuickLaunchApps || value.quickLaunch)
      next.customQuickLaunchNames = normalizeCustomQuickLaunchNames(value.customQuickLaunchNames || value.quickLaunchNames, next.customQuickLaunchApps)
      next.preferredApps = normalizePreferredApps(value.preferredApps || value.defaultLaunchers || value.appDefaults)
      next.power = normalizePowerSettings(value.power || value.session || value.system)
      next.shellSettings = normalizeShellSettings(value.shellSettings || value.omarchySettings)
      next.mediaProviders = normalizeMediaProviders(value.mediaProviders || value.providers)
      if (value.sidebar && typeof value.sidebar === "object") {
        next.sidebar.defaultMode = normalizeSidebarDefaultMode(value.sidebar.defaultMode)
        next.sidebar.collapsed = value.sidebar.collapsed === true
        next.sidebar.exclusive = value.sidebar.exclusive !== false
        next.sidebar.cornerPieces = value.sidebar.cornerPieces !== false
      }
      next.backgroundEffects = normalizeBackgroundEffects(value.backgroundEffects || value.bgEffects)
      next.backgroundVignette = normalizeBackgroundVignette(value.backgroundVignette || value.bgVignette || value.vignette)
      if (value.frame && typeof value.frame === "object") {
        next.frame.mode = normalizeFrameMode(value.frame.mode)
        next.frame.reserveMode = normalizeFrameReserveMode(value.frame.reserveMode)
        next.frame.shadow = value.frame.shadow === true
        next.frame.border = value.frame.border === true
        next.frame.thickness = boundedInt(value.frame.thickness, 8, 2, 24)
        next.frame.radius = boundedInt(value.frame.radius, 14, 0, 32)
        next.frame.shadowDirection = normalizeShadowDirection(value.frame.shadowDirection)
        var offset = shadowOffsetFor(next.frame.shadowDirection)
        next.frame.shadowOffsetX = boundedInt(value.frame.shadowOffsetX, offset.x, -8, 8)
        next.frame.shadowOffsetY = boundedInt(value.frame.shadowOffsetY, offset.y, -8, 8)
      }
    }
    return next
  }

  function normalizeBackgroundVignette(value) {
    var defaults = defaultData().backgroundVignette
    var next = {
      enabled: defaults.enabled,
      intensity: defaults.intensity,
      ignoreBackgroundAnimationLayer: defaults.ignoreBackgroundAnimationLayer
    }

    if (value === true || value === false) {
      next.enabled = value === true
      return next
    }

    if (value && typeof value === "object") {
      next.enabled = value.enabled === true
      next.intensity = boundedReal(value.intensity, defaults.intensity, 0, 1)
      next.ignoreBackgroundAnimationLayer = value.ignoreBackgroundAnimationLayer === true
        || value.ignoreBackgroundAnimations === true
        || value.ignoreAnimationLayer === true
    }

    return next
  }

  function normalizePowerSettings(value) {
    var next = defaultData().power
    if (value && typeof value === "object") {
      next.instantRestart = value.instantRestart === true || value.instantReboot === true
    }
    return next
  }

  function normalizeShellSettings(value) {
    var next = defaultData().shellSettings
    if (value && typeof value === "object") {
      var surface = String(value.surface || value.mode || "").toLowerCase()
      next.surface = surface === "window" || surface === "floating" || surface === "panel" ? "window" : "flyout"
    }
    return next
  }

  function normalizeMediaProviders(value) {
    var next = defaultData().mediaProviders
    if (value && typeof value === "object") {
      var youtube = value.youtube && typeof value.youtube === "object" ? value.youtube : ({})
      var legacyYoutubeMusic = value.youtubeMusic && typeof value.youtubeMusic === "object" ? value.youtubeMusic : ({})
      next.youtube = {
        enabled: youtube.enabled === true || legacyYoutubeMusic.enabled === true,
        cookiesFromBrowser: String(youtube.cookiesFromBrowser || ""),
        cookiesFile: String(youtube.cookiesFile || legacyYoutubeMusic.authPath || "")
      }
      var jellyfin = value.jellyfin && typeof value.jellyfin === "object" ? value.jellyfin : ({})
      next.jellyfin = {
        enabled: jellyfin.enabled === true,
        serverUrl: String(jellyfin.serverUrl || ""),
        apiKey: String(jellyfin.apiKey || ""),
        userId: String(jellyfin.userId || "")
      }
    }
    return next
  }

  function normalizeBackgroundEffects(value) {
    var defaults = defaultData().backgroundEffects
    var next = {
      enabled: true,
      foregroundOverlay: defaults.foregroundOverlay === true,
      opacity: defaults.opacity,
      activeEffect: defaults.activeEffect,
      activeEffects: defaults.activeEffects.slice(),
      effects: {}
    }

    for (var defaultId in defaults.effects) {
      next.effects[defaultId] = normalizeBackgroundEffectConfig(defaultId, defaults.effects[defaultId])
    }

    if (value && typeof value === "object") {
      next.enabled = value.enabled !== false
      next.foregroundOverlay = value.foregroundOverlay === true
      next.opacity = boundedReal(value.opacity, defaults.opacity, 0, 1)
      next.activeEffects = normalizeBackgroundEffectStack(value.activeEffects, value.activeEffect || value.selectedEffect || value.currentEffect)
      next.activeEffect = next.activeEffects.length > 0 ? next.activeEffects[0] : normalizeBackgroundEffectId(value.activeEffect || value.selectedEffect || value.currentEffect, defaults.activeEffect)

      var sourceEffects = value.effects && typeof value.effects === "object" ? value.effects : {}
      for (var effectId in sourceEffects) {
        next.effects[effectId] = normalizeBackgroundEffectConfig(effectId, sourceEffects[effectId])
      }
    }

    if (!next.effects.trackingLines) next.effects.trackingLines = normalizeBackgroundEffectConfig("trackingLines", true)
    if (!next.effects.filmGrain) next.effects.filmGrain = normalizeBackgroundEffectConfig("filmGrain", true)
    if (!next.effects.dustMotes) next.effects.dustMotes = normalizeBackgroundEffectConfig("dustMotes", true)
    if (!next.effects.auroraDrift) next.effects.auroraDrift = normalizeBackgroundEffectConfig("auroraDrift", true)
    if (!next.effects.rainfall) next.effects.rainfall = normalizeBackgroundEffectConfig("rainfall", true)
    if (!next.effects.cinematicLight) next.effects.cinematicLight = normalizeBackgroundEffectConfig("cinematicLight", true)
    if (!next.effects.godRays) next.effects.godRays = normalizeBackgroundEffectConfig("godRays", true)
    if (!next.effects.crt) next.effects.crt = normalizeBackgroundEffectConfig("crt", true)
    if (!value || typeof value !== "object") {
      next.activeEffect = next.activeEffects.length > 0 ? next.activeEffects[0] : defaults.activeEffect
    }
    return next
  }

  function normalizeBackgroundEffectConfig(effectId, value) {
    var defaults = defaultData().backgroundEffects.effects[String(effectId || "")] || { enabled: true }
    var next = {}
    for (var key in defaults) next[key] = defaults[key]

    if (value === true || value === false) {
      next.enabled = value === true
      return next
    }

    if (value && typeof value === "object") {
      next.enabled = value.enabled !== false
      if (effectId === "filmGrain") {
        next.intensity = boundedReal(value.intensity, defaults.intensity, 0, 1)
        next.speed = boundedReal(value.speed, defaults.speed, 0.2, 5)
        next.grainCount = boundedInt(value.grainCount, defaults.grainCount, 32, 520)
        next.grainSize = boundedReal(value.grainSize, defaults.grainSize, 0.6, 3.5)
        next.accentBlend = boundedReal(value.accentBlend, defaults.accentBlend, 0, 1)
      } else if (effectId === "dustMotes") {
        next.intensity = boundedReal(value.intensity, defaults.intensity, 0, 1)
        next.speed = boundedReal(value.speed, defaults.speed, 0.15, 4)
        next.moteCount = boundedInt(value.moteCount, defaults.moteCount, 12, 180)
        next.moteSize = boundedReal(value.moteSize, defaults.moteSize, 1, 8)
        next.accentBlend = boundedReal(value.accentBlend, defaults.accentBlend, 0, 1)
        next.mouseReactive = value.mouseReactive !== false
        next.mouseInfluence = boundedReal(value.mouseInfluence, defaults.mouseInfluence, 0, 1)
      }
    }

    return next
  }

  function normalizeBackgroundEffectStack(value, fallback) {
    var source = Array.isArray(value) ? value : [fallback || defaultData().backgroundEffects.activeEffect]
    var seen = {}
    var next = []
    for (var i = 0; i < source.length; i++) {
      var id = normalizeBackgroundEffectId(source[i], "")
      if (id === "" || seen[id] === true) continue
      seen[id] = true
      next.push(id)
    }
    return next
  }

  function normalizeBackgroundEffectId(value, fallback) {
    var id = String(value || "").trim()
    if (id === "trackingLines" || id === "filmGrain" || id === "dustMotes" || id === "auroraDrift" || id === "rainfall" || id === "cinematicLight" || id === "godRays" || id === "crt") return id
    if (fallback === "filmGrain" || fallback === "dustMotes" || fallback === "auroraDrift" || fallback === "rainfall" || fallback === "cinematicLight" || fallback === "godRays" || fallback === "crt") return fallback
    if (fallback === "trackingLines") return fallback
    if (fallback === "") return ""
    return "trackingLines"
  }

  function boundedReal(value, fallback, minimum, maximum) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return fallback
    return Math.max(minimum, Math.min(maximum, parsed))
  }

  function boundedInt(value, fallback, minimum, maximum) {
    var parsed = Math.round(Number(value))
    if (!isFinite(parsed)) return fallback
    return Math.max(minimum, Math.min(maximum, parsed))
  }

  function normalizeFrameMode(value) {
    var mode = String(value || "").toLowerCase()
    if (mode === "fullframe" || mode === "on" || mode === "true" || mode === "1") return "fullframe"
    return "off"
  }

  function normalizeFrameReserveMode(value) {
    var mode = String(value || "").toLowerCase()
    if (mode === "comfort" || mode === "flush") return mode
    return "auto"
  }

  function normalizeShadowDirection(value) {
    var direction = String(value || "").toLowerCase()
    var valid = {
      top_left: true,
      top: true,
      top_right: true,
      left: true,
      center: true,
      right: true,
      bottom_left: true,
      bottom: true,
      bottom_right: true
    }
    return valid[direction] ? direction : "bottom_right"
  }

  function shadowOffsetFor(value) {
    var direction = normalizeShadowDirection(value)
    if (direction === "top_left") return Qt.point(-2, -2)
    if (direction === "top") return Qt.point(0, -3)
    if (direction === "top_right") return Qt.point(2, -2)
    if (direction === "left") return Qt.point(-3, 0)
    if (direction === "center") return Qt.point(0, 0)
    if (direction === "right") return Qt.point(3, 0)
    if (direction === "bottom_left") return Qt.point(-2, 2)
    if (direction === "bottom") return Qt.point(0, 3)
    return Qt.point(2, 3)
  }

  function normalizeBarSizeMode(value, compactFallback) {
    var mode = String(value || "").toLowerCase()
    if (mode === "theme" || mode === "compact" || mode === "full") return mode
    return compactFallback === true ? "compact" : "full"
  }

  function normalizeControlsLayout(value) {
    return normalizeLayoutMode(value, "grid")
  }

  function normalizeSidebarDefaultMode(value) {
    var mode = String(value || "").toLowerCase()
    if (mode === "off" || mode === "rail" || mode === "full") return mode
    return "off"
  }

  function normalizeLayoutMode(value, fallback) {
    var layout = String(value || "").toLowerCase()
    if (layout === "grid" || layout === "list") return layout
    return fallback === "list" ? "list" : "grid"
  }

  function normalizeBarSizeSnapshot(value) {
    if (!value || typeof value !== "object") return null

    var themeName = String(value.themeName || "").trim()
    var sizeHorizontal = Math.round(Number(value.sizeHorizontal))
    var sizeVertical = Math.round(Number(value.sizeVertical))

    if (themeName === "" || !isFinite(sizeHorizontal) || !isFinite(sizeVertical)) return null
    if (sizeHorizontal <= 0 || sizeVertical <= 0) return null

    return {
      themeName: themeName,
      sizeHorizontal: sizeHorizontal,
      sizeVertical: sizeVertical
    }
  }

  function normalizeSizeTransition(value) {
    if (!value || typeof value !== "object") return defaultData().sizeTransition
    return {
      holdCompact: value.holdCompact === true,
      holdUntil: boundedInt(value.holdUntil, 0, 0, 9999999999999)
    }
  }

  function normalizeCustomQuickLaunchApps(value) {
    var list = []
    if (!value || !Array.isArray(value)) return list

    for (var i = 0; i < value.length; i++) {
      var id = String(value[i] || "").trim()
      if (id.indexOf("role:") === 0) continue
      if (id !== "" && list.indexOf(id) === -1) list.push(id)
    }

    return list.slice(0, 12)
  }

  function normalizeCustomQuickLaunchNames(value, ids) {
    var names = {}
    if (!value || typeof value !== "object") return names

    for (var i = 0; i < ids.length; i++) {
      var id = String(ids[i] || "")
      var name = String(value[id] || "").trim()
      if (id !== "" && name !== "") names[id] = name.slice(0, 48)
    }

    return names
  }

  function normalizePreferredApps(value) {
    var defaults = defaultData().preferredApps
    var next = {
      files: defaults.files,
      editor: defaults.editor,
      email: defaults.email,
      discord: defaults.discord
    }

    if (!value || typeof value !== "object") return next

    var roles = ["files", "editor", "email", "discord"]
    for (var i = 0; i < roles.length; i++) {
      var role = roles[i]
      var id = String(value[role] || "").trim()
      next[role] = id === "" ? "system" : id
    }

    return next
  }

  function normalizeDesignStyle(value) {
    var style = String(value || "").toLowerCase()
    if (style === "lacuna" || style === "carbon") return "lacuna"
    if (style === "omarchy" || style === "material") return style
    return "lacuna"
  }

  function normalizeDesignStyles(value) {
    var next = defaultData().designStyles
    if (!value || typeof value !== "object") return next

    var styles = ["lacuna", "omarchy", "material"]
    for (var i = 0; i < styles.length; i++) {
      var style = styles[i]
      var source = value[style]
      if (!source || typeof source !== "object") continue

      var preset = {}
      var bar = normalizeDesignStyleBar(source.bar || source.barLayout)
      if (bar !== null) preset.bar = bar
      next[style] = preset
    }

    return next
  }

  function normalizeDesignStyleBar(value) {
    if (!value || typeof value !== "object") return null
    var sourceLayout = value.layout && typeof value.layout === "object" ? value.layout : value
    var layout = normalizeBarLayout(sourceLayout)
    var centerAnchor = String(value.centerAnchor || "").trim()

    if (centerAnchor === ""
        && layout.left.length === 0
        && layout.center.length === 0
        && layout.right.length === 0) return null

    var next = { layout: layout }
    if (centerAnchor !== "") next.centerAnchor = centerAnchor
    return next
  }

  function normalizeBarLayout(value) {
    var next = { left: [], center: [], right: [] }
    if (!value || typeof value !== "object") return next

    var sections = ["left", "center", "right"]
    for (var i = 0; i < sections.length; i++) {
      var section = sections[i]
      var source = Array.isArray(value[section]) ? value[section] : []
      for (var j = 0; j < source.length; j++) {
        var entry = normalizeBarLayoutEntry(source[j])
        if (entry !== null) next[section].push(entry)
      }
    }

    return next
  }

  function normalizeBarLayoutEntry(value) {
    if (!value || typeof value !== "object") return null
    var id = String(value.id || "").trim()
    if (id === "") return null

    var next = { id: id }
    for (var key in value) {
      if (key === "id") continue
      var normalized = normalizeJsonValue(value[key])
      if (normalized !== undefined) next[key] = normalized
    }
    return next
  }

  function normalizeJsonValue(value) {
    if (value === null) return null
    var t = typeof value
    if (t === "string" || t === "boolean") return value
    if (t === "number") return isFinite(value) ? value : undefined
    if (Array.isArray(value)) {
      var list = []
      for (var i = 0; i < value.length; i++) {
        var item = normalizeJsonValue(value[i])
        if (item !== undefined) list.push(item)
      }
      return list
    }
    if (t === "object") {
      var object = {}
      for (var key in value) {
        var child = normalizeJsonValue(value[key])
        if (child !== undefined) object[key] = child
      }
      return object
    }
    return undefined
  }

  function nextDesignStyle(value) {
    var style = normalizeDesignStyle(value)
    if (style === "lacuna") return "omarchy"
    if (style === "omarchy") return "material"
    return "lacuna"
  }

  function load() {
    settingsFileView.reload()
  }

  function applyLoadedText(raw) {
    var parsed
    try {
      parsed = normalize(JSON.parse(String(raw || "{}")))
    } catch (e) {
      console.warn("Lacuna settings.json is not valid JSON; backing up and restoring defaults:", e)
      var corrupt = String(raw || "")
      if (corrupt.trim().length > 0 && corrupt.trim() !== "{}") {
        settingsBackupFileView.setText(corrupt)
        recoveredFromCorruptSettings = true
      }
      parsed = defaultData()
    }

    data = parsed
    lastLoadedData = data
    hasLoaded = true
    loaded()
    if (pendingSave) {
      var queuedTouchedQuickLaunch = pendingSaveTouchedQuickLaunch
      var queuedTouchedSidebar = pendingSaveTouchedSidebar
      var queued = mergePendingSave(lastLoadedData, pendingSave, queuedTouchedQuickLaunch, queuedTouchedSidebar)
      pendingSave = null
      pendingSaveTouchedQuickLaunch = false
      pendingSaveTouchedSidebar = false
      save(queued, queuedTouchedQuickLaunch, queuedTouchedSidebar)
    }
  }

  function writePayload(payload) {
    if (writeInFlight) {
      queuedSavePayload = payload
      return
    }

    writeInFlight = true
    lastWrittenPayload = payload
    suppressFileReloads += 1
    settingsFileView.setText(payload)
    writeInFlight = false

    if (queuedSavePayload !== "" && queuedSavePayload !== payload) {
      var nextPayload = queuedSavePayload
      queuedSavePayload = ""
      writePayload(nextPayload)
    } else {
      queuedSavePayload = ""
    }
  }

  function save(next, touchedQuickLaunch, touchedSidebar) {
    if (!hasLoaded) {
      pendingSave = normalize(next)
      pendingSaveTouchedQuickLaunch = pendingSaveTouchedQuickLaunch || touchedQuickLaunch === true
      pendingSaveTouchedSidebar = pendingSaveTouchedSidebar || touchedSidebar === true
      load()
      return
    }

    data = normalize(next)
    var json = JSON.stringify(data, null, 2) + "\n"
    writePayload(json)
  }

  function mergePendingSave(base, queued, queuedTouchedQuickLaunch, queuedTouchedSidebar) {
    var merged = normalize(queued)
    var loadedBase = normalize(base)

    if (queuedTouchedQuickLaunch !== true
        && (!merged.customQuickLaunchApps || merged.customQuickLaunchApps.length === 0)
        && loadedBase.customQuickLaunchApps && loadedBase.customQuickLaunchApps.length > 0) {
      merged.customQuickLaunchApps = loadedBase.customQuickLaunchApps
      merged.customQuickLaunchNames = loadedBase.customQuickLaunchNames || {}
    }

    if (queuedTouchedSidebar !== true
        && JSON.stringify(merged.sidebar) === JSON.stringify(defaultData().sidebar)
        && JSON.stringify(loadedBase.sidebar) !== JSON.stringify(defaultData().sidebar)) {
      merged.sidebar = loadedBase.sidebar
    }

    return merged
  }

  Component.onCompleted: load()

  FileView {
    id: settingsFileView

    path: root.settingsFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyLoadedText(text())
    onFileChanged: {
      if (root.suppressFileReloads > 0) {
        root.suppressFileReloads -= 1
      } else {
        reload()
      }
    }
    onLoadFailed: root.applyLoadedText("{}")
  }

  FileView {
    id: settingsBackupFileView

    path: root.settingsFile + ".bak"
    atomicWrites: true
    printErrors: false
  }
}
