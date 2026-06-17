import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.claude-usage"
  property var settings: ({})

  property string displayText: ""
  property string shortText: ""
  property string tooltipText: ""
  property string cssClass: "hidden"
  property string resetText: ""
  property string startText: ""
  property string latestText: ""
  property string sourceText: ""
  property int leftPercent: 100
  property int usedPercent: 0
  property int tokenCount: 0
  property int tokenLimit: 0
  property int sessionCount: 0
  property int entriesCount: 0
  property var modelsList: []
  property bool activeBlock: false
  property bool pendingRefresh: false
  property bool loadedOnce: false
  property bool flyoutOpen: false

  // Weekly (trailing 7-day) readout, cycled into the bar alongside the 5h block.
  property string weekText: ""
  property string weekShortText: ""
  property string weekClass: "idle"
  property string weekResetText: ""
  property int weekLeftPercent: 100
  property int weekUsedPercent: 0
  property int weekTokens: 0
  property int weekLimit: 0
  property bool weekActive: false

  // 0 = 5h block, 1 = weekly. Advanced on a loop while idle.
  property int displayCycle: 0

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color background: bar ? bar.background : "#101315"
  readonly property color moduleColor: colorProfile.statusColor(activeClass, "claude")
  readonly property color sessionModuleColor: colorProfile.statusColor(cssClass, "claude")
  readonly property color weekModuleColor: colorProfile.statusColor(weekClass, "claude")
  readonly property color mutedColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)
  readonly property color trackColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
  readonly property int intervalMs: Math.max(5000, Number(setting("interval", 30000)))
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 32)))
  readonly property bool showIcon: setting("showIcon", true) === true
  readonly property bool showReset: setting("showReset", true) === true
  readonly property bool showProgress: setting("showProgress", true) === true
  readonly property bool showIdle: setting("showIdle", true) === true
  readonly property bool showWeekly: setting("showWeekly", true) === true
  readonly property int cycleMs: Math.max(2000, Number(setting("cycleInterval", 6000)))
  readonly property string displayMode: String(setting("displayMode", "left"))
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/claude-code-status.sh"))
  readonly property url iconSource: Qt.resolvedUrl("assets/claude-ai.svg")

  // Cycling between the 5h block (mode 0) and the 7-day window (mode 1). Weekly
  // only joins the rotation once it has real data and the setting is on.
  readonly property bool weeklyReady: loadedOnce && showWeekly && weekActive
  readonly property int activeMode: (weeklyReady && (displayCycle % 2 === 1)) ? 1 : 0
  readonly property string activeClass: activeMode === 1 ? weekClass : cssClass
  readonly property bool actionableState: activeClass === "alert" || activeClass === "low" || activeClass === "over"
  readonly property bool hiddenState: cssClass === "hidden" || (!showIdle && cssClass === "idle" && !weeklyReady)
  readonly property string sessionPrimary: clipped(displayMode === "percent" ? shortText : displayText)
  readonly property string weekPrimary: clipped(displayMode === "percent" ? weekShortText : weekText)
  readonly property string primaryText: activeMode === 1 ? weekPrimary : sessionPrimary
  readonly property string secondaryText: {
    if (!showReset) return ""
    if (activeMode === 1) return weekActive && weekResetText.length > 0 ? weekResetText : ""
    if (activeBlock && resetText.length > 0) return resetText
    if (!activeBlock && loadedOnce) return "idle"
    return ""
  }

  visible: !hiddenState && primaryText.length > 0
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

  function boundedPercent(value, fallback) {
    var number = Math.round(Number(value))
    if (!isFinite(number)) return fallback
    return Math.max(0, Math.min(100, number))
  }

  function clipped(value) {
    var text = String(value || "")
    if (text.length <= maxTextLength) return text
    return text.slice(0, Math.max(1, maxTextLength - 1)) + "..."
  }

  function close() {
    flyoutOpen = false
  }

  function toggleFlyout() {
    flyoutOpen = !flyoutOpen
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

  function applyPayload(raw) {
    try {
      var payload = JSON.parse(String(raw || "{}"))
      displayText = String(payload.text || "")
      shortText = String(payload.shortText || displayText)
      tooltipText = String(payload.tooltip || "")
      cssClass = String(payload.class || "")
      leftPercent = boundedPercent(payload.leftPercent, 100)
      usedPercent = boundedPercent(payload.usedPercent, Math.max(0, 100 - leftPercent))
      tokenCount = Math.max(0, Math.round(Number(payload.tokens || 0)))
      tokenLimit = Math.max(0, Math.round(Number(payload.limit || 0)))
      sessionCount = Math.max(0, Math.round(Number(payload.sessionCount || 0)))
      activeBlock = payload.active === true
      resetText = String(payload.resetText || "")
      startText = String(payload.startText || "")
      latestText = String(payload.latestText || "")
      sourceText = String(payload.source || "")
      entriesCount = Math.max(0, Math.round(Number(payload.entries || 0)))
      modelsList = Array.isArray(payload.models) ? payload.models : []
      weekActive = payload.weekActive === true
      weekText = String(payload.weekText || "")
      weekShortText = String(payload.weekShortText || weekText)
      weekClass = String(payload.weekClass || "idle")
      weekResetText = String(payload.weekResetText || "")
      weekLeftPercent = boundedPercent(payload.weekLeftPercent, 100)
      weekUsedPercent = boundedPercent(payload.weekUsedPercent, Math.max(0, 100 - weekLeftPercent))
      weekTokens = Math.max(0, Math.round(Number(payload.weekTokens || 0)))
      weekLimit = Math.max(0, Math.round(Number(payload.weekLimit || 0)))
      loadedOnce = true
    } catch (e) {
      displayText = ""
      shortText = ""
      tooltipText = "<b>Claude Code Usage</b><br/>Could not read usage payload"
      cssClass = "hidden"
    }
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

  // Loop the bar readout between the 5h block and the 7-day window. Pauses while
  // the user is hovering or has the panel open, so the value can't roll out from
  // under them mid-read.
  Timer {
    interval: root.cycleMs
    running: root.weeklyReady && !root.flyoutOpen && !mouseArea.containsMouse
    repeat: true
    onTriggered: root.displayCycle = (root.displayCycle + 1) % 2
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
      root.applyPayload(proc.output)
      if (root.pendingRefresh) root.refresh()
    }
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0
    readonly property int horizontalPadding: root.vertical ? 0 : 8
    readonly property int minimumWidth: root.vertical ? root.barSize : 44
    readonly property int meterHeight: root.showProgress && !root.vertical ? 2 : 0

    width: root.vertical ? root.barSize : Math.max(minimumWidth, content.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, content.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height
    clip: true

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: (root.actionableState ? 0.08 : 0) + button.hoverReveal * 0.06
    }

    Rectangle {
      visible: root.showProgress && !root.vertical
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: 7
      anchors.rightMargin: 7
      anchors.bottomMargin: 3
      height: button.meterHeight
      radius: height / 2
      color: root.trackColor

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(parent.height, Math.round(parent.width * root.usedPercent / 100))
        radius: height / 2
        color: root.moduleColor
        opacity: 0.86

        Behavior on width {
          NumberAnimation {
            duration: motionTokens.colorDuration
            easing.type: Easing.OutCubic
          }
        }
      }
    }

    Row {
      id: content
      anchors.centerIn: parent
      anchors.verticalCenterOffset: button.meterHeight > 0 ? -1 : 0
      spacing: 4
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
          colorizationColor: root.moduleColor
        }
      }

      BarCycleText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.primaryText
        color: root.moduleColor
        fontFamily: bar ? bar.fontFamily : "monospace"
        pixelSize: 14
        fontWeight: root.actionableState ? Font.DemiBold : Font.Normal
        colorDuration: motionTokens.colorDuration
      }

      BarCycleText {
        id: resetLabel
        visible: !root.vertical && root.secondaryText.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.secondaryText
        color: root.actionableState ? root.moduleColor : root.mutedColor
        fontFamily: bar ? bar.fontFamily : "monospace"
        pixelSize: 11
        colorDuration: motionTokens.colorDuration
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
      onEntered: if (bar && root.tooltipText && !root.flyoutOpen) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton) {
          root.refresh()
          return
        }
        if (bar) bar.hideTooltip(root)
        root.toggleFlyout()
      }
    }
  }

  ClaudeUsageFlyout {
    id: flyout
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.flyoutOpen

    panelColor: root.background
    accentColor: root.sessionModuleColor
    foreground: root.foreground
    mutedColor: root.mutedColor
    trackColor: root.trackColor
    fontFamily: bar ? bar.fontFamily : "monospace"
    iconSource: root.iconSource

    leftPercent: root.leftPercent
    usedPercent: root.usedPercent
    tokenCount: root.tokenCount
    tokenLimit: root.tokenLimit
    sessionCount: root.sessionCount
    entriesCount: root.entriesCount
    activeBlock: root.activeBlock
    resetText: root.resetText
    startText: root.startText
    latestText: root.latestText
    sourceText: root.sourceText
    models: root.modelsList

    weekActive: root.weekActive
    weekLeftPercent: root.weekLeftPercent
    weekUsedPercent: root.weekUsedPercent
    weekTokens: root.weekTokens
    weekLimit: root.weekLimit
    weekResetText: root.weekResetText
    weekAccentColor: root.weekModuleColor

    onRefreshRequested: root.refresh()
  }
}
