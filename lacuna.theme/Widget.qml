import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.theme"
  property var settings: ({})
  property var palette: ({})
  property string themeName: ""
  property bool flyoutOpen: false

  readonly property bool opened: flyoutOpen
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("theme", foreground)
  readonly property color iconColor: moduleColor
  readonly property color textColor: foreground
  readonly property bool widgetEnabled: boolSetting("enabled", true)
  readonly property int maxTextLength: Math.max(8, Number(setting("maxTextLength", 22)))
  readonly property int iconSize: barSize >= 30 ? 15 : 13
  readonly property int contentSpacing: 5
  readonly property int horizontalPadding: vertical ? 0 : 5
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/palette.svg")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string colorsPath: stateHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: stateHome + "/omarchy/current/theme.name"
  readonly property string themeTitle: formatTitle(themeName)
  readonly property string displayText: clipped(themeTitle || "Theme")
  readonly property string tooltipText: themeTitle.length > 0 ? themeTitle + " / theme details" : "Theme details"
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  enabled: widgetEnabled
  visible: widgetEnabled
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function boolSetting(name, fallback) {
    var value = setting(name, fallback)
    if (value === true || value === false) return value
    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallback
  }

  function formatTitle(value) {
    return String(value || "")
      .replace(/[-_]/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
  }

  function clipped(value) {
    var text = String(value || "")
    return text.length <= maxTextLength ? text : text.slice(0, maxTextLength - 1) + "…"
  }

  function rawColor(name) {
    return palette[name] || (name === "bg" || name === "dark_bg" ? "#101315" : foreground)
  }

  function loadTheme(raw) {
    var next = {}
    var lines = String(raw || "").split(/\n/)
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?([^"'\s]+)["']?/)
      if (match) next[match[1]] = match[2].trim()
    }
    palette = next
  }

  function open() {
    flyoutOpen = true
  }

  function close() {
    flyoutOpen = false
  }

  function toggleFlyout() {
    flyoutOpen = !flyoutOpen
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "theme"
  }

  MotionTokens { id: motionTokens }

  FileView {
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadTheme(text())
    onFileChanged: reload()
    onLoadFailed: root.loadTheme("")
  }

  FileView {
    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onLoaded: root.themeName = text().trim()
    onFileChanged: reload()
    onLoadFailed: root.themeName = ""
  }

  Item {
    id: button
    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed || root.opened ? 1 : 0
    width: root.vertical ? root.barSize : content.implicitWidth + root.horizontalPadding * 2
    height: root.vertical ? Math.max(root.barSize, content.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.07
    }

    Row {
      id: content
      anchors.centerIn: parent
      rotation: root.vertical ? -90 : 0
      spacing: root.contentSpacing

      Item {
        width: root.iconSize
        height: root.iconSize
        anchors.verticalCenter: parent.verticalCenter
        Image {
          anchors.centerIn: parent
          source: root.iconSource
          width: root.iconSize
          height: root.iconSize
          sourceSize.width: width
          sourceSize.height: height
          layer.enabled: true
          layer.effect: MultiEffect { colorization: 1; colorizationColor: root.iconColor }
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Math.max(10, root.iconSize - 1)
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        color: root.textColor
        font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: root.barSize <= 26 ? 12 : 13
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor
      onEntered: if (bar) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: {
        if (bar) bar.hideTooltip(root)
        root.toggleFlyout()
      }
    }
  }

  ThemeFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.flyoutOpen
    themeTitle: root.themeTitle
    palette: root.palette
    accentColor: root.moduleColor
  }
}
