import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.indicators"
  property var settings: ({})
  property bool nightlight: false
  property bool stayAwake: false
  property bool recording: false
  property string dictationState: "idle"

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color background: bar ? bar.background : "#101315"
  readonly property color fallbackBright: colorProfile.themeColor("color15", foreground)
  property int hoveredIndicators: 0
  readonly property bool showInactive: boolSetting("showInactive", false)
  readonly property var notificationService: bar && bar.shell && typeof bar.shell.firstPartyServiceFor === "function"
    ? bar.shell.firstPartyServiceFor("omarchy.notifications")
    : null
  readonly property int pendingCount: notificationService ? notificationService.pendingModel.count : 0
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false
  readonly property bool hasActiveIndicator: hasConfiguredActiveIndicator()
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15

  implicitWidth: indicatorRow.implicitWidth
  implicitHeight: indicatorRow.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && hoveredIndicators > 0

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function boolSetting(name, fallback) {
    var value = setting(name, fallback)
    if (value === true || value === false) return value
    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallback
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

  function hasConfiguredActiveIndicator() {
    var items = configuredItems()
    for (var i = 0; i < items.length; i++) {
      if (indicatorActive(items[i])) return true
    }
    return false
  }

  function indicatorActive(id) {
    if (id === "Dnd") return dnd || pendingCount > 0
    if (id === "NightLight") return nightlight
    if (id === "StayAwake") return stayAwake
    if (id === "ScreenRecording") return recording
    if (id === "Dictation") return dictationState === "recording" || dictationState === "transcribing"
    return false
  }

  function indicatorIcon(id) {
    if (id === "Dnd") return dnd ? "󰂛" : pendingCount > 0 ? "󱅫" : "󰂚"
    if (id === "NightLight") return "󰔎"
    if (id === "StayAwake") return "Zz"
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

  function indicatorColorRole(id) {
    if (id === "Dnd") return "color13"
    if (id === "NightLight") return "color11"
    if (id === "StayAwake") return "color14"
    if (id === "ScreenRecording") return "color9"
    if (id === "Dictation") return "color6"
    return "foreground"
  }

  function luminance(value) {
    return (0.2126 * value.r) + (0.7152 * value.g) + (0.0722 * value.b)
  }

  function contrastDistance(a, b) {
    return Math.abs(luminance(a) - luminance(b))
      + Math.abs(a.r - b.r) * 0.18
      + Math.abs(a.g - b.g) * 0.18
      + Math.abs(a.b - b.b) * 0.18
  }

  function readableIndicatorColor(id, active) {
    var candidate = colorProfile.statusColor(active ? "active" : "normal", indicatorColorRole(id))
    if (contrastDistance(candidate, background) >= 0.24) return candidate
    if (contrastDistance(foreground, background) >= 0.24) return foreground
    return fallbackBright
  }

  function indicatorTooltip(id) {
    if (id === "Dnd") {
      if (dnd) return "Do Not Disturb<br/>Right click to allow notifications"
      if (pendingCount > 0) return pendingCount + " pending notification" + (pendingCount === 1 ? "" : "s")
      return "No notifications<br/>Right click to silence notifications"
    }
    if (id === "NightLight") return nightlight ? "Day Light" : "Night Light"
    if (id === "StayAwake") return stayAwake ? "Allow idle lock & screensaver" : "Stay Awake"
    if (id === "ScreenRecording") return recording ? "Stop recording" : "Screen Recording"
    if (id === "Dictation") return dictationState === "idle" ? "Dictate" : dictationState
    return id
  }

  function toggleIndicator(id, button) {
    if (!bar) return
    if (id === "Dnd") {
      if (button === Qt.RightButton) {
        if (notificationService) notificationService.setDoNotDisturb(!notificationService.doNotDisturb)
        else bar.run("omarchy toggle notification silencing")
      } else {
        bar.run("omarchy shell notifications showHistory")
      }
    } else if (id === "NightLight") {
      if (button === Qt.MiddleButton) root.refresh()
      else bar.run("omarchy toggle nightlight")
      refreshDelay.restart()
    } else if (id === "StayAwake") {
      if (button === Qt.MiddleButton) root.refresh()
      else bar.run("omarchy toggle idle")
      refreshDelay.restart()
    } else if (id === "ScreenRecording") {
      if (button === Qt.MiddleButton) root.refresh()
      else if (recording) bar.run("omarchy capture screenrecording --stop-recording")
      else bar.run("omarchy capture screenrecording")
      refreshDelay.restart()
    } else if (id === "Dictation") {
      if (button === Qt.RightButton) bar.run("omarchy voxtype config")
      else bar.run("omarchy voxtype model")
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
    command: ["omarchy", "toggle", "nightlight", "--status"]
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
    command: ["bash", "-lc", "omarchy shell idle status 2>/dev/null"]
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
    command: ["bash", "-lc", "omarchy voxtype status"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        var parsed = root.parseData(data)
        root.dictationState = String(parsed.alt || parsed.class || "idle")
      }
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
        readonly property color indicatorColor: root.readableIndicatorColor(indicatorId, active)
        property real hoverReveal: clickArea.containsMouse || clickArea.pressed ? 1 : 0

        visible: active || root.showInactive
        width: root.barSize
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
          opacity: indicatorButton.active || clickArea.containsMouse ? 1 : 0.72
          font.family: root.bar ? root.bar.fontFamily : "monospace"
          font.pixelSize: indicatorButton.indicatorId === "StayAwake" ? Math.max(9, root.topbarIconSize - 3) : root.topbarIconSize
          font.bold: indicatorButton.indicatorId === "StayAwake"
          renderType: Text.NativeRendering
        }

        Rectangle {
          visible: indicatorButton.indicatorId === "Dnd" && root.pendingCount > 0 && !root.dnd
          anchors.right: parent.right
          anchors.rightMargin: 4
          anchors.top: parent.top
          anchors.topMargin: 4
          width: 5
          height: 5
          radius: 2.5
          color: indicatorButton.indicatorColor
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
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          onEntered: {
            root.hoveredIndicators++
            if (root.bar) root.bar.showTooltip(root, root.indicatorTooltip(indicatorButton.indicatorId))
          }
          onExited: {
            root.hoveredIndicators = Math.max(0, root.hoveredIndicators - 1)
            if (root.bar) root.bar.hideTooltip(root)
          }
          onClicked: function(mouse) { root.toggleIndicator(indicatorButton.indicatorId, mouse.button) }
        }
      }
    }
  }
}
