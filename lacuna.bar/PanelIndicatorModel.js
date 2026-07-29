function extent(vertical, item, slotWidth, slotHeight, minimumExtent) {
  var key = vertical ? "openPanelIndicatorHeight" : "openPanelIndicatorWidth"
  var hint = item && key in item ? item[key] : undefined
  if (hint !== undefined && hint !== null && hint > 0) return Math.round(hint)
  var slotExtent = vertical ? slotHeight : slotWidth
  return Math.max(minimumExtent, Math.round(slotExtent * 0.55))
}

if (typeof module !== "undefined") {
  module.exports = { extent: extent }
}
