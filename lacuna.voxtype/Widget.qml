import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.voxtype"
  property var settings: ({})
  property string dictationState: "idle"

  readonly property bool active: dictationState === "recording" || dictationState === "transcribing"
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor(active ? "active" : "normal", "dictation")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property bool showInactive: boolSetting("showInactive", false)
  readonly property bool shown: active || showInactive

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

  function parseData(raw) {
    try { return JSON.parse(String(raw || "{}")) } catch (e) { return {} }
  }

  function tooltip() {
    if (dictationState === "recording") return "Voxtype recording<br/>Click to change model"
    if (dictationState === "transcribing") return "Voxtype transcribing"
    return "Voxtype idle<br/>Click to dictate"
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "dictation"
  }

  MotionTokens {
    id: motionTokens
  }

  Process {
    command: ["omarchy", "voxtype", "status"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        var parsed = root.parseData(data)
        root.dictationState = String(parsed.alt || parsed.class || "idle")
      }
    }
    onExited: root.dictationState = "idle"
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
      text: root.dictationState === "transcribing" ? "󰔟" : "󰍬"
      color: root.moduleColor
      opacity: root.active ? 1 : 0.55
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
        if (mouse.button === Qt.RightButton) root.bar.run("omarchy voxtype config")
        else root.bar.run("omarchy voxtype model")
      }
    }
  }
}
