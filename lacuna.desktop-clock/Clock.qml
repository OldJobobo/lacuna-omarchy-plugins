import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null

  property date now: new Date()
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string colorsPath: configHome + "/omarchy/current/theme/colors.toml"
  readonly property string backgroundPath: configHome + "/omarchy/current/background"
  readonly property string pluginDir: manifest && manifest.__sourceDir ? manifest.__sourceDir : localPath(Qt.resolvedUrl("."))
  readonly property string contrastScript: pluginDir + "/scripts/wallpaper-contrast-sample"
  property var palette: ({})
  readonly property color clockColor: themeColor("foreground", "#d8dee9")
  readonly property color softColor: withAlpha(clockColor, 0.68)
  readonly property color accentColor: themeColor("accent", themeColor("color14", clockColor))
  readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.52)
  readonly property var clockSettings: pluginSettings()
  readonly property string clockAnchor: validAnchor(settingValue("anchor", "bottom-right"))
  readonly property real clockOffsetX: numberSetting("offsetX", 0)
  readonly property real clockOffsetY: numberSetting("offsetY", 0)
  readonly property real clockScale: Math.max(0.5, Math.min(2, numberSetting("scale", 1)))
  readonly property bool use12Hour: boolSetting("use12Hour", false)
  readonly property string timeText: use12Hour ? format12Hour(now) : Qt.formatDateTime(now, "HH:mm")
  readonly property string secondsText: Qt.formatDateTime(now, "ss")
  readonly property string meridiemText: Qt.formatDateTime(now, "AP")
  readonly property string dateText: Qt.formatDateTime(now, "dddd, MMMM d")

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }

  function withAlpha(value, alpha) {
    return Qt.rgba(value.r, value.g, value.b, alpha)
  }

  function format12Hour(value) {
    var hour = value.getHours() % 12
    if (hour === 0) hour = 12
    return hour + Qt.formatDateTime(value, ":mm")
  }

  function compositeOnBackground(foregroundColor, backgroundColor) {
    var alpha = foregroundColor.a === undefined ? 1 : foregroundColor.a
    return Qt.rgba(
      foregroundColor.r * alpha + backgroundColor.r * (1 - alpha),
      foregroundColor.g * alpha + backgroundColor.g * (1 - alpha),
      foregroundColor.b * alpha + backgroundColor.b * (1 - alpha),
      1
    )
  }

  function linearChannel(value) {
    if (value <= 0.04045) return value / 12.92
    return Math.pow((value + 0.055) / 1.055, 2.4)
  }

  function relativeLuminance(value) {
    return 0.2126 * linearChannel(value.r) + 0.7152 * linearChannel(value.g) + 0.0722 * linearChannel(value.b)
  }

  function contrastRatio(foregroundColor, backgroundColor) {
    var fg = compositeOnBackground(foregroundColor, backgroundColor)
    var fgLum = relativeLuminance(fg)
    var bgLum = relativeLuminance(backgroundColor)
    var light = Math.max(fgLum, bgLum)
    var dark = Math.min(fgLum, bgLum)
    return (light + 0.05) / (dark + 0.05)
  }

  function contrastSafeColor(preferredColor, backgroundColor, minimumRatio, backupColor) {
    if (contrastRatio(preferredColor, backgroundColor) >= minimumRatio) return preferredColor
    if (backupColor && contrastRatio(backupColor, backgroundColor) >= minimumRatio) return backupColor

    var light = Qt.rgba(0.94, 0.95, 0.96, 1)
    var dark = Qt.rgba(0.05, 0.06, 0.07, 1)
    return contrastRatio(light, backgroundColor) >= contrastRatio(dark, backgroundColor) ? light : dark
  }

  function themeColor(name, fallbackColor) {
    return palette[name] || fallbackColor
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

  function pluginSettings() {
    var merged = {}
    var defaults = manifest && manifest.defaults ? manifest.defaults : {}

    for (var key in defaults) merged[key] = defaults[key]

    var config = shell && shell.shellConfig ? shell.shellConfig : null
    var plugins = config && config.plugins && Array.isArray(config.plugins) ? config.plugins : []

    for (var i = 0; i < plugins.length; i++) {
      var entry = plugins[i]
      if (!entry || entry.id !== "lacuna.desktop-clock") continue
      for (var entryKey in entry) {
        if (entryKey !== "id") merged[entryKey] = entry[entryKey]
      }
      break
    }

    return merged
  }

  function settingValue(key, fallbackValue) {
    return clockSettings && clockSettings[key] !== undefined ? clockSettings[key] : fallbackValue
  }

  function numberSetting(key, fallbackValue) {
    var value = Number(settingValue(key, fallbackValue))
    return isNaN(value) ? fallbackValue : value
  }

  function boolSetting(key, fallbackValue) {
    var value = settingValue(key, fallbackValue)
    if (value === true || value === false) return value
    var normalized = String(value || "").toLowerCase()
    if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on") return true
    if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off") return false
    return fallbackValue
  }

  function validAnchor(value) {
    var anchor = String(value || "bottom-right").toLowerCase()
    var valid = {
      "top-left": true,
      "top": true,
      "top-right": true,
      "left": true,
      "center": true,
      "right": true,
      "bottom-left": true,
      "bottom": true,
      "bottom-right": true
    }

    return valid[anchor] ? anchor : "bottom-right"
  }

  FontLoader {
    id: tekturFont

    source: "assets/fonts/Tektur-SemiBold.ttf"
  }

  FileView {
    id: themeFile

    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadTheme(text())
    onFileChanged: reload()
    onLoadFailed: themeRetry.restart()
  }

  Timer {
    id: themeRetry

    interval: 500
    repeat: false
    onTriggered: themeFile.reload()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: clockWindow

      required property var modelData

      screen: modelData
      visible: true
      color: "transparent"
      implicitWidth: 0
      implicitHeight: 0
      WlrLayershell.namespace: "lacuna-desktop-clock"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Item {
        id: clockFace

        property color sampledBackground: "#101315"
        property bool hasWallpaperSample: false
        readonly property real scaleUnit: Math.min(clockWindow.width, clockWindow.height)
        readonly property int clockSize: Math.max(76, Math.min(168, Math.round(scaleUnit * 0.145 * root.clockScale)))
        readonly property int secondSize: Math.max(24, Math.round(clockSize * 0.34))
        readonly property int dateSize: Math.max(13, Math.round(clockSize * 0.14))
        readonly property int blockWidth: Math.min(clockWindow.width - 96, Math.round(clockSize * 4.6))
        readonly property int baseMarginX: Math.max(48, Math.round(clockWindow.width * 0.055))
        readonly property int baseMarginY: Math.max(46, Math.round(clockWindow.height * 0.08))
        readonly property bool alignLeft: root.clockAnchor.indexOf("left") !== -1
        readonly property bool alignRight: root.clockAnchor.indexOf("right") !== -1
        readonly property bool alignTop: root.clockAnchor.indexOf("top") !== -1
        readonly property bool alignBottom: root.clockAnchor.indexOf("bottom") !== -1
        readonly property real anchorX: alignLeft ? baseMarginX : (alignRight ? clockWindow.width - width - baseMarginX : Math.round((clockWindow.width - width) / 2))
        readonly property real anchorY: alignTop ? baseMarginY : (alignBottom ? clockWindow.height - height - baseMarginY : Math.round((clockWindow.height - height) / 2))
        readonly property real displayContrastRatio: 3.0
        readonly property real smallContrastRatio: 4.5
        readonly property color timeColor: hasWallpaperSample ? root.contrastSafeColor(root.clockColor, sampledBackground, displayContrastRatio) : root.clockColor
        readonly property color secondsColor: hasWallpaperSample ? root.contrastSafeColor(root.accentColor, sampledBackground, displayContrastRatio, timeColor) : root.accentColor
        readonly property color dateColor: hasWallpaperSample ? root.contrastSafeColor(root.softColor, sampledBackground, smallContrastRatio, root.clockColor) : root.softColor

        x: Math.round(anchorX + root.clockOffsetX)
        y: Math.round(anchorY + root.clockOffsetY)
        width: blockWidth
        height: clockSize + dateSize + 24
        opacity: 0.94

        function sampleWallpaper() {
          if (contrastProcess.running || clockWindow.width <= 0 || clockWindow.height <= 0 || width <= 0 || height <= 0) return

          contrastProcess.output = ""
          contrastProcess.command = [
            root.contrastScript,
            "--wallpaper", root.backgroundPath,
            "--screen-width", String(clockWindow.width),
            "--screen-height", String(clockWindow.height),
            "--x", String(Math.max(0, x)),
            "--y", String(Math.max(0, y)),
            "--width", String(width),
            "--height", String(height)
          ]
          contrastProcess.running = true
        }

        onXChanged: contrastSampleTimer.restart()
        onYChanged: contrastSampleTimer.restart()
        onWidthChanged: contrastSampleTimer.restart()
        onHeightChanged: contrastSampleTimer.restart()

        Component.onCompleted: contrastSampleTimer.restart()

        Timer {
          id: contrastSampleTimer

          interval: 250
          repeat: false
          onTriggered: clockFace.sampleWallpaper()
        }

        Timer {
          interval: 30000
          running: true
          repeat: true
          onTriggered: clockFace.sampleWallpaper()
        }

        Process {
          id: contrastProcess

          property string output: ""

          stdout: SplitParser {
            onRead: function(data) {
              contrastProcess.output += data + "\n"
            }
          }

          onExited: function(exitCode) {
            if (exitCode !== 0) return

            try {
              var data = JSON.parse(contrastProcess.output)
              if (data.background) {
                clockFace.sampledBackground = data.background
                clockFace.hasWallpaperSample = true
              }
            } catch (error) {
              console.warn("lacuna desktop clock contrast sample parse failed:", error)
            }
          }
        }

        Text {
          id: timeWidthProbe

          visible: false
          text: root.use12Hour ? "12:88" : "88:88"
          font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
          font.pixelSize: clockFace.clockSize
          font.weight: Font.DemiBold
          font.letterSpacing: 0
          renderType: Text.NativeRendering
        }

        Text {
          id: secondsWidthProbe

          visible: false
          text: "88"
          font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
          font.pixelSize: clockFace.secondSize
          font.weight: Font.DemiBold
          font.letterSpacing: 0
          renderType: Text.NativeRendering
        }

        Text {
          id: meridiemWidthProbe

          visible: false
          text: "AM"
          font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
          font.pixelSize: Math.max(18, Math.round(clockFace.secondSize * 0.62))
          font.weight: Font.DemiBold
          font.letterSpacing: 0
          renderType: Text.NativeRendering
        }

        Row {
          id: timeRow

          anchors.right: parent.right
          anchors.top: parent.top
          spacing: Math.max(8, Math.round(clockFace.clockSize * 0.07))

          Text {
            width: Math.ceil(timeWidthProbe.implicitWidth)
            text: root.timeText
            color: clockFace.timeColor
            font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
            font.pixelSize: clockFace.clockSize
            font.weight: Font.DemiBold
            font.letterSpacing: 0
            horizontalAlignment: Text.AlignRight
            style: Text.Raised
            styleColor: root.shadowColor
            renderType: Text.NativeRendering
          }

          Text {
            width: Math.ceil(secondsWidthProbe.implicitWidth)
            anchors.baseline: parent.children[0].baseline
            anchors.baselineOffset: -Math.round(clockFace.clockSize * 0.08)
            text: root.secondsText
            color: clockFace.secondsColor
            opacity: 0.78
            font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
            font.pixelSize: clockFace.secondSize
            font.weight: Font.DemiBold
            font.letterSpacing: 0
            horizontalAlignment: Text.AlignRight
            style: Text.Raised
            styleColor: root.shadowColor
            renderType: Text.NativeRendering
          }

          Text {
            visible: root.use12Hour
            width: Math.ceil(meridiemWidthProbe.implicitWidth)
            anchors.baseline: parent.children[0].baseline
            anchors.baselineOffset: Math.round(clockFace.clockSize * 0.16)
            text: root.meridiemText
            color: clockFace.secondsColor
            opacity: 0.72
            font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
            font.pixelSize: Math.max(18, Math.round(clockFace.secondSize * 0.62))
            font.weight: Font.DemiBold
            font.letterSpacing: 0
            horizontalAlignment: Text.AlignRight
            style: Text.Raised
            styleColor: root.shadowColor
            renderType: Text.NativeRendering
          }
        }

        Text {
          anchors.right: timeRow.right
          anchors.top: timeRow.bottom
          anchors.topMargin: -Math.round(clockFace.clockSize * 0.05)
          text: root.dateText.toUpperCase()
          color: clockFace.dateColor
          font.family: tekturFont.name !== "" ? tekturFont.name : "Tektur"
          font.pixelSize: clockFace.dateSize
          font.weight: Font.DemiBold
          font.letterSpacing: 0
          style: Text.Raised
          styleColor: root.shadowColor
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
