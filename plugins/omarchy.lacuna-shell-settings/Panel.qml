import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "settings"

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property var barWidgetRegistry: null
  property var service: null
  property bool closingFromHost: false

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "omarchy.lacuna-shell-settings"
  readonly property string lacunaPath: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl("."))
  readonly property var shellConfig: shell && shell.shellConfig ? shell.shellConfig : ({})
  readonly property var activeService: service || fallbackService

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function parsePayload(payloadJson) {
    try {
      var parsed = JSON.parse(String(payloadJson || "{}"))
      return parsed && typeof parsed === "object" ? parsed : {}
    } catch (e) {
      return {}
    }
  }

  function open(payloadJson) {
    var payload = parsePayload(payloadJson)
    if (payload.section) settingsPanel.currentSection = String(payload.section)
    closingFromHost = false
    window.visible = true
    settingsPanel.forceActiveFocus()
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  QtObject {
    id: registry

    property var pluginRegistry: root.pluginRegistry
    property var barWidgetRegistry: root.barWidgetRegistry
    property var shellPlugins: root.shellConfig && Array.isArray(root.shellConfig.plugins) ? root.shellConfig.plugins : []

    function shellQuote(value) {
      return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function terminalCommand(command, title, holdOpen) {
      var terminalBody = command
      if (holdOpen) {
        terminalBody = command + "; status=$?; printf '\\nCommand exited with status %s. Press Enter to close...' \"$status\"; read -r _; exit \"$status\""
      }
      return "foot --app-id=org.omarchy.terminal --title=" + shellQuote(title || "Lacuna") + " -e bash -lc " + shellQuote(terminalBody)
    }

    function shellPluginEnabled(id) {
      var plugins = Array.isArray(shellPlugins) ? shellPlugins : []
      for (var i = 0; i < plugins.length; i++) {
        if (plugins[i] && String(plugins[i].id || "") === String(id || "")) return true
      }
      return false
    }

    function installedShellPluginRows() {
      if (!pluginRegistry || !pluginRegistry.installedPlugins) return []
      var plugins = pluginRegistry.installedPlugins
      var rows = []
      for (var id in plugins) {
        var manifest = plugins[id]
        if (!manifest || manifest.__isFirstParty) continue
        if (id === "omarchy.lacuna-menu") continue
        rows.push({
          id: id,
          name: manifest.name || id,
          description: manifest.description || id,
          enabled: shellPluginEnabled(id)
        })
      }
      rows.sort(function(a, b) { return a.name.localeCompare(b.name) })
      return rows
    }

    function restartLacunaCommand() {
      return "omarchy restart shell"
    }

    function omarchyShellPath() {
      var path = root.omarchyPath || Quickshell.env("OMARCHY_PATH") || ((Quickshell.env("HOME") || "") + "/.local/share/omarchy")
      return path + "/shell"
    }

    function openLogCommand() {
      return terminalCommand("quickshell log --path " + shellQuote(omarchyShellPath()) + " --tail 200 --newest", "Omarchy Shell Log", false)
    }

    function editShellConfigCommand() {
      var path = (Quickshell.env("HOME") || "") + "/.config/omarchy/shell.json"
      return terminalCommand("${EDITOR:-nvim} " + shellQuote(path), "Omarchy Shell Config", false)
    }

    function debugCommand() {
      return terminalCommand("omarchy debug --print --no-sudo; printf '\\nCommand exited. Press Enter to close...'; read -r _", "Omarchy Debug", false)
    }

    function debugIdleCommand() {
      return terminalCommand("omarchy debug idle; printf '\\nCommand exited. Press Enter to close...'; read -r _", "Omarchy Idle Debug", false)
    }

    function switchThemeCommand() {
      return "theme=$(omarchy theme switcher); [ -n \"$theme\" ] && omarchy theme set \"$theme\""
    }

    function switchBackgroundCommand() {
      return "background=$(omarchy theme bg-switcher); [ -n \"$background\" ] && omarchy theme bg set \"$background\""
    }
  }

  Service {
    id: fallbackService

    shell: root.shell
    manifest: root.manifest
    pluginRegistry: root.pluginRegistry
    shellConfig: root.shellConfig
  }

  FloatingWindow {
    id: window

    title: "Lacuna Shell Settings"
    color: Color.background
    visible: false
    implicitWidth: Style.space(500)
    implicitHeight: Style.space(620)
    minimumSize: Qt.size(Style.space(430), Style.space(460))

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide(root.pluginId)
    }

    Rectangle {
      anchors.fill: parent
      color: Color.background

      OmarchyShellSettingsWindow {
        id: settingsPanel

        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        open: window.visible
        compact: false
        drawBackground: false
        registry: registry
        settingsService: root.activeService
        foreground: Color.foreground
        background: Color.background
        accent: Color.accent
        shellAccent: Color.accent
        sessionAccent: "#ebcb8b"
        dangerAccent: Color.urgent
        navAccent: Color.foreground
        muted: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.48)
        onActivated: function(entry) {
          if (entry.command && root.activeService && root.activeService.commandRunner && typeof root.activeService.commandRunner.run === "function")
            root.activeService.commandRunner.run(entry.command)
        }
        onCloseRequested: root.close()
      }
    }
  }
}
