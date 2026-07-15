import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.claude-usage"
  property var settings: ({})

  property string displayText: "Claude"
  property string shortText: "Claude"
  property string tooltipText: "<b>Claude Code Usage</b><br/>Loading usage data"
  property string cssClass: "idle"
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
  readonly property color iconColor: moduleColor
  readonly property color textColor: foreground
  readonly property color mutedColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)
  readonly property color trackColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
  readonly property color seamColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)
  readonly property int intervalMs: Math.max(5000, Number(setting("interval", 30000)))
  readonly property bool compact: !vertical && barSize <= 26
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", compact ? 10 : 32)))
  readonly property bool showIcon: setting("showIcon", true) === true
  readonly property bool showProgress: setting("showProgress", true) === true
  readonly property bool showIdle: setting("showIdle", true) === true
  readonly property bool showWeekly: setting("showWeekly", true) === true
  readonly property int cycleMs: Math.max(2000, Number(setting("cycleInterval", 6000)))
  readonly property string displayMode: String(setting("displayMode", "left"))
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property int topbarTextSize: barSize <= 26 ? 12 : 13
  readonly property int contentSpacing: 5
  readonly property int horizontalPadding: vertical ? 0 : 5
  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/claude-code-status.sh"))
  readonly property url iconSource: Qt.resolvedUrl("assets/claude-ai.svg")

  // Cycling between the 5h block (mode 0) and the 7-day window (mode 1). Weekly
  // only joins the rotation once it has real data and the setting is on.
  readonly property bool weeklyReady: loadedOnce && showWeekly && weekActive
  readonly property int activeMode: (weeklyReady && (displayCycle % 2 === 1)) ? 1 : 0
  readonly property string activeClass: activeMode === 1 ? weekClass : cssClass
  readonly property bool actionableState: activeClass === "alert" || activeClass === "low" || activeClass === "over"
  readonly property bool hiddenState: cssClass === "hidden" || (!showIdle && cssClass === "idle" && !weeklyReady)
  readonly property int activeUsedPercent: activeMode === 1 ? weekUsedPercent : usedPercent
  readonly property string sessionPrimary: clipped((compact || displayMode === "percent") ? shortText : displayText)
  readonly property string weekPrimary: clipped((compact || displayMode === "percent") ? weekShortText : weekText)
  readonly property string primaryText: activeMode === 1 ? weekPrimary : sessionPrimary

  visible: !hiddenState && primaryText.length > 0
  implicitWidth: !hiddenState && primaryText.length > 0 ? button.implicitWidth : 0
  implicitHeight: !hiddenState && primaryText.length > 0 ? button.implicitHeight : 0
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
    readonly property int stableMinimumWidth: root.vertical ? root.barSize : (root.compact ? 58 : 104)
    readonly property int meterHeight: root.showProgress && !root.vertical ? 2 : 0
    readonly property bool meterAtTop: !root.vertical && root.bar && root.bar.position === "top"

    width: root.vertical ? root.barSize : Math.max(stableMinimumWidth, content.implicitWidth + root.horizontalPadding * 2)
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
      anchors.leftMargin: 7
      anchors.rightMargin: 7
      y: button.meterAtTop ? 3 : parent.height - height - 3
      height: button.meterHeight
      radius: height / 2
      color: root.trackColor

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(parent.height, Math.round(parent.width * root.activeUsedPercent / 100))
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
      anchors.verticalCenterOffset: button.meterHeight > 0 ? (button.meterAtTop ? 1 : -1) : 0
      spacing: root.contentSpacing
      rotation: root.vertical ? -90 : 0

      Item {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcon
        width: root.topbarIconSize
        height: root.topbarIconSize

        Image {
          id: icon
          anchors.centerIn: parent
          source: root.iconSource
          width: root.topbarIconSize
          height: root.topbarIconSize
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          layer.enabled: true
          layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: root.iconColor
          }
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcon && label.text.length > 0
        width: 1
        height: Math.max(10, root.topbarIconSize - 1)
        color: root.seamColor
      }

      BarCycleText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.primaryText
        color: root.textColor
        fontFamily: bar ? bar.fontFamily : "Hack Nerd Font Propo"
        pixelSize: root.topbarTextSize
        fontWeight: Font.DemiBold
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
    fontFamily: bar ? bar.fontFamily : "Hack Nerd Font Propo"
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
