import Quickshell
import QtQuick

Item {
  id: root

  property string lacunaPath: ""
  property bool sidebarExclusive: true
  property bool sidebarCollapsed: false
  property bool sidebarCornerPieces: true
  property bool compact: false
  property string designStyle: "carbon"
  property string colorProfile: "semantic"
  property var appCatalog: null
  property var quickLaunch: []
  property var appDefaults: ({})

  function item(kind, icon, label, hint, view, command, tone, priority, layout, danger, group, action, iconSource, switchVisible, switchChecked) {
    return {
      kind: kind,
      icon: icon,
      iconSource: iconSource || "",
      label: label,
      hint: hint,
      view: view,
      command: command,
      action: action || "",
      tone: tone || (kind === "header" ? "section" : "nav"),
      priority: priority || "normal",
      layout: layout || (kind === "header" ? "section" : "row"),
      danger: danger || tone === "danger",
      group: group || "",
      switchVisible: switchVisible === true,
      switchChecked: switchChecked === true,
      badgeText: "",
      trailingAction: "",
      trailingIcon: "",
      trailingTooltip: "",
      appId: ""
    }
  }

  function designStyleControl(group) {
    return {
      kind: "item",
      icon: "palette",
      iconSource: "",
      label: "Design",
      hint: designStyleName(),
      view: "",
      command: "",
      action: "",
      tone: "lacuna",
      priority: "normal",
      layout: "design-style-control",
      danger: false,
      group: group || "lacuna",
      switchVisible: false,
      switchChecked: false,
      optionValue: root.designStyle,
      options: [
        { value: "carbon", label: "Carbon" },
        { value: "omarchy", label: "Omarchy" },
        { value: "material", label: "Material" }
      ]
    }
  }

  function titleFor(view) {
    if (view === "main") return "Lacuna"
    if (view === "lacuna") return "Lacuna"
    if (view === "customize") return "Customize"
    if (view === "lacuna-shell") return "Runtime"
    if (view === "lacuna-preferences") return "Layout"
    if (view === "lacuna-app-defaults") return "App Defaults"
    if (view === "system") return "System"
    if (view === "apps") return "Apps"
    if (view === "apps-all") return "All Apps"
    if (view.indexOf("apps-") === 0) return categoryTitle(view.substring(5))
    return "Utility Sidebar"
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function shellDoubleQuote(value) {
    return "\"" + String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$").replace(/`/g, "\\`") + "\""
  }

  function hyprExec(command) {
    return "hyprctl dispatch " + shellDoubleQuote("hl.dsp.exec_cmd([[" + command + "]])")
  }

  function terminalCommand(command, title, holdOpen) {
    var terminalBody = command
    if (holdOpen) {
      terminalBody = command + "; status=$?; printf '\\nCommand exited with status %s. Press Enter to close...' \"$status\"; read -r _; exit \"$status\""
    }
    return "foot --app-id=org.omarchy.terminal --title=" + shellQuote(title || "Lacuna") + " -e bash -lc " + shellQuote(terminalBody)
  }

  function openTerminalCommand() {
    return hyprExec("omarchy launch terminal")
  }

  function updateLacunaCommand() {
    return terminalCommand("echo 'Lacuna plugin updates are managed from the plugin repository.'", "Lacuna Plugin", true)
  }

  function restartLacunaCommand() {
    return "omarchy restart shell"
  }

  function openLogCommand() {
    return terminalCommand("quickshell log --path " + shellQuote(omarchyShellPath()) + " --tail 200 --newest", "Omarchy Shell Log", false)
  }

  function editPluginCommand() {
    return terminalCommand("cd " + shellQuote(root.lacunaPath) + " && ${EDITOR:-nvim} .", "Lacuna Plugin", false)
  }

  function omarchyShellPath() {
    var omarchyPath = Quickshell.env("OMARCHY_PATH") || ((Quickshell.env("HOME") || "") + "/.local/share/omarchy")
    return omarchyPath + "/default/quickshell/omarchy-shell"
  }

  function switchThemeCommand() {
    return "theme=$(omarchy theme switcher); [ -n \"$theme\" ] && omarchy theme set \"$theme\""
  }

  function switchBackgroundCommand() {
    return "background=$(omarchy theme bg-switcher); [ -n \"$background\" ] && omarchy theme bg set \"$background\""
  }

  function categories() {
    return [
      { id: "games", label: "Games", icon: "gamepad", tone: "lacuna" },
      { id: "internet", label: "Internet", icon: "world", tone: "nav" },
      { id: "development", label: "Development", icon: "code", tone: "shell" },
      { id: "media", label: "Media", icon: "music", tone: "session" },
      { id: "graphics", label: "Graphics", icon: "palette", tone: "shell" },
      { id: "office", label: "Office", icon: "file-text", tone: "nav" },
      { id: "system", label: "System", icon: "settings", tone: "session" },
      { id: "utilities", label: "Utilities", icon: "tool", tone: "nav" },
      { id: "other", label: "Other", icon: "dots", tone: "nav" }
    ]
  }

  function categoryMeta(category) {
    var all = categories()
    for (var i = 0; i < all.length; i++) {
      if (all[i].id === category) return all[i]
    }
    return { id: category, label: "Apps", icon: "apps", tone: "nav" }
  }

  function categoryTitle(category) {
    return categoryMeta(category).label
  }

  function designStyleName() {
    if (root.designStyle === "omarchy") return "Omarchy"
    if (root.designStyle === "material") return "Material"
    return "Carbon"
  }

  function designStyleHint() {
    if (root.designStyle === "omarchy") return "Native Omarchy borders and containment"
    if (root.designStyle === "material") return "Softer tonal surfaces and clearer states"
    return "Flat compact Lacuna linework"
  }

  function appCount(category) {
    return root.appCatalog ? root.appCatalog.countFor(category) : 0
  }

  function categoryLabel(meta) {
    return meta.label
  }

  function categoryItem(meta) {
    var row = item("item", meta.icon, categoryLabel(meta), "", "apps-" + meta.id, "", meta.tone, "primary", "row", false, "apps")
    var count = appCount(meta.id)
    row.badgeText = count > 0 ? String(count) : ""
    return row
  }

  function appIcon(app) {
    if (app.category === "games") return "gamepad"
    if (app.category === "internet") return "world"
    if (app.category === "development") return "code"
    if (app.category === "media") return "music"
    if (app.category === "graphics") return "palette"
    if (app.category === "office") return "file-text"
    if (app.category === "system") return "settings"
    return "apps"
  }

  function appIconSource(app) {
    var icon = String(app.Icon || "").trim()
    if (icon === "") return ""
    if (icon.indexOf("file://") === 0) return icon
    if (icon.indexOf("/") === 0) return "file://" + encodeURI(icon)
    return "image://icon/" + icon
  }

  function appEntry(app, quickAdd) {
    var row = item("item", appIcon(app), app.Name, app.Comment || app.GenericName, "", "gtk-launch " + shellQuote(app.id), categoryMeta(app.category).tone, "primary", "row", false, "apps", "", appIconSource(app))
    row.appId = app.id
    if (quickAdd) {
      row.trailingAction = "add-quicklaunch"
      row.trailingIcon = quickLaunchContains(app.id) ? "check" : "plus"
      row.trailingTooltip = quickLaunchContains(app.id) ? "Already in quick launch" : "Add to quick launch"
    }
    return row
  }

  function quickLaunchContains(id) {
    var ids = root.quickLaunch || []
    for (var i = 0; i < ids.length; i++) {
      if (String(ids[i]) === String(id)) return true
    }
    return false
  }

  function roleMeta(role) {
    if (role === "files") return { label: "Files", icon: "folder", tone: "nav", systemHint: "System default" }
    if (role === "editor") return { label: "Editor", icon: "edit", tone: "shell", systemHint: "System editor" }
    if (role === "email") return { label: "Email", icon: "mail", tone: "nav", systemHint: "System email" }
    if (role === "discord") return { label: "Discord", icon: "message", tone: "session", systemHint: "Detected Discord app" }
    return { label: "App", icon: "apps", tone: "nav", systemHint: "System default" }
  }

  function appDefaultValue(role) {
    if (!root.appDefaults || typeof root.appDefaults !== "object") return "system"
    var value = String(root.appDefaults[role] || "").trim()
    return value === "" ? "system" : value
  }

  function detectedDiscordApp() {
    var ids = ["Discord", "vesktop"]
    if (!root.appCatalog || !root.appCatalog.ready) return ""

    for (var i = 0; i < ids.length; i++) {
      if (root.appCatalog.appById(ids[i])) return ids[i]
    }

    return ""
  }

  function appName(id) {
    if (!root.appCatalog || !root.appCatalog.ready || !id) return ""
    var app = root.appCatalog.appById(id)
    return app ? app.Name : ""
  }

  function appDefaultHint(role) {
    var value = appDefaultValue(role)
    var meta = roleMeta(role)
    if (value === "system") {
      if (role === "discord") {
        var detected = detectedDiscordApp()
        return detected ? "System: " + (appName(detected) || detected) : "System: Discord web app"
      }
      return meta.systemHint
    }

    return "Manual: " + (appName(value) || value)
  }

  function appLaunchCommand(id) {
    return hyprExec("gtk-launch " + shellQuote(id))
  }

  function roleCommand(role) {
    var value = appDefaultValue(role)
    if (value !== "system") return appLaunchCommand(value)

    if (role === "files") return hyprExec("omarchy launch nautilus")
    if (role === "editor") return hyprExec("omarchy launch editor")
    if (role === "email") return hyprExec("xdg-open mailto:")
    if (role === "discord") {
      var detected = detectedDiscordApp()
      if (detected) return appLaunchCommand(detected)
      return hyprExec("omarchy launch webapp https://discord.com/channels/@me")
    }

    return ""
  }

  function roleEntry(role, priority) {
    var meta = roleMeta(role)
    return item("item", meta.icon, meta.label, appDefaultHint(role), "", roleCommand(role), meta.tone, priority || "primary", "row", false, "launch")
  }

  function roleSettingsItem(role) {
    var meta = roleMeta(role)
    return item("item", meta.icon, meta.label, appDefaultHint(role), "", "", meta.tone, "primary", "row", false, "app-defaults", "choose-app-default-" + role)
  }

  function quickLaunchItems() {
    var rows = []
    var ids = root.quickLaunch || []
    if (!root.appCatalog || !root.appCatalog.ready) return rows

    for (var i = 0; i < ids.length; i++) {
      var id = String(ids[i] || "")
      if (id.indexOf("role:") === 0) {
        rows.push(roleEntry(id.substring(5), "primary"))
        continue
      }

      var app = root.appCatalog.appById(id)
      if (app) rows.push(appEntry(app, false))
    }

    return rows
  }

  function appItems(category) {
    var source = root.appCatalog ? root.appCatalog.appsFor(category) : []
    var rows = []

    if (!root.appCatalog || !root.appCatalog.ready) {
      return [
        item("header", "", "Loading", "", "", "", "nav"),
        item("item", "󰑐", "Scanning apps", "", "", "", "nav", "primary", "row")
      ]
    }

    if (source.length === 0) {
      return [
        item("header", "", "Empty", "", "", "", "nav"),
        item("item", "apps", "No apps found", "", "", "", "nav", "primary", "row")
      ]
    }

    rows.push(item("header", "", category === "all" ? "Applications" : categoryTitle(category), "", "", "", "nav"))
    for (var i = 0; i < source.length; i++) {
      var app = source[i]
      rows.push(appEntry(app, true))
    }
    return rows
  }

  function railItems() {
    return [
      item("item", "lacuna", "Lacuna", "Runtime and layout controls", "lacuna", "", "lacuna", "primary", "row", false, "lacuna"),
      item("item", "apps", "Apps", "Browse categorized launchers", "apps", "", "nav", "primary", "row", false, "apps"),
      item("item", "palette", "Customize", "Theme, background, and wallpaper tools", "customize", "", "shell", "primary", "row", false, "customize"),
      item("item", "power", "System", "Lock, logout, restart, shutdown", "system", "", "session", "primary", "row", false, "session")
    ].concat(quickLaunchItems()).concat([
      item("item", "terminal", "Terminal", "Open a terminal", "", openTerminalCommand(), "nav", "normal", "row", false, "launch"),
      item("item", "world", "Browser", "Launch browser", "", "omarchy launch browser", "nav", "normal", "row", false, "launch")
    ])
  }

  function itemsFor(view) {
    if (view === "apps") {
      var rows = [item("header", "", "Categories", "", "", "", "lacuna", "normal", "section", false, "apps")]
      var cats = categories()
      for (var c = 0; c < cats.length; c++) {
        var meta = cats[c]
        if (appCount(meta.id) > 0 || meta.id === "games") {
          rows.push(categoryItem(meta))
        }
      }
      rows.push(item("header", "", "Fallback", "", "", "", "shell"))
      rows.push(item("item", "apps", "All Apps", "", "apps-all", "", "nav", "primary", "row", false, "apps"))
      rows.push(item("item", "refresh", "Reload app catalog", "", "", "", "shell", "normal", "row", false, "apps", "reload-apps"))
      rows.push(item("item", "search", "Open Walker", "", "", "walker -p 'Launch…'", "shell", "normal", "row", false, "apps"))
      return rows
    }

    if (view === "apps-all") {
      return appItems("all")
    }

    if (view.indexOf("apps-") === 0) {
      return appItems(view.substring(5))
    }

    if (view === "lacuna") {
      return [
        item("header", "", "Settings", "", "", "", "lacuna", "normal", "section", false, "lacuna"),
        item("item", "settings", "Runtime", "Commands, logs, and diagnostics", "lacuna-shell", "", "lacuna", "primary", "row", false, "lacuna"),
        item("item", "density-normal", "Layout", "Density, sidebar, and surface behavior", "lacuna-preferences", "", "lacuna", "primary", "row", false, "lacuna"),
        item("header", "", "Source", "", "", "", "shell"),
        item("item", "refresh", "Restart shell", "Reload Omarchy shell", "", restartLacunaCommand(), "shell"),
        item("item", "edit", "Open plugin source", "Edit the Lacuna plugin repository", "", editPluginCommand(), "shell")
      ]
    }

    if (view === "lacuna-shell") {
      return [
        item("header", "", "Runtime", "", "", "", "shell", "normal", "section", false, "shell"),
        item("item", "refresh", "Restart shell", "Restart Omarchy shell", "", restartLacunaCommand(), "shell", "primary", "row", false, "shell"),
        item("item", "file-search", "Open log", "View the current Lacuna log", "", openLogCommand(), "shell"),
        item("item", "edit", "Edit plugin", "Open Lacuna plugin source", "", editPluginCommand(), "lacuna")
      ]
    }

    if (view === "lacuna-preferences") {
      return [
        item("header", "", "Layout", "", "", "", "lacuna", "normal", "section", false, "lacuna"),
        designStyleControl("lacuna"),
        item("item", "list-check", "App Defaults", "Files, editor, email, and Discord launch targets", "lacuna-app-defaults", "", "lacuna", "primary", "row", false, "lacuna"),
        item("item", "color-swatch", root.colorProfile === "colorful" ? "Colorful Profile" : "Semantic Profile", root.colorProfile === "colorful" ? "Use theme colors across Lacuna topbar modules" : "Use foreground with semantic colors only", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-color-profile", "", true, root.colorProfile === "colorful"),
        item("item", root.compact ? "density-compact" : "density-normal", root.compact ? "Compact Density" : "Normal Density", root.compact ? "Use tighter Lacuna UI spacing" : "Use standard Lacuna UI spacing", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-bar-density", "", true, root.compact),
        item("item", root.sidebarCollapsed ? "sidebar-expand" : "sidebar-collapse", root.sidebarCollapsed ? "Icon Rail" : "Full Sidebar", root.sidebarCollapsed ? "Show the compact icon rail" : "Show the full sidebar surface", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-sidebar-rail", "", true, root.sidebarCollapsed),
        item("item", "sidebar-overlay", root.sidebarExclusive ? "Sidebar Overlay" : "Sidebar Docked", root.sidebarExclusive ? "Let the sidebar float over windows" : "Reserve screen space for the sidebar", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-sidebar-mode", "", true, root.sidebarExclusive),
        item("item", "corners", root.sidebarCornerPieces ? "Corner Pieces" : "Flat Edge", root.sidebarCornerPieces ? "Show the rounded connector pieces" : "Hide the rounded connector pieces", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-corner-pieces", "", true, root.sidebarCornerPieces),
        item("item", "refresh", "Reload app catalog", "Rescan desktop launchers", "", "", "shell", "normal", "row", false, "apps", "reload-apps")
      ]
    }

    if (view === "lacuna-app-defaults") {
      return [
        item("header", "", "App Defaults", "", "", "", "lacuna", "normal", "section", false, "app-defaults"),
        roleSettingsItem("files"),
        roleSettingsItem("editor"),
        roleSettingsItem("email"),
        roleSettingsItem("discord")
      ]
    }

    if (view === "customize") {
      return [
        item("header", "", "Customize", "", "", "", "shell", "normal", "section", false, "customize"),
        item("item", "photo", "Wallpaper Catalog", "Open wallpaper picker", "", "jobowalls-gui", "shell", "primary", "row", false, "customize"),
        item("item", "palette", "Theme", "Switch Omarchy theme", "", switchThemeCommand(), "shell", "primary", "row", false, "customize"),
        item("item", "background", "Background", "Switch theme background", "", switchBackgroundCommand(), "shell", "primary", "row", false, "customize"),
        item("header", "", "Layout", "", "", "", "lacuna", "normal", "section", false, "layout"),
        designStyleControl("layout"),
        item("item", "color-swatch", root.colorProfile === "colorful" ? "Colorful Profile" : "Semantic Profile", root.colorProfile === "colorful" ? "Use theme colors across Lacuna topbar modules" : "Use foreground with semantic colors only", "", "", "lacuna", "normal", "row", false, "layout", "toggle-color-profile", "", true, root.colorProfile === "colorful"),
        item("item", root.compact ? "density-compact" : "density-normal", root.compact ? "Compact Density" : "Normal Density", root.compact ? "Use tighter Lacuna UI spacing" : "Use standard Lacuna UI spacing", "", "", "lacuna", "normal", "row", false, "layout", "toggle-bar-density", "", true, root.compact),
        item("item", root.sidebarCollapsed ? "sidebar-expand" : "sidebar-collapse", root.sidebarCollapsed ? "Icon Rail" : "Full Sidebar", root.sidebarCollapsed ? "Show the compact icon rail" : "Show the full sidebar surface", "", "", "lacuna", "normal", "row", false, "layout", "toggle-sidebar-rail", "", true, root.sidebarCollapsed),
        item("item", "sidebar-overlay", root.sidebarExclusive ? "Sidebar Overlay" : "Sidebar Docked", root.sidebarExclusive ? "Let the sidebar float over windows" : "Reserve screen space for the sidebar", "", "", "lacuna", "normal", "row", false, "layout", "toggle-sidebar-mode", "", true, root.sidebarExclusive),
        item("item", "corners", root.sidebarCornerPieces ? "Corner Pieces" : "Flat Edge", root.sidebarCornerPieces ? "Show the rounded connector pieces" : "Hide the rounded connector pieces", "", "", "lacuna", "normal", "row", false, "layout", "toggle-corner-pieces", "", true, root.sidebarCornerPieces)
      ]
    }

    if (view === "system") {
      return [
        item("header", "", "Session", "", "", "", "session", "normal", "section", false, "session"),
        item("item", "moon", "Screensaver", "Start screensaver now", "", "omarchy-launch-screensaver force", "session"),
        item("item", "lock", "Lock", "Lock session", "", "omarchy-system-lock", "session", "primary", "row", false, "session"),
        item("item", "logout", "Logout", "End session", "", "omarchy-system-logout", "session"),
        item("header", "", "Power", "", "", "", "danger", "normal", "section", true, "power"),
        item("item", "refresh", "Restart", "Reboot machine", "", "omarchy-system-reboot", "danger", "normal", "row", true, "power"),
        item("item", "power", "Shutdown", "Power off machine", "", "omarchy-system-shutdown", "danger", "primary", "row", true, "power")
      ]
    }

    return [
      item("header", "", "Lacuna", "", "", "", "lacuna", "normal", "section", false, "lacuna"),
      item("item", "apps", "Apps", "Browse categorized launchers", "apps", "", "nav", "primary", "featured"),
      item("item", "palette", "Customize", "Theme, background, and wallpaper tools", "customize", "", "shell", "primary", "featured", false, "customize"),
      item("item", "power", "System", "Lock, logout, restart, shutdown", "system", "", "session", "primary", "featured", false, "session"),
      item("header", "", "Launch", "", "", "", "nav"),
      item("item", "plus", "Add quick launch", "Pick an app for this section", "", "", "lacuna", "primary", "row", false, "launch", "open-quicklaunch-picker")
    ].concat(quickLaunchItems()).concat([
      item("item", "terminal", "Terminal", "Open a terminal", "", openTerminalCommand(), "nav", "primary", "row"),
      item("item", "world", "Browser", "Launch browser", "", "omarchy launch browser", "nav", "primary", "row"),
      item("header", "", "System Tools", "", "", "", "session"),
      item("item", "wifi", "Wi-Fi", "Open Wi-Fi controls", "", "hyprctl dispatch 'hl.dsp.exec_cmd([[omarchy launch wifi]])'", "session"),
      item("item", "bluetooth", "Bluetooth", "Open Bluetooth controls", "", "hyprctl dispatch 'hl.dsp.exec_cmd([[omarchy launch bluetooth]])'", "session"),
      item("item", "volume", "Audio", "Open audio mixer", "", "hyprctl dispatch 'hl.dsp.exec_cmd([[omarchy launch audio]])'", "session"),
      item("item", "video", "Record screen", "Choose screen recording mode", "", "", "session", "normal", "row", false, "session", "open-screenrecord-menu"),
      item("item", "idle", "Idle", "Toggle idle behavior", "", "omarchy toggle idle", "session"),
      item("header", "", "Maintenance", "", "", "", "shell"),
      item("item", "lacuna", "Lacuna Settings", "Runtime and layout controls", "lacuna", "", "lacuna", "normal", "row", false, "lacuna"),
      item("item", "update", "Update Lacuna", "Pull the Lacuna git repo", "", updateLacunaCommand(), "shell"),
      item("item", "refresh", "Restart shell", "Reload Omarchy shell", "", restartLacunaCommand(), "shell")
    ])
  }
}
