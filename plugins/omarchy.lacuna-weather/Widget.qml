import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-weather"
  property var settings: ({})
  property string weatherText: ""

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("weather", foreground)
  readonly property int intervalMs: Math.max(10000, Number(setting("interval", 60000)))
  readonly property bool showText: setting("showText", true) === true
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15
  readonly property string home: Quickshell.env("HOME")
  readonly property string weatherScript: home + "/.config/omarchy/bar/scripts/weather-temp"

  visible: weatherText.length > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() {
    if (!weatherProc.running) weatherProc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "weather"
  }

  MotionTokens {
    id: motionTokens
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: weatherProc
    command: ["bash", "-lc", "[ -x " + shellQuote(root.weatherScript) + " ] && " + shellQuote(root.weatherScript) + " || omarchy-weather-status | head -n 1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.weatherText = String(text || "").trim()
    }
  }

  function shellQuote(value) {
    if (root.bar && root.bar.shellQuote) return root.bar.shellQuote(value)
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0
    readonly property int horizontalPadding: root.vertical ? 0 : 8

    width: root.vertical ? root.barSize : Math.max(root.barSize, content.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, content.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.06
    }

    Row {
      id: content
      anchors.centerIn: parent
      rotation: root.vertical ? -90 : 0
      spacing: root.showText ? 4 : 0

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰖐"
        color: root.moduleColor
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: root.topbarIconSize
        renderType: Text.NativeRendering
      }

      Text {
        visible: root.showText
        anchors.verticalCenter: parent.verticalCenter
        text: root.weatherText
        color: root.moduleColor
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: 12
        maximumLineCount: 1
        renderType: Text.NativeRendering
      }
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, "Weather<br/>" + root.weatherText)
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.MiddleButton) root.refresh()
        else root.bar.run("omarchy-notification-send \"$(omarchy-weather-status)\"")
      }
    }
  }
}
