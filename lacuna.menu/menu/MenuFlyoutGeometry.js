function finiteNumber(value, fallback) {
  var number = Number(value)
  return isFinite(number) ? number : fallback
}

function clamp(value, minimum, maximum) {
  return Math.max(minimum, Math.min(value, maximum))
}

function boundedGeometry(options) {
  var data = options || {}
  var screenWidth = Math.max(1, finiteNumber(data.screenWidth, 1))
  var screenHeight = Math.max(1, finiteNumber(data.screenHeight, 1))
  var leftInset = Math.max(0, finiteNumber(data.leftInset, 0))
  var rightInset = Math.max(0, finiteNumber(data.rightInset, 0))
  var topInset = Math.max(0, finiteNumber(data.topInset, 0))
  var bottomInset = Math.max(0, finiteNumber(data.bottomInset, 0))
  var preferredWidth = Math.max(1, finiteNumber(data.preferredWidth, 1))
  var preferredHeight = Math.max(1, finiteNumber(data.preferredHeight, 1))
  var preferredY = finiteNumber(data.preferredY, topInset)

  var availableWidth = Math.max(1, screenWidth - leftInset - rightInset)
  var availableHeight = Math.max(1, screenHeight - topInset - bottomInset)
  var width = Math.min(preferredWidth, availableWidth)
  var height = Math.min(preferredHeight, availableHeight)
  var maxY = Math.max(topInset, screenHeight - bottomInset - height)

  return {
    y: Math.round(clamp(preferredY, topInset, maxY)),
    width: Math.round(width),
    height: Math.round(height)
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    boundedGeometry: boundedGeometry
  }
}
