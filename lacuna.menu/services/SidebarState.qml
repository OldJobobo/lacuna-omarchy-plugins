import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var settingsService: null
  property bool exclusive: true
  property bool collapsed: false
  property bool cornerPieces: true
  property string defaultMode: "off"
  property string monitorPolicy: "auto"
  property var monitorNames: []
  property bool displayInitialized: false

  // Two distinct concepts that previously bled together:
  //   desiredDefaultMode - the persisted startup preference (off/rail/full).
  //   runtimeCollapsed    - the live rail/full toggle for the current session.
  // The aliases name the split so consumers can read intent directly.
  readonly property string desiredDefaultMode: defaultMode
  readonly property bool runtimeCollapsed: collapsed

  function load() {
    if (settingsService && settingsService.load) settingsService.load()
  }

  function toggle() {
    setExclusive(!exclusive)
  }

  function setExclusive(value) {
    exclusive = value === true
    save()
  }

  function toggleCollapsed() {
    collapsed = !collapsed
  }

  function toggleCornerPieces() {
    setCornerPiecesEnabled(!cornerPieces)
  }

  function setCornerPiecesEnabled(value) {
    cornerPieces = value === true
    save()
  }

  function expand() {
    collapsed = false
  }

  function setDisplay(mode) {
    var value = String(mode || "full").toLowerCase()
    collapsed = value === "rail"
  }

  function setDefaultMode(mode) {
    defaultMode = normalizeDefaultMode(mode)
    collapsed = defaultMode === "rail"
    save()
  }

  function normalizeDefaultMode(mode) {
    var value = String(mode || "").toLowerCase()
    if (value === "off" || value === "rail" || value === "full") return value
    return "off"
  }

  function save() {
    if (!settingsService || !settingsService.save) return
    var next = settingsService.normalize ? settingsService.normalize(settingsService.data) : settingsService.data
    if (!next || typeof next !== "object") next = { version: 1 }
    next.sidebar = {
      defaultMode: defaultMode,
      // Persist the real runtime toggle rather than a value re-derived from
      // defaultMode, so changing the default preference no longer silently
      // rewrites the stored collapsed state.
      collapsed: collapsed,
      exclusive: exclusive,
      cornerPieces: cornerPieces,
      monitorPolicy: next.sidebar && next.sidebar.monitorPolicy ? String(next.sidebar.monitorPolicy) : monitorPolicy,
      monitorNames: next.sidebar && Array.isArray(next.sidebar.monitorNames) ? next.sidebar.monitorNames : monitorNames
    }
    settingsService.save(next, false, true)
  }

  function applySettings() {
    var sidebar = settingsService && settingsService.data ? settingsService.data.sidebar : null
    defaultMode = normalizeDefaultMode(sidebar && sidebar.defaultMode)
    if (!displayInitialized) {
      // Seed the session toggle from the startup preference on first load; from
      // then on it is session state that setDefaultMode/toggleCollapsed own.
      collapsed = defaultMode === "rail"
      displayInitialized = true
    }
    exclusive = !(sidebar && sidebar.exclusive === false)
    cornerPieces = !(sidebar && sidebar.cornerPieces === false)
    monitorPolicy = sidebar && sidebar.monitorPolicy ? String(sidebar.monitorPolicy) : "auto"
    monitorNames = sidebar && Array.isArray(sidebar.monitorNames) ? sidebar.monitorNames : []
  }

  Component.onCompleted: {
    if (!settingsService || settingsService.hasLoaded !== false) applySettings()
  }

  Connections {
    target: root.settingsService
    function onLoaded() {
      root.applySettings()
    }
  }
}
