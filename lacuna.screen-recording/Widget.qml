import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.screen-recording"
  property var settings: ({})
  property var recordingService: null
  property bool polledRecording: false
  property bool headsUp: false

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool recording: polledRecording || (recordingService ? recordingService.recording : false)
  readonly property color moduleColor: colorProfile.statusColor(recording ? "active" : "normal", "recording")
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property bool showInactive: boolSetting("showInactive", false)
  readonly property bool shown: recording || showInactive
  readonly property int intervalMs: Math.max(500, Number(setting("interval", 1000)))

  visible: shown
  implicitWidth: shown ? button.implicitWidth : 0
  implicitHeight: shown ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function boolSetting(name, fallback) {
    var value = setting(name, fallback)
    return value === true || String(value).toLowerCase() === "true"
  }

  function resolveService() {
    if (recordingService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("lacuna.screen-recording")
      if (ensured) {
        recordingService = ensured
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("lacuna.screen-recording")
      if (existing) recordingService = existing
    }
  }

  function refresh() {
    if (recordingService && typeof recordingService.refresh === "function") recordingService.refresh()
    if (!statusProc.running) statusProc.running = true
  }

  function tooltip() {
    if (recordingService && typeof recordingService.tooltip === "function") return recordingService.tooltip()
    return recording ? "Screen recording active<br/>Click to stop" : "Screen recording<br/>Click to start"
  }

  function toggleRecording() {
    if (recordingService && typeof recordingService.toggleRecording === "function") {
      recordingService.toggleRecording()
      refreshDelay.restart()
    }
  }

  onRecordingChanged: {
    if (recording) {
      headsUp = true
      headsUpTimer.restart()
    } else {
      headsUp = false
      headsUpTimer.stop()
    }
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "recording"
  }

  MotionTokens { id: motionTokens }

  Component.onCompleted: {
    resolveService()
    refresh()
  }
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.recordingService === null
    repeat: true
    onTriggered: root.resolveService()
  }

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay
    interval: 350
    onTriggered: root.refresh()
  }

  Timer {
    id: headsUpTimer
    interval: 2400
    onTriggered: root.headsUp = false
  }

  Process {
    id: statusProc
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(exitCode) { root.polledRecording = exitCode === 0 }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    BarHoverSeam {
      anchors.fill: parent
      reveal: parent.hoverReveal
      seam: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
      accent: colorProfile.accent
    }

    width: root.barSize + (root.headsUp && !root.vertical ? 30 : 0)
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Behavior on width {
      NumberAnimation { duration: motionTokens.quick; easing.type: Easing.OutCubic }
    }

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.07
    }

    Rectangle {
      visible: root.recording
      anchors.centerIn: recordingIcon
      width: root.topbarIconSize + 8
      height: width
      radius: width / 2
      color: "transparent"
      border.width: 1
      border.color: root.moduleColor

      SequentialAnimation on scale {
        running: root.recording
        loops: Animation.Infinite
        NumberAnimation { from: 0.72; to: 1.35; duration: 760; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 140 }
      }
      SequentialAnimation on opacity {
        running: root.recording
        loops: Animation.Infinite
        NumberAnimation { from: 0.78; to: 0.08; duration: 760; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 140 }
      }
    }

    Text {
      id: recordingIcon
      anchors.verticalCenter: parent.verticalCenter
      x: Math.round((root.barSize - width) / 2)
      text: "󰻂"
      color: root.moduleColor
      opacity: root.recording ? 1 : 0.55
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: root.topbarIconSize
      renderType: Text.NativeRendering
    }

    Text {
      visible: root.headsUp && !root.vertical
      anchors.left: recordingIcon.right
      anchors.leftMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      text: "REC"
      color: root.moduleColor
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: Math.max(9, root.topbarIconSize - 3)
      font.bold: true
      renderType: Text.NativeRendering
    }

    Behavior on hoverReveal {
      NumberAnimation { duration: motionTokens.hoverDuration; easing.type: Easing.OutCubic }
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
        if (mouse.button === Qt.MiddleButton) root.refresh()
        else root.toggleRecording()
      }
    }
  }
}
