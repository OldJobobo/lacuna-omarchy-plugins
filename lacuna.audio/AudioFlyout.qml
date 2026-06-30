import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

PopupWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property var owner: null
  property var service: null

  property bool open: false
  property int panelWidth: 392
  property int panelHeight: 430
  property int joinRadius: 13
  property int cornerRadius: 14
  property int margin: 8
  property color accentColor: "#89b4fa"
  property string fontFamily: bar ? bar.fontFamily : "Hack Nerd Font Propo"

  readonly property var activeService: service || fallbackService
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property int contentPadding: 14
  readonly property int innerWidth: panelWidth - contentPadding * 2
  readonly property color surfaceBackground: opaqueColor(bar ? bar.background : "#101315")
  readonly property color panelColor: Qt.rgba(surfaceBackground.r, surfaceBackground.g, surfaceBackground.b, 0.98)
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color panelFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.045)
  readonly property color panelHover: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.11)
  readonly property color lineColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
  readonly property color dimColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.60)

  function space(value) {
    return Math.round(Number(value || 0))
  }

  function opaqueColor(colorValue) {
    var c = colorValue
    if (typeof c === "string") c = Qt.color(c)
    return Qt.rgba(c.r, c.g, c.b, 1)
  }

  function close() {
    if (owner && "close" in owner) owner.close()
    else root.open = false
  }

  property real reveal: open ? 1 : 0
  Behavior on reveal { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
  readonly property real contentOpacity: Math.max(0, Math.min(1, (reveal - 0.3) / 0.7))

  visible: open || reveal > 0.001
  color: "transparent"
  implicitWidth: surface.fullWidth
  implicitHeight: surface.implicitHeight

  onOpenChanged: {
    if (!bar) return
    if (open) bar.requestPopout(root)
    else if (bar.activePopout === root) bar.releasePopout(root)
  }

  QtObject {
    id: fallbackService
    property bool hasSink: false
    property bool hasSource: false
    property bool outputMuted: true
    property bool inputMuted: true
    property real outputVolume: 0
    property real inputVolume: 0
    property int outputPercent: 0
    property int inputPercent: 0
    property string outputIcon: ""
    property string inputIcon: "󰍭"
    property string outputLabel: "No output"
    property string inputLabel: "No input"
    property string outputMood: "Muted"
    property var sinks: []
    property var sources: []
    function setOutputVolume(value) {}
    function toggleOutputMute() {}
    function toggleInputMute() {}
    function setDefaultSink(node) {}
    function setDefaultSource(node) {}
    function nodeLabel(node) { return "Unknown" }
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
    gravity: root.bar && root.bar.position === "bottom" ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1

    onAnchoring: {
      if (!root.anchorItem || !root.bar) return
      var target = root.anchorItem
      var window = target.QsWindow.window
      if (!window) return
      var below = root.bar.position !== "bottom"
      var localX = target.width / 2 - (root.joinRadius + root.panelWidth / 2)
      var localY = below ? target.height : -root.implicitHeight
      var point = window.contentItem.mapFromItem(target, localX, localY)
      point.x = Math.max(root.margin, Math.min(point.x, window.width - root.implicitWidth - root.margin))
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
      width: root.implicitWidth
      height: root.implicitHeight

      BarFlyoutSurface {
        id: surface
        panelWidth: root.panelWidth
        panelHeight: root.panelHeight
        joinRadius: root.joinRadius
        cornerRadius: root.cornerRadius
        panelColor: root.panelColor
      }

      Item {
        x: surface.panelLeft + root.contentPadding
        y: surface.panelTop + root.contentPadding
        width: root.innerWidth
        height: root.panelHeight - root.contentPadding * 2
        opacity: root.contentOpacity

        Rectangle {
          id: hero
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: root.space(126)
          radius: 0
          color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.075)

          Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: root.space(12)
            anchors.topMargin: root.space(11)
            text: "LACUNA AUDIO"
            color: root.dimColor
            font.family: root.fontFamily
            font.pixelSize: 11
            font.bold: true
          }

          Text {
            id: outputIcon
            anchors.left: parent.left
            anchors.leftMargin: root.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: activeService.outputIcon
            color: root.accentColor
            font.family: root.fontFamily
            font.pixelSize: 34
          }

          Column {
            anchors.left: outputIcon.right
            anchors.leftMargin: root.space(12)
            anchors.right: parent.right
            anchors.rightMargin: root.space(12)
            anchors.verticalCenter: outputIcon.verticalCenter
            spacing: root.space(3)

            Text {
              width: parent.width
              text: activeService.outputMuted ? "Muted" : activeService.outputPercent + "%"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: 20
              font.bold: true
            }

            Text {
              width: parent.width
              text: activeService.outputLabel + " / " + activeService.outputMood
              color: root.dimColor
              font.family: root.fontFamily
              font.pixelSize: 13
              elide: Text.ElideRight
            }
          }

          Slider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.space(12)
            from: 0
            to: 150
            value: activeService.outputPercent
            live: true
            onMoved: activeService.setOutputVolume(value / 100)
          }
        }

        Row {
          id: actions
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: hero.bottom
          anchors.topMargin: root.space(10)
          spacing: root.space(7)

          ActionChip {
            text: activeService.outputMuted ? "UNMUTE" : "MUTE"
            accent: root.accentColor
            onTriggered: activeService.toggleOutputMute()
          }

          ActionChip {
            text: activeService.inputMuted ? "MIC OFF" : "MIC ON"
            accent: root.dimColor
            enabled: activeService.hasSource
            onTriggered: activeService.toggleInputMute()
          }
        }

        Text {
          id: outputTitle
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: actions.bottom
          anchors.topMargin: root.space(16)
          text: "OUTPUT DEVICES"
          color: root.dimColor
          font.family: root.fontFamily
          font.pixelSize: 11
          font.bold: true
        }

        Flickable {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: outputTitle.bottom
          anchors.topMargin: root.space(8)
          anchors.bottom: parent.bottom
          clip: true
          contentWidth: width
          contentHeight: deviceColumn.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: deviceColumn
            width: parent.width
            spacing: root.space(7)

            Repeater {
              model: activeService.sinks
              DeviceSlat {
                required property var modelData
                width: parent ? parent.width : 0
                label: activeService.nodeLabel(modelData)
                selected: modelData === activeService.sink
                onTriggered: activeService.setDefaultSink(modelData)
              }
            }

            Repeater {
              model: activeService.sources
              DeviceSlat {
                required property var modelData
                width: parent ? parent.width : 0
                label: "MIC / " + activeService.nodeLabel(modelData)
                selected: modelData === activeService.source
                onTriggered: activeService.setDefaultSource(modelData)
              }
            }
          }
        }
      }
    }
  }

  component ActionChip: Rectangle {
    id: chip
    signal triggered()
    property string text: ""
    property color accent: root.accentColor
    property bool enabled: true
    width: label.implicitWidth + root.space(16)
    height: root.space(24)
    radius: 0
    color: chipMouse.containsMouse && enabled ? Qt.rgba(accent.r, accent.g, accent.b, 0.18) : Qt.rgba(accent.r, accent.g, accent.b, 0.075)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, enabled ? 0.35 : 0.15)
    opacity: enabled ? 1 : 0.48
    Text {
      id: label
      anchors.centerIn: parent
      text: chip.text
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: 11
      font.bold: true
    }
    MouseArea {
      id: chipMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: chip.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.triggered()
    }
  }

  component DeviceSlat: Rectangle {
    id: slat
    signal triggered()
    property string label: ""
    property bool selected: false
    height: root.space(42)
    radius: 0
    color: selected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : (slatMouse.containsMouse ? root.panelHover : root.panelFill)
    border.width: 1
    border.color: selected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.42) : root.lineColor
    Text {
      anchors.left: parent.left
      anchors.right: status.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: root.space(12)
      anchors.rightMargin: root.space(8)
      text: slat.label
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: 13
      elide: Text.ElideRight
    }
    Text {
      id: status
      anchors.right: parent.right
      anchors.rightMargin: root.space(12)
      anchors.verticalCenter: parent.verticalCenter
      text: slat.selected ? "ACTIVE" : "USE"
      color: slat.selected ? root.accentColor : root.dimColor
      font.family: root.fontFamily
      font.pixelSize: 11
      font.bold: true
    }
    MouseArea {
      id: slatMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: slat.triggered()
    }
  }
}
