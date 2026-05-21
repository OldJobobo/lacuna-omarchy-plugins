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
  property var barWidgetRegistry: null
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
  property real compactProgress: compact ? 1 : 0
  property bool forceCompactRail: false
  property bool railCompact: forceCompactRail ? true : compact
  property string designStyle: lacunaSettings.data && lacunaSettings.data.designStyle ? lacunaSettings.data.designStyle : "lacuna"
  readonly property string barPosition: currentBarPosition()
  readonly property bool topBar: barPosition === "top"
  readonly property bool bottomBar: barPosition === "bottom"
  readonly property bool leftBar: barPosition === "left"
  readonly property bool rightBar: barPosition === "right"
  readonly property bool hostBarHidden: shell && shell.bar && shell.bar.barHidden === true
  readonly property bool lacunaEnabled: !hostBarHidden
  // Lacuna is its own left sidebar. The Omarchy bar position only affects
  // offsets and sizing, not which edge Lacuna owns.
  readonly property bool panelOnRight: false
  readonly property bool sidebarSurfaceVisible: lacunaEnabled && panelController.menuRenderable
  readonly property bool effectiveCornerPieces: sidebarSurfaceVisible && sidebarState.cornerPieces && !panelOnRight
  property int fullPanelWidth: Math.round(sizeMix(310, 270))
  property real barControlSize: currentBarSize()
  property int railButtonWidth: Math.round(forceCompactRail ? 24 : sizeMix(barControlSize, 24))
  property int railLeftInset: railDesignTokens.railLeftInset
  property int railRightInset: railDesignTokens.railRightInset
  property int railPanelWidth: railButtonWidth + railLeftInset + railRightInset
  property int panelWidth: sidebarSurfaceVisible ? (sidebarState.collapsed ? railPanelWidth : fullPanelWidth) : 0
  property int defaultTopBarHeight: 26
  property int barHeight: topBarHeight()
  property int lacunaJoinRadius: Math.max(frameThickness, frameRadius)
  property int joinRadius: effectiveCornerPieces ? lacunaJoinRadius : 0
  property int connectorOverlap: effectiveCornerPieces ? Math.round(lacunaJoinRadius * 1.85) : 0
  property int railTopGap: Math.round(sizeMix(10, 6))
  property int bodyRightInset: effectiveCornerPieces ? joinRadius : 0
  property int surfaceRightInset: bodyRightInset
  property int settingsConnectorWidth: effectiveCornerPieces ? joinRadius : 0
  property int barEdgeCasterSize: 3
  property int frameReservePadding: 4
  property int sidebarReserveExtra: 6
  property int flyoutLaneWidth: lacunaEnabled && panelController.menuRenderable ? maxFlyoutLaneWidth : 0
  // In exclusive mode the compositor already places this window below the top
  // bar, so the bar edge is local y=0. In overlay mode the window starts at
  // screen top and the bar edge is the live bar height.
  property int barBottomY: sidebarState.exclusive ? 0 : barHeight
  property bool panelVisible: panelController.panelVisible
  readonly property bool settingsPanelOpen: panelController.isFlyoutOpen("settings")
  readonly property bool settingsPanelVisible: panelController.isFlyoutVisible("settings")
  property int settingsPanelWidth: Math.round(sizeMix(400, 360))
  readonly property bool shellSettingsPanelOpen: panelController.isFlyoutOpen("shellSettings")
  readonly property bool shellSettingsPanelVisible: panelController.isFlyoutVisible("shellSettings")
  property int shellSettingsPanelWidth: Math.round(sizeMix(440, 390))
  readonly property bool appPickerOpen: panelController.isFlyoutOpen("appPicker")
  readonly property bool appPickerVisible: panelController.isFlyoutVisible("appPicker")
  readonly property bool flyoutOpen: panelController.flyoutOpen
  readonly property bool flyoutInteractive: panelController.flyoutInteractive
  property string appPickerMode: "customQuickLaunchApp"
  property string preferredAppPickerRole: ""
  property int appPickerWidth: Math.round(sizeMix(300, 260))
  readonly property int maxFlyoutLaneWidth: Math.max(settingsPanelWidth, shellSettingsPanelWidth, appPickerWidth)
  readonly property string visibleFlyout: panelController.visibleFlyout
  readonly property string outgoingFlyout: panelController.outgoingFlyout
  readonly property bool activeFlyoutSettings: visibleFlyout === "settings"
  readonly property bool activeFlyoutShellSettings: visibleFlyout === "shellSettings"
  readonly property bool activeFlyoutAppPicker: visibleFlyout === "appPicker"
  readonly property bool renderSettingsContent: settingsPanelVisible || outgoingFlyout === "settings"
  readonly property bool renderShellSettingsContent: shellSettingsPanelVisible || outgoingFlyout === "shellSettings"
  readonly property bool renderAppPickerContent: appPickerVisible || outgoingFlyout === "appPicker"
  readonly property int activeFlyoutWidth: activeFlyoutSettings ? settingsPanelWidth : activeFlyoutShellSettings ? shellSettingsPanelWidth : activeFlyoutAppPicker ? appPickerWidth : 0
  readonly property int activeFlyoutHeight: activeFlyoutSettings ? settingsFlyoutHeight() : activeFlyoutShellSettings ? shellSettingsFlyoutHeight() : activeFlyoutAppPicker ? appPickerHeightFor(activeFlyoutY) : 0
  readonly property int activeFlyoutY: activeFlyoutSettings ? settingsFlyoutY(settingsFlyoutHeight()) : activeFlyoutShellSettings ? shellSettingsFlyoutY(shellSettingsFlyoutHeight()) : activeFlyoutAppPicker ? appPickerFlyoutY() : 0
  readonly property int frameOverlayWidth: !lacunaEnabled || frameMode === "off" ? 0 : ((sidebarScreen ? sidebarScreen.width : 0) + 100)
  readonly property bool frameReserveActive: lacunaEnabled && sidebarState.exclusive && (panelController.menuRenderable || frameMode === "fullframe") && frameMode !== "off"
  readonly property bool sidebarReserveActive: lacunaEnabled && sidebarState.exclusive && panelController.menuRenderable && sidebarSurfaceVisible
  readonly property int reservePadding: lacunaEnabled && frameMode !== "off" ? frameReservePadding : 0
  readonly property int sidebarReserveSize: sidebarReserveActive ? panelWidth + reservePadding + sidebarReserveExtra : 0
  readonly property int visualTopInset: lacunaEnabled && sidebarState.exclusive && root.topBar ? root.barHeight : 0
  readonly property int visualBottomInset: lacunaEnabled && sidebarState.exclusive && root.bottomBar ? root.barHeight : 0
  readonly property int visualLeftInset: lacunaEnabled && sidebarState.exclusive && root.leftBar ? root.barControlSize : 0
  readonly property int visualRightInset: lacunaEnabled && sidebarState.exclusive && root.rightBar ? root.barControlSize : 0
  readonly property int frameShadowRightReserve: frameShadow ? Math.max(0, frameShadowOffsetX) : 0
  readonly property int frameReserveTop: frameReserveActive && frameMode === "fullframe" && !root.topBar ? frameThickness + reservePadding : 0
  readonly property int frameReserveBottom: frameReserveActive && frameMode === "fullframe" && !root.bottomBar ? frameThickness + reservePadding : 0
  readonly property int frameReserveLeft: frameReserveActive && frameMode === "fullframe" && !root.leftBar && (root.panelOnRight || !root.sidebarSurfaceVisible) ? frameThickness + reservePadding : 0
  readonly property int frameReserveRight: frameReserveActive && frameMode === "fullframe" && !root.panelOnRight && !root.rightBar ? frameThickness + frameShadowRightReserve + reservePadding : 0
  readonly property int topBarShadowReserve: frameReserveActive && root.frameShadow && root.topBar ? root.barEdgeCasterSize + reservePadding : 0
  readonly property real frameOverlayProgress: !lacunaEnabled ? 0 : frameMode === "fullframe" ? 1 : panelController.menuProgress
  property string pendingFlyoutFocus: ""
  property int pluginStateRevision: 0
  readonly property var shellConfig: shell && shell.shellConfig ? shell.shellConfig : ({})
  readonly property var shellBarConfig: shellConfig && shellConfig.bar ? shellConfig.bar : ({})
  readonly property var shellIdleConfig: shellConfig && shellConfig.idle ? shellConfig.idle : ({})
  readonly property int shellIdleScreensaver: positiveInt(shellIdleConfig.screensaver, 150)
  readonly property int shellIdleLock: positiveInt(shellIdleConfig.lock, 300)
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
  readonly property var backgroundEffectsSettings: lacunaSettings.data && lacunaSettings.data.backgroundEffects ? lacunaSettings.data.backgroundEffects : ({})
  readonly property var frameSettings: lacunaSettings.data && lacunaSettings.data.frame ? lacunaSettings.data.frame : ({})
  readonly property string frameMode: validFrameMode(frameSettings.mode)
  readonly property bool frameShadow: boolSetting(frameSettings.shadow, false)
  readonly property int frameThickness: positiveInt(frameSettings.thickness, 8)
  readonly property int frameRadius: Math.max(0, positiveInt(frameSettings.radius, 14))
  readonly property int frameShadowOffsetX: numberSetting(frameSettings.shadowOffsetX, 2)
  readonly property int frameShadowOffsetY: numberSetting(frameSettings.shadowOffsetY, 3)
  readonly property var sidebarScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  Behavior on compactProgress {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Behavior on barControlSize {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  onLacunaEnabledChanged: {
    if (!lacunaEnabled) {
      pendingFlyoutFocus = ""
      panelController.closeMenu()
    }
  }

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

  function sizeMix(fullValue, compactValue) {
    return Number(fullValue) + (Number(compactValue) - Number(fullValue)) * compactProgress
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

  function shellSettingsFlyoutHeight() {
    var availableHeight = menuWindow.height - barBottomY - designTokens.topInset - designTokens.bottomInset
    return Math.max(300, Math.min(availableHeight, compact ? 480 : 560))
  }

  function shellSettingsFlyoutY(panelHeight) {
    var topLimit = barBottomY + designTokens.topInset
    var lift = compact ? 54 : 78
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
    if (!lacunaEnabled) return
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
    if (!lacunaEnabled) return

    if (appPickerOpen && appPickerMode === "customQuickLaunchApp") {
      pendingFlyoutFocus = ""
      panelController.closeFlyout("appPicker")
      return
    }

    if (!appCatalog.ready) appCatalog.reload()
    appPickerContent.resetSearch()
    appPickerMode = "customQuickLaunchApp"
    preferredAppPickerRole = ""
    panelController.openFlyout("appPicker")
    if (sidebarState.collapsed) sidebarState.expand()
    requestFlyoutFocus("appPicker")
  }

  function openPreferredAppPicker(role) {
    if (!lacunaEnabled) return

    if (!appCatalog.ready) appCatalog.reload()
    appPickerContent.resetSearch()
    appPickerMode = "preferredApp"
    preferredAppPickerRole = role
    panelController.openFlyout("appPicker")
    if (sidebarState.collapsed) sidebarState.expand()
    requestFlyoutFocus("appPicker")
  }

  function toggleSettingsPanel() {
    if (!lacunaEnabled) return
    panelController.toggleFlyout("settings")
    if (settingsPanelOpen) {
      if (!menuState.open) panelController.openMenu()
      requestFlyoutFocus("settings")
    }
  }

  function openSettingsSection(sectionId) {
    if (!lacunaEnabled) return

    var nextSection = String(sectionId || "overview")
    if (settingsPanelOpen && settingsPanel.currentSection === nextSection) {
      panelController.closeFlyout("settings")
      return
    }

    settingsPanel.currentSection = nextSection
    panelController.openFlyout("settings")
    if (sidebarState.collapsed) sidebarState.expand()
    requestFlyoutFocus("settings")
  }

  function toggleShellSettingsPanel() {
    if (!lacunaEnabled) return
    panelController.toggleFlyout("shellSettings")
    if (shellSettingsPanelOpen) {
      if (!menuState.open) panelController.openMenu()
      requestFlyoutFocus("shellSettings")
    }
  }

  function requestFlyoutFocus(id) {
    if (!lacunaEnabled) return

    pendingFlyoutFocus = String(id || "")
    Qt.callLater(applyPendingFlyoutFocus)
  }

  function applyPendingFlyoutFocus() {
    if (!lacunaEnabled) {
      pendingFlyoutFocus = ""
      return
    }

    if (pendingFlyoutFocus === "" || !panelController.flyoutInteractive) return
    if (pendingFlyoutFocus === "appPicker" && appPickerOpen) {
      appPickerContent.forceSearchFocus()
      pendingFlyoutFocus = ""
    } else if (pendingFlyoutFocus === "settings" && settingsPanelOpen) {
      settingsPanel.forceActiveFocus()
      pendingFlyoutFocus = ""
    } else if (pendingFlyoutFocus === "shellSettings" && shellSettingsPanelOpen) {
      shellSettingsPanel.forceActiveFocus()
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
    if (mode === "fullframe" || mode === "on" || mode === "true" || mode === "1") return "fullframe"
    return "off"
  }

  function setFrameMode(mode) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.mode = validFrameMode(mode)
    lacunaSettings.save(next)
  }

  function setBackgroundEffectEnabled(effectId, enabled) {
    var id = String(effectId || "").trim()
    if (id === "") return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    if (!next.backgroundEffects || typeof next.backgroundEffects !== "object") next.backgroundEffects = lacunaSettings.normalizeBackgroundEffects({})
    if (!next.backgroundEffects.effects || typeof next.backgroundEffects.effects !== "object") next.backgroundEffects.effects = {}
    next.backgroundEffects.enabled = true
    next.backgroundEffects.effects[id] = { enabled: enabled === true }
    lacunaSettings.save(next)
  }

  function toggleFrameShadow() {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.shadow = !next.frame.shadow
    lacunaSettings.save(next)
  }

  function setSidebarDisplay(mode) {
    sidebarState.setDisplay(mode)
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

  function validShellBarPosition(value) {
    var position = String(value || "top").toLowerCase()
    if (position === "top" || position === "right" || position === "bottom" || position === "left") return position
    return "top"
  }

  function defaultShellBarConfig() {
    return {
      position: "top",
      transparent: false,
      centerAnchor: "calendar",
      layout: {
        left: [{ id: "Omarchy" }, { id: "Workspaces" }],
        center: [
          { id: "Clock", format: "dddd HH:mm", formatAlt: "dd MMMM 'W'ww yyyy", verticalFormat: "HH\n\u2014\nmm" },
          { id: "Weather" },
          { id: "Indicators", items: ["Dnd", "NightLight", "StayAwake", "ScreenRecording", "Dictation"] },
          { id: "SystemUpdate" },
          { id: "NotificationCenter" }
        ],
        right: [
          { id: "Tray" },
          { id: "BluetoothPanel" },
          { id: "NetworkPanel" },
          { id: "AudioPanel" },
          { id: "MonitorPanel" },
          { id: "PowerPanel" }
        ]
      }
    }
  }

  function ensureShellBarShape(config) {
    if (!config.bar || typeof config.bar !== "object") config.bar = defaultShellBarConfig()
    if (!config.bar.layout || typeof config.bar.layout !== "object") config.bar.layout = { left: [], center: [], right: [] }
    if (!Array.isArray(config.bar.layout.left)) config.bar.layout.left = []
    if (!Array.isArray(config.bar.layout.center)) config.bar.layout.center = []
    if (!Array.isArray(config.bar.layout.right)) config.bar.layout.right = []
    return config.bar
  }

  function mutateOmarchyShellConfig(mutator) {
    if (shell && typeof shell.mutateShellConfig === "function") {
      shell.mutateShellConfig(function(config) {
        ensureShellBarShape(config)
        mutator(config)
      })
      pluginStateRevision++
      return true
    }

    commands.run("notify-send 'Lacuna' 'Omarchy shell settings require the live shell config mutator'")
    return false
  }

  function setShellBarPosition(position) {
    mutateOmarchyShellConfig(function(config) {
      ensureShellBarShape(config).position = validShellBarPosition(position)
    })
  }

  function toggleShellBarTransparent() {
    mutateOmarchyShellConfig(function(config) {
      var bar = ensureShellBarShape(config)
      bar.transparent = !(bar.transparent === true)
    })
  }

  function setShellBarCenterAnchor(anchor) {
    mutateOmarchyShellConfig(function(config) {
      ensureShellBarShape(config).centerAnchor = anchor === "none" ? "" : String(anchor || "")
    })
  }

  function resetShellBarDefaults() {
    mutateOmarchyShellConfig(function(config) {
      config.bar = defaultShellBarConfig()
    })
  }

  function setShellIdleTimeout(kind, seconds) {
    var value = positiveInt(seconds, kind === "lock" ? 300 : 150)
    mutateOmarchyShellConfig(function(config) {
      if (!config.idle || typeof config.idle !== "object") config.idle = {}
      config.idle[kind] = value
    })
  }

  function mutateShellBarSection(section, mutator) {
    var sectionId = String(section || "")
    if (sectionId !== "left" && sectionId !== "center" && sectionId !== "right") return

    mutateOmarchyShellConfig(function(config) {
      var bar = ensureShellBarShape(config)
      var list = bar.layout[sectionId].slice()
      mutator(list, bar)
      bar.layout[sectionId] = list
      if (sectionId === "center" && bar.centerAnchor) {
        var anchorFound = false
        for (var i = 0; i < list.length; i++) {
          if (list[i] && String(list[i].id || "") === String(bar.centerAnchor)) {
            anchorFound = true
            break
          }
        }
        if (!anchorFound) bar.centerAnchor = ""
      }
    })
  }

  function moveShellBarWidget(section, index, direction) {
    mutateShellBarSection(section, function(list) {
      var from = Math.round(Number(index) || 0)
      var to = direction === "up" ? from - 1 : from + 1
      if (from < 0 || from >= list.length || to < 0 || to >= list.length) return
      var entry = list[from]
      list.splice(from, 1)
      list.splice(to, 0, entry)
    })
  }

  function removeShellBarWidget(section, index) {
    mutateShellBarSection(section, function(list) {
      var at = Math.round(Number(index) || 0)
      if (at < 0 || at >= list.length) return
      list.splice(at, 1)
    })
  }

  function addShellBarWidget(section, id) {
    var widgetId = String(id || "").trim()
    if (widgetId === "") return
    mutateShellBarSection(section, function(list) {
      list.push({ id: widgetId })
    })
  }

  function runOmarchyCommand(command) {
    if (!command) return
    commands.run(command)
  }

  function activate(entry) {
    if (!entry || entry.kind === "header") return
    if (!lacunaEnabled) return

    if (entry.action === "toggle-sidebar-mode") {
      sidebarState.toggle()
      return
    }

    if (entry.action === "toggle-sidebar-rail") {
      sidebarState.toggleCollapsed()
      return
    }

    if (entry.action.indexOf("set-sidebar-display-") === 0) {
      setSidebarDisplay(entry.action.substring("set-sidebar-display-".length))
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

    if (entry.action.indexOf("set-shell-bar-position-") === 0) {
      setShellBarPosition(entry.action.substring("set-shell-bar-position-".length))
      return
    }

    if (entry.action.indexOf("set-default-terminal-") === 0) {
      runOmarchyCommand("omarchy default terminal " + commands.quote(entry.action.substring("set-default-terminal-".length)))
      return
    }

    if (entry.action.indexOf("set-default-browser-") === 0) {
      runOmarchyCommand("omarchy default browser " + commands.quote(entry.action.substring("set-default-browser-".length)))
      return
    }

    if (entry.action.indexOf("set-default-editor-") === 0) {
      runOmarchyCommand("omarchy default editor " + commands.quote(entry.action.substring("set-default-editor-".length)))
      return
    }

    if (entry.action === "toggle-window-gaps") {
      runOmarchyCommand("omarchy hyprland window gaps toggle")
      return
    }

    if (entry.action === "toggle-single-window-square") {
      runOmarchyCommand("omarchy hyprland window single square aspect toggle")
      return
    }

    if (entry.action === "toggle-omarchy-bar") {
      runOmarchyCommand("omarchy toggle bar")
      return
    }

    if (entry.action.indexOf("set-monitor-scaling-") === 0) {
      runOmarchyCommand("omarchy hyprland monitor scaling " + commands.quote(entry.action.substring("set-monitor-scaling-".length)))
      return
    }

    if (entry.action.indexOf("set-omarchy-font-") === 0) {
      runOmarchyCommand("omarchy font set " + commands.quote(entry.action.substring("set-omarchy-font-".length)))
      return
    }

    if (entry.action.indexOf("set-power-profile-") === 0) {
      runOmarchyCommand("powerprofilesctl set " + commands.quote(entry.action.substring("set-power-profile-".length)))
      return
    }

    if (entry.action === "toggle-nightlight") {
      runOmarchyCommand("omarchy toggle nightlight")
      return
    }

    if (entry.action === "toggle-idle") {
      runOmarchyCommand("omarchy toggle idle")
      return
    }

    if (entry.action === "toggle-screensaver") {
      runOmarchyCommand("omarchy toggle screensaver")
      return
    }

    if (entry.action === "toggle-notification-silencing") {
      runOmarchyCommand("omarchy toggle notification silencing")
      return
    }

    if (entry.action === "toggle-suspend") {
      runOmarchyCommand("omarchy toggle suspend")
      return
    }

    if (entry.action.indexOf("set-shell-idle-screensaver-") === 0) {
      setShellIdleTimeout("screensaver", entry.action.substring("set-shell-idle-screensaver-".length))
      return
    }

    if (entry.action.indexOf("set-shell-idle-lock-") === 0) {
      setShellIdleTimeout("lock", entry.action.substring("set-shell-idle-lock-".length))
      return
    }

    if (entry.action.indexOf("toggle-shell-plugin-") === 0) {
      var pluginId = entry.action.substring("toggle-shell-plugin-".length)
      setShellPluginEnabled(pluginId, !shellPluginEnabled(pluginId))
      return
    }

    if (entry.action === "toggle-shell-bar-transparent") {
      toggleShellBarTransparent()
      return
    }

    if (entry.action.indexOf("set-shell-bar-center-anchor-") === 0) {
      setShellBarCenterAnchor(entry.action.substring("set-shell-bar-center-anchor-".length))
      return
    }

    if (entry.action === "reset-shell-bar-defaults") {
      resetShellBarDefaults()
      return
    }

    if (entry.action.indexOf("move-shell-bar-widget-") === 0) {
      var moveParts = entry.action.substring("move-shell-bar-widget-".length).split("-")
      if (moveParts.length >= 3) moveShellBarWidget(moveParts[0], moveParts[1], moveParts[2])
      return
    }

    if (entry.action.indexOf("remove-shell-bar-widget-") === 0) {
      var removeParts = entry.action.substring("remove-shell-bar-widget-".length).split("-")
      if (removeParts.length >= 2) removeShellBarWidget(removeParts[0], removeParts[1])
      return
    }

    if (entry.action.indexOf("add-shell-bar-widget-") === 0) {
      var addPayload = entry.action.substring("add-shell-bar-widget-".length)
      var sectionEnd = addPayload.indexOf("-")
      if (sectionEnd > 0) addShellBarWidget(addPayload.substring(0, sectionEnd), addPayload.substring(sectionEnd + 1))
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

    if (entry.action.indexOf("toggle-background-effect-") === 0) {
      var effectId = entry.action.substring("toggle-background-effect-".length)
      setBackgroundEffectEnabled(effectId, !registry.backgroundEffectEnabled(effectId))
      return
    }

    if (entry.action.indexOf("open-settings-section-") === 0) {
      openSettingsSection(entry.action.substring("open-settings-section-".length))
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
    compactProgress: root.compactProgress
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }

  DesignTokens {
    id: railDesignTokens
    designStyle: root.designStyle
    compact: root.railCompact
    compactProgress: root.forceCompactRail ? 1 : root.compactProgress
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
    backgroundEffects: root.backgroundEffectsSettings
    shellBarConfig: root.shellBarConfig
    shellBarPosition: root.barPosition
    shellBarTransparent: root.shellBarConfig && root.shellBarConfig.transparent === true
    shellBarCenterAnchor: root.shellBarConfig && root.shellBarConfig.centerAnchor ? String(root.shellBarConfig.centerAnchor) : ""
    shellIdleScreensaver: root.shellIdleScreensaver
    shellIdleLock: root.shellIdleLock
    shellPlugins: root.shellConfig && Array.isArray(root.shellConfig.plugins) ? root.shellConfig.plugins : []
    barWidgetRegistry: root.barWidgetRegistry
    pluginRegistry: root.pluginRegistry
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
      if (root.frameMode === "fullframe") return
      if (root.shell && root.shell.hide) root.shell.hide(root.pluginId)
    }
  }

  CommandRunner {
    id: commands
  }

  OmarchyShellSettings {
    id: shellSettingsService
    lacunaPath: root.lacunaPath
    commandRunner: commands
    shell: root.shell
    pluginRegistry: root.pluginRegistry
    shellConfig: root.shellConfig
    onPluginStateChanged: root.pluginStateRevision++
  }

  LacunaPanelWindow {
    id: menuWindow

    targetScreen: root.sidebarScreen
    menuOpen: root.menuState.open
    panelVisible: root.lacunaEnabled && root.panelVisible
    keepMapped: root.lacunaEnabled && root.frameMode !== "off"
    flyoutOpen: root.lacunaEnabled && root.flyoutOpen
    flyoutInteractive: root.lacunaEnabled && root.flyoutInteractive
    exclusive: sidebarState.exclusive
    panelWidth: root.panelWidth
    surfaceRightInset: root.surfaceRightInset
    flyoutLaneWidth: root.flyoutLaneWidth
    visualWidth: root.frameOverlayWidth
    visualTopInset: root.visualTopInset
    visualBottomInset: root.visualBottomInset
    visualLeftInset: root.visualLeftInset
    visualRightInset: root.visualRightInset
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
      connectorRenderable: root.lacunaEnabled && root.sidebarSurfaceVisible && panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0
      flyoutY: root.activeFlyoutY
      flyoutWidth: Math.max(0, root.activeFlyoutWidth)
      flyoutHeight: Math.max(0, root.activeFlyoutHeight)
      flyoutProgress: panelController.flyoutProgress
      flyoutRenderable: root.lacunaEnabled && panelController.flyoutRenderable
    }

    LacunaFrameOverlay {
      id: frameOverlay

      anchors.fill: parent
      mode: root.lacunaEnabled ? root.frameMode : "off"
      shadowEnabled: root.lacunaEnabled && root.frameShadow && root.frameMode !== "off"
      barPosition: root.barPosition
      barSize: root.barControlSize
      barBottomY: root.barBottomY
      frameWidth: root.sidebarScreen ? root.sidebarScreen.width : menuWindow.width
      frameThickness: root.frameThickness
      frameRadius: root.frameRadius
      joinRadius: root.lacunaJoinRadius
      progress: root.frameOverlayProgress
      frameColor: root.panelColor
      shadowOffsetX: root.frameShadowOffsetX
      shadowOffsetY: root.frameShadowOffsetY
      sidebarX: panelHost.sidebarMaskX
      sidebarY: panelHost.sidebarMaskY
      sidebarWidth: root.sidebarSurfaceVisible ? root.panelWidth : 0
      sidebarHeight: panelHost.sidebarMaskHeight
      sidebarCornerWidth: root.surfaceRightInset
      sidebarCornerVisible: root.sidebarSurfaceVisible && root.effectiveCornerPieces && root.surfaceRightInset > 0
      leftEdgeOccupied: root.sidebarSurfaceVisible && !root.panelOnRight
      rightEdgeOccupied: root.sidebarSurfaceVisible && root.panelOnRight
      connectorX: panelHost.connectorX
      connectorY: panelHost.connectorY
      connectorWidth: panelHost.effectiveConnectorWidth
      connectorHeight: panelHost.effectiveFlyoutHeight + panelHost.effectiveConnectorWidth * 2
      connectorVisible: root.sidebarSurfaceVisible && panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0
      flyoutX: panelHost.flyoutMaskX
      flyoutY: panelHost.flyoutMaskY
      flyoutWidth: panelHost.flyoutMaskWidth
      flyoutHeight: panelHost.flyoutMaskHeight
      flyoutVisible: panelController.flyoutRenderable
    }

    MenuSurface {
      id: surface

      visible: root.sidebarSurfaceVisible
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
        visible: root.sidebarSurfaceVisible && !sidebarState.collapsed
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
        onShellSettingsRequested: root.toggleShellSettingsPanel()
        onCollapseRequested: sidebarState.toggleCollapsed()
      }

      MenuRail {
        visible: root.sidebarSurfaceVisible && sidebarState.collapsed
        anchors.top: parent.top
        anchors.topMargin: root.barBottomY + root.railTopGap
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
        onShellSettingsRequested: root.toggleShellSettingsPanel()
      }
    }

    LacunaPanelConnector {
      id: flyoutConnector

      open: root.flyoutOpen
      renderable: root.sidebarSurfaceVisible && panelController.flyoutRenderable && sidebarState.cornerPieces && root.settingsConnectorWidth > 0
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
      panelRadius: root.lacunaJoinRadius
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

      OmarchyShellSettingsWindow {
        id: shellSettingsPanel

        anchors.fill: parent
        visible: root.renderShellSettingsContent
        enabled: root.shellSettingsPanelOpen
        opacity: root.shellSettingsPanelOpen ? 1 : 0
        open: root.shellSettingsPanelOpen
        compact: root.compact
        drawBackground: false
        designTokens: designTokens
        registry: registry
        settingsService: shellSettingsService
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
        onCloseRequested: panelController.closeFlyout("shellSettings")
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

  LacunaFrameReserveWindow {
    targetScreen: root.sidebarScreen
    active: root.sidebarReserveSize > 0
    edge: root.panelOnRight ? "right" : "left"
    reserveSize: root.sidebarReserveSize
    layerNamespace: root.pluginId + "-sidebar-reserve"
  }

  LacunaFrameReserveWindow {
    targetScreen: root.sidebarScreen
    active: root.frameReserveTop > 0
    edge: "top"
    reserveSize: root.frameReserveTop
    layerNamespace: root.pluginId + "-frame-reserve"
  }

  LacunaFrameReserveWindow {
    targetScreen: root.sidebarScreen
    active: root.topBarShadowReserve > 0
    edge: "top"
    reserveSize: root.topBarShadowReserve
    layerNamespace: root.pluginId + "-topbar-shadow-reserve"
  }

  LacunaFrameReserveWindow {
    targetScreen: root.sidebarScreen
    active: root.frameReserveBottom > 0
    edge: "bottom"
    reserveSize: root.frameReserveBottom
    layerNamespace: root.pluginId + "-frame-reserve"
  }

  LacunaFrameReserveWindow {
    targetScreen: root.sidebarScreen
    active: root.frameReserveLeft > 0
    edge: "left"
    reserveSize: root.frameReserveLeft
    layerNamespace: root.pluginId + "-frame-reserve"
  }

  LacunaFrameReserveWindow {
    targetScreen: root.sidebarScreen
    active: root.frameReserveRight > 0
    edge: "right"
    reserveSize: root.frameReserveRight
    layerNamespace: root.pluginId + "-frame-reserve"
  }
}
