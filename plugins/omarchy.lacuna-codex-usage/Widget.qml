import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-codex-usage"
  property var settings: ({})

  property string displayText: ""
  property string tooltipText: ""
  property string cssClass: "hidden"
  property bool pendingRefresh: false

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color background: bar ? bar.background : "#101315"
  readonly property color moduleColor: colorProfile.roleColor("codex", foreground)
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 300000)))
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 32)))
  readonly property bool showIcon: setting("showIcon", true) === true
  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/codex-weekly-status.sh"))
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/brand-openai.svg")

  visible: cssClass !== "hidden" && displayText.length > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function clipped(value) {
    var text = String(value || "")
    if (text.length <= maxTextLength) return text
    return text.slice(0, Math.max(1, maxTextLength - 1)) + "..."
  }

  function refresh() {
    if (proc.running) {
      pendingRefresh = true
      return
    }

    pendingRefresh = false
    proc.output = ""
    proc.command = [scriptPath]
    proc.running = true
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "codex"
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
    id: proc
    property string output: ""

    stdout: SplitParser {
      onRead: function(data) {
        proc.output += data
      }
    }

    onExited: {
      try {
        var payload = JSON.parse(proc.output || "{}")
        root.displayText = root.clipped(payload.text || "")
        root.tooltipText = payload.tooltip || ""
        root.cssClass = payload.class || ""
      } catch (e) {
        root.displayText = ""
        root.tooltipText = ""
        root.cssClass = "hidden"
      }

      if (root.pendingRefresh) root.refresh()
    }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0
    readonly property int horizontalPadding: root.vertical ? 0 : 8
    readonly property int minimumWidth: root.vertical ? root.barSize : 32

    width: root.vertical ? root.barSize : Math.max(minimumWidth, content.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, content.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height
    clip: true

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.06
    }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: icon.visible && label.text.length > 0 ? 4 : 0
      rotation: root.vertical ? -90 : 0

      Image {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcon
        source: root.iconSource
        width: 14
        height: 14
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: 0.88 + button.hoverReveal * 0.12
        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1.0
          colorizationColor: root.moduleColor
        }
      }

      Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        color: root.moduleColor
        font.family: bar ? bar.fontFamily : "monospace"
        font.pixelSize: 12
        font.weight: Font.Normal
        font.underline: false
        maximumLineCount: 1
        elide: Text.ElideRight
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
      onEntered: if (bar && root.tooltipText) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: root.refresh()
    }
  }
}
