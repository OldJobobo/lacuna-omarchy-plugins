import QtQuick

Item {
  id: root

  property var appCatalog: null
  property var customQuickLaunchApps: []
  property var customQuickLaunchNames: ({})
  property var preferredApps: ({})
  property var entries: null
  property var commands: null

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

  function appCount(category) {
    return root.appCatalog ? root.appCatalog.countFor(category) : 0
  }

  function categoryItem(meta) {
    var row = root.entries.nav({
      icon: meta.icon,
      label: meta.label,
      view: "apps-" + meta.id,
      tone: meta.tone,
      group: "apps"
    })
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

  function customQuickLaunchContains(id) {
    var ids = root.customQuickLaunchApps || []
    for (var i = 0; i < ids.length; i++) {
      if (String(ids[i]) === String(id)) return true
    }
    return false
  }

  function appEntry(app, quickAdd) {
    var row = root.entries.command({
      icon: appIcon(app),
      iconSource: appIconSource(app),
      label: app.Name,
      hint: app.Comment || app.GenericName,
      command: appLaunchCommand(app),
      tone: categoryMeta(app.category).tone,
      group: "apps"
    })
    row.appId = app.id
    if (quickAdd) {
      row.trailingAction = "add-custom-quick-launch-app"
      row.trailingIcon = customQuickLaunchContains(app.id) ? "check" : "plus"
      row.trailingTooltip = customQuickLaunchContains(app.id) ? "Already in quick launch" : "Add to quick launch"
    }
    return row
  }

  function roleMeta(role) {
    if (role === "files") return { label: "Files", icon: "folder", tone: "nav", systemHint: "System default" }
    if (role === "editor") return { label: "Editor", icon: "edit", tone: "shell", systemHint: "System editor" }
    if (role === "email") return { label: "Email", icon: "mail", tone: "nav", systemHint: "System email" }
    if (role === "discord") return { label: "Discord", icon: "message", tone: "session", systemHint: "Detected Discord app" }
    return { label: "App", icon: "apps", tone: "nav", systemHint: "System default" }
  }

  function preferredAppValue(role) {
    if (!root.preferredApps || typeof root.preferredApps !== "object") return "system"
    var value = String(root.preferredApps[role] || "").trim()
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

  function preferredAppHint(role) {
    var value = preferredAppValue(role)
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

  function appLaunchCommand(appOrId) {
    var app = null
    var id = ""

    if (typeof appOrId === "object" && appOrId !== null) {
      app = appOrId
      id = String(app.id || "")
    } else {
      id = String(appOrId || "")
      if (root.appCatalog && root.appCatalog.ready) app = root.appCatalog.appById(id)
    }

    if (app && app.Terminal === true) {
      var command = root.commands.desktopExecCommand(app.Exec)
      if (command !== "") return root.commands.terminalLaunchCommand(command, app.Name || id)
    }

    return root.commands.hyprExec("gtk-launch " + root.commands.shellQuote(id))
  }

  function roleCommand(role) {
    var value = preferredAppValue(role)
    if (value !== "system") return appLaunchCommand(value)

    if (role === "files") return root.commands.hyprExec("omarchy launch nautilus")
    if (role === "editor") return root.commands.hyprExec("omarchy launch editor")
    if (role === "email") return root.commands.hyprExec("xdg-open mailto:")
    if (role === "discord") {
      var detected = detectedDiscordApp()
      if (detected) return appLaunchCommand(detected)
      return root.commands.hyprExec("omarchy launch webapp https://discord.com/channels/@me")
    }

    return ""
  }

  function roleEntry(role, priority) {
    var meta = roleMeta(role)
    return root.entries.command({
      icon: meta.icon,
      label: meta.label,
      hint: preferredAppHint(role),
      command: roleCommand(role),
      tone: meta.tone,
      priority: priority || "primary",
      group: "launch"
    })
  }

  function roleSettingsItem(role) {
    var meta = roleMeta(role)
    return root.entries.action({
      icon: meta.icon,
      label: meta.label,
      hint: preferredAppHint(role),
      action: "choose-preferred-app-" + role,
      tone: meta.tone,
      priority: "primary",
      group: "preferred-apps"
    })
  }

  function customQuickLaunchItems() {
    var rows = []
    var ids = root.customQuickLaunchApps || []
    if (!root.appCatalog || !root.appCatalog.ready) return rows

    for (var i = 0; i < ids.length; i++) {
      var id = String(ids[i] || "")
      var app = root.appCatalog.appById(id)
      if (app) {
        var row = appEntry(app, false)
        var customName = root.customQuickLaunchNames && root.customQuickLaunchNames[id] ? String(root.customQuickLaunchNames[id]).trim() : ""
        if (customName !== "") row.label = customName
        row.group = "quick-launch"
        row.priority = "normal"
        row.reorderable = true
        row.quickLaunchIndex = i
        rows.push(row)
      }
    }

    return rows
  }

  function preferredAppItems(priority) {
    return [
      roleEntry("files", priority || "normal"),
      roleEntry("editor", priority || "normal"),
      roleEntry("email", priority || "normal"),
      roleEntry("discord", priority || "normal")
    ]
  }

  function appItems(category) {
    var source = root.appCatalog ? root.appCatalog.appsFor(category) : []
    var rows = []

    if (!root.appCatalog || !root.appCatalog.ready) {
      return [
        root.entries.header("Loading", "nav"),
        root.entries.nav({ icon: "refresh", label: "Scanning apps", tone: "nav" })
      ]
    }

    if (source.length === 0) {
      return [
        root.entries.header("Empty", "nav"),
        root.entries.nav({ icon: "apps", label: "No apps found", tone: "nav" })
      ]
    }

    rows.push(root.entries.header(category === "all" ? "Applications" : categoryTitle(category), "nav"))
    for (var i = 0; i < source.length; i++) rows.push(appEntry(source[i], true))
    return rows
  }
}
