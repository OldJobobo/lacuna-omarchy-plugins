import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property bool loaded: false
  property bool hadStateFile: false
  property bool manageIdle: true
  property bool manageNightlight: true
  property bool idleRestoreComplete: false
  property bool nightlightRestoreComplete: false
  readonly property bool restoreComplete: (!manageIdle || idleRestoreComplete) && (!manageNightlight || nightlightRestoreComplete)
  readonly property bool applying: applyingIdle || applyingNightlight
  property bool applyingIdle: false
  property bool applyingNightlight: false
  property bool desiredIdleEnabled: true
  property bool currentIdleEnabled: true
  property bool haveCurrentIdle: false
  property bool desiredNightlightEnabled: false
  property bool desiredNightlightKnown: false
  property bool currentNightlightEnabled: false
  property int currentNightlightTemperature: 6000
  property bool haveCurrentNightlight: false
  property string lastStatus: "starting"
  property string lastError: ""
  property string lastUpdatedAt: ""
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/lacuna"
  readonly property string stateFile: stateDir + "/settings-persistence.json"

  function timestamp() {
    return new Date().toISOString()
  }

  function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function parseJson(text, fallback) {
    try {
      var parsed = JSON.parse(String(text || "{}"))
      return parsed && typeof parsed === "object" ? parsed : fallback
    } catch (e) {
      return fallback
    }
  }

  function parseBool(value, fallback) {
    if (value === true || value === "true" || value === "1" || value === "on" || value === "yes") return true
    if (value === false || value === "false" || value === "0" || value === "off" || value === "no") return false
    return fallback
  }

  function hydrate(text) {
    hadStateFile = String(text || "").trim().length > 0
    var data = parseJson(text, {})
    manageIdle = data.manageIdle === false ? false : true
    manageNightlight = data.manageNightlight === false ? false : true
    if (!manageIdle && !manageNightlight) manageIdle = true

    desiredIdleEnabled = data.idleEnabled === false ? false : true
    desiredNightlightKnown = typeof data.nightlightEnabled === "boolean"
    desiredNightlightEnabled = desiredNightlightKnown ? data.nightlightEnabled === true : false

    loaded = true
    lastStatus = "loaded"
    requestManagedStatus("restore")
    pollTimer.start()
  }

  function requestManagedStatus(reason) {
    if (!loaded) return
    if (manageIdle) requestIdleStatus(reason)
    else idleRestoreComplete = true

    if (manageNightlight) requestNightlightStatus(reason)
    else nightlightRestoreComplete = true
  }

  function requestIdleStatus(reason) {
    if (idleStatusProc.running) return
    idleStatusProc.reason = String(reason || "poll")
    idleStatusProc.command = ["bash", "-lc", "omarchy-shell idle status 2>/dev/null"]
    idleStatusProc.running = true
  }

  function requestNightlightStatus(reason) {
    if (nightlightStatusProc.running) return
    nightlightStatusProc.reason = String(reason || "poll")
    nightlightStatusProc.command = ["bash", "-lc", "omarchy-toggle-nightlight --status 2>/dev/null"]
    nightlightStatusProc.running = true
  }

  function handleIdleStatus(text, reason) {
    var data = parseJson(text, null)
    if (!data || typeof data.enabled !== "boolean") {
      lastError = "idle status unavailable"
      lastStatus = "waiting"
      return
    }

    var enabled = data.enabled === true
    currentIdleEnabled = enabled
    haveCurrentIdle = true

    if (!idleRestoreComplete) {
      if (enabled !== desiredIdleEnabled) {
        applyIdleEnabled(desiredIdleEnabled, "restore")
      } else {
        idleRestoreComplete = true
        lastStatus = restoreComplete ? "restored" : "restoring"
        if (!hadStateFile) scheduleSave("seeded")
      }
      return
    }

    if (!applyingIdle && enabled !== desiredIdleEnabled) {
      desiredIdleEnabled = enabled
      scheduleSave("observed")
    }
  }

  function handleNightlightStatus(text, reason) {
    var data = parseJson(text, null)
    if (!data || typeof data.enabled !== "boolean") {
      lastError = "nightlight status unavailable"
      lastStatus = "waiting"
      return
    }

    var enabled = data.enabled === true
    currentNightlightEnabled = enabled
    currentNightlightTemperature = typeof data.temperature === "number" ? data.temperature : currentNightlightTemperature
    haveCurrentNightlight = true

    if (!nightlightRestoreComplete) {
      if (!desiredNightlightKnown) {
        desiredNightlightEnabled = enabled
        desiredNightlightKnown = true
        nightlightRestoreComplete = true
        lastStatus = restoreComplete ? "restored" : "restoring"
        scheduleSave(!hadStateFile ? "seeded" : "migrated")
      } else if (enabled !== desiredNightlightEnabled) {
        applyNightlightEnabled(desiredNightlightEnabled, "restore")
      } else {
        nightlightRestoreComplete = true
        lastStatus = restoreComplete ? "restored" : "restoring"
        if (!hadStateFile) scheduleSave("seeded")
      }
      return
    }

    if (!applyingNightlight && enabled !== desiredNightlightEnabled) {
      desiredNightlightEnabled = enabled
      scheduleSave("observed")
    }
  }

  function applyIdleEnabled(enabled, reason) {
    if (applyingIdle) return
    applyingIdle = true
    lastStatus = "applying"
    idleApplyProc.expected = enabled === true
    idleApplyProc.reason = String(reason || "manual")
    idleApplyProc.command = ["bash", "-lc", "omarchy-shell idle " + (enabled ? "enable" : "disable") + " 2>/dev/null"]
    idleApplyProc.running = true
  }

  function applyNightlightEnabled(enabled, reason) {
    if (applyingNightlight) return
    applyingNightlight = true
    lastStatus = "applying"
    nightlightApplyProc.expected = enabled === true
    nightlightApplyProc.reason = String(reason || "manual")
    var temp = enabled ? "4000" : "6000"
    nightlightApplyProc.command = ["bash", "-lc", "if ! pgrep -x hyprsunset >/dev/null; then setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; fi; hyprctl hyprsunset temperature " + temp + " >/dev/null 2>&1; omarchy-shell -q Indicators refresh"]
    nightlightApplyProc.running = true
  }

  function setManagedToggles(idle, nightlight) {
    var nextIdle = parseBool(idle, manageIdle)
    var nextNightlight = parseBool(nightlight, manageNightlight)
    if (!nextIdle && !nextNightlight) {
      lastError = "select at least one toggle"
      return false
    }

    var changed = nextIdle !== manageIdle || nextNightlight !== manageNightlight
    manageIdle = nextIdle
    manageNightlight = nextNightlight
    if (!manageIdle) idleRestoreComplete = true
    else if (changed) idleRestoreComplete = false
    if (!manageNightlight) nightlightRestoreComplete = true
    else if (changed) nightlightRestoreComplete = false

    lastError = ""
    scheduleSave("settings")
    requestManagedStatus("settings")
    return true
  }

  function scheduleSave(reason) {
    lastStatus = String(reason || "changed")
    lastUpdatedAt = timestamp()
    saveTimer.restart()
  }

  function saveState() {
    var json = JSON.stringify({
      version: 2,
      manageIdle: manageIdle === true,
      manageNightlight: manageNightlight === true,
      idleEnabled: desiredIdleEnabled === true,
      nightlightEnabled: desiredNightlightEnabled === true,
      nightlightTemperature: currentNightlightTemperature || null,
      updatedAt: lastUpdatedAt || timestamp()
    }, null, 2) + "\n"

    saveProc.command = ["bash", "-lc", "mkdir -p " + quote(stateDir)
      + "; tmp=$(mktemp); printf %s " + quote(json) + " > \"$tmp\"; mv \"$tmp\" " + quote(stateFile)]
    saveProc.running = true
  }

  Component.onCompleted: stateFileView.reload()

  FileView {
    id: stateFileView

    path: root.stateFile
    watchChanges: false
    printErrors: false
    onLoaded: root.hydrate(text())
    onLoadFailed: root.hydrate("")
  }

  Timer {
    id: pollTimer

    interval: root.restoreComplete ? 3000 : 900
    repeat: true
    running: false
    onTriggered: root.requestManagedStatus(root.restoreComplete ? "poll" : "restore")
  }

  Timer {
    id: saveTimer

    interval: 250
    repeat: false
    onTriggered: root.saveState()
  }

  Process {
    id: idleStatusProc
    property string reason: "poll"

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.handleIdleStatus(text, idleStatusProc.reason)
    }
  }

  Process {
    id: nightlightStatusProc
    property string reason: "poll"

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.handleNightlightStatus(text, nightlightStatusProc.reason)
    }
  }

  Process {
    id: idleApplyProc
    property bool expected: true
    property string reason: "manual"

    onExited: function(exitCode) {
      root.applyingIdle = false
      if (exitCode === 0) {
        root.currentIdleEnabled = expected
        root.haveCurrentIdle = true
        root.idleRestoreComplete = true
        root.lastError = ""
        root.lastStatus = root.restoreComplete ? (idleApplyProc.reason === "restore" ? "restored" : "applied") : "restoring"
        root.scheduleSave(root.lastStatus)
      } else {
        root.lastError = "idle " + (expected ? "enable" : "disable") + " failed"
        root.lastStatus = "failed"
      }
    }
  }

  Process {
    id: nightlightApplyProc
    property bool expected: true
    property string reason: "manual"

    onExited: function(exitCode) {
      root.applyingNightlight = false
      if (exitCode === 0) {
        root.currentNightlightEnabled = expected
        root.currentNightlightTemperature = expected ? 4000 : 6000
        root.haveCurrentNightlight = true
        root.desiredNightlightKnown = true
        root.nightlightRestoreComplete = true
        root.lastError = ""
        root.lastStatus = root.restoreComplete ? (nightlightApplyProc.reason === "restore" ? "restored" : "applied") : "restoring"
        root.scheduleSave(root.lastStatus)
      } else {
        root.lastError = "nightlight " + (expected ? "enable" : "disable") + " failed"
        root.lastStatus = "failed"
      }
    }
  }

  Process {
    id: saveProc

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.lastError = "state save failed"
        root.lastStatus = "failed"
      }
    }
  }

  IpcHandler {
    target: "lacuna-settings-persistence"

    function status(): string {
      return JSON.stringify({
        loaded: root.loaded,
        restored: root.restoreComplete,
        applying: root.applying,
        manageIdle: root.manageIdle,
        manageNightlight: root.manageNightlight,
        idleEnabled: root.currentIdleEnabled,
        desiredIdleEnabled: root.desiredIdleEnabled,
        nightlightEnabled: root.currentNightlightEnabled,
        desiredNightlightEnabled: root.desiredNightlightEnabled,
        nightlightTemperature: root.currentNightlightTemperature,
        stateFile: root.stateFile,
        status: root.lastStatus,
        error: root.lastError,
        updatedAt: root.lastUpdatedAt
      })
    }

    function setManaged(idle: string, nightlight: string): string {
      return root.setManagedToggles(idle, nightlight) ? status() : "select-at-least-one-toggle"
    }

    function restore(): string {
      root.idleRestoreComplete = !root.manageIdle
      root.nightlightRestoreComplete = !root.manageNightlight
      root.requestManagedStatus("restore")
      return "restore-requested"
    }
  }
}
