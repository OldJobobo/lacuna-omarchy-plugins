import Quickshell
import Quickshell.Hyprland
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
  property bool hostManaged: false
  property int hostBarSize: 0
  property string pluginId: manifest && manifest.id ? manifest.id : "lacuna.menu"
  property var menuState: localMenuState
  property bool initialSidebarDefaultApplied: false
  property string lacunaPath: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl(".."))
  property var sharedCompactState: null
  property var sharedSidebarState: null
  readonly property var lacunaSettings: resolveLacunaSettings()
  readonly property var compactState: sharedCompactState || localCompactState
  readonly property var sidebarState: sharedSidebarState || localSidebarState
  property color foreground: menuTheme.foreground
  property color background: menuTheme.background
  property color surfaceBackground: menuTheme.panelBackground
  property color panelColor: surfaceBackground
  property color accent: menuTheme.accent
  property color shellAccent: menuTheme.color("color6")
  property color sessionAccent: menuTheme.color("color11")
  property color dangerAccent: menuTheme.color("color9")
  property color navAccent: menuTheme.soft
  property color muted: menuTheme.muted
  property string version: ""
  property string bodyFontFamily: "JetBrains Mono"
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
  readonly property bool barOwnsLacunaFrame: hostManaged || (shell && shell.bar && shell.bar.lacunaFrameHost === true)
  readonly property bool lacunaEnabled: !hostBarHidden
  // Lacuna is its own left sidebar. The Omarchy bar position only affects
  // offsets and sizing, not which edge Lacuna owns.
  readonly property bool panelOnRight: false
  readonly property bool sidebarSurfaceVisible: lacunaEnabled && panelController.menuRenderable
  readonly property bool effectiveCornerPieces: sidebarSurfaceVisible && sidebarState.cornerPieces && !panelOnRight
  property int defaultTopBarHeight: 26
  property int barHeight: topBarHeight()
  property int fullPanelWidth: Math.round(sizeMix(310, 270))
  property real barControlSize: currentBarSize()
  property int railReferenceBarHeight: Math.max(1, root.topBar && root.barHeight > 0 ? root.barHeight : configBarHeight())
  property int railPanelWidth: Math.round(railReferenceBarHeight)
  property int railButtonWidth: railPanelWidth
  property int railLeftInset: 0
  property int railRightInset: 0
  property int panelWidth: sidebarSurfaceVisible ? (sidebarState.collapsed ? railPanelWidth : fullPanelWidth) : 0
  property int lacunaJoinRadius: Math.max(frameThickness, frameRadius)
  property int joinRadius: effectiveCornerPieces ? lacunaJoinRadius : 0
  property int connectorOverlap: effectiveCornerPieces ? Math.round(lacunaJoinRadius * 1.85) : 0
  property int railTopGap: Math.round(sizeMix(10, 6))
  property int bodyRightInset: effectiveCornerPieces ? joinRadius : 0
  property int surfaceRightInset: bodyRightInset
  property int settingsConnectorWidth: effectiveCornerPieces ? joinRadius : 0
  property int barEdgeCasterSize: frameThickness
  property int frameReservePadding: 4
  property int sidebarReserveExtra: 0
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
  property int shellSettingsPanelWidth: Math.round(sizeMix(520, 440))
  readonly property bool appPickerOpen: panelController.isFlyoutOpen("appPicker")
  readonly property bool appPickerVisible: panelController.isFlyoutVisible("appPicker")
  readonly property bool flyoutOpen: panelController.flyoutOpen
  readonly property bool flyoutInteractive: panelController.flyoutInteractive
  property string appPickerMode: "customQuickLaunchApp"
  property string preferredAppPickerRole: ""
  property string shellSettingsSection: "apps"
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
  readonly property int frameOverlayWidth: !lacunaEnabled || barOwnsLacunaFrame || frameMode === "off" ? 0 : ((sidebarScreen ? sidebarScreen.width : 0) + 100)
  readonly property bool frameReserveActive: !barOwnsLacunaFrame && lacunaEnabled && sidebarState.exclusive && (panelController.menuRenderable || frameMode === "fullframe") && frameMode !== "off"
  readonly property bool sidebarReserveActive: lacunaEnabled && sidebarState.exclusive && panelController.menuRenderable && sidebarSurfaceVisible
  readonly property bool frameReserveFlush: frameReserveMode === "flush" || hyprWindowGapsDisabled || (frameReserveMode === "auto" && fakeFullscreenWorkspaceActive())
  readonly property int reservePadding: lacunaEnabled && frameMode !== "off" && !frameReserveFlush ? frameReservePadding : 0
  readonly property int effectiveSidebarReserveExtra: frameReserveFlush ? 0 : sidebarReserveExtra
  readonly property bool externalLeftFrameReserveActive: frameMode === "fullframe" && !root.leftBar && !root.panelOnRight
  readonly property int barOwnedLeftFrameReserve: barOwnsLacunaFrame && externalLeftFrameReserveActive && !sidebarSurfaceVisible ? frameThickness : 0
  readonly property int sidebarReserveSize: sidebarReserveActive ? Math.max(0, panelWidth + effectiveSidebarReserveExtra - barOwnedLeftFrameReserve) : 0
  readonly property int visualTopInset: lacunaEnabled && sidebarState.exclusive && root.topBar ? root.barHeight : 0
  readonly property int visualBottomInset: lacunaEnabled && sidebarState.exclusive && root.bottomBar ? root.barHeight : 0
  readonly property int visualLeftInset: lacunaEnabled && sidebarState.exclusive && root.leftBar ? root.barControlSize : 0
  readonly property int visualRightInset: lacunaEnabled && sidebarState.exclusive && root.rightBar ? root.barControlSize : 0
  readonly property int frameShadowRightReserve: frameShadow ? Math.max(0, frameShadowOffsetX) : 0
  readonly property int frameReserveTop: frameReserveActive && frameMode === "fullframe" && !root.topBar ? frameThickness + reservePadding : 0
  readonly property int frameReserveBottom: frameReserveActive && frameMode === "fullframe" && !root.bottomBar ? frameThickness + reservePadding : 0
  readonly property int frameReserveLeft: frameReserveActive && frameMode === "fullframe" && !root.leftBar && (root.panelOnRight || !root.sidebarSurfaceVisible) ? frameThickness + reservePadding : 0
  readonly property int frameReserveRight: frameReserveActive && frameMode === "fullframe" && !root.panelOnRight && !root.rightBar ? frameThickness + reservePadding : 0
  readonly property int topBarShadowReserve: frameReserveActive && root.topBar ? reservePadding : 0
  readonly property real frameOverlayProgress: !lacunaEnabled ? 0 : frameMode === "fullframe" ? 1 : panelController.menuProgress
  property string pendingFlyoutFocus: ""
  property bool pendingSystemRestartConfirmation: false
  property int pluginStateRevision: 0
  property int hyprWorkspaceRevision: 0
  property double ignoreFlyoutFocusClearUntil: 0
  readonly property var shellConfig: shell && shell.shellConfig ? shell.shellConfig : ({})
  readonly property var shellBarConfig: shellConfig && shellConfig.bar ? shellConfig.bar : ({})
  readonly property var shellIdleConfig: shellConfig && shellConfig.idle ? shellConfig.idle : ({})
  readonly property int shellIdleScreensaver: positiveInt(shellIdleConfig.screensaver, 150)
  readonly property int shellIdleLock: positiveInt(shellIdleConfig.lock, 300)
  readonly property var desktopClockSettings: shellPluginSettings("lacuna.desktop-clock", {
    anchor: "bottom-right",
    offsetX: 0,
    offsetY: 0,
    scale: 1,
    use12Hour: false
  })
  readonly property bool desktopClockEnabled: shellPluginEnabled("lacuna.desktop-clock")
  readonly property string desktopClockAnchor: validClockAnchor(desktopClockSettings.anchor)
  readonly property int desktopClockOffsetX: numberSetting(desktopClockSettings.offsetX, 0)
  readonly property int desktopClockOffsetY: numberSetting(desktopClockSettings.offsetY, 0)
  readonly property real desktopClockScale: numberSetting(desktopClockSettings.scale, 1)
  readonly property bool desktopClockUse12Hour: boolSetting(desktopClockSettings.use12Hour, false)
  readonly property var backgroundEffectsSettings: lacunaSettings.data && lacunaSettings.data.backgroundEffects ? lacunaSettings.data.backgroundEffects : ({})
  readonly property var backgroundVignetteSettings: lacunaSettings.data && lacunaSettings.data.backgroundVignette ? lacunaSettings.data.backgroundVignette : ({})
  readonly property var shellSettingsSettings: lacunaSettings.data && lacunaSettings.data.shellSettings ? lacunaSettings.data.shellSettings : ({})
  readonly property string shellSettingsSurface: validShellSettingsSurface(shellSettingsSettings.surface)
  readonly property var shellSettingsService: resolveShellSettingsService()
  readonly property var shellHyprState: shellSettingsService && shellSettingsService.state && shellSettingsService.state.hypr ? shellSettingsService.state.hypr : ({})
  readonly property bool hyprWindowGapsDisabled: shellHyprState.windowGapsEnabled === false || (hyprGapValue(shellHyprState.gapsIn) === 0 && hyprGapValue(shellHyprState.gapsOut) === 0)
  readonly property var powerSettings: lacunaSettings.data && lacunaSettings.data.power ? lacunaSettings.data.power : ({})
  readonly property bool instantRestart: boolSetting(powerSettings.instantRestart, false)
  readonly property var frameSettings: lacunaSettings.data && lacunaSettings.data.frame ? lacunaSettings.data.frame : ({})
  readonly property string frameMode: validFrameMode(frameSettings.mode)
  readonly property string frameReserveMode: validFrameReserveMode(frameSettings.reserveMode)
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

  function resolveLacunaSettings() {
    if (root.shell && typeof root.shell.ensureService === "function") {
      var ensured = root.shell.ensureService("lacuna.state")
      if (ensured) return ensured
    }
    if (root.shell && typeof root.shell.serviceFor === "function") {
      var service = root.shell.serviceFor("lacuna.state")
      if (service) return service
    }
    return localLacunaSettings
  }

  function resolveShellSettingsService() {
    if (root.shell && typeof root.shell.ensureService === "function") {
      var ensured = root.shell.ensureService("lacuna.shell-settings")
      if (ensured) return ensured
    }
    if (root.shell && typeof root.shell.serviceFor === "function") {
      var service = root.shell.serviceFor("lacuna.shell-settings")
      if (service) return service
    }
    return localShellSettingsService
  }

  function applyInitialSidebarDefault() {
    if (root.initialSidebarDefaultApplied) return
    if (lacunaSettings && lacunaSettings.hasLoaded === false) return
    root.initialSidebarDefaultApplied = true
    Qt.callLater(root.applySidebarDefaultState)
  }

  function shellIpcCommand(target, method, args) {
    var path = resolvedOmarchyPath()
    var command = "OMARCHY_PATH=" + commands.quote(path) + " omarchy shell"
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

  function safeValue(value, fallback) {
    return value === undefined || value === null ? fallback : value
  }

  function configBarHeight() {
    var barConfig = shell && shell.barConfig ? shell.barConfig : null
    if (!barConfig || typeof barConfig !== "object") return defaultTopBarHeight
    return positiveInt(barConfig.height !== undefined ? barConfig.height : barConfig.size, defaultTopBarHeight)
  }

  function currentBarSize() {
    var liveBar = shell && shell.bar ? shell.bar : null
    var verticalFallback = (barPosition === "left" || barPosition === "right") ? 28 : configBarHeight()
    if (hostBarSize > 0) return positiveInt(hostBarSize, verticalFallback)
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
    if (hostBarSize > 0) return positiveInt(hostBarSize, configBarHeight())
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

  function shellSettingsFlyoutHeight() {
    var availableHeight = menuWindow.height - barBottomY - designTokens.topInset - designTokens.bottomInset
    return Math.max(360, Math.min(availableHeight, compact ? 560 : 660))
  }

  function shellSettingsFlyoutY(panelHeight) {
    return settingsFlyoutY(panelHeight)
  }

  function validShellSettingsSurface(value) {
    var surface = String(value || "").toLowerCase()
    if (surface === "window" || surface === "floating" || surface === "panel") return "window"
    return "flyout"
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
    if (Date.now() < ignoreFlyoutFocusClearUntil) return
    pendingFlyoutFocus = ""
    panelController.closeActiveFlyout()
  }

  function holdFlyoutAfterSettingsActivation() {
    ignoreFlyoutFocusClearUntil = Date.now() + 900
  }

  function applySidebarDefaultState() {
    if (!lacunaEnabled) return

    var mode = sidebarState.defaultMode || "off"
    pendingFlyoutFocus = ""
    panelController.closeActiveFlyout()
    if (menuState) {
      menuState.stack = ["main"]
      if (typeof menuState.save === "function") menuState.save()
    }

    if (mode === "rail") {
      sidebarState.setDisplay("rail")
      panelController.openMenu()
      return
    }

    if (mode === "full") {
      sidebarState.setDisplay("full")
      panelController.openMenu()
      return
    }

    sidebarState.setDisplay("full")
    panelController.closeMenu()
  }

  function viewToneAccent() {
    return root.accent
  }

  function setDesignStyle(style) {
    var nextStyleSettings = lacunaSettings.normalize(lacunaSettings.data)
    nextStyleSettings.designStyle = lacunaSettings.normalizeDesignStyle(style)
    lacunaSettings.save(nextStyleSettings)
  }

  function setControlsLayout(layout) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.controlsLayout = layout === "list" ? "list" : "grid"
    lacunaSettings.save(next)
  }

  function setShortcutsLayout(layout) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.shortcutsLayout = layout === "grid" ? "grid" : "list"
    lacunaSettings.save(next)
  }

  function setShellSettingsSurface(surface) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    if (!next.shellSettings || typeof next.shellSettings !== "object") next.shellSettings = {}
    next.shellSettings.surface = validShellSettingsSurface(surface)
    lacunaSettings.save(next)
  }

  function setDailyLaunchLayout(layout) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.dailyLaunchLayout = layout === "grid" ? "grid" : "list"
    lacunaSettings.save(next)
  }

  function setQuickLaunchLayout(layout) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.quickLaunchLayout = layout === "grid" ? "grid" : "list"
    lacunaSettings.save(next)
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
    lacunaSettings.save(next, true)
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
    lacunaSettings.save(next, true)
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
    lacunaSettings.save(next, true)
  }

  function removeCustomQuickLaunchApp(id) {
    var appId = String(id || "")
    if (appId === "" || !customQuickLaunchContains(appId)) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    var ids = []
    var sourceIds = next.customQuickLaunchApps || []
    for (var i = 0; i < sourceIds.length; i++) {
      if (String(sourceIds[i]) !== appId) ids.push(String(sourceIds[i]))
    }

    var names = {}
    var sourceNames = next.customQuickLaunchNames || {}
    for (var key in sourceNames) {
      if (String(key) !== appId) names[key] = sourceNames[key]
    }

    next.customQuickLaunchApps = ids
    next.customQuickLaunchNames = names
    lacunaSettings.save(next, true)
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

  function openShellSettingsPanel(sectionId) {
    if (root.shellSettingsSurface === "flyout") {
      openShellSettingsSection(sectionId)
      return
    }

    var payload = JSON.stringify({ section: String(sectionId || "apps") })
    if (root.shell && typeof root.shell.summon === "function") {
      root.shell.summon("lacuna.shell-settings", payload)
      return
    }
    commands.run(shellIpcCommand("shell", "summon", ["lacuna.shell-settings", payload]))
  }

  function toggleShellSettingsPanel() {
    openShellSettingsPanel("apps")
  }

  function openShellSettingsSection(sectionId) {
    if (!lacunaEnabled) return

    var nextSection = String(sectionId || "apps")
    if (shellSettingsPanelOpen && shellSettingsPanel.item && shellSettingsPanel.item.currentSection === nextSection) {
      panelController.closeFlyout("shellSettings")
      return
    }

    shellSettingsSection = nextSection
    if (shellSettingsPanel.item) shellSettingsPanel.item.currentSection = nextSection
    panelController.openFlyout("shellSettings")
    requestFlyoutFocus("shellSettings")
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
    } else if (pendingFlyoutFocus === "shellSettings" && shellSettingsPanelOpen && shellSettingsPanel.item) {
      shellSettingsPanel.item.forceActiveFocus()
      pendingFlyoutFocus = ""
    }
  }

  function shellPluginEnabled(id) {
    var revision = pluginStateRevision
    if (pluginRegistry && typeof pluginRegistry.isEnabled === "function") {
      return pluginRegistry.isEnabled(id)
    }

    var config = root.shellConfig
    var bar = config && config.bar ? config.bar : null
    var layout = bar && bar.layout ? bar.layout : null
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var list = layout && Array.isArray(layout[sections[s]]) ? layout[sections[s]] : []
      for (var j = 0; j < list.length; j++) {
        if (list[j] && list[j].id === id) return true
      }
    }

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

  function validFrameReserveMode(value) {
    var mode = String(value || "auto").toLowerCase()
    if (mode === "comfort" || mode === "flush") return mode
    return "auto"
  }

  function activeHyprWorkspace() {
    hyprWorkspaceRevision
    var monitor = root.sidebarScreen && Hyprland.monitorFor ? Hyprland.monitorFor(root.sidebarScreen) : null
    if (monitor && monitor.activeWorkspace) return monitor.activeWorkspace
    return Hyprland.focusedWorkspace || null
  }

  function activeWorkspaceWindowCount() {
    var workspace = activeHyprWorkspace()
    if (!workspace) return 0
    if (workspace.toplevels && workspace.toplevels.values) return Number(workspace.toplevels.values.length || 0)
    if (workspace.lastIpcObject && workspace.lastIpcObject.windows !== undefined) return Number(workspace.lastIpcObject.windows || 0)
    return 0
  }

  function hyprGapValue(value) {
    var parsed = Number(value)
    return isFinite(parsed) ? Math.round(parsed) : -1
  }

  function fakeFullscreenWorkspaceActive() {
    var workspace = activeHyprWorkspace()
    if (!workspace) return false
    if (workspace.hasFullscreen === true) return true
    return activeWorkspaceWindowCount() <= 1
  }

  function gapslessWorkspaceActive() {
    return hyprWindowGapsDisabled || fakeFullscreenWorkspaceActive()
  }

  function refreshHyprWorkspaceState() {
    if (Hyprland.refreshWorkspaces) Hyprland.refreshWorkspaces()
    if (Hyprland.refreshToplevels) Hyprland.refreshToplevels()
    hyprWorkspaceRevision += 1
  }

  function setFrameMode(mode) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.mode = validFrameMode(mode)
    lacunaSettings.save(next)
  }

  function setFrameReserveMode(mode) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.reserveMode = validFrameReserveMode(mode)
    lacunaSettings.save(next)
  }

  function setBackgroundEffectsEnabled(enabled) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    if (!next.backgroundEffects || typeof next.backgroundEffects !== "object") next.backgroundEffects = lacunaSettings.normalizeBackgroundEffects({})
    next.backgroundEffects.enabled = enabled === true
    lacunaSettings.save(next)
  }

  function setBackgroundVignetteEnabled(enabled) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    if (!next.backgroundVignette || typeof next.backgroundVignette !== "object") next.backgroundVignette = lacunaSettings.normalizeBackgroundVignette({})
    next.backgroundVignette.enabled = enabled === true
    lacunaSettings.save(next)

    if (enabled === true && !shellPluginEnabled("lacuna.background-vignette")) {
      setShellPluginEnabled("lacuna.background-vignette", true)
    }
  }

  function desiredChecked(entry, fallback) {
    return entry && entry.desiredChecked !== undefined ? entry.desiredChecked === true : fallback
  }

  function setBackgroundEffect(effectId) {
    var id = String(effectId || "").trim()
    if (id === "") return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    if (!next.backgroundEffects || typeof next.backgroundEffects !== "object") next.backgroundEffects = lacunaSettings.normalizeBackgroundEffects({})
    if (!next.backgroundEffects.effects || typeof next.backgroundEffects.effects !== "object") next.backgroundEffects.effects = {}
    next.backgroundEffects.enabled = true
    next.backgroundEffects.activeEffect = lacunaSettings.normalizeBackgroundEffectId(id, next.backgroundEffects.activeEffect)
    next.backgroundEffects.effects.trackingLines = { enabled: true }
    next.backgroundEffects.effects.auroraDrift = { enabled: true }
    next.backgroundEffects.effects.rainfall = { enabled: true }
    next.backgroundEffects.effects.cinematicLight = { enabled: true }
    next.backgroundEffects.effects.crt = { enabled: true }
    lacunaSettings.save(next)

    var pluginId = registry.backgroundEffectPluginId(next.backgroundEffects.activeEffect)
    if (pluginId !== "" && !shellPluginEnabled(pluginId)) {
      setShellPluginEnabled(pluginId, true)
    }
  }

  function setBackgroundEffectForeground(effectId, enabled) {
    var id = registry.activeBackgroundEffect() === effectId ? effectId : registry.activeBackgroundEffect()
    var pluginId = registry.backgroundEffectPluginId(id)
    if (pluginId === "") return

    if (!shellPluginEnabled(pluginId)) {
      setShellPluginEnabled(pluginId, true)
    }

    var next = registry.backgroundEffectLayerSettings(id)
    next.foregroundOverlay = enabled === true

    if (shell && typeof shell.updateEntryInline === "function") {
      shell.updateEntryInline(pluginId, next)
      pluginStateRevision++
      return
    }

    commands.run("notify-send 'Lacuna' 'Background overlay settings require the Omarchy shell plugin registry'")
  }

  function toggleBackgroundEffectForeground(effectId) {
    setBackgroundEffectForeground(effectId, !registry.backgroundEffectForegroundEnabled(effectId))
  }

  function setFrameShadow(enabled) {
    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.frame.shadow = enabled === true
    lacunaSettings.save(next)
  }

  function toggleFrameShadow() {
    setFrameShadow(!lacunaSettings.normalize(lacunaSettings.data).frame.shadow)
  }

  function setSidebarDefaultMode(mode) {
    sidebarState.setDefaultMode(mode)
    applySidebarDefaultState()
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
      pluginRegistry.setEnabled("lacuna.desktop-clock", true)
    }

    if (shell && typeof shell.updateEntryInline === "function") {
      shell.updateEntryInline("lacuna.desktop-clock", next)
      pluginStateRevision++
      return
    }

    commands.run("notify-send 'Lacuna' 'Clock settings require the Omarchy shell plugin registry'")
  }

  function setCinematicLightSetting(key, value) {
    var next = registry.cinematicLightSettings()
    var normalizedKey = String(key || "")
    var normalizedValue = String(value || "")

    if (normalizedKey !== "stylePreset" && normalizedKey !== "intensity") {
      return
    }

    if (normalizedKey === "stylePreset") {
      next.stylePreset = normalizedValue === "cinematicFlare" || normalizedValue === "anamorphicGlow" ? normalizedValue : "lightLeak"
    } else {
      var intensity = Number(normalizedValue)
      next.intensity = isNaN(intensity) ? 1 : Math.max(0, Math.min(1, intensity))
    }

    if (shell && typeof shell.updateEntryInline === "function") {
      shell.updateEntryInline("lacuna.cinematic-light-overlay", next)
      pluginStateRevision++
      return
    }

    commands.run("notify-send 'Lacuna' 'Cinematic Light settings require the Omarchy shell plugin registry'")
  }

  function setCinematicLightMotion(mode, enabled) {
    var normalizedMode = String(mode || "")
    if (normalizedMode !== "slowDrift" && normalizedMode !== "occasionalSweeps" && normalizedMode !== "activeShimmer") return

    var next = registry.cinematicLightSettings()
    var modes = registry.cinematicLightMotionModes()
    modes[normalizedMode] = enabled === true
    if (!modes.slowDrift && !modes.occasionalSweeps && !modes.activeShimmer) modes[normalizedMode] = true

    next.slowDrift = modes.slowDrift
    next.occasionalSweeps = modes.occasionalSweeps
    next.activeShimmer = modes.activeShimmer
    delete next.motionMode

    if (shell && typeof shell.updateEntryInline === "function") {
      shell.updateEntryInline("lacuna.cinematic-light-overlay", next)
      pluginStateRevision++
      return
    }

    commands.run("notify-send 'Lacuna' 'Cinematic Light settings require the Omarchy shell plugin registry'")
  }

  function toggleCinematicLightMotion(mode) {
    var modes = registry.cinematicLightMotionModes()
    setCinematicLightMotion(mode, !modes[String(mode || "")])
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

  function runOmarchyCommand(command) {
    if (!command) return
    commands.run(command)
  }

  function requestSystemRestart() {
    if (instantRestart) {
      confirmSystemRestart()
      return
    }

    pendingSystemRestartConfirmation = true
    if (!menuState.open) panelController.openMenu()
  }

  function confirmSystemRestart() {
    pendingSystemRestartConfirmation = false
    panelController.closeActiveFlyout()
    commands.run("omarchy system reboot")
    applySidebarDefaultState()
  }

  function cancelSystemRestart() {
    pendingSystemRestartConfirmation = false
  }

  function handleSidebarAction(entry) {
    if (entry.action === "toggle-sidebar-mode") {
      sidebarState.setExclusive(desiredChecked(entry, !sidebarState.exclusive))
      return true
    }

    if (entry.action === "toggle-sidebar-rail") {
      sidebarState.toggleCollapsed()
      return true
    }

    if (entry.action.indexOf("set-sidebar-default-") === 0) {
      setSidebarDefaultMode(entry.action.substring("set-sidebar-default-".length))
      return true
    }

    if (entry.action === "toggle-corner-pieces") {
      sidebarState.setCornerPiecesEnabled(desiredChecked(entry, !sidebarState.cornerPieces))
      return true
    }

    if (entry.action === "toggle-bar-density") {
      compactState.toggle()
      return true
    }

    if (entry.action === "toggle-lacuna-density") {
      compactState.toggle()
      return true
    }

    if (entry.action.indexOf("set-bar-size-mode-") === 0) {
      barSizeModeService.setMode(entry.action.substring("set-bar-size-mode-".length))
      return true
    }

    if (entry.action.indexOf("set-controls-layout-") === 0) {
      setControlsLayout(entry.action.substring("set-controls-layout-".length))
      return true
    }

    if (entry.action.indexOf("set-shortcuts-layout-") === 0) {
      setShortcutsLayout(entry.action.substring("set-shortcuts-layout-".length))
      return true
    }

    if (entry.action.indexOf("set-shell-settings-surface-") === 0) {
      setShellSettingsSurface(entry.action.substring("set-shell-settings-surface-".length))
      return true
    }

    if (entry.action.indexOf("set-daily-launch-layout-") === 0) {
      setDailyLaunchLayout(entry.action.substring("set-daily-launch-layout-".length))
      return true
    }

    if (entry.action.indexOf("set-quick-launch-layout-") === 0) {
      setQuickLaunchLayout(entry.action.substring("set-quick-launch-layout-".length))
      return true
    }

    return false
  }

  function handleLacunaSettingsAction(entry) {
    if (entry.action.indexOf("set-frame-mode-") === 0) {
      setFrameMode(entry.action.substring("set-frame-mode-".length))
      return true
    }

    if (entry.action.indexOf("set-frame-reserve-mode-") === 0) {
      setFrameReserveMode(entry.action.substring("set-frame-reserve-mode-".length))
      return true
    }

    if (entry.action === "toggle-frame-shadow") {
      setFrameShadow(desiredChecked(entry, !lacunaSettings.normalize(lacunaSettings.data).frame.shadow))
      return true
    }

    if (entry.action === "toggle-background-effects") {
      setBackgroundEffectsEnabled(desiredChecked(entry, !registry.backgroundEffectsEnabled()))
      return true
    }

    if (entry.action === "toggle-background-vignette") {
      setBackgroundVignetteEnabled(desiredChecked(entry, !registry.backgroundVignetteEnabled()))
      return true
    }

    if (entry.action.indexOf("set-background-effect-") === 0) {
      setBackgroundEffect(entry.action.substring("set-background-effect-".length))
      return true
    }

    if (entry.action.indexOf("toggle-background-effect-foreground-") === 0) {
      var foregroundEffect = entry.action.substring("toggle-background-effect-foreground-".length)
      setBackgroundEffectForeground(foregroundEffect, desiredChecked(entry, !registry.backgroundEffectForegroundEnabled(foregroundEffect)))
      return true
    }

    if (entry.action.indexOf("set-cinematic-light-style-") === 0) {
      setCinematicLightSetting("stylePreset", entry.action.substring("set-cinematic-light-style-".length))
      return true
    }

    if (entry.action.indexOf("set-cinematic-light-intensity-") === 0) {
      setCinematicLightSetting("intensity", entry.action.substring("set-cinematic-light-intensity-".length))
      return true
    }

    if (entry.action.indexOf("toggle-cinematic-light-motion-") === 0) {
      var motionMode = entry.action.substring("toggle-cinematic-light-motion-".length)
      setCinematicLightMotion(motionMode, desiredChecked(entry, !registry.cinematicLightMotionModes()[motionMode]))
      return true
    }

    if (entry.action.indexOf("open-settings-section-") === 0) {
      openSettingsSection(entry.action.substring("open-settings-section-".length))
      return true
    }

    if (entry.action === "toggle-color-profile") {
      var next = lacunaSettings.normalize(lacunaSettings.data)
      next.colorProfile = desiredChecked(entry, next.colorProfile !== "colorful") ? "colorful" : "semantic"
      lacunaSettings.save(next)
      return true
    }

    if (entry.action === "toggle-instant-restart") {
      var nextPowerSettings = lacunaSettings.normalize(lacunaSettings.data)
      nextPowerSettings.power.instantRestart = desiredChecked(entry, !root.instantRestart)
      lacunaSettings.save(nextPowerSettings)
      return true
    }

    if (entry.action === "toggle-desktop-clock") {
      setShellPluginEnabled("lacuna.desktop-clock", desiredChecked(entry, !desktopClockEnabled))
      return true
    }

    if (entry.action === "toggle-clock-12-hour") {
      setDesktopClockSettings({ use12Hour: desiredChecked(entry, !root.desktopClockUse12Hour) })
      return true
    }

    if (entry.action.indexOf("set-clock-anchor-x-") === 0) {
      setDesktopClockAnchorAxis("x", entry.action.substring("set-clock-anchor-x-".length))
      return true
    }

    if (entry.action.indexOf("set-clock-anchor-y-") === 0) {
      setDesktopClockAnchorAxis("y", entry.action.substring("set-clock-anchor-y-".length))
      return true
    }

    if (entry.action === "nudge-clock-left") {
      nudgeDesktopClock(-24, 0)
      return true
    }

    if (entry.action === "scale-clock-down") {
      scaleDesktopClock(-0.1)
      return true
    }

    if (entry.action === "scale-clock-up") {
      scaleDesktopClock(0.1)
      return true
    }

    if (entry.action === "nudge-clock-right") {
      nudgeDesktopClock(24, 0)
      return true
    }

    if (entry.action === "nudge-clock-up") {
      nudgeDesktopClock(0, -24)
      return true
    }

    if (entry.action === "nudge-clock-down") {
      nudgeDesktopClock(0, 24)
      return true
    }

    if (entry.action === "reset-clock-position") {
      resetDesktopClockPosition()
      return true
    }

    if (entry.action === "cycle-design-style") {
      var nextStyleSettings = lacunaSettings.normalize(lacunaSettings.data)
      nextStyleSettings.designStyle = lacunaSettings.nextDesignStyle(nextStyleSettings.designStyle)
      lacunaSettings.save(nextStyleSettings)
      return true
    }

    if (entry.action.indexOf("set-design-style-") === 0) {
      setDesignStyle(entry.action.substring("set-design-style-".length))
      return true
    }

    return false
  }

  function handleQuickAccessAction(entry) {
    if (entry.action === "confirm-system-restart") {
      requestSystemRestart()
      return true
    }

    if (entry.action === "open-custom-quick-launch-picker") {
      openCustomQuickLaunchPicker()
      return true
    }

    if (entry.action === "add-custom-quick-launch-app") {
      addCustomQuickLaunchApp(entry.appId)
      return true
    }

    if (entry.action.indexOf("choose-preferred-app-") === 0) {
      openPreferredAppPicker(entry.action.substring("choose-preferred-app-".length))
      return true
    }

    if (entry.action === "reload-apps") {
      appCatalog.reload()
      return true
    }

    if (entry.action === "open-screenrecord-menu") {
      commands.run("omarchy capture screenrecording --stop-recording || "
        + "omarchy menu toggle trigger.capture.screenrecord")
      applySidebarDefaultState()
      return true
    }

    return false
  }

  function activate(entry) {
    if (!entry || entry.kind === "header") return
    if (!lacunaEnabled) return

    if (entry.action) {
      if (handleSidebarAction(entry)) return
      if (handleLacunaSettingsAction(entry)) return
      if (handleQuickAccessAction(entry)) return
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
      applySidebarDefaultState()
    }
  }

  Component.onCompleted: {
    versionFile.reload()
    applyInitialSidebarDefault()
    refreshHyprWorkspaceState()
  }

  LacunaMenuState {
    id: localMenuState
  }

  LacunaSettings {
    id: localLacunaSettings
  }

  OmarchyShellSettingsService {
    id: localShellSettingsService
    shell: root.shell
    manifest: root.manifest
    pluginRegistry: root.pluginRegistry
    shellConfig: root.shellConfig
  }

  Connections {
    target: root.lacunaSettings
    function onLoaded() { root.applyInitialSidebarDefault() }
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

  Timer {
    id: hyprWorkspaceRefreshTimer
    interval: 80
    repeat: false
    onTriggered: root.refreshHyprWorkspaceState()
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      var name = event.name
      if (name.indexOf("workspace") >= 0 || name === "focusedmon" || name.indexOf("window") >= 0 || name === "fullscreen") {
        hyprWorkspaceRefreshTimer.restart()
      }
    }

    function onFocusedWorkspaceChanged() {
      root.hyprWorkspaceRevision += 1
    }
  }

  Connections {
    target: Hyprland.workspaces

    function onValuesChanged() {
      root.hyprWorkspaceRevision += 1
    }
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
    sidebarDefaultMode: sidebarState.defaultMode
    compact: root.compact
    barSizeMode: barSizeModeService.barSizeMode
    designStyle: root.designStyle
    colorProfile: lacunaSettings.data && lacunaSettings.data.colorProfile ? lacunaSettings.data.colorProfile : "semantic"
    quickLaunchLayout: lacunaSettings.data && lacunaSettings.data.quickLaunchLayout ? lacunaSettings.data.quickLaunchLayout : "list"
    dailyLaunchLayout: lacunaSettings.data && lacunaSettings.data.dailyLaunchLayout ? lacunaSettings.data.dailyLaunchLayout : "list"
    shortcutsLayout: lacunaSettings.data && lacunaSettings.data.shortcutsLayout ? lacunaSettings.data.shortcutsLayout : "list"
    controlsLayout: lacunaSettings.data && lacunaSettings.data.controlsLayout ? lacunaSettings.data.controlsLayout : "grid"
    shellSettingsSurface: root.shellSettingsSurface
    frameMode: root.frameMode
    frameReserveMode: root.frameReserveMode
    frameShadow: root.frameShadow
    backgroundEffects: root.backgroundEffectsSettings
    backgroundVignette: root.backgroundVignetteSettings
    instantRestart: root.instantRestart
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
      if (root.hostManaged) return
      if (root.frameMode === "fullframe") return
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
      mode: root.lacunaEnabled && !root.barOwnsLacunaFrame ? root.frameMode : "off"
      shadowEnabled: root.lacunaEnabled && !root.barOwnsLacunaFrame && root.frameShadow && root.frameMode !== "off"
      barPosition: root.barPosition
      barSize: root.barControlSize
      barBottomY: root.barBottomY
      barEdgeCasterSize: root.barEdgeCasterSize
      frameWidth: root.sidebarScreen ? root.sidebarScreen.width : menuWindow.width
      frameThickness: root.frameThickness
      frameRadius: root.frameRadius
      joinRadius: root.lacunaJoinRadius
      cornerPieces: sidebarState.cornerPieces
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
      fullFrame: root.frameMode === "fullframe"
      frameThickness: root.frameThickness
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
        onQuickLaunchRemoveRequested: function(appId) {
          root.removeCustomQuickLaunchApp(appId)
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
          root.holdFlyoutAfterSettingsActivation()
          root.activate(entry)
          root.requestFlyoutFocus("settings")
        }
        onCloseRequested: panelController.closeFlyout("settings")
      }

      Loader {
        id: shellSettingsPanel

        property var registryRef: registry

        anchors.fill: parent
        active: root.renderShellSettingsContent
        visible: root.renderShellSettingsContent
        opacity: root.shellSettingsPanelOpen ? 1 : 0
        onLoaded: if (item) item.currentSection = root.shellSettingsSection
        sourceComponent: Component {
          OmarchyShellSettingsWindow {
            currentSection: root.shellSettingsSection
            open: root.shellSettingsPanelOpen
            compact: root.compact
            drawBackground: false
            designTokens: designTokens
            registry: shellSettingsPanel.registryRef
            settingsService: root.shellSettingsService
            foreground: root.foreground
            background: root.background
            accent: root.accent
            shellAccent: root.shellAccent
            sessionAccent: root.sessionAccent
            dangerAccent: root.dangerAccent
            navAccent: root.navAccent
            muted: root.muted
            onCurrentSectionChanged: root.shellSettingsSection = currentSection
            onActivated: function(entry) {
              root.holdFlyoutAfterSettingsActivation()
              root.activate(entry)
              root.requestFlyoutFocus("shellSettings")
            }
            onCloseRequested: panelController.closeFlyout("shellSettings")
          }
        }
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

    Item {
      id: restartConfirmOverlay

      visible: root.pendingSystemRestartConfirmation && root.sidebarSurfaceVisible
      enabled: visible
      focus: visible
      z: 1000
      x: panelHost.sidebarMaskX
      y: panelHost.sidebarMaskY
      width: root.panelWidth
      height: panelHost.sidebarMaskHeight
      opacity: visible ? 1 : 0
      onVisibleChanged: if (visible) forceActiveFocus()
      Keys.onEscapePressed: root.cancelSystemRestart()
      Keys.onReturnPressed: root.confirmSystemRestart()
      Keys.onEnterPressed: root.confirmSystemRestart()

      Behavior on opacity {
        LacunaAnim { motion: "fast" }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.cancelSystemRestart()
      }

      LacunaRect {
        id: restartConfirmDialog

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(root.barBottomY + 44, Math.round((parent.height - height) / 2) - 18)
        width: Math.max(220, Math.min(parent.width - 28, root.compact ? 238 : 270))
        height: root.compact ? 164 : 184
        radius: root.designStyle === "material" ? 12 : designTokens.radius
        color: root.background
        border.width: root.designStyle === "lacuna" ? 0 : 1
        border.color: Qt.rgba(root.dangerAccent.r, root.dangerAccent.g, root.dangerAccent.b, 0.26)
        clip: true

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {}
        }

        LacunaRect {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: 2
          color: root.dangerAccent
          opacity: 0.86
        }

        LacunaTablerIcon {
          id: restartConfirmIcon

          anchors.left: parent.left
          anchors.leftMargin: 16
          anchors.top: parent.top
          anchors.topMargin: root.compact ? 18 : 20
          name: "refresh"
          color: root.dangerAccent
          iconSize: root.compact ? 20 : 22
        }

        LacunaText {
          anchors.left: restartConfirmIcon.right
          anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.verticalCenter: restartConfirmIcon.verticalCenter
          text: "Restart System?"
          color: root.safeValue(root.foreground, "#d8dee9")
          fontFamily: root.safeValue(root.bodyFontFamily, "JetBrains Mono")
          font.pixelSize: root.compact ? 12 : 13
          font.weight: Font.DemiBold
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 16
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.top: restartConfirmIcon.bottom
          anchors.topMargin: root.compact ? 16 : 18
          text: "This will reboot the machine now. Unsaved work in other apps may be lost."
          color: root.safeValue(root.muted, "#8b949e")
          font.family: root.safeValue(root.bodyFontFamily, "JetBrains Mono")
          font.pixelSize: root.compact ? 10 : 11
          wrapMode: Text.WordWrap
          lineHeight: 1.16
          renderType: Text.NativeRendering
        }

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 16
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 16
          height: root.compact ? 30 : 34
          spacing: 8

          LacunaRect {
            width: Math.floor((parent.width - parent.spacing) / 2)
            height: parent.height
            radius: root.designStyle === "material" ? height / 2 : designTokens.controlRadius
            color: "transparent"
            border.width: root.designStyle === "lacuna" ? 0 : 1
            border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)

            LacunaText {
              anchors.centerIn: parent
              width: parent.width - 14
              text: "Cancel"
              color: root.safeValue(root.muted, "#8b949e")
              fontFamily: root.safeValue(root.bodyFontFamily, "JetBrains Mono")
              font.pixelSize: root.compact ? 10 : 11
              font.weight: Font.DemiBold
              horizontalAlignment: Text.AlignHCenter
            }

            LacunaStateLayer {
              anchors.fill: parent
              stateColor: root.foreground
              hoverOpacity: designTokens.hoverOpacity
              pressOpacity: designTokens.activeOpacity
              onTriggered: root.cancelSystemRestart()
            }
          }

          LacunaRect {
            width: parent.width - parent.spacing - Math.floor((parent.width - parent.spacing) / 2)
            height: parent.height
            radius: root.designStyle === "material" ? height / 2 : designTokens.controlRadius
            color: Qt.rgba(root.dangerAccent.r, root.dangerAccent.g, root.dangerAccent.b, 0.16)
            border.width: root.designStyle === "lacuna" ? 0 : 1
            border.color: Qt.rgba(root.dangerAccent.r, root.dangerAccent.g, root.dangerAccent.b, 0.32)

            LacunaText {
              anchors.centerIn: parent
              width: parent.width - 14
              text: "Restart"
              color: root.safeValue(root.foreground, "#d8dee9")
              fontFamily: root.safeValue(root.bodyFontFamily, "JetBrains Mono")
              font.pixelSize: root.compact ? 10 : 11
              font.weight: Font.DemiBold
              horizontalAlignment: Text.AlignHCenter
            }

            LacunaStateLayer {
              anchors.fill: parent
              stateColor: root.dangerAccent
              hoverOpacity: designTokens.hoverOpacity
              pressOpacity: designTokens.activeOpacity
              onTriggered: root.confirmSystemRestart()
            }
          }
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
