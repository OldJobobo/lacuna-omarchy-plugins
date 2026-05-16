import Quickshell
import QtQuick

Item {
  id: root

  property string lacunaPath: ""
  property bool sidebarExclusive: true
  property bool sidebarCollapsed: false
  property bool sidebarCornerPieces: true
  property bool compact: false
  property string colorProfile: "semantic"
  readonly property string lacunaIconSource: String(Qt.resolvedUrl("../assets/tabler/circle-dotted-letter-l.svg"))
  property var appCatalog: null

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
      switchChecked: switchChecked === true
    }
  }

  function titleFor(view) {
    if (view === "main") return "Lacuna"
    if (view === "lacuna") return "Lacuna"
    if (view === "customize") return "Customize"
    if (view === "lacuna-shell") return "Runtime"
    if (view === "lacuna-preferences") return "Layout"
    if (view === "system") return "System"
    if (view === "apps") return "Apps"
    if (view === "apps-all") return "All Apps"
    if (view.indexOf("apps-") === 0) return categoryTitle(view.substring(5))
    return "Utility Sidebar"
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function terminalCommand(command, title, holdOpen) {
    var terminalBody = command
    if (holdOpen) {
      terminalBody = command + "; status=$?; printf '\\nCommand exited with status %s. Press Enter to close...' \"$status\"; read -r _; exit \"$status\""
    }
    return "foot --app-id=org.omarchy.terminal --title=" + shellQuote(title || "Lacuna") + " -e bash -lc " + shellQuote(terminalBody)
  }

  function openTerminalCommand() {
    return "foot --app-id=org.omarchy.terminal --title=" + shellQuote("Terminal")
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
      { id: "games", label: "Games", icon: "󰊴", tone: "lacuna" },
      { id: "internet", label: "Internet", icon: "󰖟", tone: "nav" },
      { id: "development", label: "Development", icon: "", tone: "shell" },
      { id: "media", label: "Media", icon: "󰝚", tone: "session" },
      { id: "graphics", label: "Graphics", icon: "󰸌", tone: "shell" },
      { id: "office", label: "Office", icon: "󰈙", tone: "nav" },
      { id: "system", label: "System", icon: "󰒓", tone: "session" },
      { id: "utilities", label: "Utilities", icon: "󰆧", tone: "nav" },
      { id: "other", label: "Other", icon: "󰘳", tone: "nav" }
    ]
  }

  function categoryMeta(category) {
    var all = categories()
    for (var i = 0; i < all.length; i++) {
      if (all[i].id === category) return all[i]
    }
    return { id: category, label: "Apps", icon: "󰀻", tone: "nav" }
  }

  function categoryTitle(category) {
    return categoryMeta(category).label
  }

  function appCount(category) {
    return root.appCatalog ? root.appCatalog.countFor(category) : 0
  }

  function categoryLabel(meta) {
    var count = appCount(meta.id)
    return count > 0 ? meta.label + " " + count : meta.label
  }

  function appIcon(app) {
    if (app.category === "games") return "󰊴"
    if (app.category === "internet") return "󰖟"
    if (app.category === "development") return ""
    if (app.category === "media") return "󰝚"
    if (app.category === "graphics") return "󰸌"
    if (app.category === "office") return "󰈙"
    if (app.category === "system") return "󰒓"
    return "󰀻"
  }

  function appIconSource(app) {
    var icon = app.Icon || ""
    if (icon === "") return ""
    if (icon.indexOf("file://") === 0 || icon.indexOf("image://") === 0) return icon
    if (icon.indexOf("/") === 0) return "file://" + encodeURI(icon)
    return "image://icon/" + icon
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
        item("item", "󰀻", "No apps found", "", "", "", "nav", "primary", "row")
      ]
    }

    rows.push(item("header", "", category === "all" ? "Applications" : categoryTitle(category), "", "", "", "nav"))
    for (var i = 0; i < source.length; i++) {
      var app = source[i]
      rows.push(item("item", appIcon(app), app.Name, app.Comment || app.GenericName, "", "gtk-launch " + shellQuote(app.id), categoryMeta(app.category).tone, "primary", "row", false, "apps", "", appIconSource(app)))
    }
    return rows
  }

  function railItems() {
    return [
      item("item", "", "Lacuna", "Runtime and layout controls", "lacuna", "", "lacuna", "primary", "row", false, "lacuna", "", root.lacunaIconSource),
      item("item", "󰀻", "Apps", "Browse categorized launchers", "apps", "", "nav", "primary", "row", false, "apps"),
      item("item", "", "Customize", "Theme, background, and wallpaper tools", "customize", "", "shell", "primary", "row", false, "customize"),
      item("item", "", "System", "Lock, logout, restart, shutdown", "system", "", "session", "primary", "row", false, "session"),
      item("item", "", "Terminal", "Open a terminal", "", openTerminalCommand(), "nav", "normal", "row", false, "launch"),
      item("item", "󰈹", "Browser", "Launch browser", "", "omarchy launch browser", "nav", "normal", "row", false, "launch")
    ]
  }

  function itemsFor(view) {
    if (view === "apps") {
      var rows = [item("header", "", "Categories", "", "", "", "lacuna", "normal", "section", false, "apps")]
      var cats = categories()
      for (var c = 0; c < cats.length; c++) {
        var meta = cats[c]
        if (appCount(meta.id) > 0 || meta.id === "games") {
          rows.push(item("item", meta.icon, categoryLabel(meta), "", "apps-" + meta.id, "", meta.tone, "primary", "row", false, "apps"))
        }
      }
      rows.push(item("header", "", "Fallback", "", "", "", "shell"))
      rows.push(item("item", "󰀻", "All Apps", "", "apps-all", "", "nav", "primary", "row", false, "apps"))
      rows.push(item("item", "󰑐", "Reload app catalog", "", "", "", "shell", "normal", "row", false, "apps", "reload-apps"))
      rows.push(item("item", "󰅶", "Open Walker", "", "", "walker -p 'Launch…'", "shell", "normal", "row", false, "apps"))
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
        item("item", "󰒓", "Runtime", "Commands, logs, and diagnostics", "lacuna-shell", "", "lacuna", "primary", "row", false, "lacuna"),
        item("item", "", "Layout", "Density, sidebar, and surface behavior", "lacuna-preferences", "", "lacuna", "primary", "row", false, "lacuna"),
        item("header", "", "Source", "", "", "", "shell"),
        item("item", "󰑐", "Restart shell", "Reload Omarchy shell", "", restartLacunaCommand(), "shell"),
        item("item", "", "Open plugin source", "Edit the Lacuna plugin repository", "", editPluginCommand(), "shell")
      ]
    }

    if (view === "lacuna-shell") {
      return [
        item("header", "", "Runtime", "", "", "", "shell", "normal", "section", false, "shell"),
        item("item", "󰑐", "Restart shell", "Restart Omarchy shell", "", restartLacunaCommand(), "shell", "primary", "row", false, "shell"),
        item("item", "󰌾", "Open log", "View the current Lacuna log", "", openLogCommand(), "shell"),
        item("item", "", "Edit plugin", "Open Lacuna plugin source", "", editPluginCommand(), "lacuna")
      ]
    }

    if (view === "lacuna-preferences") {
      return [
        item("header", "", "Layout", "", "", "", "lacuna", "normal", "section", false, "lacuna"),
        item("item", "󰏘", root.colorProfile === "colorful" ? "Colorful Profile" : "Semantic Profile", root.colorProfile === "colorful" ? "Use theme colors across Lacuna topbar modules" : "Use foreground with semantic colors only", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-color-profile", "", true, root.colorProfile === "colorful"),
        item("item", "󰙵", root.compact ? "Compact Density" : "Normal Density", root.compact ? "Use tighter Lacuna UI spacing" : "Use standard Lacuna UI spacing", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-bar-density", "", true, root.compact),
        item("item", root.sidebarCollapsed ? "󰍽" : "󰍾", root.sidebarCollapsed ? "Icon Rail" : "Full Sidebar", root.sidebarCollapsed ? "Show the compact icon rail" : "Show the full sidebar surface", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-sidebar-rail", "", true, root.sidebarCollapsed),
        item("item", root.sidebarExclusive ? "󰹑" : "󰹐", root.sidebarExclusive ? "Sidebar Overlay" : "Sidebar Docked", root.sidebarExclusive ? "Let the sidebar float over windows" : "Reserve screen space for the sidebar", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-sidebar-mode", "", true, root.sidebarExclusive),
        item("item", "󰉼", root.sidebarCornerPieces ? "Corner Pieces" : "Flat Edge", root.sidebarCornerPieces ? "Show the rounded connector pieces" : "Hide the rounded connector pieces", "", "", "lacuna", "normal", "row", false, "lacuna", "toggle-corner-pieces", "", true, root.sidebarCornerPieces),
        item("item", "󰑐", "Reload app catalog", "Rescan desktop launchers", "", "", "shell", "normal", "row", false, "apps", "reload-apps")
      ]
    }

    if (view === "customize") {
      return [
        item("header", "", "Customize", "", "", "", "shell", "normal", "section", false, "customize"),
        item("item", "󰸉", "Wallpaper Catalog", "Open wallpaper picker", "", "jobowalls-gui", "shell", "primary", "row", false, "customize"),
        item("item", "󰔎", "Theme", "Switch Omarchy theme", "", switchThemeCommand(), "shell", "primary", "row", false, "customize"),
        item("item", "󰖔", "Background", "Switch theme background", "", switchBackgroundCommand(), "shell", "primary", "row", false, "customize"),
        item("header", "", "Layout", "", "", "", "lacuna", "normal", "section", false, "layout"),
        item("item", "󰏘", root.colorProfile === "colorful" ? "Colorful Profile" : "Semantic Profile", root.colorProfile === "colorful" ? "Use theme colors across Lacuna topbar modules" : "Use foreground with semantic colors only", "", "", "lacuna", "normal", "row", false, "layout", "toggle-color-profile", "", true, root.colorProfile === "colorful"),
        item("item", "󰙵", root.compact ? "Compact Density" : "Normal Density", root.compact ? "Use tighter Lacuna UI spacing" : "Use standard Lacuna UI spacing", "", "", "lacuna", "normal", "row", false, "layout", "toggle-bar-density", "", true, root.compact),
        item("item", root.sidebarCollapsed ? "󰍽" : "󰍾", root.sidebarCollapsed ? "Icon Rail" : "Full Sidebar", root.sidebarCollapsed ? "Show the compact icon rail" : "Show the full sidebar surface", "", "", "lacuna", "normal", "row", false, "layout", "toggle-sidebar-rail", "", true, root.sidebarCollapsed),
        item("item", root.sidebarExclusive ? "󰹑" : "󰹐", root.sidebarExclusive ? "Sidebar Overlay" : "Sidebar Docked", root.sidebarExclusive ? "Let the sidebar float over windows" : "Reserve screen space for the sidebar", "", "", "lacuna", "normal", "row", false, "layout", "toggle-sidebar-mode", "", true, root.sidebarExclusive),
        item("item", "󰉼", root.sidebarCornerPieces ? "Corner Pieces" : "Flat Edge", root.sidebarCornerPieces ? "Show the rounded connector pieces" : "Hide the rounded connector pieces", "", "", "lacuna", "normal", "row", false, "layout", "toggle-corner-pieces", "", true, root.sidebarCornerPieces)
      ]
    }

    if (view === "system") {
      return [
        item("header", "", "Session", "", "", "", "session", "normal", "section", false, "session"),
        item("item", "󱄄", "Screensaver", "Start screensaver now", "", "omarchy-launch-screensaver force", "session"),
        item("item", "", "Lock", "Lock session", "", "omarchy-system-lock", "session", "primary", "row", false, "session"),
        item("item", "󰍃", "Logout", "End session", "", "omarchy-system-logout", "session"),
        item("header", "", "Power", "", "", "", "danger", "normal", "section", true, "power"),
        item("item", "󰜉", "Restart", "Reboot machine", "", "omarchy-system-reboot", "danger", "normal", "row", true, "power"),
        item("item", "󰐥", "Shutdown", "Power off machine", "", "omarchy-system-shutdown", "danger", "primary", "row", true, "power")
      ]
    }

    return [
      item("header", "", "Lacuna", "", "", "", "lacuna", "normal", "section", false, "lacuna"),
      item("item", "󰀻", "Apps", "Browse categorized launchers", "apps", "", "nav", "primary", "featured"),
      item("item", "", "Customize", "Theme, background, and wallpaper tools", "customize", "", "shell", "primary", "featured", false, "customize"),
      item("item", "", "System", "Lock, logout, restart, shutdown", "system", "", "session", "primary", "featured", false, "session"),
      item("header", "", "Launch", "", "", "", "nav"),
      item("item", "", "Terminal", "Open a terminal", "", openTerminalCommand(), "nav", "primary", "row"),
      item("item", "󰈹", "Browser", "Launch browser", "", "omarchy launch browser", "nav", "primary", "row"),
      item("header", "", "System Tools", "", "", "", "session"),
      item("item", "󰖩", "Wi-Fi", "Open Wi-Fi controls", "", "hyprctl dispatch 'hl.dsp.exec_cmd([[omarchy launch wifi]])'", "session"),
      item("item", "󰂯", "Bluetooth", "Open Bluetooth controls", "", "hyprctl dispatch 'hl.dsp.exec_cmd([[omarchy launch bluetooth]])'", "session"),
      item("item", "󰕾", "Audio", "Open audio mixer", "", "hyprctl dispatch 'hl.dsp.exec_cmd([[omarchy launch audio]])'", "session"),
      item("item", "󰄄", "Record screen", "Toggle screen recording", "", "omarchy capture screenrecording", "session"),
      item("item", "󰒲", "Idle", "Toggle idle behavior", "", "omarchy toggle idle", "session"),
      item("header", "", "Maintenance", "", "", "", "shell"),
      item("item", "", "Lacuna Settings", "Runtime and layout controls", "lacuna", "", "lacuna", "normal", "row", false, "lacuna", "", root.lacunaIconSource),
      item("item", "", "Update Lacuna", "Pull the Lacuna git repo", "", updateLacunaCommand(), "shell"),
      item("item", "󰑐", "Restart shell", "Reload Omarchy shell", "", restartLacunaCommand(), "shell")
    ]
  }
}
