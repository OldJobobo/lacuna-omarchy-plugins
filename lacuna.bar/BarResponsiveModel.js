function finiteNumber(value, fallback) {
  var number = Number(value)
  return isFinite(number) ? number : fallback
}

function widthClass(logicalWidth) {
  var width = Math.max(0, finiteNumber(logicalWidth, 0))
  if (width >= 1680) return "wide"
  if (width >= 1200) return "standard"
  if (width >= 800) return "constrained"
  return "minimal"
}

function centerRatio(className) {
  if (className === "wide") return 0.24
  if (className === "standard") return 0.20
  if (className === "constrained") return 0.16
  return 0
}

// Divide a horizontal surface into three non-overlapping corridors. The center
// remains geometrically centered; both sides receive the same budget so an
// overloaded side can never push the clock away from the output midpoint.
function horizontalPlan(logicalWidth, outerMargin, sectionGap, anchorLength, barSize) {
  var width = Math.max(0, Math.floor(finiteNumber(logicalWidth, 0)))
  var margin = Math.max(0, Math.floor(finiteNumber(outerMargin, 0)))
  var gap = Math.max(0, Math.floor(finiteNumber(sectionGap, 0)))
  var thickness = Math.max(0, Math.ceil(finiteNumber(barSize, 0)))
  var innerLength = Math.max(0, width - margin * 2)
  var anchor = Math.min(innerLength, Math.max(
    thickness,
    Math.ceil(Math.max(0, finiteNumber(anchorLength, 0)))
  ))
  var className = widthClass(width)
  var desiredCenter = Math.min(innerLength, Math.max(
    anchor,
    Math.round(width * centerRatio(className))
  ))
  var sideLength = Math.max(0, Math.floor((innerLength - desiredCenter - gap * 2) / 2))
  var effectiveGap = sideLength > 0 ? gap : 0
  var centerLength = Math.max(0, innerLength - sideLength * 2 - effectiveGap * 2)

  return {
    widthClass: className,
    logicalWidth: width,
    innerLength: innerLength,
    centerLength: centerLength,
    centerHalfLength: Math.max(0, Math.floor((centerLength - anchor) / 2)),
    anchorLength: anchor,
    sideLength: sideLength,
    gap: effectiveGap
  }
}

function targetDescendsFrom(target, ancestor) {
  var current = target
  while (current) {
    if (current === ancestor) return true
    current = current.parent || null
  }
  return false
}

// Responsive hiding must also retire surfaces and interaction state owned by
// the disappearing slot; PopupWindows otherwise outlive their hidden anchor.
function prepareSlotForHide(host, slot) {
  if (!host || !slot) return
  var item = slot.activeItem
  var popout = host.activePopout
  var popoutOwner = null
  try {
    popoutOwner = popout && "owner" in popout ? popout.owner : null
  } catch (error) {
  }
  var ownsPopout = !!item && (popout === item || popoutOwner === item)
  if (ownsPopout) {
    if (popout && typeof popout.close === "function") popout.close()
    else if (item && typeof item.close === "function") item.close()
    if (host.activePopout === popout) host.activePopout = null
  }
  if (targetDescendsFrom(host.tooltipTarget, item) || targetDescendsFrom(host.pendingTooltipTarget, item)) {
    if (typeof host.clearTooltip === "function") host.clearTooltip()
  }
  if (host.barDragSource === slot && typeof host.clearBarDrag === "function") host.clearBarDrag()
}

// Greedily retain the highest-priority modules that fit. An oversized module
// is never forced into its corridor; that was the source of narrow-bar overlap.
function fit(items, availableLength) {
  var values = Array.isArray(items) ? items : []
  var limit = Math.max(0, Math.floor(finiteNumber(availableLength, 0)))
  var candidates = []
  var totalLength = 0
  var visible = []

  for (var i = 0; i < values.length; i++) {
    visible.push(false)
    var length = Math.max(0, Math.ceil(finiteNumber(values[i] && values[i].length, 0)))
    if (length <= 0) continue
    totalLength += length
    candidates.push({
      index: i,
      length: length,
      priority: finiteNumber(values[i] && values[i].priority, 0)
    })
  }

  if (totalLength <= limit) {
    for (var showIndex = 0; showIndex < candidates.length; showIndex++)
      visible[candidates[showIndex].index] = true
    return {
      visible: visible,
      usedLength: totalLength,
      totalLength: totalLength,
      hiddenCount: 0
    }
  }

  candidates.sort(function(left, right) {
    if (right.priority !== left.priority) return right.priority - left.priority
    return left.index - right.index
  })

  var usedLength = 0
  var keptCount = 0
  for (var keepIndex = 0; keepIndex < candidates.length; keepIndex++) {
    var candidate = candidates[keepIndex]
    if (usedLength + candidate.length > limit) continue
    visible[candidate.index] = true
    usedLength += candidate.length
    keptCount++
  }

  return {
    visible: visible,
    usedLength: usedLength,
    totalLength: totalLength,
    hiddenCount: candidates.length - keptCount
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    widthClass: widthClass,
    horizontalPlan: horizontalPlan,
    prepareSlotForHide: prepareSlotForHide,
    fit: fit
  }
}
