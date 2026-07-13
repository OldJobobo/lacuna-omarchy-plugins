import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.audio"
  property var settings: ({})
  property var audioService: null
  property bool flyoutOpen: false
  readonly property bool opened: flyoutOpen

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool hasSink: audioService ? audioService.hasSink : false
  readonly property bool muted: audioService ? audioService.outputMuted : true
  readonly property real volume: audioService ? audioService.outputVolume : 0
  readonly property int percent: audioService ? audioService.outputPercent : 0
  readonly property color moduleColor: colorProfile.statusColor(!hasSink || muted ? "warning" : "normal", "audio")
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property int wheelStep: Math.max(1, Math.min(25, Number(setting("wheelStep", 5))))
  readonly property string icon: audioService ? audioService.outputIcon : ""

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function setVolume(next) {
    if (audioService && typeof audioService.setOutputVolume === "function")
      audioService.setOutputVolume(next)
  }

  function toggleMute() {
    if (audioService && typeof audioService.toggleOutputMute === "function")
      audioService.toggleOutputMute()
  }

  function close() {
    flyoutOpen = false
  }

  function open() {
    flyoutOpen = true
  }

  function tooltip() {
    if (audioService && typeof audioService.tooltip === "function") return audioService.tooltip()
    if (!hasSink) return "No audio sink"
    return (muted ? "Muted" : "Volume " + percent + "%") + "<br/>Wheel adjusts volume"
  }

  function resolveService() {
    if (audioService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("lacuna.audio")
      if (ensured) {
        audioService = ensured
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("lacuna.audio")
      if (existing) audioService = existing
    }
  }

  function togglePanel() {
    flyoutOpen = !flyoutOpen
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "audio"
  }

  MotionTokens {
    id: motionTokens
  }

  Component.onCompleted: resolveService()
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.audioService === null
    repeat: true
    onTriggered: root.resolveService()
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
      text: root.icon
      color: root.moduleColor
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton) root.toggleMute()
        else {
          root.bar.hideTooltip(root)
          root.togglePanel()
        }
      }
      onWheel: function(wheel) {
        root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep) / 100)
      }
    }
  }

  AudioFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    service: root.audioService
    accentColor: root.moduleColor
    open: root.flyoutOpen
  }
}
