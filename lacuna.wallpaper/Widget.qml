import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.wallpaper"
  property var settings: ({})
  property string backgroundPath: ""
  property bool flyoutOpen: false

  readonly property bool opened: flyoutOpen
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("wallpaper", foreground)
  readonly property color iconColor: moduleColor
  readonly property color textColor: foreground
  readonly property bool widgetEnabled: boolSetting("enabled", true)
  readonly property int maxTextLength: Math.max(8, Number(setting("maxTextLength", 22)))
  readonly property int iconSize: barSize >= 30 ? 15 : 13
  readonly property int contentSpacing: 5
  readonly property int horizontalPadding: vertical ? 0 : 5
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/photo.svg")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string backgroundLink: stateHome + "/omarchy/current/background"
  readonly property string wallpaperTitle: backgroundPath ? formatTitle(backgroundPath) : "No Wallpaper"
  readonly property string displayText: clipped(wallpaperTitle)
  readonly property string tooltipText: wallpaperTitle + " / wallpaper details"
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

  function formatTitle(path) {
    var filename = String(path || "").split("/").pop()
    var name = filename.replace(/\.[^.]+$/, "").replace(/^[0-9]+[-_.\s]*/, "")
      .replace(/[-_]+/g, " ").replace(/\s+/g, " ").trim().toLowerCase()
    return name.replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
  }

  function clipped(value) {
    var text = String(value || "")
    return text.length <= maxTextLength ? text : text.slice(0, maxTextLength - 1) + "…"
  }

  function refresh() {
    if (!readlinkProc.running) readlinkProc.running = true
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

  Component.onCompleted: refresh()

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "wallpaper"
  }

  MotionTokens { id: motionTokens }

  FileView {
    path: root.backgroundLink
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
    onLoadFailed: root.backgroundPath = ""
  }

  // Omarchy replaces the current/background symlink when the wallpaper
  // changes. FileView can remain attached to the previous resolved inode, so
  // periodically re-resolve the link as a low-cost fallback.
  Timer {
    interval: 1500
    running: root.widgetEnabled
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: readlinkProc
    command: ["readlink", "-f", root.backgroundLink]
    stdout: StdioCollector {
      id: wallpaperOutput
      waitForEnd: true
      onStreamFinished: root.backgroundPath = String(wallpaperOutput.text || "").trim()
    }
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

  WallpaperFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.flyoutOpen
    backgroundPath: root.backgroundPath
    wallpaperTitle: root.wallpaperTitle
    accentColor: root.moduleColor
  }
}
