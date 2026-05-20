import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-script-pill"
  property var settings: ({})
  property string displayText: ""
  property string tooltipText: ""
  property string cssClass: "hidden"
  property bool pendingRefresh: false

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property color accent: colorProfile.statusColor(cssClass, "script")
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 30000)))
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 32)))
  readonly property string script: String(setting("script", ""))
  readonly property bool showWhenEmpty: setting("showWhenEmpty", false) === true
  readonly property string command: script.length > 0 ? resolveCommand(script) : ""

  visible: (showWhenEmpty || displayText.length > 0) && cssClass !== "hidden"
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function shellQuote(value) {
    if (bar && bar.shellQuote) return bar.shellQuote(value)
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function resolveCommand(value) {
    var text = String(value || "")
    if (text.indexOf("/") === 0 || text.indexOf("~") === 0) return text
    if (text.indexOf("scripts/") === 0) return shellQuote(localPath(Qt.resolvedUrl(text)))
    return text
  }

  function clipped(value) {
    var text = String(value || "")
    if (text.length <= maxTextLength) return text
    return text.slice(0, Math.max(1, maxTextLength - 1)) + "..."
  }

  function refresh() {
    if (!command) return
    if (proc.running) {
      pendingRefresh = true
      return
    }

    pendingRefresh = false
    proc.output = ""
    proc.command = ["bash", "-lc", command]
    proc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "script"
  }

  MotionTokens {
    id: motionTokens
  }

  Timer {
    interval: root.intervalMs
    running: root.command.length > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: proc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) {
        proc.output += data
      }
    }

    onExited: {
      var raw = String(proc.output || "").trim()
      try {
        var payload = JSON.parse(raw || "{}")
        root.displayText = root.clipped(payload.text || "")
        root.tooltipText = payload.tooltip || ""
        root.cssClass = payload.class || ""
      } catch (e) {
        root.displayText = root.clipped(raw)
        root.tooltipText = raw
        root.cssClass = raw.length > 0 ? "normal" : "hidden"
      }

      if (root.pendingRefresh) root.refresh()
    }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0
    readonly property int horizontalPadding: root.vertical ? 0 : 8

    width: root.vertical ? root.barSize : Math.max(32, label.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, label.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height
    clip: true

    Rectangle {
      anchors.fill: parent
      color: root.accent
      opacity: button.hoverReveal * 0.06
    }

    Text {
      id: label
      anchors.centerIn: parent
      rotation: root.vertical ? -90 : 0
      text: root.displayText
      color: root.accent
      font.family: bar ? bar.fontFamily : "monospace"
      font.pixelSize: 12
      maximumLineCount: 1
      elide: Text.ElideRight
    }

    Behavior on hoverReveal {
      NumberAnimation {
        duration: motionTokens.hoverDuration
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onEntered: if (bar && root.tooltipText) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: root.refresh()
    }
  }
}
