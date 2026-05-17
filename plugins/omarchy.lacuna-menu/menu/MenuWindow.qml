import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
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
  property bool hostClosing: false
  readonly property var compactState: sharedCompactState || localCompactState
  readonly property var sidebarState: sharedSidebarState || localSidebarState
  property color foreground: menuTheme.foreground
  property color background: menuTheme.background
  property color panelColor: menuTheme.background
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
  property int fullPanelWidth: compact ? 270 : 310
  property int railButtonWidth: railCompact ? 24 : barHeight
  property int railLeftInset: railDesignTokens.railLeftInset
  property int railRightInset: railDesignTokens.railRightInset
  property int railPanelWidth: railButtonWidth + railLeftInset + railRightInset
  property int panelWidth: sidebarState.collapsed ? railPanelWidth : fullPanelWidth
  property int defaultTopBarHeight: 26
  property int barHeight: topBarHeight()
  property int joinRadius: sidebarState.cornerPieces ? (compact ? 14 : 18) : 0
  property int connectorOverlap: sidebarState.cornerPieces ? (compact ? 25 : 33) : 0
  property int bodyRightInset: sidebarState.cornerPieces ? joinRadius : 0
  property int surfaceRightInset: bodyRightInset
  property int flyoutLeftX: panelWidth + surfaceRightInset
  property int flyoutTopY: sidebarState.cornerPieces ? (sidebarState.exclusive ? 0 : barHeight) : (sidebarState.exclusive ? designTokens.topInset : barHeight + designTokens.topInset)
  property int flyoutLaneWidth: (settingsPanelOpen ? settingsPanelWidth : 0) + (appPickerOpen ? appPickerWidth : 0)
  // In exclusive mode the compositor already places this window below the top
  // bar, so the bar edge is local y=0. In overlay mode the window starts at
  // screen top and the bar edge is the live bar height.
  property int barBottomY: sidebarState.exclusive ? 0 : barHeight
  property bool panelVisible: menuState.open
  property bool settingsPanelOpen: false
  property int settingsPanelWidth: compact ? 360 : 400
  property bool appPickerOpen: false
  property string appPickerMode: "customQuickLaunchApp"
  property string preferredAppPickerRole: ""
  property int appPickerWidth: compact ? 260 : 300
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
  readonly property var sidebarScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
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

  function topBarHeight() {
    var liveBar = shell && shell.bar ? shell.bar : null
    var livePosition = liveBar && liveBar.position ? String(liveBar.position) : ""
    var configPosition = shell && shell.barConfig && shell.barConfig.position ? String(shell.barConfig.position) : "top"
    var position = livePosition || configPosition

    if (position !== "top") return 0
    if (liveBar && !liveBar.barHidden && liveBar.barSize !== undefined) {
      return positiveInt(liveBar.barSize, configBarHeight())
    }
    return configBarHeight()
  }

  function open(payloadJson) {
    hostClosing = false
    menuState.show()
  }

  function close() {
    hostClosing = true
    menuState.close()
    panelVisible = false
    hostClosing = false
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

  function preferredAppValue(role) {
    var defaults = lacunaSettings.data && lacunaSettings.data.preferredApps ? lacunaSettings.data.preferredApps : {}
    var value = String(defaults[role] || "").trim()
    return value === "" ? "system" : value
  }

  function setPreferredApp(role, id) {
    if (!role) return

    var next = lacunaSettings.normalize(lacunaSettings.data)
    next.preferredApps[role] = String(id || "system").trim() || "system"
    lacunaSettings.save(next)
    appPickerOpen = false
  }

  function openCustomQuickLaunchPicker() {
    if (!appCatalog.ready) appCatalog.reload()
    appPicker.query = ""
    searchInput.text = ""
    appPickerMode = "customQuickLaunchApp"
    preferredAppPickerRole = ""
    appPickerOpen = true
    if (sidebarState.collapsed && !settingsPanelOpen) sidebarState.expand()
    Qt.callLater(function() {
      searchInput.forceActiveFocus()
    })
  }

  function openPreferredAppPicker(role) {
    if (!appCatalog.ready) appCatalog.reload()
    appPicker.query = ""
    searchInput.text = ""
    appPickerMode = "preferredApp"
    preferredAppPickerRole = role
    appPickerOpen = true
    if (sidebarState.collapsed && !settingsPanelOpen) sidebarState.expand()
    Qt.callLater(function() {
      searchInput.forceActiveFocus()
    })
  }

  function toggleSettingsPanel() {
    settingsPanelOpen = !settingsPanelOpen
    if (settingsPanelOpen) {
      if (!menuState.open) menuState.show()
      Qt.callLater(function() {
        settingsPanel.forceActiveFocus()
      })
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

    commands.run("omarchy-shell-ipc shell setPluginEnabled " + id + " " + (enabled ? "true" : "false"))
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
      menuState.close()
      commands.run("omarchy-capture-screenrecording --stop-recording || omarchy-shell-ipc menu summon trigger.capture.screenrecord")
      return
    }

    if (entry.view) {
      if (sidebarState.collapsed) sidebarState.expand()
      appPickerOpen = false
      menuState.push(entry.view)
      return
    }

    if (entry.command) {
      appPickerOpen = false
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
    designStyle: root.designStyle
    colorProfile: lacunaSettings.data && lacunaSettings.data.colorProfile ? lacunaSettings.data.colorProfile : "semantic"
    desktopClockEnabled: root.desktopClockEnabled
    desktopClockAnchor: root.desktopClockAnchor
    desktopClockOffsetX: root.desktopClockOffsetX
    desktopClockOffsetY: root.desktopClockOffsetY
    desktopClockScale: root.desktopClockScale
    desktopClockUse12Hour: root.desktopClockUse12Hour
    appCatalog: appCatalog
    customQuickLaunchApps: lacunaSettings.data && lacunaSettings.data.customQuickLaunchApps ? lacunaSettings.data.customQuickLaunchApps : []
    preferredApps: lacunaSettings.data && lacunaSettings.data.preferredApps ? lacunaSettings.data.preferredApps : ({})
  }

  Connections {
    target: root.menuState
    function onOpenChanged() {
      if (root.menuState.open) {
        root.panelVisible = true
      } else {
        root.appPickerOpen = false
        root.settingsPanelOpen = false
        hideTimer.restart()
        if (!root.hostClosing && root.shell && root.shell.hide) {
          root.shell.hide(root.pluginId)
        }
      }
    }
  }

  Timer {
    id: hideTimer
    interval: 190
    repeat: false
    onTriggered: if (!root.menuState.open) root.panelVisible = false
  }

  CommandRunner {
    id: commands
  }

  PanelWindow {
    id: menuWindow

    visible: root.panelVisible
    screen: root.sidebarScreen
    color: "transparent"
    implicitWidth: root.panelWidth + root.surfaceRightInset + root.flyoutLaneWidth
    exclusiveZone: sidebarState.exclusive && root.menuState.open ? root.panelWidth : 0
    exclusionMode: sidebarState.exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
    WlrLayershell.namespace: "lacuna-menu"
    WlrLayershell.layer: sidebarState.exclusive ? WlrLayer.Top : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.appPickerOpen || root.settingsPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
      top: true
      bottom: true
      left: true
    }

    MenuSurface {
      id: surface

      anchors.top: parent.top
      anchors.bottom: parent.bottom
      panelWidth: root.panelWidth
      open: root.menuState.open
      barHeight: root.barHeight
      barBottomY: root.barBottomY
      joinRadius: root.joinRadius
      connectorOverlap: root.connectorOverlap
      bodyRightInset: root.surfaceRightInset
      cornerPieces: sidebarState.cornerPieces
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
        iconRailWidth: root.barHeight
        onActivated: function(entry) {
          root.activate(entry)
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

    SettingsWindow {
      id: settingsPanel

      visible: root.menuState.open && root.settingsPanelOpen
      enabled: root.settingsPanelOpen
      opacity: root.settingsPanelOpen ? 1 : 0
      x: root.flyoutLeftX
      y: root.flyoutTopY
      width: root.settingsPanelWidth
      height: Math.min(menuWindow.height - y - designTokens.bottomInset, root.compact ? 520 : 620)
      open: root.settingsPanelOpen
      compact: root.compact
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
      onCloseRequested: root.settingsPanelOpen = false
    }

    LacunaRect {
      id: appPicker

      property string query: ""

      function filteredApps() {
        var apps = appCatalog.apps || []
        var needle = query.toLowerCase().trim()
        var list = []

        for (var i = 0; i < apps.length; i++) {
          var app = apps[i]
          var haystack = String((app.Name || "") + " " + (app.GenericName || "") + " " + (app.Comment || "") + " " + (app.Categories || "")).toLowerCase()
          if (needle === "" || haystack.indexOf(needle) >= 0) list.push(app)
          if (list.length >= 80) break
        }

        return list
      }

      visible: root.menuState.open && root.appPickerOpen
      enabled: root.appPickerOpen
      opacity: root.appPickerOpen ? 1 : 0
      x: root.flyoutLeftX + (root.settingsPanelOpen ? root.settingsPanelWidth : 0)
      y: root.flyoutTopY
      width: root.appPickerWidth
      height: Math.min(menuWindow.height - y - designTokens.bottomInset, root.compact ? 430 : 520)
      radius: designTokens.material ? designTokens.radius : 0
      color: root.panelColor
      border.width: designTokens.borderWidth
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
      clip: true

      Behavior on opacity {
        LacunaAnim { motion: "fast" }
      }

      Column {
        anchors.fill: parent
        anchors.margins: root.compact ? 10 : 12
        spacing: root.compact ? 8 : 10

        Row {
          width: parent.width
          height: root.compact ? 26 : 30
          spacing: 8

          LacunaText {
            width: parent.width - closePicker.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: root.appPickerMode === "preferredApp" ? "Set " + registry.roleMeta(root.preferredAppPickerRole).label + " App" : "Add Quick Launch App"
            color: root.foreground
            fontFamily: "Tektur"
            font.pixelSize: root.compact ? 13 : 15
            font.weight: Font.DemiBold
          }

          LacunaIconButton {
            id: closePicker

            icon: "x"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 28
            buttonRadius: designTokens.controlRadius
            hoverOpacity: designTokens.hoverOpacity
            pressOpacity: designTokens.activeOpacity
            iconSize: root.compact ? 13 : 15
            onTriggered: root.appPickerOpen = false
          }
        }

        LacunaRect {
          width: parent.width
          height: root.compact ? 28 : 32
          radius: designTokens.material ? height / 2 : designTokens.controlRadius
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
          border.width: 1
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

          LacunaText {
            visible: searchInput.text === ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "Search apps"
            color: root.muted
            fontFamily: "JetBrains Mono"
            font.pixelSize: root.compact ? 10 : 11
          }

          TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            focus: root.appPickerOpen
            activeFocusOnPress: true
            color: root.foreground
            selectedTextColor: root.background
            selectionColor: root.accent
            font.family: "JetBrains Mono"
            font.pixelSize: root.compact ? 10 : 11
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            onTextChanged: appPicker.query = text
          }
        }

        Flickable {
          id: appPickerFlick

          width: parent.width
          height: Math.max(0, parent.height - y)
          contentWidth: width
          contentHeight: appPickerList.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: true
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          function scrollBy(delta) {
            contentY = Math.max(0, Math.min(contentHeight - height, contentY - delta))
          }

          Column {
            id: appPickerList

            width: parent.width
            spacing: root.compact ? 4 : 5

            LacunaRect {
              visible: root.appPickerMode === "preferredApp"
              width: parent.width
              height: visible ? (root.compact ? 32 : 38) : 0
              radius: designTokens.radius
              color: systemPickerMouse.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10) : "transparent"
              border.width: root.preferredAppValue(root.preferredAppPickerRole) === "system" && !designTokens.carbon ? 1 : 0
              border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.30)
              clip: true

              LacunaTablerIcon {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                name: "settings"
                color: root.accent
                iconSize: root.compact ? 13 : 15
              }

              LacunaText {
                anchors.left: parent.left
                anchors.leftMargin: 42
                anchors.right: systemState.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: registry.roleMeta(root.preferredAppPickerRole).systemHint
                color: root.foreground
                fontFamily: "JetBrains Mono"
                font.pixelSize: root.compact ? 10 : 11
                font.weight: systemPickerMouse.containsMouse ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Item {
                id: systemState

                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18

                LacunaTablerIcon {
                  visible: root.preferredAppValue(root.preferredAppPickerRole) === "system"
                  anchors.centerIn: parent
                  name: "check"
                  color: root.accent
                  iconSize: root.compact ? 12 : 14
                }
              }

              LacunaStateLayer {
                id: systemPickerMouse

                anchors.fill: parent
                stateColor: root.accent
                hoverOpacity: designTokens.hoverOpacity
                pressOpacity: designTokens.activeOpacity
                onTriggered: root.setPreferredApp(root.preferredAppPickerRole, "system")
                onScrolled: function(delta) {
                  appPickerFlick.scrollBy(delta)
                }
              }
            }

            Repeater {
              model: root.appPickerOpen ? appPicker.filteredApps() : []

              LacunaRect {
                required property var modelData

                readonly property bool alreadyAdded: root.appPickerMode === "customQuickLaunchApp" && root.customQuickLaunchContains(modelData.id)
                readonly property bool selectedOverride: root.appPickerMode === "preferredApp" && root.preferredAppValue(root.preferredAppPickerRole) === String(modelData.id)
                width: parent.width
                height: root.compact ? 32 : 38
                radius: designTokens.radius
                color: pickerMouse.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10) : "transparent"
                border.width: (alreadyAdded || selectedOverride) && !designTokens.carbon ? 1 : 0
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.26)
                clip: true

                IconImage {
                  id: pickerIcon

                  anchors.left: parent.left
                  anchors.leftMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  width: root.compact ? 15 : 18
                  height: width
                  implicitSize: width
                  source: registry.appIconSource(modelData)
                  visible: source !== "" && status !== Image.Error
                }

                LacunaTablerIcon {
                  anchors.centerIn: pickerIcon
                  visible: pickerIcon.source === "" || pickerIcon.status === Image.Error
                  name: registry.appIcon(modelData)
                  color: alreadyAdded ? root.muted : root.accent
                  iconSize: root.compact ? 13 : 15
                }

                LacunaText {
                  anchors.left: pickerIcon.right
                  anchors.leftMargin: 8
                  anchors.right: addState.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.Name || modelData.id
                  color: alreadyAdded ? root.muted : root.foreground
                  fontFamily: "JetBrains Mono"
                  font.pixelSize: root.compact ? 10 : 11
                  font.weight: pickerMouse.containsMouse ? Font.DemiBold : Font.Normal
                  elide: Text.ElideRight
                  maximumLineCount: 1
                }

                Item {
                  id: addState

                  anchors.right: parent.right
                  anchors.rightMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  width: 18
                  height: 18

                  LacunaTablerIcon {
                    visible: alreadyAdded || selectedOverride || root.appPickerMode === "customQuickLaunchApp"
                    anchors.centerIn: parent
                    name: alreadyAdded || selectedOverride ? "check" : "plus"
                    color: alreadyAdded ? root.muted : root.accent
                    iconSize: root.compact ? 12 : 14
                  }
                }

                LacunaStateLayer {
                  id: pickerMouse

                  anchors.fill: parent
                  stateColor: root.accent
                  hoverOpacity: designTokens.hoverOpacity
                  pressOpacity: designTokens.activeOpacity
                  onTriggered: {
                    if (root.appPickerMode === "preferredApp") root.setPreferredApp(root.preferredAppPickerRole, modelData.id)
                    else root.addCustomQuickLaunchApp(modelData.id)
                  }
                  onScrolled: function(delta) {
                    appPickerFlick.scrollBy(delta)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
