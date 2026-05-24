import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-claude-usage"
  property var settings: ({})

  property string displayText: ""
  property string tooltipText: ""
  property string cssClass: "hidden"
  property bool pendingRefresh: false

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color activeColor: colorProfile.statusColor(cssClass === "active" ? "normal" : cssClass, "claude")
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 30000)))
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 32)))
  readonly property bool showIcon: setting("showIcon", true) === true
  readonly property int topbarIconSize: barSize >= 32 ? 18 : 14
  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/claude-code-status.sh"))
  readonly property url iconSource: Qt.resolvedUrl("assets/claude-ai.svg")
  readonly property bool activeState: cssClass === "alert" || cssClass === "low" || cssClass === "active" || cssClass === "over"

  visible: cssClass !== "hidden" && displayText.length > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

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
    role: "claude"
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

  Rectangle {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0
    readonly property int horizontalPadding: root.vertical ? 0 : 8
    readonly property int minimumWidth: root.vertical ? root.barSize : 32

    width: root.vertical ? root.barSize : Math.max(minimumWidth, content.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, content.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height
    radius: 0
    color: root.activeState || hoverReveal > 0
      ? Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, root.activeState ? 0.08 + hoverReveal * 0.04 : hoverReveal * 0.06)
      : "transparent"
    border.width: 0
    clip: true

    Behavior on color {
      ColorAnimation {
        duration: motionTokens.colorDuration
        easing.type: Easing.OutCubic
      }
    }

    Behavior on hoverReveal {
      NumberAnimation {
        duration: motionTokens.hoverDuration
        easing.type: Easing.OutCubic
      }
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
        width: root.topbarIconSize
        height: root.topbarIconSize
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: 0.88 + button.hoverReveal * 0.12
        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1.0
          colorizationColor: root.activeColor
        }
      }

      Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        color: root.activeColor
        font.family: bar ? bar.fontFamily : "monospace"
        font.pixelSize: 14
        font.weight: root.activeState ? Font.DemiBold : Font.Normal
        maximumLineCount: 1
        elide: Text.ElideRight
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
