import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Lacuna molded flyout for the Claude Code usage widget. A PopupWindow anchored
// flush under the bar that drops the full usage readout on a molded attached
// surface (BarFlyoutSurface). Outside-click dismissal via HyprlandFocusGrab and
// single-popout coordination through the injected bar, mirroring the host
// qs.Ui PopupCard contract while staying self-contained.
PopupWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property var owner: null

  property bool open: false
  property int panelWidth: 312
  property int joinRadius: 13
  property int cornerRadius: 14
  property int margin: 8

  // Usage data (bound from Widget.qml).
  property int leftPercent: 100
  property int usedPercent: 0
  property int tokenCount: 0
  property int tokenLimit: 0
  property int sessionCount: 0
  property int entriesCount: 0
  property bool activeBlock: false
  property string resetText: ""
  property string startText: ""
  property string latestText: ""
  property string sourceText: ""
  property var models: []

  // Weekly (trailing 7-day) window.
  property bool weekActive: false
  property int weekLeftPercent: 100
  property int weekUsedPercent: 0
  property int weekTokens: 0
  property int weekLimit: 0
  property string weekResetText: ""
  property color weekAccentColor: "#d8dee9"

  // Theming (bound from Widget.qml / ColorProfile).
  property color accentColor: "#d8dee9"
  property color foreground: "#d8dee9"
  property color mutedColor: "#8a929c"
  property color trackColor: "#2a2f35"
  property color panelColor: "#0e1113"
  property string fontFamily: "monospace"
  property url iconSource: ""

  signal refreshRequested()

  // Frame drop-shadow — mirrors the Lacuna frame/panel shadow so the flyout
  // reads as part of the same shell surface. Sourced live from the shared
  // lacuna settings (frame.shadow + offsets), like MenuWindow's panel shadow.
  property bool shadowEnabled: false
  property int shadowOffsetX: 2
  property int shadowOffsetY: 3
  readonly property int shadowBlurMax: 28
  readonly property int shadowMargin: shadowEnabled
    ? Math.ceil(shadowBlurMax + Math.max(Math.abs(shadowOffsetX), Math.abs(shadowOffsetY)))
    : 0

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string lacunaSettingsPath: configHome + "/omarchy/lacuna/settings.json"

  function loadFrameSettings(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      var frame = data.frame || {}
      shadowEnabled = frame.shadow === true
      var ox = Number(frame.shadowOffsetX)
      shadowOffsetX = isFinite(ox) ? ox : 2
      var oy = Number(frame.shadowOffsetY)
      shadowOffsetY = isFinite(oy) ? oy : 3
    } catch (e) {
      shadowEnabled = false
    }
  }

  FileView {
    id: frameSettingsFile
    path: root.lacunaSettingsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadFrameSettings(text())
    onFileChanged: reload()
    onLoadFailed: root.loadFrameSettings("")
  }

  // A labeled usage meter: title + "% left" on top, a used-percent bar, and a
  // token detail line. Reused for the 5h and 7-day windows.
  component UsageMeter: Column {
    property string title: ""
    property string leftLabel: ""
    property int usedPercent: 0
    property string detail: ""
    property color accent: root.accentColor

    spacing: 5

    Item {
      width: parent.width
      height: meterTitle.implicitHeight

      Text {
        id: meterTitle
        anchors.left: parent.left
        text: title
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }

      Text {
        anchors.right: parent.right
        text: leftLabel
        color: accent
        font.family: root.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }
    }

    Rectangle {
      width: parent.width
      height: 7
      radius: 3.5
      color: root.trackColor

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(height, Math.round(parent.width * usedPercent / 100))
        radius: 3.5
        color: accent
        opacity: 0.92

        Behavior on width {
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
      }
    }

    Item {
      width: parent.width
      height: meterUsed.implicitHeight

      Text {
        id: meterUsed
        anchors.left: parent.left
        text: usedPercent + "% used"
        color: root.mutedColor
        font.family: root.fontFamily
        font.pixelSize: 11
        renderType: Text.NativeRendering
      }

      Text {
        anchors.right: parent.right
        text: detail + " tokens"
        color: root.mutedColor
        font.family: root.fontFamily
        font.pixelSize: 11
        renderType: Text.NativeRendering
      }
    }
  }

  readonly property var coordinatorKey: owner || root
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property var popupScreen: anchorWindow ? anchorWindow.screen : null
  readonly property real screenW: popupScreen ? popupScreen.width : 0
  readonly property int contentPadding: 14
  readonly property int innerWidth: panelWidth - contentPadding * 2

  function grouped(value) {
    var text = String(Math.max(0, Math.round(Number(value) || 0)))
    return text.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }

  function close() {
    if (owner && "close" in owner) owner.close()
    else root.open = false
  }

  // Animated reveal — rolls down from the bar.
  property real reveal: open ? 1 : 0
  Behavior on reveal {
    NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
  }

  readonly property real contentOpacity: Math.max(0, Math.min(1, (reveal - 0.3) / 0.7))

  visible: open || reveal > 0.001
  color: "transparent"
  implicitWidth: surface.fullWidth + shadowMargin * 2
  implicitHeight: surface.implicitHeight + shadowMargin

  onOpenChanged: {
    if (!bar) return
    if (open) {
      bar.requestPopout(coordinatorKey)
      root.refreshRequested()
    } else if (bar.activePopout === coordinatorKey) {
      bar.releasePopout(coordinatorKey)
    }
  }

  HyprlandFocusGrab {
    active: root.open
    windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
    onCleared: root.close()
  }

  anchor {
    id: popupAnchor
    window: root.anchorItem ? root.anchorItem.QsWindow.window : null
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1

    onAnchoring: {
      if (!root.anchorItem || !root.bar) return
      var target = root.anchorItem
      var window = target.QsWindow.window
      if (!window) return

      var below = root.bar.position !== "bottom"
      // Align the panel body (offset by the shadow margin + joinRadius) on the
      // widget center.
      var localX = target.width / 2 - (root.shadowMargin + root.joinRadius + root.panelWidth / 2)
      var localY = below ? target.height : -root.implicitHeight

      var point = window.contentItem.mapFromItem(target, localX, localY)
      point.x = Math.max(root.margin, Math.min(point.x, window.width - root.implicitWidth - root.margin))
      popupAnchor.rect.x = Math.round(point.x)
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  Item {
    id: clipper
    anchors.top: parent.top
    width: parent.width
    height: Math.round(root.implicitHeight * root.reveal)
    clip: true

    Item {
      id: stage
      x: 0
      y: 0
      width: root.implicitWidth
      height: root.implicitHeight

      LacunaDropShadow {
        source: surface
        shadowEnabled: root.shadowEnabled
        shadowColor: "black"
        shadowOpacity: 0.62
        shadowBlur: 0.85
        blurMax: root.shadowBlurMax
        shadowHorizontalOffset: root.shadowOffsetX
        shadowVerticalOffset: root.shadowOffsetY
      }

      BarFlyoutSurface {
        id: surface
        x: root.shadowMargin
        y: 0
        panelWidth: root.panelWidth
        panelHeight: Math.round(content.implicitHeight + root.contentPadding * 2)
        joinRadius: root.joinRadius
        cornerRadius: root.cornerRadius
        panelColor: root.panelColor
      }

    Column {
      id: content
      x: surface.x + surface.panelLeft + root.contentPadding
      y: surface.y + surface.panelTop + root.contentPadding
      width: root.innerWidth
      spacing: 11
      opacity: root.contentOpacity

      // Header: icon + title, status chip on the right.
      Item {
        width: parent.width
        height: 22

        Image {
          id: headerIcon
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: String(root.iconSource) !== ""
          source: root.iconSource
          width: 16
          height: 16
          sourceSize.width: 16
          sourceSize.height: 16
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
        }

        Text {
          anchors.left: headerIcon.visible ? headerIcon.right : parent.left
          anchors.leftMargin: headerIcon.visible ? 8 : 0
          anchors.verticalCenter: parent.verticalCenter
          text: "Claude Code"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: 14
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Rectangle {
          id: chip
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: chipText.implicitWidth + 16
          height: 20
          radius: 10
          color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)

          Text {
            id: chipText
            anchors.centerIn: parent
            text: root.activeBlock ? (root.usedPercent + "% used") : "idle"
            color: root.accentColor
            font.family: root.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
          }
        }
      }

      // 5h block meter.
      UsageMeter {
        width: parent.width
        title: "5h block"
        leftLabel: root.activeBlock ? (root.usedPercent + "% used") : "idle"
        usedPercent: root.usedPercent
        detail: root.resetText.length > 0 ? ("resets " + root.resetText) : ""
        accent: root.accentColor
      }

      // 7-day window meter.
      UsageMeter {
        width: parent.width
        title: "7-day"
        leftLabel: root.weekActive ? (root.weekUsedPercent + "% used") : "idle"
        usedPercent: root.weekUsedPercent
        detail: root.weekResetText.length > 0 ? ("resets " + root.weekResetText) : ""
        accent: root.weekAccentColor
      }

      // Divider.
      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)
      }

      // Detail rows.
      Column {
        width: parent.width
        spacing: 7

        Repeater {
          model: root.detailRows
          delegate: Item {
            required property var modelData
            width: content.width
            height: 16

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.label
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: 12
              renderType: Text.NativeRendering
            }

            Text {
              anchors.right: parent.right
              anchors.left: parent.horizontalCenter
              horizontalAlignment: Text.AlignRight
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.value
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: 12
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }
          }
        }
      }

      // Footer: source + refresh.
      Item {
        width: parent.width
        height: 16

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: refreshButton.left
          anchors.rightMargin: 8
          text: root.sourceText || "local Claude project logs"
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)
          font.family: root.fontFamily
          font.pixelSize: 10
          elide: Text.ElideRight
          renderType: Text.NativeRendering
        }

        Text {
          id: refreshButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: "Refresh"
          color: refreshHover.containsMouse ? root.accentColor : root.mutedColor
          font.family: root.fontFamily
          font.pixelSize: 11
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering

          MouseArea {
            id: refreshHover
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.refreshRequested()
          }
        }
      }
      }
    }
  }

  readonly property var detailRows: {
    var rows = []
    rows.push({ label: "Live sessions", value: String(root.sessionCount) })
    if (root.models && root.models.length > 0)
      rows.push({ label: "Models", value: root.models.slice(0, 2).join(", ") })
    if (root.latestText.length > 0)
      rows.push({ label: "Latest", value: root.latestText })
    return rows
  }
}
