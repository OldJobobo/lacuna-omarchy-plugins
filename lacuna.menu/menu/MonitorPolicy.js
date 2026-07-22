function screenName(screen) {
  return screen && screen.name !== undefined ? String(screen.name) : ""
}

function normalizeMonitorPolicy(value) {
  var policy = String(value || "").trim().toLowerCase()
  if (policy === "pinned" || policy === "fixed" || policy === "selected") return "pinned"
  if (policy === "all" || policy === "everywhere") return "all"
  return "auto"
}

function normalizeMonitorNames(values) {
  var source = Array.isArray(values) ? values : String(values || "").split(",")
  var names = []
  var seen = {}

  for (var i = 0; i < source.length && names.length < 16; i++) {
    var name = String(source[i] || "").trim()
    if (name === "" || seen[name]) continue
    seen[name] = true
    names.push(name)
  }

  return names
}

function chooseFocusedScreen(screens, focusedName) {
  var values = screens || []
  var wanted = String(focusedName || "").trim()

  if (wanted !== "") {
    for (var i = 0; i < values.length; i++) {
      if (screenName(values[i]) === wanted) return values[i]
    }
  }

  return values.length > 0 ? values[0] : null
}

function chooseSidebarScreens(screens, policy, focusedName, pinnedNames) {
  var values = screens || []
  var normalizedPolicy = normalizeMonitorPolicy(policy)

  if (normalizedPolicy === "all") {
    var allScreens = []
    for (var allIndex = 0; allIndex < values.length; allIndex++) allScreens.push(values[allIndex])
    return allScreens
  }

  if (normalizedPolicy === "pinned") {
    var wanted = normalizeMonitorNames(pinnedNames)
    var selected = []
    for (var i = 0; i < values.length; i++) {
      if (wanted.indexOf(screenName(values[i])) >= 0) selected.push(values[i])
    }
    if (selected.length > 0) return selected
  }

  var focused = chooseFocusedScreen(values, focusedName)
  return focused ? [focused] : []
}

function choosePrimarySidebarScreen(screens, policy, focusedName, pinnedNames) {
  if (arguments.length < 3) return chooseFocusedScreen(screens, policy)
  var targets = chooseSidebarScreens(screens, policy, focusedName, pinnedNames)
  return chooseFocusedScreen(targets, focusedName)
}

function chooseFlyoutScreen(screens, policy, focusedName, pinnedNames) {
  var targets = chooseSidebarScreens(screens, policy, focusedName, pinnedNames)
  var focused = chooseFocusedScreen(screens, focusedName)

  // The sidebar may be mirrored to several outputs, but its interactive
  // flyout belongs to the active output. If a pinned set excludes the active
  // output, keep the flyout on the first valid pinned target as a fallback.
  if (focused && isSidebarScreen(targets, focused)) return focused
  return targets.length > 0 ? targets[0] : null
}

function chooseSidebarScreen(screens, focusedName) {
  return choosePrimarySidebarScreen(screens, focusedName)
}

function isSidebarScreen(targets, screen) {
  if (!screen) return false
  var values = targets || []
  for (var i = 0; i < values.length; i++) {
    if (values[i] === screen || screenName(values[i]) === screenName(screen)) return true
  }
  return false
}

function workspaceHasFullscreen(workspace) {
  if (!workspace) return false
  if (workspace.hasFullscreen === true) return true

  var ipc = workspace.lastIpcObject || {}
  return ipc.hasfullscreen === true
    || ipc.hasFullscreen === true
    || Number(ipc.fullscreen || 0) > 0
}

function monitorOptions(screens, pinnedNames) {
  var wanted = normalizeMonitorNames(pinnedNames)
  var values = screens || []
  var options = []
  for (var i = 0; i < values.length; i++) {
    var name = screenName(values[i])
    if (name === "") continue
    options.push({
      name: name,
      label: name,
      checked: wanted.indexOf(name) >= 0
    })
  }
  return options
}

if (typeof module !== "undefined") {
  module.exports = {
    screenName: screenName,
    normalizeMonitorPolicy: normalizeMonitorPolicy,
    normalizeMonitorNames: normalizeMonitorNames,
    chooseFocusedScreen: chooseFocusedScreen,
    chooseSidebarScreens: chooseSidebarScreens,
    choosePrimarySidebarScreen: choosePrimarySidebarScreen,
    chooseFlyoutScreen: chooseFlyoutScreen,
    chooseSidebarScreen: chooseSidebarScreen,
    isSidebarScreen: isSidebarScreen,
    workspaceHasFullscreen: workspaceHasFullscreen,
    monitorOptions: monitorOptions
  }
}
