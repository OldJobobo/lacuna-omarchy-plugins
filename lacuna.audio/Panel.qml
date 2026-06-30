import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null
  property bool closingFromHost: false

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "lacuna.audio"
  readonly property var activeService: service || fallbackService
  readonly property color surfaceBackground: opaqueColor(Color.bar.background)
  readonly property color lacunaSurface: Qt.rgba(surfaceBackground.r, surfaceBackground.g, surfaceBackground.b, 0.98)
  readonly property color lacunaPanel: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.045)
  readonly property color lacunaHover: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.11)
  readonly property color lacunaLine: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.14)
  readonly property color lacunaDim: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.60)

  function opaqueColor(colorValue) {
    var c = colorValue
    if (typeof c === "string") c = Qt.color(c)
    return Qt.rgba(c.r, c.g, c.b, 1)
  }

  function resolveService() {
    if (service) return
    if (shell && typeof shell.ensureService === "function") {
      var ensured = shell.ensureService("lacuna.audio")
      if (ensured) {
        service = ensured
        return
      }
    }
    if (shell && typeof shell.serviceFor === "function") {
      var existing = shell.serviceFor("lacuna.audio")
      if (existing) service = existing
    }
  }

  function open(payloadJson) {
    resolveService()
    closingFromHost = false
    window.visible = true
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  Component.onCompleted: resolveService()
  onShellChanged: resolveService()

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
    property var streams: []
    function setOutputVolume(value) {}
    function setInputVolume(value) {}
    function toggleOutputMute() {}
    function toggleInputMute() {}
    function setDefaultSink(node) {}
    function setDefaultSource(node) {}
    function nodeLabel(node) { return "Unknown" }
    function streamLabel(node) { return "Stream" }
    function setStreamVolume(node, value) {}
    function toggleStreamMute(node) {}
  }

  PanelWindow {
    id: window

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "lacuna-audio-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide(root.pluginId)
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Rectangle {
      id: card

      width: Math.min(Style.space(500), Math.max(Style.space(390), window.width - Style.space(32)))
      height: Math.min(Style.space(620), Math.max(Style.space(430), window.height - Style.space(64)))
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(42)
      anchors.rightMargin: Style.space(14)
      radius: Math.max(2, Style.cornerRadius)
      color: root.lacunaSurface
      border.width: 1
      border.color: root.lacunaLine
      clip: true

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Rectangle {
        id: spine
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.space(54)
        color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.035)

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Style.space(3)
          color: Color.accent
        }

        Text {
          anchors.centerIn: parent
          text: "MIX"
          rotation: -90
          color: root.lacunaDim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      Flickable {
        id: content
        anchors.left: spine.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Style.space(18)
        anchors.leftMargin: Style.space(16)
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: column
          width: content.width
          spacing: Style.space(12)

          Rectangle {
            width: parent.width
            height: Style.space(154)
            radius: Style.cornerRadius
            color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.075)
            border.width: 1
            border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.20)

            Text {
              id: eyebrow
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.leftMargin: Style.space(16)
              anchors.topMargin: Style.space(14)
              text: "LACUNA AUDIO PROVIDER"
              color: root.lacunaDim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              id: heroIcon
              anchors.left: parent.left
              anchors.top: eyebrow.bottom
              anchors.leftMargin: Style.space(16)
              anchors.topMargin: Style.space(14)
              text: activeService.outputIcon
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.display
            }

            Column {
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(15)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(16)
              anchors.verticalCenter: heroIcon.verticalCenter
              spacing: Style.space(3)

              Text {
                width: parent.width
                text: activeService.outputMood
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: activeService.outputLabel
                color: root.lacunaDim
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }
            }

            Row {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: Style.space(12)
              spacing: Style.space(8)

              ActionChip {
                text: activeService.outputMuted ? "UNMUTE" : "MUTE"
                accent: activeService.outputMuted ? root.lacunaDim : Color.accent
                enabled: activeService.hasSink
                onTriggered: activeService.toggleOutputMute()
              }

              ActionChip {
                text: "CLOSE"
                accent: root.lacunaDim
                onTriggered: root.close()
              }
            }
          }

          VolumeSlab {
            title: "OUTPUT"
            icon: activeService.outputIcon
            label: activeService.outputLabel
            percent: activeService.outputPercent
            muted: activeService.outputMuted
            enabled: activeService.hasSink
            onChanged: function(value) { activeService.setOutputVolume(value / 100) }
            onToggle: activeService.toggleOutputMute()
          }

          VolumeSlab {
            title: "INPUT"
            icon: activeService.inputIcon
            label: activeService.inputLabel
            percent: activeService.inputPercent
            muted: activeService.inputMuted
            enabled: activeService.hasSource
            onChanged: function(value) { activeService.setInputVolume(value / 100) }
            onToggle: activeService.toggleInputMute()
          }

          Text {
            width: parent.width
            text: "OUTPUT DEVICES"
            color: root.lacunaDim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Repeater {
            model: activeService.sinks
            DeviceSlat {
              width: column.width
              label: activeService.nodeLabel(modelData)
              active: modelData === activeService.sink
              onTriggered: activeService.setDefaultSink(modelData)
            }
          }

          Text {
            width: parent.width
            visible: activeService.streams.length > 0
            text: "PLAYBACK STREAMS"
            color: root.lacunaDim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Repeater {
            model: activeService.streams
            StreamSlat {
              width: column.width
              node: modelData
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
    property color accent: Color.accent
    property bool enabled: true
    width: label.implicitWidth + Style.space(20)
    height: Style.space(28)
    radius: height / 2
    color: chipMouse.containsMouse && enabled ? Qt.rgba(accent.r, accent.g, accent.b, 0.18) : Qt.rgba(accent.r, accent.g, accent.b, 0.075)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, enabled ? 0.35 : 0.15)
    opacity: enabled ? 1 : 0.48
    Text {
      id: label
      anchors.centerIn: parent
      text: chip.text
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
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

  component VolumeSlab: Rectangle {
    id: slab
    signal changed(real value)
    signal toggle()
    property string title: ""
    property string icon: ""
    property string label: ""
    property int percent: 0
    property bool muted: false
    property bool enabled: true
    height: Style.space(86)
    radius: Style.cornerRadius
    color: slabMouse.containsMouse ? root.lacunaHover : root.lacunaPanel
    border.width: 1
    border.color: root.lacunaLine
    opacity: enabled ? 1 : 0.48

    Text {
      id: slabIcon
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: Style.space(14)
      anchors.topMargin: Style.space(13)
      text: slab.icon
      color: slab.muted ? root.lacunaDim : Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.title
    }

    Text {
      anchors.left: slabIcon.right
      anchors.right: percentLabel.left
      anchors.top: parent.top
      anchors.leftMargin: Style.space(12)
      anchors.rightMargin: Style.space(8)
      anchors.topMargin: Style.space(12)
      text: slab.title + " / " + slab.label
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      id: percentLabel
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: Style.space(14)
      anchors.topMargin: Style.space(12)
      text: slab.percent + "%"
      color: root.lacunaDim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Style.space(14)
      height: Style.space(8)
      radius: height / 2
      color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10)

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1.5, slab.percent / 100)) / 1.5
        height: parent.height
        radius: parent.radius
        color: slab.muted ? root.lacunaDim : Color.accent
      }
    }

    MouseArea {
      id: slabMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: slab.enabled
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) slab.toggle()
        else slab.changed(mouse.x / width * 150)
      }
      onWheel: function(wheel) {
        slab.changed(slab.percent + (wheel.angleDelta.y > 0 ? 5 : -5))
      }
    }
  }

  component DeviceSlat: Rectangle {
    id: slat
    signal triggered()
    property string label: ""
    property bool active: false
    height: Style.space(42)
    radius: Style.cornerRadius
    color: active ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12) : (slatMouse.containsMouse ? root.lacunaHover : root.lacunaPanel)
    border.width: 1
    border.color: active ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.42) : root.lacunaLine
    Text {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(14)
      anchors.rightMargin: Style.space(14)
      text: slat.label
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
    }
    MouseArea {
      id: slatMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: slat.triggered()
    }
  }

  component StreamSlat: VolumeSlab {
    required property var node
    title: "STREAM"
    icon: node && node.audio && node.audio.muted ? "" : ""
    label: activeService.streamLabel(node)
    percent: node && node.audio ? Math.round(node.audio.volume * 100) : 0
    muted: node && node.audio ? node.audio.muted : false
    enabled: !!node && !!node.audio
    onChanged: function(value) { activeService.setStreamVolume(node, value / 100) }
    onToggle: activeService.toggleStreamMute(node)
  }
}
