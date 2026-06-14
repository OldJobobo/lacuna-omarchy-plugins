import QtQuick

// Pure, stateless value validators and converters extracted from MenuWindow.
// Nothing here reads component state: every function is parameters-in,
// value-out, so the logic is independently testable and the orchestrator's
// body is smaller. MenuWindow keeps thin delegators of the same name so call
// sites and the source contract are unchanged.
QtObject {
  id: root

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function positiveInt(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) && parsed > 0 ? Math.round(parsed) : fallback
  }

  function safeValue(value, fallback) {
    return value === undefined || value === null ? fallback : value
  }

  function numberSetting(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) ? parsed : fallback
  }

  function boolSetting(value, fallback) {
    if (value === true || value === false) return value
    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallback
  }

  function validFrameMode(value) {
    var mode = String(value || "off").toLowerCase()
    if (mode === "fullframe" || mode === "on" || mode === "true" || mode === "1") return "fullframe"
    return "off"
  }

  function validFrameReserveMode(value) {
    var mode = String(value || "auto").toLowerCase()
    if (mode === "comfort" || mode === "flush") return mode
    return "auto"
  }

  function validShellSettingsSurface(value) {
    var surface = String(value || "").toLowerCase()
    if (surface === "window" || surface === "floating" || surface === "panel") return "window"
    return "flyout"
  }

  function desiredChecked(entry, fallback) {
    return entry && entry.desiredChecked !== undefined ? entry.desiredChecked === true : fallback
  }

  function validClockAnchor(value) {
    var anchor = String(value || "bottom-right").toLowerCase()
    var valid = {
      "top-left": true,
      "top": true,
      "top-right": true,
      "left": true,
      "center": true,
      "right": true,
      "bottom-left": true,
      "bottom": true,
      "bottom-right": true
    }

    return valid[anchor] ? anchor : "bottom-right"
  }

  function clockAnchorHorizontal(anchor) {
    if (anchor.indexOf("left") !== -1) return "left"
    if (anchor.indexOf("right") !== -1) return "right"
    return "center"
  }

  function clockAnchorVertical(anchor) {
    if (anchor.indexOf("top") !== -1) return "top"
    if (anchor.indexOf("bottom") !== -1) return "bottom"
    return "center"
  }

  function clockAnchorFromParts(horizontal, vertical) {
    var h = String(horizontal || "center")
    var v = String(vertical || "center")

    if (h === "center" && v === "center") return "center"
    if (h === "center") return v
    if (v === "center") return h
    return v + "-" + h
  }
}
