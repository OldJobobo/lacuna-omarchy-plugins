import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.nightlight"
  property var settings: ({})
  property bool nightlight: false

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor(nightlight ? "active" : "normal", "nightlight")
  readonly property int intervalMs: Math.max(500, Number(setting("interval", 5000)))
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property bool showInactive: boolSetting("showInactive", false)
  readonly property bool shown: nightlight || showInactive

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

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function tooltip() {
    return nightlight ? "Night Light active<br/>Click for Day Light" : "Day Light active<br/>Click for Night Light"
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "nightlight"
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
      text: "󰔎"
      color: root.moduleColor
      opacity: root.nightlight ? 1 : 0.55
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
        if (mouse.button === Qt.MiddleButton) {
          root.refresh()
        } else {
          root.bar.run("omarchy toggle nightlight")
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
