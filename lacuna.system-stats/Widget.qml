import QtQuick
import QtQuick.Effects

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.system-stats"
  property var settings: ({})
  property var manifest: null
  property var statsService: null
  property bool subscribed: false
  property bool flyoutOpen: false
  property string flyoutMode: "cpu"
  readonly property bool opened: flyoutOpen
  readonly property int historyLimit: 60

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color urgent: bar ? bar.urgent : "#d42b5b"
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))
  readonly property bool compact: !vertical && barSize <= 26
  readonly property int buttonSpacing: compact ? 0 : 2
  readonly property bool showLabels: setting("showLabels", compact ? false : true) === true
  readonly property int cpuPercent: statsService ? statsService.cpuPercent : 0
  readonly property int memoryPercent: statsService ? statsService.memoryPercent : 0
  readonly property string diskText: statsService ? statsService.diskText : "--"
  readonly property int diskPercent: statsService ? statsService.diskPercent : 0
  readonly property var snapshot: statsService ? statsService.snapshot : ({})
  readonly property var cpuHistory: statsService ? statsService.cpuHistory : []
  readonly property var memoryHistory: statsService ? statsService.memoryHistory : []
  readonly property var diskHistory: statsService ? statsService.diskHistory : []
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property int topbarTextSize: barSize <= 26 ? 12 : 13
  readonly property int contentSpacing: 5
  readonly property int horizontalPadding: 0
  readonly property int metricValueWidth: Math.ceil(metricFontMetrics.advanceWidth("100%"))

  visible: true
  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function resolveService() {
    if (statsService || !bar || !bar.shell) return
    if (typeof bar.shell.ensureService === "function") statsService = bar.shell.ensureService("lacuna.system-stats")
    if (!statsService && typeof bar.shell.serviceFor === "function") statsService = bar.shell.serviceFor("lacuna.system-stats")
    syncSubscription()
  }

  function syncSubscription() {
    if (!statsService) return
    var shouldSubscribe = root.visible
    if (shouldSubscribe && !subscribed) {
      statsService.subscribe(root)
      subscribed = true
    } else if (!shouldSubscribe && subscribed) {
      statsService.unsubscribe(root)
      subscribed = false
    }
  }

  function refresh() {
    resolveService()
    if (statsService) statsService.refresh()
  }

  function openMetric(metric) {
    flyoutMode = metric
    flyoutOpen = true
    if (bar) bar.hideTooltip(root)
  }

  function open() { openMetric("cpu") }
  function close() { flyoutOpen = false }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "cpu"
  }

  MotionTokens {
    id: motionTokens
    animationDisabled: colorProfile.reduceMotion
  }

  FontMetrics {
    id: metricFontMetrics
    font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
    font.pixelSize: root.topbarTextSize
    font.weight: Font.DemiBold
  }

  Component.onCompleted: refresh()
  Component.onDestruction: if (subscribed && statsService) statsService.unsubscribe(root)
  onBarChanged: resolveService()
  onVisibleChanged: syncSubscription()

  Timer {
    interval: 500
    running: root.statsService === null
    repeat: true
    onTriggered: root.resolveService()
  }

  Row {
    id: content
    spacing: root.buttonSpacing

    StatButton {
      id: diskButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/database-filled.svg")
      label: root.diskText
      tooltip: "<b>Disk usage</b><br/>Root filesystem: " + root.diskText
      accent: colorProfile.roleColor("disk", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
      showLabel: root.showLabels
      valueWidth: root.metricValueWidth
      metric: "disk"
    }

    StatButton {
      id: memButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/stack-3-filled.svg")
      label: root.memoryPercent + "%"
      tooltip: "<b>Memory usage</b><br/>" + root.memoryPercent + "% used"
      accent: root.memoryPercent >= 90 ? root.urgent : colorProfile.roleColor("memory", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
      showLabel: root.showLabels
      valueWidth: root.metricValueWidth
      metric: "memory"
    }

    StatButton {
      id: cpuButton
      bar: root.bar
      iconSource: Qt.resolvedUrl("assets/tabler/cpu.svg")
      label: root.cpuPercent + "%"
      tooltip: "<b>CPU usage</b><br/>" + root.cpuPercent + "% used"
      accent: root.cpuPercent >= 90 ? root.urgent : colorProfile.roleColor("cpu", root.foreground)
      vertical: root.vertical
      barSize: root.barSize
      hoverDuration: motionTokens.hoverDuration
      showLabel: root.showLabels
      valueWidth: root.metricValueWidth
      metric: "cpu"
    }
  }

  component StatButton: Item {
    property var bar: null
    property url iconSource: ""
    property string label: ""
    property string tooltip: ""
    property color accent: "#d8dee9"
    property bool vertical: false
    property int barSize: 26
    property int hoverDuration: 150
    property bool showLabel: true
    property int valueWidth: 0
    property string metric: "cpu"
    property bool compact: !vertical && barSize <= 26
    property color foreground: bar ? bar.foreground : "#d8dee9"
    property int topbarIconSize: barSize >= 30 ? 15 : 13
    property int topbarTextSize: barSize <= 26 ? 12 : 13
    property int contentSpacing: 5
    property int horizontalPadding: 0
    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    BarHoverSeam {
      reduceMotion: colorProfile.reduceMotion
      anchors.fill: parent
      reveal: parent.hoverReveal
      seam: parent.bar ? Qt.rgba(parent.bar.foreground.r, parent.bar.foreground.g, parent.bar.foreground.b, 0.35) : "#888888"
      accent: parent.accent
    }

    width: vertical ? barSize : Math.max(compact ? barSize : 36, content.implicitWidth + horizontalPadding * 2)
    height: vertical ? Math.max(barSize, content.implicitHeight + 10) : barSize
    implicitWidth: width
    implicitHeight: height
    readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

    Rectangle {
      anchors.fill: parent
      color: parent.accent
      opacity: parent.hoverReveal * 0.06
    }

    Row {
      id: content
      anchors.centerIn: parent
      rotation: parent.vertical ? -90 : 0
      spacing: content.parent.contentSpacing

      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: content.parent.topbarIconSize
        height: content.parent.topbarIconSize

        Image {
          anchors.centerIn: parent
          source: content.parent.iconSource
          width: content.parent.topbarIconSize
          height: content.parent.topbarIconSize
          sourceSize.width: width
          sourceSize.height: height
          smooth: true
          mipmap: true
          layer.enabled: true
          layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: content.parent.accent
          }
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: content.parent.showLabel
        width: 1
        height: Math.max(10, content.parent.topbarIconSize - 1)
        color: Qt.rgba(content.parent.foreground.r, content.parent.foreground.g, content.parent.foreground.b, 0.18)
      }

      Text {
        visible: content.parent.showLabel
        anchors.verticalCenter: parent.verticalCenter
        width: content.parent.valueWidth
        text: content.parent.label
        color: content.parent.foreground
        font.family: content.parent.bar ? content.parent.bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: content.parent.topbarTextSize
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignLeft
        maximumLineCount: 1
      }
    }

    Behavior on hoverReveal {
      NumberAnimation {
        duration: hoverDuration
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      onEntered: if (parent.bar && parent.tooltip) parent.bar.showTooltip(parent, parent.tooltip)
      onExited: if (parent.bar) parent.bar.hideTooltip(parent)
      onClicked: root.openMetric(parent.metric)
    }
  }

  TelemetryFlyout {
    reduceMotion: colorProfile.reduceMotion
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.flyoutOpen
    mode: root.flyoutMode
    cpuPercent: root.cpuPercent
    memoryPercent: root.memoryPercent
    diskPercent: root.diskPercent
    cpuHistory: root.cpuHistory
    memoryHistory: root.memoryHistory
    diskHistory: root.diskHistory
    snapshot: root.snapshot
    cpuAccent: colorProfile.roleColor("cpu", root.foreground)
    memoryAccent: colorProfile.roleColor("memory", root.foreground)
    diskAccent: colorProfile.roleColor("disk", root.foreground)
  }
}
