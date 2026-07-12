import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

PopupWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property var owner: null
  property bool open: false
  property string themeTitle: ""
  property var palette: ({})
  property color accentColor: "#89b4fa"
  property int panelWidth: 360
  property int panelHeight: 284
  property int joinRadius: 13
  property int margin: 8

  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property string fontFamily: tokens.monoFont
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color background: opaque(bar ? bar.background : "#101315")
  readonly property color whisper: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  readonly property color soft: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.78)
  readonly property color seam: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)
  readonly property var paletteKeys: [
    "dark_bg", "bg", "lighter_bg", "muted", "dark_fg", "fg", "light_fg", "bright_fg",
    "red", "orange", "yellow", "green", "cyan", "blue", "magenta", "bright_magenta"
  ]
  property bool shadowEnabled: false
  property int shadowOffsetX: 2
  property int shadowOffsetY: 3
  readonly property int shadowBlurMax: 28
  readonly property int shadowMargin: shadowEnabled ? Math.ceil(shadowBlurMax + Math.max(Math.abs(shadowOffsetX), Math.abs(shadowOffsetY))) : 0
  readonly property int shadowBottomMargin: shadowEnabled ? Math.ceil(shadowMargin + shadowBlurMax * 0.6 + Math.max(0, shadowOffsetY)) : 0
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string lacunaSettingsPath: configHome + "/omarchy/lacuna/settings.json"
  property real reveal: open ? 1 : 0

  LacunaTokens { id: tokens }
  MotionTokens { id: motionTokens }

  function opaque(value) {
    var c = typeof value === "string" ? Qt.color(value) : value
    return Qt.rgba(c.r, c.g, c.b, 1)
  }

  function colorAt(index) {
    var key = paletteKeys[index] || "accent"
    return palette[key] || (index < 8 ? background : foreground)
  }

  function close() {
    if (owner && typeof owner.close === "function") owner.close()
    else open = false
  }

  function loadFrameSettings(raw) {
    try {
      var frame = JSON.parse(String(raw || "{}")).frame || {}
      shadowEnabled = frame.shadow === true
      var ox = Number(frame.shadowOffsetX)
      var oy = Number(frame.shadowOffsetY)
      shadowOffsetX = isFinite(ox) ? ox : 2
      shadowOffsetY = isFinite(oy) ? oy : 3
    } catch (e) {
      shadowEnabled = false
    }
  }

  FileView {
    path: root.lacunaSettingsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadFrameSettings(text())
    onFileChanged: reload()
    onLoadFailed: root.loadFrameSettings("")
  }

  Behavior on reveal { NumberAnimation { duration: motionTokens.reveal; easing.type: Easing.OutCubic } }
  visible: open || reveal > 0.001
  color: "transparent"
  implicitWidth: surface.fullWidth + shadowMargin * 2
  implicitHeight: surface.implicitHeight + shadowBottomMargin

  onOpenChanged: {
    if (!bar) return
    if (open) bar.requestPopout(root)
    else if (bar.activePopout === root) bar.releasePopout(root)
  }

  HyprlandFocusGrab {
    active: root.open
    windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
    onCleared: root.close()
  }

  anchor {
    id: popupAnchor
    window: root.anchorWindow
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: root.bar && root.bar.position === "bottom" ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1
    onAnchoring: {
      if (!root.anchorWindow || !root.bar) return
      var below = root.bar.position !== "bottom"
      var localX = root.anchorItem.width / 2 - (root.shadowMargin + root.joinRadius + root.panelWidth / 2)
      var localY = below ? root.anchorItem.height : -root.implicitHeight
      var point = root.anchorWindow.contentItem.mapFromItem(root.anchorItem, localX, localY)
      point.x = Math.max(root.margin, Math.min(point.x, root.anchorWindow.width - root.implicitWidth - root.margin))
      popupAnchor.rect.x = Math.round(point.x)
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  Item {
    anchors.top: parent.top
    width: parent.width
    height: Math.round(root.implicitHeight * root.reveal)
    clip: true

    Item {
      id: stage
      width: root.implicitWidth
      height: root.implicitHeight

      Item {
        id: shadowSource
        anchors.fill: parent
        visible: root.shadowEnabled
        z: -2
        BarFlyoutSurface {
          x: root.shadowMargin
          panelWidth: root.panelWidth
          panelHeight: root.panelHeight
          joinRadius: root.joinRadius
          panelColor: root.background
        }
      }

      LacunaDropShadow {
        source: shadowSource
        shadowEnabled: root.shadowEnabled
        shadowColor: "black"
        shadowOpacity: 0.62
        shadowBlur: 0.85
        blurMax: root.shadowBlurMax
        shadowHorizontalOffset: root.shadowOffsetX
        shadowVerticalOffset: root.shadowOffsetY
        z: -1
      }

      BarFlyoutSurface {
        id: surface
        x: root.shadowMargin
        panelWidth: root.panelWidth
        panelHeight: root.panelHeight
        joinRadius: root.joinRadius
        panelColor: root.background
      }

      Column {
        x: surface.x + surface.panelLeft + tokens.spaceXLarge
        y: surface.panelTop + tokens.spaceXLarge
        width: root.panelWidth - tokens.spaceXLarge * 2
        spacing: tokens.spaceLarge
        opacity: Math.max(0, Math.min(1, (root.reveal - 0.55) / 0.45))

        Text {
          text: "ACTIVE THEME"
          color: root.whisper
          font.family: tokens.monoFont
          font.pixelSize: tokens.textSmall
        }

        Text {
          width: parent.width
          text: root.themeTitle || "Unknown Theme"
          color: root.foreground
          font.family: tokens.displayFont
          font.pixelSize: tokens.textTitle
          font.bold: true
          font.letterSpacing: tokens.trackingTitle
          renderType: Text.NativeRendering
          textFormat: Text.PlainText
          elide: Text.ElideRight
          maximumLineCount: 1
        }

        Item {
          width: parent.width
          height: 1
          Rectangle { width: parent.width / 2 - 11; height: 1; color: root.seam }
          Rectangle { x: parent.width / 2 + 11; width: parent.width / 2 - 11; height: 1; color: root.seam }
        }

        Text {
          text: "PALETTE ANATOMY"
          color: root.whisper
          font.family: tokens.monoFont
          font.pixelSize: tokens.textSmall
        }

        Grid {
          columns: 8
          spacing: tokens.spaceSmall
          Repeater {
            model: 16
            Rectangle {
              required property int index
              width: 37
              height: 28
              color: root.colorAt(index)
            }
          }
        }

        Row {
          width: parent.width
          spacing: 8
          ThemeDatum { label: "BACKGROUND"; value: root.palette.bg || root.colorAt(1); swatch: root.palette.bg || root.colorAt(1) }
          ThemeDatum { label: "ACCENT"; value: root.palette.accent || root.colorAt(13); swatch: root.palette.accent || root.colorAt(13) }
        }
      }
    }
  }

  component ThemeDatum: Rectangle {
    required property string label
    required property string value
    required property color swatch
    width: 160
    height: 42
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
    Rectangle { x: 9; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 24; color: parent.swatch }
    Column {
      x: 29
      anchors.verticalCenter: parent.verticalCenter
      Text { text: parent.parent.label; color: root.whisper; font.family: tokens.monoFont; font.pixelSize: tokens.textHint }
      Text { text: parent.parent.value; color: root.soft; font.family: tokens.monoFont; font.pixelSize: tokens.textSmall }
    }
  }
}
