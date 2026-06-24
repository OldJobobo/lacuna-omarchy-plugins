import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.wallpaper"
  property var settings: ({})
  property string backgroundPath: ""
  property string nextBackgroundPath: ""

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("wallpaper", foreground)
  readonly property bool widgetEnabled: boolSetting("enabled", true)
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 18)))
  readonly property bool showIcon: boolSetting("showIcon", true)
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string backgroundLink: stateHome + "/omarchy/current/background"
  readonly property string wallpaperTitle: backgroundPath ? formatTitle(backgroundPath) : "No Wallpaper"
  readonly property string nextWallpaperTitle: nextBackgroundPath ? formatTitle(nextBackgroundPath) : ""
  readonly property string displayText: clipped(wallpaperTitle)
  readonly property string tooltipText: backgroundPath
    ? "<b>" + wallpaperTitle + "</b><br/>Current wallpaper"
      + (nextWallpaperTitle.length > 0 ? "<br/>Next: " + nextWallpaperTitle : "")
      + "<br/><br/>Left click: picker<br/>Right click: next"
    : "<b>No Wallpaper</b><br/>No active Omarchy background symlink was found."

  enabled: widgetEnabled
  visible: widgetEnabled && displayText.length > 0
  implicitWidth: widgetEnabled && displayText.length > 0 ? button.implicitWidth : 0
  implicitHeight: widgetEnabled && displayText.length > 0 ? button.implicitHeight : 0
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

  function switchBackgroundCommand() {
    return "background=$(omarchy theme bg-switcher); [ -n \"$background\" ] && omarchy theme bg set \"$background\""
  }

  function nextBackgroundCommand() {
    return "omarchy theme bg next"
  }

  function clipped(value) {
    var text = String(value || "")
    if (text.length <= maxTextLength) return text
    return text.slice(0, Math.max(1, maxTextLength - 1)) + "..."
  }

  function formatTitle(path) {
    var filename = String(path || "").split("/").pop()
    var name = filename
      .replace(/\.[^.]+$/, "")
      .replace(/^[0-9]+[-_.\s]*/, "")
      .replace(/[-_]+/g, " ")
      .replace(/\s+/g, " ")
      .replace(/^\s+|\s+$/g, "")
      .toLowerCase()

    return name.replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
  }

  function refresh() {
    if (!readlinkProc.running) {
      readlinkProc.running = true
    }
  }

  Component.onCompleted: refresh()

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "wallpaper"
  }

  MotionTokens {
    id: motionTokens
  }

  FileView {
    path: root.backgroundLink
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
    onLoadFailed: {
      root.backgroundPath = ""
      root.nextBackgroundPath = ""
    }
  }

  Process {
    id: readlinkProc
    command: [
      "bash",
      "-c",
      "link=$1; current=$(readlink -f \"$link\" 2>/dev/null || true); printf '%s\\n' \"$current\"; if [ -z \"$current\" ]; then printf '\\n'; exit 0; fi; dir=${current%/*}; mapfile -t files < <(find -L \"$dir\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \\) | sort); next=''; count=${#files[@]}; if [ \"$count\" -gt 0 ]; then for i in \"${!files[@]}\"; do resolved=$(readlink -f \"${files[$i]}\" 2>/dev/null || true); if [ \"$resolved\" = \"$current\" ]; then next=${files[$(( (i + 1) % count ))]}; break; fi; done; fi; printf '%s\\n' \"$next\"",
      "lacuna-wallpaper",
      root.backgroundLink
    ]

    stdout: StdioCollector {
      id: wallpaperOutput
      waitForEnd: true
      onStreamFinished: function() {
        var lines = String(wallpaperOutput.text || "").split(/\n/)
        root.backgroundPath = (lines[0] || "").trim()
        root.nextBackgroundPath = (lines[1] || "").trim()
      }
    }
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
            PathSvg { path: "M15 8h.01" }
            PathSvg { path: "M3 6a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v12a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" }
            PathSvg { path: "M3 16l5 -5c.93 -.89 2.07 -.89 3 0l5 5" }
            PathSvg { path: "M14 14l1 -1c.93 -.89 2.07 -.89 3 0l3 3" }
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
        if (mouse.button === Qt.RightButton) bar.run(root.nextBackgroundCommand())
        else bar.run(root.switchBackgroundCommand())
      }
    }
  }
}
