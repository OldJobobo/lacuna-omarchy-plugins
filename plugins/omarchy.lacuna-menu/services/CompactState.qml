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
    compact = !compact
    save()
  }

  function applySettings() {
    compact = !!(settingsService && settingsService.data && settingsService.data.compact === true)
  }

  function save() {
    if (!settingsService || !settingsService.save) return
    var next = settingsService.normalize ? settingsService.normalize(settingsService.data) : settingsService.data
    if (!next || typeof next !== "object") next = { version: 1 }
    next.compact = compact
    settingsService.save(next)
  }

  Component.onCompleted: applySettings()

  Connections {
    target: root.settingsService
    function onLoaded() {
      root.applySettings()
    }
  }
}
