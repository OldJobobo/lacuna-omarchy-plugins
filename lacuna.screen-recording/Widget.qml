import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.screen-recording"
  property var settings: ({})
  property bool recording: false

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor(recording ? "active" : "normal", "recording")
  readonly property int intervalMs: Math.max(500, Number(setting("interval", 1500)))
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15
  readonly property bool showInactive: boolSetting("showInactive", false)

  visible: recording || showInactive
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

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function tooltip() {
    return recording ? "Screen recording active<br/>Click to stop" : "Screen recording<br/>Click to start"
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "recording"
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
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(exitCode) { root.recording = exitCode === 0 }
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
      text: "󰻂"
      color: root.moduleColor
      opacity: root.recording ? 1 : 0.55
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: root.topbarIconSize
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
        } else if (root.recording) {
          root.bar.run("omarchy capture screenrecording --stop-recording")
          refreshDelay.restart()
        } else {
          root.bar.run("omarchy capture screenrecording")
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
