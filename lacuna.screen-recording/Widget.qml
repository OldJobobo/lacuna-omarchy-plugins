import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.screen-recording"
  property var settings: ({})
  property var recordingService: null

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool recording: recordingService ? recordingService.recording : false
  readonly property color moduleColor: colorProfile.statusColor(recording ? "active" : "normal", "recording")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
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
  }

  function tooltip() {
    if (recordingService && typeof recordingService.tooltip === "function") return recordingService.tooltip()
    return recording ? "Screen recording active<br/>Click to stop" : "Screen recording<br/>Click to start"
  }

  function toggleRecording() {
    if (recordingService && typeof recordingService.toggleRecording === "function")
      recordingService.toggleRecording()
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

  Component.onCompleted: resolveService()
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.recordingService === null
    repeat: true
    onTriggered: root.resolveService()
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
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
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
        if (mouse.button === Qt.MiddleButton) root.refresh()
        else root.toggleRecording()
      }
    }
  }
}
