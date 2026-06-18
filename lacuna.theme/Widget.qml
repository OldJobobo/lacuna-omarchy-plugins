import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.theme"
  property var settings: ({})
  property var palette: ({})
  property string themeName: ""

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("theme", foreground)
  readonly property bool widgetEnabled: boolSetting("enabled", true)
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 26)))
  readonly property bool showIcon: boolSetting("showIcon", true)
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath: configHome + "/omarchy/current/theme.name"
  readonly property string themeTitle: formatTitle(themeName)
  readonly property string displayText: clipped(themeTitle)
  readonly property string tooltipText: themeTooltip()

  enabled: widgetEnabled
  visible: widgetEnabled && themeTitle.length > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

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

  function shellQuote(value) {
    if (bar && bar.shellQuote) return bar.shellQuote(value)
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function switchThemeCommand() {
    return "theme=$(omarchy theme switcher); [ -n \"$theme\" ] && omarchy theme set \"$theme\""
  }

  function randomThemeCommand() {
    return "current=\"$(omarchy theme current)\"; next=\"$(omarchy theme list | grep -Fvx \"$current\" | shuf -n 1)\"; [ -n \"$next\" ] && omarchy theme set \"$next\""
  }

  function clipped(value) {
    var text = String(value || "")
    if (text.length <= maxTextLength) return text
    return text.slice(0, Math.max(1, maxTextLength - 1)) + "..."
  }

  function formatTitle(value) {
    return String(value || "")
      .replace(/[-_]/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
  }

  function swatchRow(start, end) {
    var row = ""
    for (var i = start; i <= end; i++) {
      row += "<font color='" + rawColor("color" + i) + "' size='+2'>■</font> "
    }
    return row
  }

  function rawColor(name) {
    return palette[name] || fallbackColor(name)
  }

  function fallbackColor(name) {
    var fallbacks = {
      foreground: "#d8dee9",
      background: "#101315",
      color0: "#101315",
      color7: "#e5e9f0",
      color11: "#ebcb8b"
    }
    return fallbacks[name] || foreground
  }

  function themeTooltip() {
    return "<b>" + themeTitle + "</b><br/>Current Omarchy theme<br/><br/><b>Palette</b><br/>"
      + swatchRow(0, 7) + "<br/>"
      + swatchRow(8, 15) + "<br/><br/>"
      + "<font color='" + rawColor("color0") + "'>■</font> base00  "
      + "<font color='" + rawColor("color7") + "'>■</font> base07  "
      + "<font color='" + rawColor("color11") + "'>■</font> accent<br/><br/>"
      + "Left click: switcher<br/>Right click: random"
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

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "theme"
  }

  MotionTokens {
    id: motionTokens
  }

  FileView {
    id: colorsFile
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadTheme(text())
    onFileChanged: reload()
    onLoadFailed: root.loadTheme("")
  }

  FileView {
    id: themeNameFile
    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onLoaded: root.themeName = text().trim()
    onFileChanged: reload()
    onLoadFailed: root.themeName = ""
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
      rotation: root.vertical ? -90 : 0
      spacing: root.showIcon ? 4 : 0

      Item {
        visible: root.showIcon
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? root.topbarIconSize : 0
        height: root.topbarIconSize

        Shape {
          width: 24
          height: 24
          scale: parent.width / 24
          transformOrigin: Item.TopLeft
          preferredRendererType: Shape.CurveRenderer

          ShapePath {
            strokeColor: root.moduleColor
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M12 21a9 9 0 1 1 0 -18c4.97 0 9 3.58 9 8c0 2.21 -1.79 4 -4 4h-2a2 2 0 0 0 -1 3.73a1.3 1.3 0 0 1 -1 2.27z" }
            PathSvg { path: "M7.5 10.5h.01" }
            PathSvg { path: "M10.5 7.5h.01" }
            PathSvg { path: "M14.5 7.5h.01" }
            PathSvg { path: "M17.5 10.5h.01" }
          }
        }
      }

      Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        color: root.moduleColor
        font.family: bar ? bar.fontFamily : "Hack Nerd Font Propo"
        font.pixelSize: 14
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (bar && root.tooltipText) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!bar) return
        if (mouse.button === Qt.RightButton) bar.run(root.randomThemeCommand())
        else bar.run(root.switchThemeCommand())
      }
    }
  }
}
