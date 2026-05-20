import Quickshell
import Quickshell.Io
import QtQuick
import "../services"
import "../components"
import "../settings"

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property string pluginId: manifest && manifest.id ? manifest.id : "omarchy.lacuna-menu"
  property var menuState: localMenuState
  property string lacunaPath: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl(".."))
  property var sharedCompactState: null
  property var sharedSidebarState: null
  readonly property var compactState: sharedCompactState || localCompactState
  readonly property var sidebarState: sharedSidebarState || localSidebarState
  property color foreground: menuTheme.foreground
  property color background: menuTheme.background
  property color panelColor: menuTheme.panelBackground
  property color accent: menuTheme.accent
  property color shellAccent: menuTheme.color("color6")
  property color sessionAccent: menuTheme.color("color11")
  property color dangerAccent: menuTheme.color("color9")
  property color navAccent: menuTheme.soft
  property color muted: menuTheme.muted
  property string version: ""
  property bool compact: compactState.compact
  property bool forceCompactRail: false
  property bool railCompact: forceCompactRail ? true : compact
  property string designStyle: lacunaSettings.data && lacunaSettings.data.designStyle ? lacunaSettings.data.designStyle : "carbon"
  readonly property string barPosition: currentBarPosition()
  // Lacuna is its own left sidebar. The Omarchy bar position only affects
  // offsets and sizing, not which edge Lacuna owns.
  readonly property bool panelOnRight: false
  readonly property bool effectiveCornerPieces: sidebarState.cornerPieces && !panelOnRight
  property int fullPanelWidth: compact ? 270 : 310
  property int barControlSize: currentBarSize()
  property int railButtonWidth: railCompact ? 24 : barControlSize
  property int railLeftInset: railDesignTokens.railLeftInset
  property int railRightInset: railDesignTokens.railRightInset
  property int railPanelWidth: railButtonWidth + railLeftInset + railRightInset
  property int panelWidth: sidebarState.collapsed ? railPanelWidth : fullPanelWidth
  property int defaultTopBarHeight: 26
  property int barHeight: topBarHeight()
  property int joinRadius: effectiveCornerPieces ? (compact ? 14 : 18) : 0
  property int connectorOverlap: effectiveCornerPieces ? (compact ? 25 : 33) : 0
  property int bodyRightInset: effectiveCornerPieces ? joinRadius : 0
  property int surfaceRightInset: bodyRightInset
  property int settingsConnectorWidth: effectiveCornerPieces ? joinRadius : 0
  property int flyoutLaneWidth: panelController.menuRenderable ? maxFlyoutLaneWidth : 0
  // In exclusive mode the compositor already places this window below the top
  // bar, so the bar edge is local y=0. In overlay mode the window starts at
  // screen top and the bar edge is the live bar height.
  property int barBottomY: sidebarState.exclusive ? 0 : barHeight
  property bool panelVisible: panelController.panelVisible
  readonly property bool settingsPanelOpen: panelController.isFlyoutOpen("settings")
  readonly property bool settingsPanelVisible: panelController.isFlyoutVisible("settings")
  property int settingsPanelWidth: compact ? 360 : 400
  readonly property bool appPickerOpen: panelController.isFlyoutOpen("appPicker")
  readonly property bool appPickerVisible: panelController.isFlyoutVisible("appPicker")
  readonly property bool flyoutOpen: panelController.flyoutOpen
  readonly property bool flyoutInteractive: panelController.flyoutInteractive
  property string appPickerMode: "customQuickLaunchApp"
  property string preferredAppPickerRole: ""
  property int appPickerWidth: compact ? 260 : 300
  readonly property int maxFlyoutLaneWidth: Math.max(settingsPanelWidth, appPickerWidth)
  readonly property string visibleFlyout: panelController.visibleFlyout
  readonly property string outgoingFlyout: panelController.outgoingFlyout
  readonly property bool activeFlyoutSettings: visibleFlyout === "settings"
  readonly property bool activeFlyoutAppPicker: visibleFlyout === "appPicker"
  readonly property bool renderSettingsContent: settingsPanelVisible || outgoingFlyout === "settings"
  readonly property bool renderAppPickerContent: appPickerVisible || outgoingFlyout === "appPicker"
  readonly property int activeFlyoutWidth: activeFlyoutSettings ? settingsPanelWidth : activeFlyoutAppPicker ? appPickerWidth : 0
  readonly property int activeFlyoutHeight: activeFlyoutSettings ? settingsFlyoutHeight() : activeFlyoutAppPicker ? appPickerHeightFor(activeFlyoutY) : 0
  readonly property int activeFlyoutY: activeFlyoutSettings ? settingsFlyoutY(settingsFlyoutHeight()) : activeFlyoutAppPicker ? appPickerFlyoutY() : 0
  readonly property int frameOverlayWidth: frameMode === "off" ? 0 : ((sidebarScreen ? sidebarScreen.width : 0) + 100)
  property string pendingFlyoutFocus: ""
  property int pluginStateRevision: 0
  readonly property var shellConfig: shell && shell.shellConfig ? shell.shellConfig : ({})
  readonly property var desktopClockSettings: shellPluginSettings("omarchy.lacuna-desktop-clock", {
    anchor: "bottom-right",
    offsetX: 0,
    offsetY: 0,
    scale: 1,
    use12Hour: false
  })
  readonly property bool desktopClockEnabled: shellPluginEnabled("omarchy.lacuna-desktop-clock")
  readonly property string desktopClockAnchor: validClockAnchor(desktopClockSettings.anchor)
  readonly property int desktopClockOffsetX: numberSetting(desktopClockSettings.offsetX, 0)
  readonly property int desktopClockOffsetY: numberSetting(desktopClockSettings.offsetY, 0)
  readonly property real desktopClockScale: numberSetting(desktopClockSettings.scale, 1)
  readonly property bool desktopClockUse12Hour: boolSetting(desktopClockSettings.use12Hour, false)
  readonly property var frameSettings: lacunaSettings.data && lacunaSettings.data.frame ? lacunaSettings.data.frame : ({})
  readonly property string frameMode: validFrameMode(frameSettings.mode)
  readonly property bool frameShadow: boolSetting(frameSettings.shadow, false)
  readonly property int frameThickness: positiveInt(frameSettings.thickness, 8)
  readonly property int frameRadius: Math.max(0, positiveInt(frameSettings.radius, 14))
  readonly property int frameShadowOffsetX: numberSetting(frameSettings.shadowOffsetX, 2)
  readonly property int frameShadowOffsetY: numberSetting(frameSettings.shadowOffsetY, 3)
  readonly property var sidebarScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function resolvedOmarchyPath() {
    return root.omarchyPath || Quickshell.env("OMARCHY_PATH") || (Quickshell.env("HOME") + "/.local/share/omarchy")
  }

  function shellIpcCommand(target, method, args) {
    var path = resolvedOmarchyPath()
    var command = "OMARCHY_PATH=" + commands.quote(path) + " " + commands.quote(path + "/bin/omarchy-shell")
      + " " + commands.quote(target) + " " + commands.quote(method)
    for (var i = 0; i < args.length; i++) command += " " + commands.quote(args[i])
    return command
  }

  function positiveInt(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) && parsed > 0 ? Math.round(parsed) : fallback
  }

  function configBarHeight() {
    var barConfig = shell && shell.barConfig ? shell.barConfig : null
    if (!barConfig || typeof barConfig !== "object") return defaultTopBarHeight
    return positiveInt(barConfig.height !== undefined ? barConfig.height : barConfig.size, defaultTopBarHeight)
  }

  function currentBarSize() {
    var liveBar = shell && shell.bar ? shell.bar : null
    var verticalFallback = (barPosition === "left" || barPosition === "right") ? 28 : configBarHeight()
    if (liveBar && liveBar.barSize !== undefined) return positiveInt(liveBar.barSize, verticalFallback)
    return verticalFallback
  }

  function currentBarPosition() {
    var liveBar = shell && shell.bar ? shell.bar : null
    var livePosition = liveBar && liveBar.position ? String(liveBar.position) : ""
    var configPosition = shell && shell.barConfig && shell.barConfig.position ? String(shell.barConfig.position) : ""
    var shellConfigPosition = shell && shell.shellConfig && shell.shellConfig.bar && shell.shellConfig.bar.position
      ? String(shell.shellConfig.bar.position) : ""

    // shell.bar can briefly expose its default before the persisted config is
    // applied. Prefer the config source for offset and size decisions.
    return configPosition || shellConfigPosition || livePosition || "top"
  }

  function topBarHeight() {
    var liveBar = shell && shell.bar ? shell.bar : null
    var position = currentBarPosition()

    if (position !== "top") return 0
    if (liveBar && !liveBar.barHidden && liveBar.barSize !== undefined) {
      return positiveInt(liveBar.barSize, configBarHeight())
    }
    return configBarHeight()
  }

  function settingsFlyoutHeight() {
    var availableHeight = menuWindow.height - barBottomY - designTokens.topInset - designTokens.bottomInset
    return Math.max(260, Math.min(availableHeight, compact ? 430 : 470))
  }

  function settingsFlyoutY(panelHeight) {
    var topLimit = barBottomY + designTokens.topInset
    var lift = compact ? 72 : 112
    return Math.max(topLimit, menuWindow.height - panelHeight - designTokens.bottomInset - lift)
  }

  function appPickerFlyoutY() {
    var topLimit = barBottomY + designTokens.topInset
    var panelHeight = root.compact ? 430 : 520
    var preferredY = topLimit + (compact ? 38 : 52)
    var maxY = Math.max(topLimit, menuWindow.height - panelHeight - designTokens.bottomInset)
    return Math.min(preferredY, maxY)
  }

  function appPickerHeightFor(y) {
    return Math.min(menuWindow.height - y - designTokens.bottomInset, root.compact ? 430 : 520)
  }

  function open(payloadJson) {
    panelController.openMenu()
  }

  function close() {
    pendingFlyoutFocus = ""
    panelController.closeMenu()
  }

  function closeFlyouts() {
    pendingFlyoutFocus = ""
    panelController.closeActiveFlyout()
  }

  function viewToneAccent() {
    if (menuState.currentView === "system") return root.dangerAccent
    if (menuState.currentView === "lacuna-shell") return root.shellAccent
    if (menuState.currentView === "lacuna" || menuState.currentView === "lacuna-preferences") return root.accent
    return root.accent
  }

  function setDesignStyle(style) {
    var nextStyleSettings = lacunaSettings.normalize(lacunaSettings.data)
    nextStyleSettings.designStyle = lacunaSettings.normalizeDesignStyle(style)
    lacunaSettings.save(nextStyleSettings)
  }

  function customQuickLaunchContains(id) {
    var ids = lacunaSettings.data && lacunaSettings.data.customQuickLaunchApps ? lacunaSettings.data.customQuickLaunchApps : []
    for (var i = 0; i < ids.length; i++) {
      if (String(ids[i]) === String(id)) return true
    }
    return false
  }

  function addCustomQuickLaunchApp(id) {
    if (!id || customQuickLaunchContains(id)) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.customQuickLaunchApps = next.customQuickLaunchApps.concat([String(id)]).slice(0, 12)
    lacunaSettings.save(next)
  }

  function moveCustomQuickLaunchApp(id, targetIndex) {
    var appId = String(id || "")
    if (appId === "") return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    var ids = next.customQuickLaunchApps.slice()
    var from = ids.indexOf(appId)
    if (from < 0) return

    var target = Math.max(0, Math.min(ids.length, Math.round(Number(targetIndex) || 0)))
    ids.splice(from, 1)
    if (target > from) target--
    target = Math.max(0, Math.min(ids.length, target))
    if (target === from) return

    ids.splice(target, 0, appId)
    next.customQuickLaunchApps = ids
    lacunaSettings.save(next)
  }

  function renameCustomQuickLaunchApp(id, label) {
    var appId = String(id || "")
    if (appId === "" || !customQuickLaunchContains(appId)) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    var names = {}
    var source = next.customQuickLaunchNames || {}
    for (var key in source) names[key] = source[key]

    var trimmed = String(label || "").trim().slice(0, 48)
    if (trimmed === "") delete names[appId]
    else names[appId] = trimmed

    next.customQuickLaunchNames = names
    lacunaSettings.save(next)
  }

  function setPreferredApp(role, id) {
    if (!role) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.preferredApps[role] = String(id || "system").trim() || "system"
    lacunaSettings.save(next)
    panelController.closeFlyout("appPicker")
  }

  function openCustomQuickLaunchPicker() {
    if (!appCatalog.ready) appCatalog.reload()
    appPickerContent.resetSearch()
    appPickerMode = "customQuickLaunchApp"
    preferredAppPickerRole = ""
    panelController.openFlyout("appPicker")
    if (sidebarState.collapsed) sidebarState.expand()
    requestFlyoutFocus("appPicker")
  }

  function openPreferredAppPicker(role) {
    if (!appCatalog.ready) appCatalog.reload()
    appPickerContent.resetSearch()
    appPickerMode = "preferredApp"
    preferredAppPickerRole = role
    panelController.openFlyout("appPicker")
    if (sidebarState.collapsed) sidebarState.expand()
    requestFlyoutFocus("appPicker")
  }

  function toggleSettingsPanel() {
    panelController.toggleFlyout("settings")
    if (settingsPanelOpen) {
      if (!menuState.open) panelController.openMenu()
      requestFlyoutFocus("settings")
    }
  }

  function requestFlyoutFocus(id) {
    pendingFlyoutFocus = String(id || "")
    Qt.callLater(applyPendingFlyoutFocus)
  }

  function applyPendingFlyoutFocus() {
    if (pendingFlyoutFocus === "" || !panelController.flyoutInteractive) return
    if (pendingFlyoutFocus === "appPicker" && appPickerOpen) {
      appPickerContent.forceSearchFocus()
      pendingFlyoutFocus = ""
    } else if (pendingFlyoutFocus === "settings" && settingsPanelOpen) {
      settingsPanel.forceActiveFocus()
      pendingFlyoutFocus = ""
    }
  }

  function shellPluginEnabled(id) {
    var revision = pluginStateRevision
    var config = root.shellConfig
    var plugins = config && Array.isArray(config.plugins) ? config.plugins : []
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i] && plugins[i].id === id) return true
    }
    return false
  }

  function shellPluginSettings(id, defaults) {
    var revision = pluginStateRevision
    var merged = {}
    for (var key in defaults) merged[key] = defaults[key]

    var config = root.shellConfig
    var plugins = config && Array.isArray(config.plugins) ? config.plugins : []
    for (var i = 0; i < plugins.length; i++) {
      var entry = plugins[i]
      if (!entry || entry.id !== id) continue
      for (var entryKey in entry) {
        if (entryKey !== "id") merged[entryKey] = entry[entryKey]
      }
      break
    }

    return merged
  }

  function numberSetting(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) ? parsed : fallback
  }

  function boolSetting(value, fallback) {
    if (value === true || value === false) return value
    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallback
  }

  function validFrameMode(value) {
    var mode = String(value || "off").toLowerCase()
    if (mode === "sidebar" || mode === "fullframe") return mode
    return "off"
  }

  function setFrameMode(mode) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.mode = validFrameMode(mode)
    lacunaSettings.save(next)
  }

  function toggleFrameShadow() {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.shadow = !next.frame.shadow
    lacunaSettings.save(next)
  }

  function validClockAnchor(value) {
    var anchor = String(value || "bottom-right").toLowerCase()
    var valid = {
      "top-left": true,
      "top": true,
      "top-right": true,
      "left": true,
      "center": true,
      "right": true,
      "bottom-left": true,
      "bottom": true,
      "bottom-right": true
    }

    return valid[anchor] ? anchor : "bottom-right"
  }

  function clockAnchorHorizontal(anchor) {
    if (anchor.indexOf("left") !== -1) return "left"
    if (anchor.indexOf("right") !== -1) return "right"
    return "center"
  }

  function clockAnchorVertical(anchor) {
    if (anchor.indexOf("top") !== -1) return "top"
    if (anchor.indexOf("bottom") !== -1) return "bottom"
    return "center"
  }

  function clockAnchorFromParts(horizontal, vertical) {
    var h = String(horizontal || "center")
    var v = String(vertical || "center")

    if (h === "center" && v === "center") return "center"
    if (h === "center") return v
    if (v === "center") return h
    return v + "-" + h
  }

  function setShellPluginEnabled(id, enabled) {
    if (pluginRegistry && typeof pluginRegistry.setEnabled === "function") {
      pluginRegistry.setEnabled(id, enabled)
      pluginStateRevision++
      return
    }

    commands.run(shellIpcCommand("shell", "setPluginEnabled", [id, enabled ? "true" : "false"]))
    pluginStateRevision++
  }

  function setDesktopClockSettings(patch) {
    var next = {
      anchor: root.desktopClockAnchor,
      offsetX: root.desktopClockOffsetX,
      offsetY: root.desktopClockOffsetY,
      scale: root.desktopClockScale,
      use12Hour: root.desktopClockUse12Hour
    }

    for (var key in patch) next[key] = patch[key]

    if (!root.desktopClockEnabled && pluginRegistry && typeof pluginRegistry.setEnabled === "function") {
      pluginRegistry.setEnabled("omarchy.lacuna-desktop-clock", true)
    }

    if (shell && typeof shell.updateEntryInline === "function") {
      shell.updateEntryInline("omarchy.lacuna-desktop-clock", next)
      pluginStateRevision++
      return
    }

    commands.run("notify-send 'Lacuna' 'Clock settings require the Omarchy shell plugin registry'")
  }

  function setDesktopClockAnchorAxis(axis, value) {
    var horizontal = clockAnchorHorizontal(root.desktopClockAnchor)
    var vertical = clockAnchorVertical(root.desktopClockAnchor)

    if (axis === "x") horizontal = value
    else vertical = value

    setDesktopClockSettings({ anchor: clockAnchorFromParts(horizontal, vertical) })
  }

  function nudgeDesktopClock(dx, dy) {
    setDesktopClockSettings({
      offsetX: root.desktopClockOffsetX + dx,
      offsetY: root.desktopClockOffsetY + dy
    })
  }

  function scaleDesktopClock(delta) {
    var nextScale = Math.max(0.5, Math.min(2, Math.round((root.desktopClockScale + delta) * 100) / 100))
    setDesktopClockSettings({ scale: nextScale })
  }

  function resetDesktopClockPosition() {
    setDesktopClockSettings({
      anchor: "bottom-right",
      offsetX: 0,
      offsetY: 0,
      scale: 1
    })
  }

  function activate(entry) {
    if (!entry || entry.kind === "header") return

    if (entry.action === "toggle-sidebar-mode") {
      sidebarState.toggle()
      return
    }

    if (entry.action === "toggle-sidebar-rail") {
      sidebarState.toggleCollapsed()
      return
    }

    if (entry.action === "toggle-corner-pieces") {
      sidebarState.toggleCornerPieces()
      return
    }

    if (entry.action === "toggle-bar-density") {
      compactState.toggle()
      return
    }

    if (entry.action === "toggle-lacuna-density") {
      compactState.toggle()
      return
    }

    if (entry.action.indexOf("set-bar-size-mode-") === 0) {
      barSizeModeService.setMode(entry.action.substring("set-bar-size-mode-".length))
      return
    }

    if (entry.action.indexOf("set-frame-mode-") === 0) {
      setFrameMode(entry.action.substring("set-frame-mode-".length))
      return
    }

    if (entry.action === "toggle-frame-shadow") {
      toggleFrameShadow()
      return
    }

    if (entry.action === "open-custom-quick-launch-picker") {
      openCustomQuickLaunchPicker()
      return
    }

    if (entry.action === "add-custom-quick-launch-app") {
      addCustomQuickLaunchApp(entry.appId)
      return
    }

    if (entry.action === "toggle-color-profile") {
      var next = lacunaSettings.normalize(lacunaSettings.data)
      next.colorProfile = next.colorProfile === "colorful" ? "semantic" : "colorful"
      lacunaSettings.save(next)
      return
    }

    if (entry.action === "toggle-desktop-clock") {
      setShellPluginEnabled("omarchy.lacuna-desktop-clock", !desktopClockEnabled)
      return
    }

    if (entry.action === "toggle-clock-12-hour") {
      setDesktopClockSettings({ use12Hour: !root.desktopClockUse12Hour })
      return
    }

    if (entry.action.indexOf("set-clock-anchor-x-") === 0) {
      setDesktopClockAnchorAxis("x", entry.action.substring("set-clock-anchor-x-".length))
      return
    }

    if (entry.action.indexOf("set-clock-anchor-y-") === 0) {
      setDesktopClockAnchorAxis("y", entry.action.substring("set-clock-anchor-y-".length))
      return
    }

    if (entry.action === "nudge-clock-left") {
      nudgeDesktopClock(-24, 0)
      return
    }

    if (entry.action === "scale-clock-down") {
      scaleDesktopClock(-0.1)
      return
    }

    if (entry.action === "scale-clock-up") {
      scaleDesktopClock(0.1)
      return
    }

    if (entry.action === "nudge-clock-right") {
      nudgeDesktopClock(24, 0)
      return
    }

    if (entry.action === "nudge-clock-up") {
      nudgeDesktopClock(0, -24)
      return
    }

    if (entry.action === "nudge-clock-down") {
      nudgeDesktopClock(0, 24)
      return
    }

    if (entry.action === "reset-clock-position") {
      resetDesktopClockPosition()
      return
    }

    if (entry.action === "cycle-design-style") {
      var nextStyleSettings = lacunaSettings.normalize(lacunaSettings.data)
      nextStyleSettings.designStyle = lacunaSettings.nextDesignStyle(nextStyleSettings.designStyle)
      lacunaSettings.save(nextStyleSettings)
      return
    }

    if (entry.action.indexOf("set-design-style-") === 0) {
      setDesignStyle(entry.action.substring("set-design-style-".length))
      return
    }

    if (entry.action.indexOf("choose-preferred-app-") === 0) {
      openPreferredAppPicker(entry.action.substring("choose-preferred-app-".length))
      return
    }

    if (entry.action === "reload-apps") {
      appCatalog.reload()
      return
    }

    if (entry.action === "open-screenrecord-menu") {
      panelController.closeMenu()
      commands.run("omarchy-capture-screenrecording --stop-recording || "
        + shellIpcCommand("menu", "toggle", ["trigger.capture.screenrecord"]))
      return
    }

    if (entry.view) {
      if (sidebarState.collapsed) sidebarState.expand()
      panelController.closeActiveFlyout()
      menuState.push(entry.view)
      return
    }

    if (entry.command) {
      panelController.closeActiveFlyout()
      commands.run(entry.command)
    }
  }

  Component.onCompleted: versionFile.reload()

  LacunaMenuState {
    id: localMenuState
  }

  LacunaSettings {
    id: lacunaSettings
  }

  CompactState {
    id: localCompactState
    settingsService: lacunaSettings
  }

  SidebarState {
    id: localSidebarState
    settingsService: lacunaSettings
  }

  BarSizeMode {
    id: barSizeModeService
    settingsService: lacunaSettings
    commandRunner: commands
    themeName: menuTheme.themeName
    omarchyPath: root.resolvedOmarchyPath()
  }

  AppCatalog {
    id: appCatalog
    lacunaPath: root.lacunaPath
  }

  Theme {
    id: menuTheme
  }

  DesignTokens {
    id: designTokens
    designStyle: root.designStyle
    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }

  DesignTokens {
    id: railDesignTokens
    designStyle: root.designStyle
    compact: root.railCompact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }

  FileView {
    id: versionFile

    path: root.lacunaPath + "/VERSION"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var raw = text().trim()
      root.version = raw === "" ? "" : "v" + raw.replace(/^v/, "")
    }
    onFileChanged: reload()
  }

  MenuRegistry {
    id: registry
    lacunaPath: root.lacunaPath
    sidebarExclusive: sidebarState.exclusive
    sidebarCollapsed: sidebarState.collapsed
    sidebarCornerPieces: sidebarState.cornerPieces
    compact: root.compact
    barSizeMode: barSizeModeService.barSizeMode
    designStyle: root.designStyle
    colorProfile: lacunaSettings.data && lacunaSettings.data.colorProfile ? lacunaSettings.data.colorProfile : "semantic"
    frameMode: root.frameMode
    frameShadow: root.frameShadow
    desktopClockEnabled: root.desktopClockEnabled
    desktopClockAnchor: root.desktopClockAnchor
    desktopClockOffsetX: root.desktopClockOffsetX
    desktopClockOffsetY: root.desktopClockOffsetY
    desktopClockScale: root.desktopClockScale
    desktopClockUse12Hour: root.desktopClockUse12Hour
    appCatalog: appCatalog
    customQuickLaunchApps: lacunaSettings.data && lacunaSettings.data.customQuickLaunchApps ? lacunaSettings.data.customQuickLaunchApps : []
    customQuickLaunchNames: lacunaSettings.data && lacunaSettings.data.customQuickLaunchNames ? lacunaSettings.data.customQuickLaunchNames : ({})
    preferredApps: lacunaSettings.data && lacunaSettings.data.preferredApps ? lacunaSettings.data.preferredApps : ({})
  }

  PanelController {
    id: panelController
    menuState: root.menuState
    onFlyoutOpenChanged: {
      if (!flyoutOpen) root.pendingFlyoutFocus = ""
      else root.applyPendingFlyoutFocus()
    }
    onFlyoutInteractiveChanged: root.applyPendingFlyoutFocus()
    onActiveFlyoutChanged: root.applyPendingFlyoutFocus()
    onHostHideRequested: {
      if (root.shell && root.shell.hide) root.shell.hide(root.pluginId)
    }
  }

  CommandRunner {
    id: commands
  }

  LacunaPanelWindow {
    id: menuWindow

    targetScreen: root.sidebarScreen
    menuOpen: root.menuState.open
    panelVisible: root.panelVisible
    flyoutOpen: root.flyoutOpen
    flyoutInteractive: root.flyoutInteractive
    exclusive: sidebarState.exclusive
    panelWidth: root.panelWidth
    surfaceRightInset: root.surfaceRightInset
    flyoutLaneWidth: root.flyoutLaneWidth
    visualWidth: root.frameOverlayWidth
    anchorRight: root.panelOnRight
    sidebarMaskX: panelHost.sidebarMaskX
    sidebarMaskY: panelHost.sidebarMaskY
    sidebarMaskWidth: panelHost.sidebarMaskWidth
    sidebarMaskHeight: panelHost.sidebarMaskHeight
    connectorMaskX: panelHost.connectorMaskX
    connectorMaskY: panelHost.connectorMaskY
    connectorMaskWidth: panelHost.connectorMaskWidth
    connectorMaskHeight: panelHost.connectorMaskHeight
    flyoutMaskX: panelHost.flyoutMaskX
    flyoutMaskY: panelHost.flyoutMaskY
    flyoutMaskWidth: panelHost.flyoutMaskWidth
    flyoutMaskHeight: panelHost.flyoutMaskHeight
    onFocusGrabCleared: root.closeFlyouts()

    LacunaPanelHost {
      id: panelHost

      panelWidth: root.panelWidth
      surfaceRightInset: root.surfaceRightInset
      surfaceX: surface.x + surface.surfaceX
      sidebarHeight: menuWindow.height
      anchorRight: root.panelOnRight
      connectorWidth: root.settingsConnectorWidth
      connectorRenderable: panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0
      flyoutY: root.activeFlyoutY
      flyoutWidth: Math.max(0, root.activeFlyoutWidth)
      flyoutHeight: Math.max(0, root.activeFlyoutHeight)
      flyoutProgress: panelController.flyoutProgress
      flyoutRenderable: panelController.flyoutRenderable
    }

    LacunaFrameOverlay {
      id: frameOverlay

      anchors.fill: parent
      mode: root.frameMode
      shadowEnabled: root.frameShadow && root.frameMode !== "off"
      barPosition: root.barPosition
      barSize: root.barControlSize
      barBottomY: root.barBottomY
      frameWidth: root.sidebarScreen ? root.sidebarScreen.width : menuWindow.width
      frameThickness: root.frameThickness
      frameRadius: root.frameRadius
      progress: panelController.menuProgress
      frameColor: root.panelColor
      shadowOffsetX: root.frameShadowOffsetX
      shadowOffsetY: root.frameShadowOffsetY
      sidebarX: panelHost.sidebarMaskX
      sidebarY: panelHost.sidebarMaskY
      sidebarWidth: root.panelWidth
      sidebarHeight: panelHost.sidebarMaskHeight
      sidebarCornerWidth: root.surfaceRightInset
      sidebarCornerVisible: root.effectiveCornerPieces && root.surfaceRightInset > 0
      leftEdgeOccupied: !root.panelOnRight
      rightEdgeOccupied: root.panelOnRight
      connectorX: panelHost.connectorX
      connectorY: panelHost.connectorY
      connectorWidth: panelHost.effectiveConnectorWidth
      connectorHeight: panelHost.effectiveFlyoutHeight + panelHost.effectiveConnectorWidth * 2
      connectorVisible: panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0
      flyoutX: panelHost.flyoutMaskX
      flyoutY: panelHost.flyoutMaskY
      flyoutWidth: panelHost.flyoutMaskWidth
      flyoutHeight: panelHost.flyoutMaskHeight
      flyoutVisible: panelController.flyoutRenderable
    }

    MenuSurface {
      id: surface

      anchors.top: parent.top
      anchors.bottom: parent.bottom
      x: panelHost.sidebarX
      panelWidth: root.panelWidth
      open: root.menuState.open
      progress: panelController.menuProgress
      barHeight: root.barHeight
      barBottomY: root.barBottomY
      joinRadius: root.joinRadius
      connectorOverlap: root.connectorOverlap
      bodyRightInset: root.surfaceRightInset
      cornerPieces: root.effectiveCornerPieces
      openFromRight: root.panelOnRight
      panelColor: root.panelColor
      foreground: root.foreground
      designTokens: designTokens

      MenuContent {
        visible: !sidebarState.collapsed
        anchors.fill: parent
        anchors.leftMargin: designTokens.contentInset
        anchors.rightMargin: designTokens.contentInset
        anchors.topMargin: root.barBottomY + designTokens.topInset
        anchors.bottomMargin: designTokens.bottomInset
        compact: root.compact
        designTokens: designTokens
        open: root.menuState.open
        menuState: root.menuState
        registry: registry
        version: root.version
        themeTitle: menuTheme.themeTitle
        foreground: root.foreground
        background: root.background
        accent: root.accent
        shellAccent: root.shellAccent
        sessionAccent: root.sessionAccent
        dangerAccent: root.dangerAccent
        navAccent: root.navAccent
        muted: root.muted
        iconRailWidth: root.barControlSize
        onActivated: function(entry) {
          root.activate(entry)
        }
        onQuickLaunchMoveRequested: function(appId, targetIndex) {
          root.moveCustomQuickLaunchApp(appId, targetIndex)
        }
        onQuickLaunchRenameRequested: function(appId, label) {
          root.renameCustomQuickLaunchApp(appId, label)
        }
        onSettingsRequested: root.toggleSettingsPanel()
        onCollapseRequested: sidebarState.toggleCollapsed()
      }

      MenuRail {
        visible: sidebarState.collapsed
        anchors.top: parent.top
        anchors.topMargin: root.barBottomY + (root.railCompact ? 6 : 10)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: designTokens.bottomInset
        anchors.left: parent.left
        anchors.leftMargin: root.railLeftInset
        compact: root.railCompact
        designTokens: railDesignTokens
        open: root.menuState.open
        menuState: root.menuState
        registry: registry
        foreground: root.foreground
        panelWindow: menuWindow
        panelColor: root.panelColor
        accent: root.accent
        shellAccent: root.shellAccent
        sessionAccent: root.sessionAccent
        dangerAccent: root.dangerAccent
        navAccent: root.navAccent
        muted: root.muted
        railWidth: root.railButtonWidth
        onExpandRequested: sidebarState.toggleCollapsed()
        onCompactToggleRequested: compactState.toggle()
        onActivated: function(entry) {
          root.activate(entry)
        }
        onSettingsRequested: root.toggleSettingsPanel()
      }
    }

    LacunaPanelConnector {
      id: flyoutConnector

      open: root.flyoutOpen
      renderable: panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0
      progress: Math.min(panelController.menuProgress, panelController.flyoutProgress)
      x: panelHost.connectorX
      y: panelHost.connectorY
      connectorWidth: panelHost.effectiveConnectorWidth
      contentHeight: panelHost.effectiveFlyoutHeight
      panelColor: root.panelColor
    }

    LacunaAttachedFlyout {
      id: attachedFlyout

      open: root.flyoutOpen
      renderable: panelController.flyoutRenderable
      interactive: root.flyoutOpen && root.flyoutInteractive
      progress: panelController.flyoutRenderable ? panelController.flyoutProgress : 0
      contentProgress: panelController.contentProgress
      openX: panelHost.flyoutX
      openY: panelHost.effectiveFlyoutY
      openToLeft: root.panelOnRight
      panelWidth: panelHost.effectiveFlyoutWidth
      panelHeight: panelHost.effectiveFlyoutHeight
      panelRadius: Math.max(designTokens.radius, root.compact ? 10 : 14)
      panelColor: root.panelColor
      foreground: root.foreground
      designTokens: designTokens

      SettingsWindow {
        id: settingsPanel

        anchors.fill: parent
        visible: root.renderSettingsContent
        enabled: root.settingsPanelOpen
        opacity: root.settingsPanelOpen ? 1 : 0
        open: root.settingsPanelOpen
        compact: root.compact
        drawBackground: false
        designTokens: designTokens
        registry: registry
        version: root.version
        themeTitle: menuTheme.themeTitle
        foreground: root.foreground
        background: root.background
        accent: root.accent
        shellAccent: root.shellAccent
        sessionAccent: root.sessionAccent
        dangerAccent: root.dangerAccent
        navAccent: root.navAccent
        muted: root.muted
        onActivated: function(entry) {
          root.activate(entry)
        }
        onCloseRequested: panelController.closeFlyout("settings")
      }

      FlyoutAppPickerContent {
        id: appPickerContent

        anchors.fill: parent
        registry: registry
        appCatalog: appCatalog
        customQuickLaunchApps: lacunaSettings.data && lacunaSettings.data.customQuickLaunchApps ? lacunaSettings.data.customQuickLaunchApps : []
        preferredApps: lacunaSettings.data && lacunaSettings.data.preferredApps ? lacunaSettings.data.preferredApps : ({})
        compact: root.compact
        open: root.appPickerOpen
        contentVisible: root.renderAppPickerContent
        mode: root.appPickerMode
        preferredRole: root.preferredAppPickerRole
        designTokens: designTokens
        foreground: root.foreground
        background: root.background
        accent: root.accent
        muted: root.muted
        onCloseRequested: panelController.closeFlyout("appPicker")
        onSystemSelected: root.setPreferredApp(root.preferredAppPickerRole, "system")
        onAppSelected: function(appId) {
          if (root.appPickerMode === "preferredApp") root.setPreferredApp(root.preferredAppPickerRole, appId)
          else root.addCustomQuickLaunchApp(appId)
        }
      }
    }
  }
}
