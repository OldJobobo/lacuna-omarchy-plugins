import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-wallpaper"
  property var settings: ({})
  property string backgroundPath: ""
  property string nextBackgroundPath: ""

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("wallpaper", foreground)
  readonly property int maxTextLength: Math.max(4, Number(setting("maxTextLength", 18)))
  readonly property bool showIcon: setting("showIcon", true) === true
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string backgroundLink: configHome + "/omarchy/current/background"
  readonly property string wallpaperTitle: backgroundPath ? formatTitle(backgroundPath) : "No Wallpaper"
  readonly property string nextWallpaperTitle: nextBackgroundPath ? formatTitle(nextBackgroundPath) : ""
  readonly property string displayText: clipped((showIcon ? " " : "") + wallpaperTitle)
  readonly property string tooltipText: backgroundPath
    ? "<b>" + wallpaperTitle + "</b><br/>Current wallpaper"
      + (nextWallpaperTitle.length > 0 ? "<br/>Next: " + nextWallpaperTitle : "")
      + "<br/><br/>Left click: picker<br/>Right click: next"
    : "<b>No Wallpaper</b><br/>No active Omarchy background symlink was found."

  visible: displayText.length > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function switchBackgroundCommand() {
    return "background=$(omarchy theme bg-switcher); [ -n \"$background\" ] && omarchy theme bg set \"$background\""
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
      "-lc",
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

    readonly property int horizontalPadding: root.vertical ? 0 : 8
    readonly property int minimumWidth: root.vertical ? root.barSize : 32

    width: root.vertical ? root.barSize : Math.max(minimumWidth, label.implicitWidth + horizontalPadding * 2)
    height: root.vertical ? Math.max(root.barSize, label.implicitHeight + 10) : root.barSize
    implicitWidth: width
    implicitHeight: height
    clip: true

    Text {
      id: label
      anchors.centerIn: parent
      rotation: root.vertical ? -90 : 0
      text: root.displayText
      color: root.moduleColor
      font.family: bar ? bar.fontFamily : "monospace"
      font.pixelSize: 12
      maximumLineCount: 1
      elide: Text.ElideRight
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (bar && root.tooltipText) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!bar) return
        if (mouse.button === Qt.RightButton) bar.run("omarchy theme bg next")
        else bar.run(root.switchBackgroundCommand())
      }
    }
  }
}
