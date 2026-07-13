import QtQuick
import Quickshell

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.clock"
  property var settings: ({})
  property bool alt: false
  property date displayDate: clock.date

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("clock", foreground)
  readonly property color dateColor: moduleColor
  readonly property color timeColor: foreground
  readonly property color seamColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)
  readonly property bool compact: !vertical && barSize <= 26
  readonly property int topbarTextSize: barSize <= 26 ? 12 : 13
  readonly property int contentSpacing: 6
  readonly property int horizontalPadding: vertical ? 0 : 7
  readonly property string normalFormat: setting("format", "ddd d h:mm AP")
  readonly property string activeFormat: alt
    ? setting("formatAlt", "dd MMMM 'W'ww yyyy")
    : (vertical ? setting("verticalFormat", "HH\n—\nmm") : (compact ? setting("compactFormat", "h:mm AP") : normalFormat))
  readonly property string displayText: formatted(displayDate)
  readonly property string normalDateFormat: dateFormatPart(normalFormat)
  readonly property string normalTimeFormat: timeFormatPart(normalFormat)
  readonly property string activeDateFormat: alt ? setting("formatAlt", "dd MMMM 'W'ww yyyy") : normalDateFormat
  readonly property string activeTimeFormat: vertical ? setting("verticalFormat", "HH\n—\nmm") : normalTimeFormat
  readonly property string dateText: formattedWith(displayDate, activeDateFormat)
  readonly property string timeText: formattedWith(displayDate, activeTimeFormat)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
  }

  function isoWeekLiteral(date) {
    var week = isoWeek(date)
    return (week < 10 ? "0" : "") + week
  }

  function formatted(date) {
    return Qt.formatDateTime(date, activeFormat.replace(/ww/g, isoWeekLiteral(date)))
  }

  function dateFormatPart(format) {
    var value = String(format || "")
    var hourIndex = value.search(/[hH]/)
    var dateFormat = hourIndex > 0 ? value.slice(0, hourIndex).trim() : ""
    return dateFormat || "ddd d"
  }

  function timeFormatPart(format) {
    var value = String(format || "")
    var hourIndex = value.search(/[hH]/)
    return hourIndex >= 0 ? value.slice(hourIndex).trim() : "h:mm AP"
  }

  function formattedWith(date, format) {
    return Qt.formatDateTime(date, String(format || "").replace(/ww/g, isoWeekLiteral(date)))
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "clock"
  }

  MotionTokens {
    id: motionTokens
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    width: root.vertical ? root.barSize : Math.max(root.barSize, content.implicitWidth + root.horizontalPadding * 2)
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
      spacing: root.contentSpacing

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.dateText
        color: root.dateColor
        font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: root.topbarTextSize
        font.weight: Font.DemiBold
        maximumLineCount: 1
        renderType: Text.NativeRendering
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Math.max(10, root.topbarTextSize)
        color: root.seamColor
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.timeText
        color: root.timeColor
        font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: root.topbarTextSize
        font.weight: Font.DemiBold
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (root.bar) root.bar.showTooltip(root, alt ? "Clock alternate format" : "Clock")
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton && root.bar) root.bar.run("omarchy menu timezone")
        else root.alt = !root.alt
      }
    }
  }
}
