function screenName(screen) {
  return screen && screen.name !== undefined ? String(screen.name) : ""
}

function chooseSidebarScreen(screens, focusedName) {
  var values = screens || []
  var wanted = String(focusedName || "").trim()

  if (wanted !== "") {
    for (var i = 0; i < values.length; i++) {
      if (screenName(values[i]) === wanted) return values[i]
    }
  }

  return values.length > 0 ? values[0] : null
}

if (typeof module !== "undefined") {
  module.exports = {
    screenName: screenName,
    chooseSidebarScreen: chooseSidebarScreen
  }
}
