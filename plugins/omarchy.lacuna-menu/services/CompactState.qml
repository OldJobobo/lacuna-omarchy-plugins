import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var settingsService: null
  property bool compact: false

  function load() {
    if (settingsService && settingsService.load) settingsService.load()
  }

  function toggle() {
    setMode(compact ? "full" : "compact")
  }

  function setMode(mode) {
    var nextMode = normalizeMode(mode)
    compact = nextMode === "compact"
    save()
  }

  function applySettings() {
    if (!settingsService || !settingsService.data) {
      compact = false
      return
    }

    var transition = settingsService.data.sizeTransition || {}
    var remaining = Math.round(Number(transition.holdUntil || 0) - Date.now())
    if (remaining > 0) {
      compact = transition.holdCompact === true
      holdTimer.interval = Math.max(16, Math.min(remaining, 180))
      holdTimer.restart()
      return
    }

    compact = normalizeMode(settingsService.data.barSizeMode, settingsService.data.compact === true) === "compact"
  }

  function save() {
    if (!settingsService || !settingsService.save) return
    var next = settingsService.normalize ? settingsService.normalize(settingsService.data) : settingsService.data
    if (!next || typeof next !== "object") next = { version: 1 }
    next.compact = compact
    next.barSizeMode = compact ? "compact" : "full"
    next.sizeTransition = {
      holdCompact: compact,
      holdUntil: Date.now() + 56
    }
    settingsService.save(next)
  }

  function normalizeMode(mode, compactFallback) {
    var value = String(mode || "").toLowerCase()
    if (value === "compact" || value === "full") return value
    return compactFallback === true ? "compact" : "full"
  }

  Component.onCompleted: applySettings()

  Connections {
    target: root.settingsService
    function onLoaded() {
      root.applySettings()
    }
  }

  Timer {
    id: holdTimer

    interval: 56
    repeat: false
    onTriggered: root.applySettings()
  }
}
