import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var settingsService: null
  property var commandRunner: null
  property string themeName: ""
  property string omarchyPath: Quickshell.env("OMARCHY_PATH") || ((Quickshell.env("HOME") || "") + "/.local/share/omarchy")
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string shellPath: configHome + "/omarchy/current/theme/shell.toml"
  readonly property string barSizeMode: currentMode()
  property string colorsRaw: ""
  property string shellRaw: ""
  property bool colorsLoaded: false
  property bool shellLoaded: false
  property bool suppressApply: false
  property string pendingMode: ""

  function currentMode() {
    if (pendingMode !== "") return pendingMode
    if (!settingsService || !settingsService.data) return "full"
    if (settingsService.normalizeBarSizeMode) return settingsService.normalizeBarSizeMode(settingsService.data.barSizeMode, settingsService.data.compact === true)

    var mode = String(settingsService.data.barSizeMode || "").toLowerCase()
    if (mode === "compact" || mode === "full") return mode
    return settingsService.data.compact === true ? "compact" : "full"
  }

  function settingsLoaded() {
    return settingsService && settingsService.hasLoaded === true
  }

  function setMode(mode) {
    var nextMode = normalizeMode(mode)
    if (!settingsService || !settingsService.save) return

    pendingMode = nextMode
    applyTimer.restart()
    saveModeTimer.restart()
  }

  function normalizeMode(mode) {
    var value = String(mode || "").toLowerCase()
    if (value === "compact" || value === "full") return value
    return "full"
  }

  function desiredValues(mode) {
    if (mode === "full") return { sizeHorizontal: 32, sizeVertical: 34 }
    return { sizeHorizontal: 26, sizeVertical: 28 }
  }

  function parseBarValues(raw) {
    var lines = String(raw || "").split(/\n/)
    var section = ""
    var result = { sizeHorizontal: 0, sizeVertical: 0, valid: false }

    for (var i = 0; i < lines.length; i++) {
      var sectionMatch = lines[i].match(/^\s*\[([^\]]+)\]\s*(#.*)?$/)
      if (sectionMatch) {
        section = String(sectionMatch[1] || "").trim()
        continue
      }

      if (section !== "bar") continue

      var horizontalMatch = lines[i].match(/^\s*size-horizontal\s*=\s*([0-9]+)\s*(#.*)?$/)
      if (horizontalMatch) {
        result.sizeHorizontal = Math.round(Number(horizontalMatch[1]))
        continue
      }

      var verticalMatch = lines[i].match(/^\s*size-vertical\s*=\s*([0-9]+)\s*(#.*)?$/)
      if (verticalMatch) result.sizeVertical = Math.round(Number(verticalMatch[1]))
    }

    result.valid = result.sizeHorizontal > 0 && result.sizeVertical > 0
    return result
  }

  function patchBarValues(raw, sizeHorizontal, sizeVertical) {
    var lines = String(raw || "").split(/\n/)
    if (lines.length > 0 && lines[lines.length - 1] === "") lines.pop()

    var barFound = false
    var inBar = false
    var horizontalFound = false
    var verticalFound = false
    var insertIndex = lines.length

    for (var i = 0; i < lines.length; i++) {
      var sectionMatch = lines[i].match(/^\s*\[([^\]]+)\]\s*(#.*)?$/)
      if (sectionMatch) {
        if (inBar) {
          insertIndex = i
          break
        }

        inBar = String(sectionMatch[1] || "").trim() === "bar"
        if (inBar) barFound = true
        continue
      }

      if (!inBar) continue

      if (lines[i].match(/^\s*size-horizontal\s*=/)) {
        lines[i] = "size-horizontal = " + sizeHorizontal
        horizontalFound = true
      } else if (lines[i].match(/^\s*size-vertical\s*=/)) {
        lines[i] = "size-vertical = " + sizeVertical
        verticalFound = true
      }
    }

    if (barFound) {
      var additions = []
      if (!horizontalFound) additions.push("size-horizontal = " + sizeHorizontal)
      if (!verticalFound) additions.push("size-vertical = " + sizeVertical)
      if (additions.length > 0) lines.splice.apply(lines, [insertIndex, 0].concat(additions))
    } else {
      if (lines.length > 0 && String(lines[lines.length - 1]).trim() !== "") lines.push("")
      lines.push("[bar]")
      lines.push("size-horizontal = " + sizeHorizontal)
      lines.push("size-vertical = " + sizeVertical)
    }

    return lines.join("\n") + "\n"
  }

  function valuesMatch(values, desired) {
    return values.valid
      && values.sizeHorizontal === desired.sizeHorizontal
      && values.sizeVertical === desired.sizeVertical
  }

  function snapshotForCurrentTheme(values) {
    if (!values.valid || String(themeName || "").trim() === "") return null
    return {
      themeName: String(themeName).trim(),
      sizeHorizontal: values.sizeHorizontal,
      sizeVertical: values.sizeVertical
    }
  }

  function currentSnapshot() {
    if (!settingsService || !settingsService.data) return null
    return settingsService.data.barSizeSnapshot || null
  }

  function snapshotMatchesTheme(snapshot) {
    return snapshot
      && String(snapshot.themeName || "") === String(themeName || "").trim()
      && Number(snapshot.sizeHorizontal) > 0
      && Number(snapshot.sizeVertical) > 0
  }

  function savePatch(patch) {
    if (!settingsLoaded() || !settingsService.save) return

    var next = settingsService.normalize ? settingsService.normalize(settingsService.data) : settingsService.data
    if (!next || typeof next !== "object") next = { version: 1 }
    for (var key in patch) next[key] = patch[key]
    settingsService.save(next)
  }

  function applyCurrentMode() {
    if (!settingsLoaded()) return
    if (!colorsLoaded || !shellLoaded || suppressApply) return

    var mode = currentMode()
    var currentValues = parseBarValues(shellRaw)
    var snapshot = currentSnapshot()

    if (mode === "theme") {
      if (!snapshotMatchesTheme(snapshot)) return

      var restored = patchBarValues(shellRaw, snapshot.sizeHorizontal, snapshot.sizeVertical)
      savePatch({ barSizeSnapshot: null })
      if (restored !== shellRaw) writeShell(restored)
      return
    }

    var desired = desiredValues(mode)
    var settingsPatch = {}
    var shouldSaveSettings = false

    if (!snapshotMatchesTheme(snapshot)) {
      var nextSnapshot = snapshotForCurrentTheme(currentValues)
      if (nextSnapshot) {
        settingsPatch.barSizeSnapshot = nextSnapshot
        shouldSaveSettings = true
      }
    }

    if (shouldSaveSettings) savePatch(settingsPatch)
    if (valuesMatch(currentValues, desired)) return

    writeShell(patchBarValues(shellRaw, desired.sizeHorizontal, desired.sizeVertical))
  }

  function writeShell(nextRaw) {
    if (nextRaw === shellRaw) return

    suppressApply = true
    shellRaw = nextRaw
    shellFile.setText(nextRaw)
    suppressApply = false
    reloadShellTheme(nextRaw)
  }

  function reloadShellTheme(nextShellRaw) {
    if (!commandRunner || !commandRunner.run) return
    if (!Qt.btoa) {
      console.warn("lacuna bar size mode: Qt.btoa unavailable; shell theme reload skipped")
      return
    }

    var colorsB64 = Qt.btoa(colorsRaw || "")
    var shellB64 = Qt.btoa(nextShellRaw || shellRaw || "")
    var shellBin = quote(omarchyPath + "/bin/omarchy-shell")
    var command = "OMARCHY_PATH=" + quote(omarchyPath) + " " + shellBin
      + " shell applyTheme " + quote(colorsB64) + " " + quote(shellB64)
    commandRunner.run(command)
  }

  function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  onThemeNameChanged: {
    colorsLoaded = false
    shellLoaded = false
    colorsFile.reload()
    shellFile.reload()
    retryTimer.restart()
  }
  onBarSizeModeChanged: applyTimer.restart()

  Connections {
    target: root.settingsService
    function onLoaded() {
      applyTimer.restart()
    }
  }

  FileView {
    id: colorsFile

    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      root.colorsRaw = text()
      root.colorsLoaded = true
      root.applyTimer.restart()
    }
    onFileChanged: reload()
    onLoadFailed: {
      root.colorsLoaded = false
      retryTimer.restart()
    }
  }

  FileView {
    id: shellFile

    path: root.shellPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.shellRaw = text()
      root.shellLoaded = true
      root.applyTimer.restart()
    }
    onFileChanged: reload()
    onLoadFailed: {
      root.shellLoaded = false
      retryTimer.restart()
    }
  }

  Timer {
    id: applyTimer

    interval: 16
    repeat: false
    onTriggered: root.applyCurrentMode()
  }

  Timer {
    id: saveModeTimer

    interval: 56
    repeat: false
    onTriggered: {
      if (!root.settingsLoaded() || !root.settingsService.save || root.pendingMode === "") return

      var mode = root.pendingMode
      var next = root.settingsService.normalize ? root.settingsService.normalize(root.settingsService.data) : root.settingsService.data
      if (!next || typeof next !== "object") next = { version: 1 }
      next.barSizeMode = mode
      next.compact = mode === "compact"
      next.sizeTransition = {
        holdCompact: root.settingsService.data && root.settingsService.data.compact === true,
        holdUntil: Date.now() + 56
      }
      root.pendingMode = ""
      root.settingsService.save(next)
    }
  }

  Timer {
    id: retryTimer

    interval: 500
    repeat: false
    onTriggered: {
      colorsFile.reload()
      shellFile.reload()
    }
  }
}
