import QtQuick
import Quickshell.Services.Pipewire

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.audio"
  property var settings: ({})

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : true
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property int percent: Math.round(volume * 100)
  readonly property color moduleColor: colorProfile.statusColor(muted ? "warning" : "normal", "audio")
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15
  readonly property int wheelStep: Math.max(1, Math.min(25, Number(setting("wheelStep", 5))))
  readonly property string icon: {
    if (!sink || !sink.audio) return ""
    if (muted || volume <= 0) return ""
    if (volume >= 0.67) return ""
    if (volume >= 0.34) return ""
    return ""
  }

  visible: sink !== null
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function setVolume(next) {
    if (!sink || !sink.audio) return
    sink.audio.volume = Math.max(0, Math.min(1.5, next))
  }

  function toggleMute() {
    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
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

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (root.bar) root.bar.showTooltip(root, (root.muted ? "Muted" : "Volume " + root.percent + "%") + "<br/>Wheel adjusts volume")
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton) root.bar.run("omarchy launch floating terminal with presentation omarchy restart audio")
        else root.toggleMute()
      }
      onWheel: function(wheel) {
        root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep) / 100)
      }
    }
  }
}
