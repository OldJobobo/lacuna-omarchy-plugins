import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-indicators"
  property var settings: ({})
  property bool nightlight: false
  property bool stayAwake: false
  property bool recording: false
  property string dictationState: "idle"

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool revealInactive: mouseArea.containsMouse
  readonly property var notificationService: bar && bar.shell && typeof bar.shell.firstPartyServiceFor === "function"
    ? bar.shell.firstPartyServiceFor("omarchy.notifications")
    : null
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false
  readonly property bool hasActiveIndicator: dnd || nightlight || stayAwake || recording || dictationState === "recording" || dictationState === "transcribing"
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15

  implicitWidth: Math.max(fallbackButton.visible ? fallbackButton.implicitWidth : 0, indicatorRow.implicitWidth)
  implicitHeight: Math.max(fallbackButton.visible ? fallbackButton.implicitHeight : 0, indicatorRow.implicitHeight)
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function configuredItems() {
    var source = setting("items", ["Dnd", "NightLight", "StayAwake", "ScreenRecording", "Dictation"])
    var result = []
    if (source && typeof source.length === "number") {
      for (var i = 0; i < source.length; i++) result.push(String(source[i]))
    }
    return result.length > 0 ? result : ["Dnd", "NightLight", "StayAwake", "ScreenRecording", "Dictation"]
  }

  function parseData(raw) {
    try { return JSON.parse(String(raw || "{}")) } catch (e) { return {} }
  }

  function refresh() {
    if (!nightlightProc.running) nightlightProc.running = true
    if (!idleProc.running) idleProc.running = true
    if (!recordingProc.running) recordingProc.running = true
  }

  function indicatorActive(id) {
    if (id === "Dnd") return dnd
    if (id === "NightLight") return nightlight
    if (id === "StayAwake") return stayAwake
    if (id === "ScreenRecording") return recording
    if (id === "Dictation") return dictationState === "recording" || dictationState === "transcribing"
    return false
  }

  function indicatorIcon(id) {
    if (id === "Dnd") return "󰂛"
    if (id === "NightLight") return "󰔎"
    if (id === "StayAwake") return "󰅶"
    if (id === "ScreenRecording") return "󰻂"
    if (id === "Dictation") return dictationState === "transcribing" ? "󰔟" : "󰍬"
    return "󰄲"
  }

  function indicatorRole(id) {
    if (id === "Dnd") return "notifications"
    if (id === "NightLight") return "nightlight"
    if (id === "StayAwake") return "idle"
    if (id === "ScreenRecording") return "recording"
    if (id === "Dictation") return "dictation"
    return "indicators"
  }

  function indicatorTooltip(id) {
    if (id === "Dnd") return dnd ? "Allow notifications" : "Silence notifications"
    if (id === "NightLight") return nightlight ? "Day Light" : "Night Light"
    if (id === "StayAwake") return stayAwake ? "Allow idle lock & screensaver" : "Stay Awake"
    if (id === "ScreenRecording") return recording ? "Stop recording" : "Screen Recording"
    if (id === "Dictation") return dictationState === "idle" ? "Dictate" : dictationState
    return id
  }

  function toggleIndicator(id, button) {
    if (!bar) return
    if (id === "Dnd") {
      if (notificationService) notificationService.setDoNotDisturb(!notificationService.doNotDisturb)
      else bar.run("omarchy-toggle-notification-silencing")
    } else if (id === "NightLight") {
      bar.run("omarchy-toggle-nightlight")
      refreshDelay.restart()
    } else if (id === "StayAwake") {
      bar.run("omarchy-toggle-idle")
      refreshDelay.restart()
    } else if (id === "ScreenRecording") {
      bar.run("omarchy-capture-screenrecording")
      refreshDelay.restart()
    } else if (id === "Dictation") {
      if (button === Qt.RightButton) bar.run("omarchy-voxtype-config")
      else bar.run("omarchy-voxtype-model")
    }
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "indicators"
  }

  MotionTokens {
    id: motionTokens
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay
    interval: 1500
    onTriggered: root.refresh()
  }

  Process {
    id: nightlightProc
    command: ["omarchy-toggle-nightlight", "--status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = root.parseData(text)
        root.nightlight = data && data.enabled === true
      }
    }
    onExited: function(exitCode) { if (exitCode !== 0) root.nightlight = false }
  }

  Process {
    id: idleProc
    command: ["bash", "-lc", "omarchy-shell idle status 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = root.parseData(text)
        root.stayAwake = data && data.enabled === false
      }
    }
  }

  Process {
    id: recordingProc
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(exitCode) { root.recording = exitCode === 0 }
  }

  Process {
    command: ["bash", "-lc", "omarchy-voxtype-status"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        var parsed = root.parseData(data)
        root.dictationState = String(parsed.alt || parsed.class || "idle")
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  Item {
    id: fallbackButton

    visible: !root.hasActiveIndicator && !root.revealInactive
    width: root.barSize
    height: root.barSize
    implicitWidth: visible ? width : 0
    implicitHeight: visible ? height : 0

    Text {
      anchors.centerIn: parent
      text: "󰄲"
      color: colorProfile.roleColor("indicators", root.foreground)
      opacity: 0.55
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: root.topbarIconSize
      renderType: Text.NativeRendering
    }
  }

  Row {
    id: indicatorRow
    spacing: 0

    Repeater {
      model: root.configuredItems()

      Item {
        id: indicatorButton

        required property string modelData

        readonly property string indicatorId: String(modelData)
        readonly property bool active: root.indicatorActive(indicatorId)
        readonly property color indicatorColor: root.colorProfile.statusColor(active ? "active" : "normal", root.indicatorRole(indicatorId))
        property real hoverReveal: clickArea.containsMouse || clickArea.pressed ? 1 : 0

        visible: active || root.revealInactive
        width: visible ? root.barSize : 0
        height: root.barSize
        implicitWidth: width
        implicitHeight: visible ? height : 0

        Rectangle {
          anchors.fill: parent
          color: indicatorButton.indicatorColor
          opacity: indicatorButton.hoverReveal * 0.07
        }

        Text {
          anchors.centerIn: parent
          text: root.indicatorIcon(indicatorButton.indicatorId)
          color: indicatorButton.indicatorColor
          opacity: indicatorButton.active ? 1 : 0.45
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
          id: clickArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onEntered: if (root.bar) root.bar.showTooltip(root, root.indicatorTooltip(indicatorButton.indicatorId))
          onExited: if (root.bar) root.bar.hideTooltip(root)
          onClicked: function(mouse) { root.toggleIndicator(indicatorButton.indicatorId, mouse.button) }
        }
      }
    }
  }
}
