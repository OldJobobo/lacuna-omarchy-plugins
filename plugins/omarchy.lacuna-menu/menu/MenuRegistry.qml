import QtQuick

Item {
  id: root

  property string lacunaPath: ""
  property bool sidebarExclusive: true
  property bool sidebarCollapsed: false
  property bool sidebarCornerPieces: true
  property string sidebarDefaultMode: "off"
  property bool compact: false
  property string barSizeMode: "full"
  property bool desktopClockEnabled: false
  property string desktopClockAnchor: "bottom-right"
  property int desktopClockOffsetX: 0
  property int desktopClockOffsetY: 0
  property real desktopClockScale: 1
  property bool desktopClockUse12Hour: false
  property string designStyle: "lacuna"
  property string colorProfile: "semantic"
  property string quickLaunchLayout: "list"
  property string dailyLaunchLayout: "list"
  property string controlsLayout: "grid"
  property string shellSettingsSurface: "flyout"
  property bool instantRestart: false
  property string frameMode: "off"
  property bool frameShadow: false
  property var backgroundEffects: ({})
  property var shellBarConfig: ({})
  property string shellBarPosition: "top"
  property bool shellBarTransparent: false
  property string shellBarCenterAnchor: ""
  property int shellIdleScreensaver: 150
  property int shellIdleLock: 300
  property var shellPlugins: []
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  property int catalogRevision: 0
  property var appCatalog: null
  property var customQuickLaunchApps: []
  property var customQuickLaunchNames: ({})
  property var preferredApps: ({})

  onBarWidgetRegistryChanged: catalogRevision++

  Connections {
    target: root.barWidgetRegistry
    function onChanged() { root.catalogRevision++ }
  }

  function item(kind, icon, label, hint, view, command, tone, priority, layout, danger, group, action, iconSource, switchVisible, switchChecked) {
    return entries.entry({
      kind: kind,
      icon: icon,
      iconSource: iconSource || "",
      label: label,
      hint: hint,
      view: view,
      command: command,
      action: action || "",
      tone: tone,
      priority: priority,
      layout: layout,
      danger: danger === true,
      group: group || "",
      switchVisible: switchVisible === true,
      switchChecked: switchChecked === true
    })
  }

  function grid(group, rows) {
    return entries.grid(group, rows)
  }

  function titleFor(view) {
    if (view === "main") return "Lacuna"
    if (view === "customize") return "Customize"
    if (view === "controls") return "Controls"
    if (view === "system") return "System"
    if (view === "apps") return "Apps"
    if (view === "apps-all") return "All Apps"
    if (view === "lacuna" || view === "lacuna-preferences" || view === "lacuna-clock" || view === "lacuna-preferred-apps") return "Lacuna Settings"
    if (view === "lacuna-shell") return "Runtime"
    if (view.indexOf("apps-") === 0) return categoryTitle(view.substring(5))
    return "Utility Sidebar"
  }

  function shellQuote(value) { return commands.shellQuote(value) }
  function shellDoubleQuote(value) { return commands.shellDoubleQuote(value) }
  function hyprExec(command) { return commands.hyprExec(command) }
  function shellIpcCommand(target, method) { return commands.shellIpcCommand(target, method) }
  function terminalCommand(command, title, holdOpen) { return commands.terminalCommand(command, title, holdOpen) }
  function terminalLaunchCommand(command, title) { return commands.terminalLaunchCommand(command, title) }
  function desktopExecCommand(execLine) { return commands.desktopExecCommand(execLine) }
  function openTerminalCommand() { return commands.openTerminalCommand() }
  function restartLacunaCommand() { return commands.restartLacunaCommand() }
  function openLogCommand() { return commands.openLogCommand() }
  function editPluginCommand() { return commands.editPluginCommand() }
  function editShellConfigCommand() { return commands.editShellConfigCommand() }
  function fontListCommand() { return commands.fontListCommand() }
  function debugCommand() { return commands.debugCommand() }
  function debugIdleCommand() { return commands.debugIdleCommand() }
  function switchThemeCommand() { return commands.switchThemeCommand() }
  function switchBackgroundCommand() { return commands.switchBackgroundCommand() }

  function categories() { return appModel.categories() }
  function categoryMeta(category) { return appModel.categoryMeta(category) }
  function categoryTitle(category) { return appModel.categoryTitle(category) }
  function appIcon(app) { return appModel.appIcon(app) }
  function appIconSource(app) { return appModel.appIconSource(app) }
  function appEntry(app, quickAdd) { return appModel.appEntry(app, quickAdd) }
  function customQuickLaunchContains(id) { return appModel.customQuickLaunchContains(id) }
  function roleMeta(role) { return appModel.roleMeta(role) }
  function preferredAppValue(role) { return appModel.preferredAppValue(role) }
  function preferredAppHint(role) { return appModel.preferredAppHint(role) }
  function roleEntry(role, priority) { return appModel.roleEntry(role, priority) }
  function roleSettingsItem(role) { return appModel.roleSettingsItem(role) }
  function customQuickLaunchItems() { return appModel.customQuickLaunchItems() }
  function preferredAppItems(priority) { return appModel.preferredAppItems(priority) }
  function appItems(category) { return appModel.appItems(category) }

  function designStyleName() {
    if (root.designStyle === "omarchy") return "Omarchy"
    if (root.designStyle === "material") return "Material"
    return "Lacuna"
  }

  function designStyleHint() {
    if (root.designStyle === "omarchy") return "Native Omarchy borders and containment"
    if (root.designStyle === "material") return "Softer tonal surfaces and clearer states"
    return "Flat compact Lacuna linework"
  }

  function barSizeModeName() {
    return root.barSizeMode === "compact" ? "Compact" : "Full"
  }

  function barSizeModeHint() {
    return root.barSizeMode === "compact" ? "Compact topbar, sidebar, and rail sizing" : "Full topbar, sidebar, and rail sizing"
  }

  function shellBarPositionHint() {
    if (root.shellBarPosition === "right") return "Bar is anchored to the right edge"
    if (root.shellBarPosition === "bottom") return "Bar is anchored to the bottom edge"
    if (root.shellBarPosition === "left") return "Bar is anchored to the left edge"
    return "Bar is anchored to the top edge"
  }

  function shellBarLayoutSection(section) {
    var bar = root.shellBarConfig || {}
    var layout = bar.layout || {}
    var list = layout[String(section || "")]
    return Array.isArray(list) ? list : []
  }

  function shellBarSectionSummary(section) {
    var count = shellBarLayoutSection(section).length
    if (count === 0) return "Empty"
    if (count === 1) return "1 widget"
    return count + " widgets"
  }

  function secondsName(value) {
    var seconds = Math.max(0, Math.round(Number(value) || 0))
    if (seconds % 60 === 0) return String(seconds / 60) + "m"
    return String(seconds) + "s"
  }

  function shellIdleScreensaverName() { return secondsName(root.shellIdleScreensaver) }
  function shellIdleLockName() { return secondsName(root.shellIdleLock) }

  function backgroundEffectsEnabled() {
    return !root.backgroundEffects || root.backgroundEffects.enabled !== false
  }

  function backgroundEffectEnabled(effectId) {
    var effects = root.backgroundEffects && root.backgroundEffects.effects ? root.backgroundEffects.effects : ({})
    var effect = effects[String(effectId || "")]
    if (!effect || typeof effect !== "object") return false
    return backgroundEffectsEnabled() && effect.enabled !== false
  }

  function backgroundEffectName(effectId) {
    if (effectId === "trackingLines") return "Tracking Lines"
    return "Background Effect"
  }

  function backgroundEffectHint(effectId) {
    if (effectId === "trackingLines") {
      return backgroundEffectEnabled(effectId) ? "Animated wallpaper tracking lines are visible" : "Animated wallpaper tracking lines are hidden"
    }
    return backgroundEffectEnabled(effectId) ? "Effect is visible" : "Effect is hidden"
  }

  function shellPluginEnabled(id) {
    var plugins = Array.isArray(root.shellPlugins) ? root.shellPlugins : []
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i] && String(plugins[i].id || "") === String(id || "")) return true
    }
    return false
  }

  function installedShellPluginRows() {
    if (!root.pluginRegistry || !root.pluginRegistry.installedPlugins) return []
    var plugins = root.pluginRegistry.installedPlugins
    var rows = []
    for (var id in plugins) {
      var manifest = plugins[id]
      if (!manifest || manifest.__isFirstParty) continue
      if (id === "omarchy.lacuna-menu") continue
      rows.push({
        id: id,
        name: manifest.name || id,
        description: manifest.description || id,
        enabled: shellPluginEnabled(id)
      })
    }
    rows.sort(function(a, b) { return a.name.localeCompare(b.name) })
    return rows
  }

  readonly property var builtinWidgetMeta: ({
    "omarchy": { name: "Omarchy menu", description: "Launches the Omarchy menu", category: "Compositor" },
    "workspaces": { name: "Workspaces", description: "Workspace number indicators", category: "Compositor" },
    "clock": { name: "Clock", description: "Date and time text", category: "Time" },
    "update": { name: "Updates", description: "Indicates available system updates", category: "System" },
    "voxtype": { name: "Voxtype", description: "Voxtype dictation state", category: "Status" },
    "screenRecording": { name: "Screen recording", description: "Active recording indicator", category: "Status" },
    "notifications": { name: "DND", description: "Do-not-disturb indicator", category: "Status" },
    "tray": { name: "System tray", description: "Status notifier items", category: "Status" }
  })

  function canonicalWidgetId(id) {
    switch (String(id || "")) {
    case "idle": return "idleInhibitor"
    case "weatherFlyout": return "weather"
    default: return String(id || "")
    }
  }

  function shellBarWidgetMetadata(id) {
    var key = String(id || "")
    var canonicalKey = canonicalWidgetId(key)
    if (root.barWidgetRegistry && root.barWidgetRegistry.has(canonicalKey)) return root.barWidgetRegistry.metadataFor(canonicalKey) || {}
    if (builtinWidgetMeta[canonicalKey]) return builtinWidgetMeta[canonicalKey]

    var manifest = root.pluginRegistry && root.pluginRegistry.installedPlugins ? root.pluginRegistry.installedPlugins[key] : null
    if (manifest) {
      var meta = manifest.barWidget || {}
      return {
        displayName: meta.displayName || manifest.name || key,
        name: meta.displayName || manifest.name || key,
        description: meta.description || manifest.description || "",
        category: meta.category || "Plugin",
        allowMultiple: meta.allowMultiple === true,
        source: "plugin"
      }
    }

    return {}
  }

  function shellBarWidgetName(id) {
    var rev = root.catalogRevision
    var meta = shellBarWidgetMetadata(id)
    return meta.displayName || meta.name || String(id || "")
  }

  function shellBarWidgetDescription(id) {
    var rev = root.catalogRevision
    var meta = shellBarWidgetMetadata(id)
    return meta.description || ""
  }

  function shellBarWidgetAllowsMultiple(id) {
    var meta = shellBarWidgetMetadata(id)
    if (meta.allowMultiple === true) return true
    return String(id || "") === "spacer"
  }

  function shellBarWidgetIcon(id) {
    var key = canonicalWidgetId(id)
    if (key === "calendar" || key === "clock") return "clock"
    if (key === "weather") return "world"
    if (key === "update") return "refresh"
    if (key === "tray") return "apps"
    if (key === "bluetoothPanel") return "bluetooth"
    if (key === "networkPanel") return "wifi"
    if (key === "audioPanel" || key === "microphone") return "volume"
    if (key === "monitorPanel") return "photo"
    if (key === "powerPanel") return "power"
    if (key === "screenRecording") return "video"
    if (key === "idleInhibitor") return "moon"
    if (key === "omarchy") return "lacuna"
    if (key === "workspaces") return "apps"
    return "settings"
  }

  function shellBarCatalogIds() {
    var rev = root.catalogRevision
    var ids = {}
    if (root.barWidgetRegistry) {
      var registered = root.barWidgetRegistry.availableIds()
      for (var i = 0; i < registered.length; i++) ids[registered[i]] = true
    }
    if (root.pluginRegistry && root.pluginRegistry.installedPlugins) {
      var plugins = root.pluginRegistry.installedPlugins
      for (var pid in plugins) {
        var manifest = plugins[pid]
        if (manifest && Array.isArray(manifest.kinds) && manifest.kinds.indexOf("bar-widget") !== -1) ids[pid] = true
      }
    }
    for (var key in builtinWidgetMeta) ids[key] = true
    return Object.keys(ids)
  }

  function shellBarWidgetExistsAnywhere(id) {
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var list = shellBarLayoutSection(sections[s])
      for (var i = 0; i < list.length; i++) {
        if (list[i] && String(list[i].id || "") === String(id || "")) return true
      }
    }
    return false
  }

  function availableShellBarWidgets(section) {
    var ids = shellBarCatalogIds().sort(function(a, b) {
      return shellBarWidgetName(a).localeCompare(shellBarWidgetName(b))
    })
    var result = []
    for (var i = 0; i < ids.length; i++) {
      var id = ids[i]
      if (!shellBarWidgetAllowsMultiple(id) && shellBarWidgetExistsAnywhere(id)) continue
      result.push({
        id: id,
        name: shellBarWidgetName(id),
        description: shellBarWidgetDescription(id)
      })
    }
    return result
  }

  function anchorHorizontal() {
    if (root.desktopClockAnchor.indexOf("left") !== -1) return "left"
    if (root.desktopClockAnchor.indexOf("right") !== -1) return "right"
    return "center"
  }

  function anchorVertical() {
    if (root.desktopClockAnchor.indexOf("top") !== -1) return "top"
    if (root.desktopClockAnchor.indexOf("bottom") !== -1) return "bottom"
    return "center"
  }

  function clockPositionHint() {
    return root.desktopClockAnchor + "  x " + root.desktopClockOffsetX + "  y " + root.desktopClockOffsetY
  }

  function clockFormatHint() {
    return root.desktopClockUse12Hour ? "12-hour time" : "24-hour time"
  }

  function clockScaleHint() {
    return Math.round(root.desktopClockScale * 100) + "%"
  }

  function controlsLayoutName() {
    return root.controlsLayout === "list" ? "List" : "Grid"
  }

  function shellSettingsSurfaceName() {
    return root.shellSettingsSurface === "window" ? "Window" : "Flyout"
  }

  function shellSettingsSurfaceHint() {
    return root.shellSettingsSurface === "window" ? "Open Omarchy shell settings as a separate floating window" : "Attach Omarchy shell settings to the Lacuna sidebar"
  }

  function layoutOptions() {
    return [
      { value: "grid", icon: "layout-grid" },
      { value: "list", icon: "list" }
    ]
  }

  function quickLaunchHeader() {
    var header = entries.header("Quick Launch", "nav", "quick-launch")
    header.optionValue = root.quickLaunchLayout === "grid" ? "grid" : "list"
    header.optionActionPrefix = "set-quick-launch-layout-"
    header.options = layoutOptions()
    header.headerAction = "open-custom-quick-launch-picker"
    header.headerActionIcon = "plus"
    header.headerActionTooltip = "Add Quick Launch App"
    return header
  }

  function dailyLaunchHeader() {
    var header = entries.header("Daily Launch", "lacuna", "launch")
    header.optionValue = root.dailyLaunchLayout === "grid" ? "grid" : "list"
    header.optionActionPrefix = "set-daily-launch-layout-"
    header.options = layoutOptions()
    return header
  }

  function controlsHeader() {
    var header = entries.header("Controls", "session", "controls")
    header.optionValue = root.controlsLayout === "list" ? "list" : "grid"
    header.optionActionPrefix = "set-controls-layout-"
    header.options = layoutOptions()
    return header
  }

  function dailyLaunchEntries() {
    return preferredAppItems("normal").concat([
      entries.command({ icon: "terminal", label: "Terminal", hint: "Open a terminal", command: openTerminalCommand(), tone: "nav", priority: "normal", group: "launch" }),
      entries.command({ icon: "world", label: "Browser", hint: "Launch browser", command: "omarchy launch browser", tone: "nav", priority: "normal", group: "launch" })
    ])
  }

  function dailyLaunchItems() {
    var rows = [dailyLaunchHeader()]
    var launchers = dailyLaunchEntries()
    if (root.dailyLaunchLayout === "grid") {
      rows.push(entries.grid("lacuna", launchers))
      return rows
    }
    return rows.concat(launchers)
  }

  function quickLaunchItems() {
    var rows = [quickLaunchHeader()]
    var launchers = customQuickLaunchItems()

    if (root.quickLaunchLayout === "grid") {
      rows.push(entries.grid("nav", launchers))
      return rows
    }

    return rows.concat(launchers)
  }

  function controlEntries() {
    return [
      entries.command({ icon: "wifi", label: "Wi-Fi", hint: "Open Wi-Fi controls", command: shellIpcCommand("panels.network", "toggle"), tone: "session", priority: "normal", group: "controls" }),
      entries.command({ icon: "bluetooth", label: "Bluetooth", hint: "Open Bluetooth controls", command: shellIpcCommand("panels.bluetooth", "toggle"), tone: "session", priority: "normal", group: "controls" }),
      entries.command({ icon: "volume", label: "Audio", hint: "Open audio mixer", command: shellIpcCommand("panels.audio", "toggle"), tone: "session", priority: "normal", group: "controls" }),
      entries.command({ icon: "camera", label: "Screenshot", hint: "Capture screen or region", command: "omarchy-capture-screenshot", tone: "session", priority: "normal", group: "controls" }),
      entries.action({ icon: "video", label: "Record", hint: "Choose screen recording mode", action: "open-screenrecord-menu", tone: "session", priority: "normal", group: "controls" }),
      entries.command({ icon: "idle", label: "Idle", hint: "Toggle idle behavior", command: "omarchy toggle idle", tone: "session", priority: "normal", group: "controls" })
    ]
  }

  function appSettingsLinks() {
    return [
      entries.action({ icon: "palette", label: "Appearance Settings", hint: designStyleHint(), action: "open-settings-section-appearance", tone: "lacuna", group: "customize" }),
      entries.action({ icon: root.compact ? "density-compact" : "density-normal", label: "Layout Settings", hint: barSizeModeHint(), action: "open-settings-section-layout", tone: "lacuna", group: "customize" }),
      entries.action({ icon: "clock", label: "Clock Settings", hint: clockPositionHint(), action: "open-settings-section-desktop-clock", tone: "lacuna", group: "customize" }),
      entries.action({ icon: "settings", label: "Runtime Tools", hint: "Logs, reloads, and source shortcuts", action: "open-settings-section-runtime", tone: "shell", group: "customize" })
    ]
  }

  function appsViewItems() {
    var rows = [entries.header("Categories", "lacuna", "apps")]
    var cats = categories()
    for (var c = 0; c < cats.length; c++) {
      var meta = cats[c]
      if (appModel.appCount(meta.id) > 0 || meta.id === "games") rows.push(appModel.categoryItem(meta))
    }
    rows.push(entries.header("Fallback", "shell", "apps"))
    rows.push(entries.nav({ icon: "apps", label: "All Apps", view: "apps-all", tone: "nav", group: "apps" }))
    rows.push(entries.action({ icon: "refresh", label: "Reload app catalog", action: "reload-apps", tone: "shell", priority: "normal", group: "apps" }))
    rows.push(entries.command({ icon: "search", label: "Open Walker", command: "walker -p 'Launch...'", tone: "shell", priority: "normal", group: "apps" }))
    return rows
  }

  function controlsItems() {
    var rows = [
      controlsHeader()
    ]

    var controls = controlEntries()
    if (root.controlsLayout === "list") return rows.concat(controls)

    rows.push(entries.grid("session", controls))
    return rows
  }

  function customizeItems() {
    return [
      entries.header("Customize", "shell", "customize"),
      entries.command({ icon: "photo", label: "Wallpaper Catalog", hint: "Open wallpaper picker", command: "jobowalls-gui", tone: "shell", group: "customize" }),
      entries.command({ icon: "palette", label: "Theme", hint: "Switch Omarchy theme", command: switchThemeCommand(), tone: "shell", group: "customize" }),
      entries.command({ icon: "background", label: "Background", hint: "Switch theme background", command: switchBackgroundCommand(), tone: "shell", group: "customize" }),
      entries.header("Lacuna Settings", "lacuna", "customize")
    ].concat(appSettingsLinks())
  }

  function systemItems() {
    return [
      entries.header("Session", "session", "session"),
      entries.command({ icon: "moon", label: "Screensaver", hint: "Start screensaver now", command: "omarchy-launch-screensaver force", tone: "session", priority: "normal", group: "session" }),
      entries.command({ icon: "lock", label: "Lock", hint: "Lock session", command: "omarchy-system-lock", tone: "session", group: "session" }),
      entries.command({ icon: "logout", label: "Logout", hint: "End session", command: "omarchy-system-logout", tone: "session", priority: "normal", group: "session" }),
      entries.header("Power", "danger", "power"),
      entries.action({ icon: "refresh", label: "Restart", hint: root.instantRestart ? "Reboot machine immediately" : "Confirm before rebooting machine", action: "confirm-system-restart", tone: "danger", priority: "normal", danger: true, group: "power" }),
      entries.command({ icon: "power", label: "Shutdown", hint: "Power off machine", command: "omarchy-system-shutdown", tone: "danger", danger: true, group: "power" })
    ]
  }

  function lacunaSettingsShortcutItems() {
    return [
      entries.header("Lacuna Settings", "lacuna", "lacuna")
    ].concat(appSettingsLinks()).concat([
      entries.header("Source", "shell", "source"),
      entries.command({ icon: "refresh", label: "Restart shell", hint: "Reload Omarchy shell", command: restartLacunaCommand(), tone: "shell", group: "source" }),
      entries.command({ icon: "edit", label: "Open plugin source", hint: "Edit the Lacuna plugin repository", command: editPluginCommand(), tone: "shell", group: "source" })
    ])
  }

  function mainItems() {
    var rows = quickLaunchItems().concat(dailyLaunchItems()).concat([
      entries.header("Shortcuts", "nav", "shortcuts"),
      entries.nav({ icon: "apps", label: "Apps", hint: "Browse categorized launchers", view: "apps", tone: "nav", group: "apps" }),
      entries.nav({ icon: "palette", label: "Customize", hint: "Theme, background, and Lacuna settings", view: "customize", tone: "shell", group: "customize" }),
      entries.nav({ icon: "power", label: "System", hint: "Lock, logout, restart, shutdown", view: "system", tone: "session", group: "session" })
    ]).concat(controlsItems())

    return rows
  }

  function railItems() {
    return [
      entries.nav({ icon: "apps", label: "Apps", hint: "Browse categorized launchers", view: "apps", tone: "nav", group: "apps" }),
      entries.nav({ icon: "controls", label: "Controls", hint: "Wi-Fi, audio, capture, and idle controls", view: "controls", tone: "session", group: "controls" }),
      entries.nav({ icon: "palette", label: "Customize", hint: "Theme, background, and Lacuna settings", view: "customize", tone: "shell", group: "customize" }),
      entries.nav({ icon: "power", label: "System", hint: "Lock, logout, restart, shutdown", view: "system", tone: "session", group: "session" })
    ].concat(customQuickLaunchItems()).concat([
      entries.command({ icon: "terminal", label: "Terminal", hint: "Open a terminal", command: openTerminalCommand(), tone: "nav", priority: "normal", group: "launch" }),
      entries.command({ icon: "world", label: "Browser", hint: "Launch browser", command: "omarchy launch browser", tone: "nav", priority: "normal", group: "launch" })
    ])
  }

  function sidebarDisplayMode() {
    return root.sidebarCollapsed ? "rail" : "full"
  }

  function sidebarDisplayName() {
    return root.sidebarCollapsed ? "Icon Rail" : "Full"
  }

  function sidebarDisplayHint() {
    return root.sidebarCollapsed ? "Only show the icon rail" : "Show the full sidebar surface"
  }

  function sidebarDefaultModeName() {
    if (root.sidebarDefaultMode === "rail") return "Rail"
    if (root.sidebarDefaultMode === "full") return "Full"
    return "Off"
  }

  function sidebarDefaultModeHint() {
    if (root.sidebarDefaultMode === "rail") return "Return to the icon rail after actions and shell restart"
    if (root.sidebarDefaultMode === "full") return "Return to the full sidebar after actions and shell restart"
    return "Close the sidebar after actions and shell restart"
  }

  function itemsFor(view) {
    if (view === "apps") return appsViewItems()
    if (view === "apps-all") return appItems("all")
    if (view.indexOf("apps-") === 0) return appItems(view.substring(5))
    if (view === "controls") return controlsItems()
    if (view === "customize") return customizeItems()
    if (view === "system") return systemItems()
    if (view === "lacuna" || view === "lacuna-shell" || view === "lacuna-preferences" || view === "lacuna-clock" || view === "lacuna-preferred-apps") return lacunaSettingsShortcutItems()
    return mainItems()
  }

  MenuEntryFactory {
    id: entries
  }

  MenuCommandCatalog {
    id: commands
    lacunaPath: root.lacunaPath
  }

  MenuAppModel {
    id: appModel
    appCatalog: root.appCatalog
    customQuickLaunchApps: root.customQuickLaunchApps
    customQuickLaunchNames: root.customQuickLaunchNames
    preferredApps: root.preferredApps
    entries: entries
    commands: commands
  }
}
