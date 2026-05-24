import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-idle-inhibitor"
  property var settings: ({})
  property bool stayAwake: false

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor(stayAwake ? "active" : "normal", "idle")
  readonly property int intervalMs: Math.max(500, Number(setting("interval", 5000)))
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15
  readonly property bool showInactive: boolSetting("showInactive", false)

  visible: stayAwake || showInactive || mouseArea.containsMouse
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function boolSetting(name, fallback) {
    var value = setting(name, fallback)
    return value === true || String(value).toLowerCase() === "true"
  }

  function parseData(raw) {
    try { return JSON.parse(String(raw || "{}")) } catch (e) { return {} }
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function tooltip() {
    return stayAwake ? "Stay Awake active<br/>Click to allow idle lock" : "Idle locking enabled<br/>Click to stay awake"
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "idle"
  }

  MotionTokens {
    id: motionTokens
  }

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: ["bash", "-lc", "omarchy-shell idle status 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = root.parseData(text)
        root.stayAwake = data && data.enabled === false
      }
    }
    onExited: function(exitCode) { if (exitCode !== 0) root.stayAwake = false }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    width: root.barSize
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.07
    }

    Text {
      anchors.centerIn: parent
      text: "Zz"
      color: root.moduleColor
      opacity: root.stayAwake || mouseArea.containsMouse ? 1 : 0.55
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: Math.max(9, root.topbarIconSize - 3)
      font.bold: true
      renderType: Text.NativeRendering
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
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.MiddleButton) {
          root.refresh()
        } else {
          root.bar.run("omarchy toggle idle")
          refreshDelay.restart()
        }
      }
    }
  }

  Timer {
    id: refreshDelay
    interval: 1500
    onTriggered: root.refresh()
  }
}
