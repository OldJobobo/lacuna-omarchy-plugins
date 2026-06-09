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
  property bool displayInitialized: false

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
      collapsed: defaultMode === "rail",
      exclusive: exclusive,
      cornerPieces: cornerPieces
    }
    settingsService.save(next)
  }

  function applySettings() {
    var sidebar = settingsService && settingsService.data ? settingsService.data.sidebar : null
    defaultMode = normalizeDefaultMode(sidebar && sidebar.defaultMode)
    if (!displayInitialized) {
      collapsed = defaultMode === "rail"
      displayInitialized = true
    }
    exclusive = !(sidebar && sidebar.exclusive === false)
    cornerPieces = !(sidebar && sidebar.cornerPieces === false)
  }

  Component.onCompleted: applySettings()

  Connections {
    target: root.settingsService
    function onLoaded() {
      root.applySettings()
    }
  }
}
