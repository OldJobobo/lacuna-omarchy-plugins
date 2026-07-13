import QtQuick
import QtQuick.Effects
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.system-update"
  property var settings: ({})
  property bool updateAvailable: false

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor(updateAvailable ? "active" : "normal", "system-update")
  readonly property int intervalMs: Math.max(60000, Number(setting("interval", 21600000)))
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13

  visible: updateAvailable
  implicitWidth: updateAvailable ? button.implicitWidth : 0
  implicitHeight: updateAvailable ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() {
    if (!updateProc.running) updateProc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "system-update"
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
    id: updateProc
    command: ["omarchy", "update", "available"]
    onExited: function(exitCode) { root.updateAvailable = exitCode === 0 }
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
      text: ""
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
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, "Omarchy update available")
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.MiddleButton) root.refresh()
        else root.bar.run("omarchy launch floating terminal with presentation omarchy update")
      }
    }
  }
}
