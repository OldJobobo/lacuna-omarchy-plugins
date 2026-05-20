import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var settingsService: null
  property bool exclusive: true
  property bool collapsed: false
  property bool cornerPieces: true

  function load() {
    if (settingsService && settingsService.load) settingsService.load()
  }

  function toggle() {
    exclusive = !exclusive
    save()
  }

  function toggleCollapsed() {
    collapsed = !collapsed
    save()
  }

  function toggleCornerPieces() {
    cornerPieces = !cornerPieces
    save()
  }

  function expand() {
    collapsed = false
    save()
  }

  function setDisplay(mode) {
    var value = String(mode || "full").toLowerCase()
    collapsed = value === "rail"
    save()
  }

  function save() {
    if (!settingsService || !settingsService.save) return
    var next = settingsService.normalize ? settingsService.normalize(settingsService.data) : settingsService.data
    if (!next || typeof next !== "object") next = { version: 1 }
    next.sidebar = {
      collapsed: collapsed,
      exclusive: exclusive,
      cornerPieces: cornerPieces
    }
    settingsService.save(next)
  }

  function applySettings() {
    var sidebar = settingsService && settingsService.data ? settingsService.data.sidebar : null
    collapsed = !!(sidebar && sidebar.collapsed === true)
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
