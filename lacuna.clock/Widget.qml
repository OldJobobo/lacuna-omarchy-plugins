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
  readonly property string activeFormat: alt
    ? setting("formatAlt", "dd MMMM 'W'ww yyyy")
    : (vertical ? setting("verticalFormat", "HH\n—\nmm") : setting("format", "ddd d h:mm AP"))
  readonly property string displayText: formatted(displayDate)

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
    readonly property int horizontalPadding: root.vertical ? 0 : 8

    width: root.vertical ? root.barSize : Math.max(root.barSize, label.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, label.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.06
    }

    Text {
      id: label
      anchors.centerIn: parent
      rotation: root.vertical ? -90 : 0
      text: root.displayText
      color: root.moduleColor
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: 14
      maximumLineCount: 1
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
