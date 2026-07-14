import QtQuick
import QtQuick.Effects

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.weather"
  property var settings: ({})
  property bool flyoutOpen: false
  property bool autoRefresh: true

  readonly property bool opened: flyoutOpen
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("weather", foreground)
  readonly property bool compact: !vertical && barSize <= 26
  readonly property bool showText: setting("showText", compact ? false : true) === true
  readonly property color iconColor: moduleColor
  readonly property color textColor: foreground
  readonly property color seamColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property int topbarTextSize: barSize <= 26 ? 12 : 13
  readonly property int contentSpacing: 6
  readonly property int horizontalPadding: vertical ? 0 : 7
  readonly property string weatherIcon: weatherState.icon
  readonly property string displayText: weatherState.barLabel
  readonly property bool shown: true
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse
  readonly property var weatherStateRef: weatherState

  visible: shown
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function shellQuote(value) {
    if (bar && bar.shellQuote) return bar.shellQuote(value)
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function open() {
    flyoutOpen = true
    if (bar) bar.hideTooltip(root)
  }

  function close() {
    flyoutOpen = false
  }

  function closeForPopoutSwitch() {
    close()
  }

  function toggleFlyout() {
    if (flyoutOpen) close()
    else open()
  }

  function refresh(force) {
    weatherState.refresh(force === true)
  }

  function tooltipText() {
    if (!weatherState.hasData)
      return weatherState.loading ? "Weather<br/>Fetching conditions" : "Weather<br/>Forecast unavailable"
    var detail = weatherState.current.description || "Current conditions"
    var location = weatherState.current.location || "Current location"
    return "Weather<br/>" + location + " · " + weatherState.current.temperature + " · " + detail
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "weather"
  }

  MotionTokens { id: motionTokens }

  WeatherState {
    id: weatherState
    settings: root.settings
    autoRefresh: root.autoRefresh
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed || root.flyoutOpen ? 1 : 0

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

      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: root.topbarIconSize + 4
        height: root.topbarIconSize + 4

        Text {
          anchors.centerIn: parent
          text: root.weatherIcon
          color: root.iconColor
          font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
          font.pixelSize: root.topbarIconSize
          renderType: Text.NativeRendering
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showText && root.displayText.length > 0
        width: 1
        height: Math.max(10, root.topbarIconSize - 1)
        color: root.seamColor
      }

      Text {
        visible: root.showText && root.displayText.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        color: root.textColor
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltipText())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
          root.toggleFlyout()
        } else if (mouse.button === Qt.MiddleButton) {
          root.refresh(true)
        } else if (mouse.button === Qt.RightButton && root.bar) {
          root.bar.run("omarchy notification send " + root.shellQuote(weatherState.notificationText()))
        }
      }
    }
  }

  WeatherFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    weatherState: weatherState
    accentColor: root.moduleColor
    open: root.flyoutOpen
  }
}
