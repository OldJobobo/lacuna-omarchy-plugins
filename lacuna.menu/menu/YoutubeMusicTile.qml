import QtQuick
import QtMultimedia
import Quickshell.Widgets
import "../components"
import "../services"

Item {
  id: root

  signal openRequested()

  property var service: null
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color accent: "#88c0d0"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property var designTokens: fallbackDesignTokens
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property bool volumeOpen: false

  readonly property bool available: service && service.available === true
  readonly property bool hasTrack: service && service.hasTrack === true
  readonly property bool playing: service && service.playing === true && service.paused !== true
  readonly property string title: hasTrack ? service.displayTitle : (available ? "YouTube Music" : "YouTube Music unavailable")
  readonly property string subtitle: service ? service.statusText() : "Service disabled"
  readonly property string thumbnail: service && service.thumbnail ? String(service.thumbnail) : ""
  readonly property string previewUrl: service && service.previewStreamUrl ? String(service.previewStreamUrl) : ""
  readonly property bool previewActive: previewUrl !== ""
  readonly property int streamVolume: service && service.volume !== undefined ? Number(service.volume) : 70
  readonly property int tileInset: compact ? 8 : 10
  readonly property int previewWidth: Math.max(120, width - (tileInset * 2))
  readonly property int previewHeight: Math.round(previewWidth * 0.5625)
  readonly property int volumeRevealHeight: volumeOpen ? (compact ? 24 : 26) : 0
  readonly property int tileHeight: previewHeight + (compact ? 82 : 92) + volumeRevealHeight

  function setVolumeFromX(localX, railWidth) {
    if (!service || railWidth <= 0) return
    service.setVolume(Math.round(Math.max(0, Math.min(1, localX / railWidth)) * 100))
  }

  width: parent ? parent.width : 260
  height: tileHeight
  visible: service !== null

  LacunaRect {
    anchors.fill: parent
    radius: root.designTokens.radius
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, stateLayer.reveal * 0.055)
    border.width: root.designTokens.lacuna ? 0 : 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)

    LacunaRect {
      visible: root.designTokens.lacuna
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 1
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
    }

    LacunaStateLayer {
      id: stateLayer
      anchors.fill: parent
      stateColor: root.accent
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      showFill: false
      onTriggered: root.openRequested()
    }

    LacunaRect {
      id: previewFrame
      anchors.top: parent.top
      anchors.topMargin: root.tileInset
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.previewWidth
      height: root.previewHeight
      radius: root.designTokens.controlRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
      clip: true

      MediaPlayer {
        id: previewPlayer
        source: root.previewActive ? root.previewUrl : ""
        videoOutput: previewOutput
        audioOutput: AudioOutput {
          muted: true
          volume: 0
        }
        loops: MediaPlayer.Infinite
        onSourceChanged: {
          if (source.toString() !== "") play()
          else stop()
        }
      }

      VideoOutput {
        id: previewOutput
        anchors.fill: parent
        visible: root.previewActive
        fillMode: VideoOutput.PreserveAspectCrop
      }

      Image {
        anchors.fill: parent
        source: root.thumbnail
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.previewActive && previewPlayer.playbackState === MediaPlayer.PlayingState ? 0 : 1
        visible: root.thumbnail !== "" && status !== Image.Error && opacity > 0

        Behavior on opacity {
          LacunaAnim { motion: "fast" }
        }
      }

      LacunaTablerIcon {
        anchors.centerIn: parent
        visible: root.thumbnail === "" && !root.previewActive
        name: "music"
        color: root.available ? root.accent : root.muted
        iconSize: root.compact ? 22 : 26
      }
    }

    Column {
      id: infoColumn
      anchors.left: parent.left
      anchors.leftMargin: root.tileInset
      anchors.right: parent.right
      anchors.rightMargin: root.tileInset
      anchors.top: previewFrame.bottom
      anchors.topMargin: root.compact ? 7 : 9
      spacing: root.compact ? 1 : 2

      LacunaText {
        width: parent.width
        text: root.title
        color: root.foreground
        fontFamily: root.bodyFontFamily
        font.pixelSize: root.compact ? 10 : 11
        font.weight: Font.DemiBold
        maximumLineCount: 1
        elide: Text.ElideRight
      }

      LacunaText {
        width: parent.width
        text: root.subtitle
        color: root.playing ? root.accent : root.muted
        fontFamily: root.bodyFontFamily
        font.pixelSize: root.compact ? 8 : 9
        maximumLineCount: 1
        elide: Text.ElideRight
      }
    }

    Row {
      id: controlRow

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: infoColumn.bottom
      anchors.topMargin: root.compact ? 6 : 7
      spacing: 6

      LacunaIconButton {
        icon: root.playing ? "player-pause" : "player-play"
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        hoverAccent: root.accent
        buttonSize: root.compact ? 24 : 26
        buttonRadius: root.designTokens.controlRadius
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        iconSize: root.compact ? 13 : 14
        onTriggered: if (root.service) root.service.togglePause()
      }

      LacunaIconButton {
        icon: "volume"
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        hoverAccent: root.accent
        buttonSize: root.compact ? 24 : 26
        buttonRadius: root.designTokens.controlRadius
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        iconSize: root.compact ? 13 : 14
        onTriggered: {
          root.volumeOpen = !root.volumeOpen
          if (root.volumeOpen) hideVolumeTimer.restart()
          else hideVolumeTimer.stop()
        }
      }

      LacunaIconButton {
        icon: "list"
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        hoverAccent: root.accent
        buttonSize: root.compact ? 24 : 26
        buttonRadius: root.designTokens.controlRadius
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        iconSize: root.compact ? 13 : 14
        onTriggered: root.openRequested()
      }
    }

    Row {
      id: volumeRow
      anchors.left: parent.left
      anchors.leftMargin: root.tileInset
      anchors.right: parent.right
      anchors.rightMargin: root.tileInset
      anchors.top: controlRow.bottom
      anchors.topMargin: root.volumeOpen ? (root.compact ? 6 : 7) : 0
      height: root.volumeRevealHeight
      opacity: root.volumeOpen ? 1 : 0
      visible: height > 0
      clip: true
      spacing: 6

      Behavior on height {
        LacunaAnim { motion: "fast" }
      }

      Behavior on opacity {
        LacunaAnim { motion: "fast" }
      }

      Item {
        id: volumeRail
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - volumeValue.width - parent.spacing
        height: parent.height

        LacunaRect {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          height: 4
          radius: 2
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
        }

        LacunaRect {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: Math.max(4, parent.width * root.streamVolume / 100)
          height: 4
          radius: 2
          color: root.accent
        }

        LacunaRect {
          x: Math.max(0, Math.min(parent.width - width, parent.width * root.streamVolume / 100 - width / 2))
          anchors.verticalCenter: parent.verticalCenter
          width: root.compact ? 10 : 11
          height: width
          radius: width / 2
          color: root.foreground
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onPressed: function(mouse) {
            root.volumeOpen = true
            hideVolumeTimer.stop()
            root.setVolumeFromX(mouse.x, volumeRail.width)
          }
          onPositionChanged: function(mouse) { if (pressed) root.setVolumeFromX(mouse.x, volumeRail.width) }
          onReleased: hideVolumeTimer.restart()
          onWheel: function(wheel) {
            if (root.service) root.service.adjustVolume(wheel.angleDelta.y > 0 ? 5 : -5)
            root.volumeOpen = true
            hideVolumeTimer.restart()
            wheel.accepted = true
          }
        }
      }

      LacunaText {
        id: volumeValue
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        horizontalAlignment: Text.AlignRight
        text: String(root.streamVolume)
        color: root.muted
        fontFamily: root.bodyFontFamily
        font.pixelSize: root.compact ? 8 : 9
      }
    }

    Timer {
      id: hideVolumeTimer
      interval: 2600
      repeat: false
      onTriggered: root.volumeOpen = false
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }
}
