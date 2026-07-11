import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.reminders"
  property var settings: ({})
  property int reminderCount: 0
  property string reminderTooltip: "Reminders"
  property bool headsUp: false
  property int previousCount: 0

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color accent: bar ? bar.accent : foreground
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property bool active: reminderCount > 0
  readonly property bool showInactive: setting("showInactive", false) === true
  readonly property bool shown: active || showInactive
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))

  visible: shown
  implicitWidth: shown ? button.implicitWidth : 0
  implicitHeight: shown ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function parse(raw) {
    try { return JSON.parse(String(raw || "{}")) } catch (e) { return ({}) }
  }

  function refresh() {
    if (!reminderProc.running) reminderProc.running = true
  }

  function update(raw) {
    var data = parse(raw)
    var nextCount = Math.max(0, Number(data.count || 0))
    reminderTooltip = String(data.tooltip || (nextCount > 0 ? nextCount + " active reminder" + (nextCount === 1 ? "" : "s") : "Reminders"))
    if (nextCount > previousCount) {
      headsUp = true
      headsUpTimer.restart()
    }
    previousCount = nextCount
    reminderCount = nextCount
  }

  function activate() {
    if (active) Quickshell.execDetached(["omarchy-reminder", "show"])
    else Quickshell.execDetached(["omarchy-reminder", "-i"])
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: headsUpTimer
    interval: 2400
    onTriggered: root.headsUp = false
  }

  Process {
    id: reminderProc
    command: ["omarchy-reminder", "show", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.update(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.update("{}")
    }
  }

  Item {
    id: button
    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    width: root.barSize + (root.headsUp && !root.vertical ? 36 : 0)
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Behavior on width {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
      anchors.fill: parent
      color: root.active ? root.urgent : root.accent
      opacity: button.hoverReveal * 0.06
    }

    Rectangle {
      visible: root.active
      anchors.centerIn: reminderIcon
      width: 22
      height: 22
      radius: 11
      color: "transparent"
      border.width: 1
      border.color: root.urgent
      SequentialAnimation on opacity {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { from: 0.72; to: 0.12; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { from: 0.12; to: 0.72; duration: 900; easing.type: Easing.InCubic }
      }
    }

    Text {
      id: reminderIcon
      anchors.verticalCenter: parent.verticalCenter
      x: Math.round((root.barSize - width) / 2)
      text: "󰢌"
      color: root.active ? root.urgent : root.foreground
      opacity: root.active ? 1 : 0.58
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: root.barSize >= 30 ? 16 : 14
      renderType: Text.NativeRendering
    }

    Text {
      visible: root.headsUp && !root.vertical
      anchors.left: reminderIcon.right
      anchors.leftMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      text: root.reminderCount + " DUE"
      color: root.urgent
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: 10
      font.bold: true
      renderType: Text.NativeRendering
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.reminderTooltip)
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton) root.refresh()
        else root.activate()
      }
    }
  }
}
