function screenName(screen) {
  if (!screen || screen.name === undefined || screen.name === null) return ""
  return String(screen.name)
}

function validScreens(screens) {
  var source = screens && screens.length !== undefined ? screens : []
  var out = []
  var seen = {}

  for (var i = 0; i < source.length; i++) {
    var screen = source[i]
    var name = screenName(screen)
    var width = Number(screen && screen.width)
    var height = Number(screen && screen.height)
    if (!name || !isFinite(width) || !isFinite(height) || width <= 0 || height <= 0 || seen[name]) continue
    seen[name] = true
    out.push(screen)
  }

  return out
}

function isPortrait(screen) {
  var width = Number(screen && screen.width)
  var height = Number(screen && screen.height)
  return isFinite(width) && isFinite(height) && width > 0 && height > 0 && height > width
}

function hasScreen(screens, name) {
  var target = String(name || "")
  if (!target) return false
  var valid = validScreens(screens)
  for (var i = 0; i < valid.length; i++) {
    if (screenName(valid[i]) === target) return true
  }
  return false
}

function fallbackScreen(screens, preferredName) {
  var valid = validScreens(screens)
  var preferred = String(preferredName || "")
  for (var i = 0; i < valid.length; i++) {
    if (screenName(valid[i]) === preferred) return valid[i]
  }
  return valid.length > 0 ? valid[0] : null
}

if (typeof module !== "undefined") {
  module.exports = {
    screenName: screenName,
    validScreens: validScreens,
    isPortrait: isPortrait,
    hasScreen: hasScreen,
    fallbackScreen: fallbackScreen
  }
}
