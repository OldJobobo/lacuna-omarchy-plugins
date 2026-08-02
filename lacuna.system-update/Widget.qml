import QtQuick
import QtQuick.Effects
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.system-update"
  property var settings: ({})
  property var systemUpdateService: null
  property bool fallbackUpdateAvailable: false

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool updateAvailable: systemUpdateService ? systemUpdateService.updateAvailable : fallbackUpdateAvailable
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

  function resolveService() {
    if (systemUpdateService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("lacuna.system-update")
      if (ensured) {
        systemUpdateService = ensured
        configureService()
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("lacuna.system-update")
      if (existing) {
        systemUpdateService = existing
        configureService()
      }
    }
  }

  function configureService() {
    if (systemUpdateService && typeof systemUpdateService.setIntervalMs === "function")
      systemUpdateService.setIntervalMs(intervalMs)
  }

  function refresh() {
    if (systemUpdateService && typeof systemUpdateService.refresh === "function") {
      systemUpdateService.refresh()
      return
    }
    if (!updateProc.running) updateProc.running = true
  }

  function triggerPress(button) {
    if (!bar) return
    if (button === Qt.MiddleButton) refresh()
    else if (button === Qt.LeftButton) bar.run("omarchy-launch-floating-terminal-with-presentation omarchy-update")
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "system-update"
  }

  MotionTokens {
    id: motionTokens
    animationDisabled: colorProfile.reduceMotion
  }

  Component.onCompleted: {
    resolveService()
    refresh()
  }
  onBarChanged: resolveService()
  onIntervalMsChanged: configureService()

  Timer {
    interval: 500
    running: root.systemUpdateService === null
    repeat: true
    onTriggered: root.resolveService()
  }

  Timer {
    interval: root.intervalMs
    running: root.systemUpdateService === null
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: updateProc
    command: ["omarchy", "update", "available"]
    onExited: function(exitCode) { root.fallbackUpdateAvailable = exitCode === 0 }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    BarHoverSeam {
      reduceMotion: colorProfile.reduceMotion
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
        root.triggerPress(mouse.button)
      }
    }
  }
}
