import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-bar-size-pill"
  property var settings: ({})
  property string mode: "full"
  property string tooltipText: ""

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.statusColor("active", "density")
  readonly property int intervalMs: Math.max(500, Number(setting("interval", 1000)))
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 15
  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/bar-size-state"))
  readonly property url iconSource: mode === "full" ? Qt.resolvedUrl("assets/tabler/arrows-minimize.svg") : Qt.resolvedUrl("assets/tabler/arrows-maximize.svg")

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function refresh() {
    if (!readProc.running) readProc.running = true
  }

  function toggle() {
    if (!toggleProc.running) toggleProc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "density"
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
    id: readProc
    command: [root.scriptPath, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyPayload(text)
    }
  }

  Process {
    id: toggleProc
    command: [root.scriptPath, "toggle"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyPayload(text)
    }
  }

  function applyPayload(raw) {
    try {
      var payload = JSON.parse(String(raw || "{}"))
      mode = payload.mode || "full"
      tooltipText = payload.tooltip || ""
    } catch (e) {
      mode = "full"
      tooltipText = ""
    }
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

    Image {
      anchors.centerIn: parent
      source: root.iconSource
      width: root.topbarIconSize
      height: root.topbarIconSize
      sourceSize.width: width
      sourceSize.height: height
      smooth: true
      mipmap: true
      layer.enabled: true
      layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: root.moduleColor
      }
      opacity: 0.88 + button.hoverReveal * 0.12
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
      acceptedButtons: Qt.LeftButton
      onEntered: if (bar && root.tooltipText) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: root.toggle()
    }
  }
}
