import Quickshell.Io
import QtQuick

Item {
  id: root

  signal pluginStateChanged()

  property string lacunaPath: ""
  property var commandRunner: null
  property var shell: null
  property var pluginRegistry: null
  property var shellConfig: ({})
  property bool loading: false
  property string errorText: ""
  property var state: defaultState()

  readonly property string currentTerminal: stringAt(state, ["defaults", "terminal"])
  readonly property string currentBrowser: stringAt(state, ["defaults", "browser"])
  readonly property string currentEditor: stringAt(state, ["defaults", "editor"])
  readonly property string currentFont: stringAt(state, ["font"])
  readonly property string currentPowerProfile: stringAt(state, ["powerProfile"])
  readonly property string focusedMonitorName: stringAt(state, ["monitor", "name"])
  readonly property string focusedMonitorScale: stringAt(state, ["monitor", "scale"])
  readonly property int idleScreensaver: positiveInt(shellConfig && shellConfig.idle ? shellConfig.idle.screensaver : undefined, 150)
  readonly property int idleLock: positiveInt(shellConfig && shellConfig.idle ? shellConfig.idle.lock : undefined, 300)

  function defaultState() {
    return {
      defaults: { terminal: "", browser: "", editor: "" },
      available: { terminal: {}, browser: {}, editor: {} },
      font: "",
      fonts: [],
      monitor: { name: "", scale: "" },
      powerProfile: "",
      powerAvailable: false,
      toggles: {
        barVisible: true,
        screensaverEnabled: true,
        suspendEnabled: true,
        idleEnabled: null,
        notificationSilencing: null,
        nightlight: null
      }
    }
  }

  function stringAt(source, path) {
    var value = source
    for (var i = 0; i < path.length; i++) {
      if (!value || value[path[i]] === undefined || value[path[i]] === null) return ""
      value = value[path[i]]
    }
    return String(value)
  }

  function boolAt(source, path, fallback) {
    var value = source
    for (var i = 0; i < path.length; i++) {
      if (!value || value[path[i]] === undefined || value[path[i]] === null) return fallback
      value = value[path[i]]
    }
    return value === true ? true : value === false ? false : fallback
  }

  function positiveInt(value, fallback) {
    var parsed = Math.round(Number(value))
    return isFinite(parsed) && parsed > 0 ? parsed : fallback
  }

  function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function option(value, label, description, enabled) {
    return {
      value: value,
      label: label,
      description: description || "",
      enabled: enabled !== false
    }
  }

  function availability(kind, value) {
    var available = state && state.available && state.available[kind] ? state.available[kind] : ({})
    if (available[value] === undefined) return true
    return available[value] === true
  }

  function terminalOptions() {
    return [
      option("foot", "Foot", "Omarchy's default terminal path", availability("terminal", "foot")),
      option("ghostty", "Ghostty", "GPU-rendered terminal", availability("terminal", "ghostty")),
      option("alacritty", "Alacritty", "Fast OpenGL terminal", availability("terminal", "alacritty")),
      option("kitty", "Kitty", "Feature-rich terminal", availability("terminal", "kitty"))
    ]
  }

  function browserOptions() {
    return [
      option("brave", "Brave", "Brave browser", availability("browser", "brave")),
      option("firefox", "Firefox", "Mozilla Firefox", availability("browser", "firefox")),
      option("chromium", "Chromium", "Chromium browser", availability("browser", "chromium")),
      option("zen", "Zen", "Zen Browser", availability("browser", "zen")),
      option("chrome", "Chrome", "Google Chrome", availability("browser", "chrome")),
      option("edge", "Edge", "Microsoft Edge", availability("browser", "edge"))
    ]
  }

  function editorOptions() {
    return [
      option("nvim", "Neovim", "Terminal editor", availability("editor", "nvim")),
      option("code", "VS Code", "Visual Studio Code", availability("editor", "code")),
      option("cursor", "Cursor", "Cursor editor", availability("editor", "cursor")),
      option("zed", "Zed", "Zed editor", availability("editor", "zed")),
      option("helix", "Helix", "Helix editor", availability("editor", "helix")),
      option("vim", "Vim", "Terminal editor", availability("editor", "vim")),
      option("emacs", "Emacs", "GNU Emacs", availability("editor", "emacs"))
    ]
  }

  function fontOptions() {
    var rows = []
    var fonts = state && Array.isArray(state.fonts) ? state.fonts : []
    for (var i = 0; i < fonts.length; i++) {
      rows.push(option(String(fonts[i]), String(fonts[i]), "Installed font", true))
    }
    if (rows.length === 0 && currentFont !== "") rows.push(option(currentFont, currentFont, "Current font", true))
    return rows
  }

  function powerProfileOptions() {
    return [
      option("performance", "Performance", "Prefer speed", state.powerAvailable === true),
      option("balanced", "Balanced", "Default power profile", state.powerAvailable === true),
      option("power-saver", "Power Saver", "Prefer lower power use", state.powerAvailable === true)
    ]
  }

  function monitorScaleOptions() {
    return [
      option("1", "1", "100%", true),
      option("1.25", "1.25", "125%", true),
      option("1.6", "1.6", "160%", true),
      option("2", "2", "200%", true),
      option("3", "3", "300%", true),
      option("4", "4", "400%", true)
    ]
  }

  function toggleValue(name, fallback) {
    return boolAt(state, ["toggles", name], fallback)
  }

  function refresh() {
    if (loading || lacunaPath === "") return
    loading = true
    errorText = ""
    loadProc.output = ""
    loadProc.command = ["python3", lacunaPath + "/scripts/omarchy-shell-settings-state.py"]
    loadProc.running = true
  }

  function scheduleRefresh() {
    refreshTimer.restart()
  }

  function run(command) {
    if (commandRunner && typeof commandRunner.run === "function") commandRunner.run(command)
    scheduleRefresh()
  }

  function setDefault(kind, value) {
    var target = String(kind || "")
    if (target !== "terminal" && target !== "browser" && target !== "editor") return
    run("omarchy default " + target + " " + quote(value))
  }

  function setFont(value) {
    run("omarchy font set " + quote(value))
  }

  function setPowerProfile(value) {
    run("powerprofilesctl set " + quote(value))
  }

  function setMonitorScale(value) {
    run("omarchy hyprland monitor scaling " + quote(value))
  }

  function setToggle(name, desired) {
    var key = String(name || "")
    var want = desired === true
    if (key === "barVisible") {
      run("omarchy toggle bar " + (want ? "show" : "hide"))
      return
    }

    var current = toggleValue(key, null)
    if (current !== null && current === want) return

    if (key === "screensaverEnabled") run("omarchy toggle screensaver")
    else if (key === "suspendEnabled") run("omarchy toggle suspend")
    else if (key === "idleEnabled") run("omarchy toggle idle")
    else if (key === "notificationSilencing") run("omarchy toggle notification silencing")
    else if (key === "nightlight") run("omarchy toggle nightlight")
  }

  function mutateShellConfig(mutator) {
    if (shell && typeof shell.mutateShellConfig === "function") {
      shell.mutateShellConfig(mutator)
      scheduleRefresh()
      return true
    }
    run("notify-send 'Lacuna' 'Omarchy shell settings require the live shell config mutator'")
    return false
  }

  function setIdleTimeout(kind, seconds) {
    var key = String(kind || "")
    var value = positiveInt(seconds, key === "lock" ? 300 : 150)
    if (key !== "screensaver" && key !== "lock") return

    mutateShellConfig(function(config) {
      if (!config.idle || typeof config.idle !== "object") config.idle = {}
      config.idle[key] = value
    })
  }

  function setShellPluginEnabled(id, enabled) {
    if (pluginRegistry && typeof pluginRegistry.setEnabled === "function") {
      pluginRegistry.setEnabled(id, enabled === true)
      pluginStateChanged()
      scheduleRefresh()
      return
    }

    run("notify-send 'Lacuna' 'Plugin toggles require the Omarchy shell plugin registry'")
  }

  Component.onCompleted: refresh()

  Timer {
    id: refreshTimer
    interval: 1200
    repeat: false
    onTriggered: root.refresh()
  }

  Process {
    id: loadProc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) {
        loadProc.output += data
      }
    }

    stderr: SplitParser {
      onRead: function(data) {
        root.errorText = String(data || "").trim()
      }
    }

    onExited: function(exitCode) {
      root.loading = false
      if (exitCode !== 0) {
        if (root.errorText === "") root.errorText = "Unable to read Omarchy settings state"
        return
      }
      try {
        root.state = JSON.parse(loadProc.output || "{}")
      } catch (error) {
        root.errorText = "Unable to parse Omarchy settings state"
      }
    }
  }
}
