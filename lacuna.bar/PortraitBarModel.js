var COMPANION_ROUTES = {
  "lacuna.codex-usage": "left",
  "lacuna.claude-usage": "left",
  "lacuna.system-stats": "center",
  "lacuna.temperature": "center",
  "lacuna.theme": "right",
  "lacuna.wallpaper": "right"
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (entry && typeof entry === "object" && !Array.isArray(entry) && entry.id !== undefined && entry.id !== null)
    return String(entry.id)
  return ""
}

function emptyLayout() {
  return { left: [], center: [], right: [] }
}

function routeLayout(layout, canonicalize) {
  var source = layout && typeof layout === "object" ? layout : {}
  var canonicalizer = typeof canonicalize === "function" ? canonicalize : function(value) { return value }
  var result = { primary: emptyLayout(), companion: emptyLayout() }
  var regions = ["left", "center", "right"]

  for (var r = 0; r < regions.length; r++) {
    var region = regions[r]
    var entries = Array.isArray(source[region]) ? source[region] : []
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i]
      var canonicalId = String(canonicalizer(entryId(entry)) || "")
      var companionRegion = COMPANION_ROUTES[canonicalId]
      if (companionRegion) result.companion[companionRegion].push(entry)
      else result.primary[region].push(entry)
    }
  }

  return result
}

if (typeof module !== "undefined") {
  module.exports = {
    COMPANION_ROUTES: COMPANION_ROUTES,
    routeLayout: routeLayout
  }
}
