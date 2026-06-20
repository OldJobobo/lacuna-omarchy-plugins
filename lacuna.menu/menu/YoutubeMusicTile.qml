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
  property real videoReveal: localPreviewVisible ? 1 : 0
  property real layoutReveal: (localPreviewVisible || videoReveal > 0.01) ? 1 : 0

  readonly property bool available: service && service.available === true
  readonly property bool hasTrack: service && service.hasTrack === true
  readonly property bool playbackLoaded: service && service.playing === true
  readonly property bool sentToBackground: service && service.backgroundVideoEnabled === true
  readonly property bool localPreviewVisible: hasTrack && !sentToBackground
  readonly property bool playing: service && service.playing === true && service.paused !== true
  readonly property string title: hasTrack ? service.displayTitle : (available ? "YouTube Music" : "YouTube Music unavailable")
  readonly property string subtitle: service ? service.statusText() : "Service disabled"
  readonly property string thumbnail: service && service.thumbnail ? String(service.thumbnail) : ""
  readonly property string previewUrl: service && service.previewStreamUrl ? String(service.previewStreamUrl) : ""
  readonly property bool previewActive: previewUrl !== ""
  readonly property real playbackPosition: service && service.playbackPosition !== undefined ? Math.max(0, Number(service.playbackPosition) || 0) : 0
  readonly property int favoritesRevision: service && service.favoritesRevision !== undefined ? Number(service.favoritesRevision) : 0
  readonly property bool currentFavorite: favoritesRevision >= 0 && service && service.currentFavorite === true
  readonly property string repeatMode: service && service.repeatMode ? String(service.repeatMode) : "none"
  readonly property int streamVolume: service && service.volume !== undefined ? Number(service.volume) : 70
  readonly property int tileInset: compact ? 8 : 10
  readonly property int previewWidth: Math.max(120, width - (tileInset * 2))
  readonly property int previewHeight: Math.round(previewWidth * 0.5625)
  readonly property real previewRevealHeight: previewHeight * videoReveal
  readonly property int previewTopGap: tileInset
  readonly property int expandedInfoTopGap: compact ? 7 : 9
  readonly property int collapsedLowerContentY: previewTopGap
  readonly property int expandedLowerContentY: previewTopGap + previewHeight + expandedInfoTopGap
  readonly property real revealedLowerContentY: collapsedLowerContentY + (expandedLowerContentY - collapsedLowerContentY) * layoutReveal
  readonly property int lowerContentHeight: compact ? 57 : 63
  readonly property int volumeRevealHeight: volumeOpen ? (compact ? 24 : 26) : 0
  readonly property int tileHeight: Math.round(revealedLowerContentY) + lowerContentHeight + 10 + volumeRevealHeight
  readonly property real collapsedContentOpacity: Math.max(0, Math.min(1, (0.3 - layoutReveal) / 0.3))
  readonly property real expandedContentOpacity: Math.max(0, Math.min(1, (layoutReveal - 0.58) / 0.42))

  Behavior on videoReveal {
    NumberAnimation {
      duration: 1200
      easing.type: Easing.OutCubic
    }
  }

  Behavior on layoutReveal {
    NumberAnimation {
      duration: layoutReveal > 0 ? 1200 : 420
      easing.type: Easing.OutCubic
    }
  }

  function setVolumeFromX(localX, railWidth) {
    if (!service || railWidth <= 0) return
    service.setVolume(Math.round(Math.max(0, Math.min(1, localX / railWidth)) * 100))
  }

  function syncPreviewPlayback() {
    if (!previewActive) {
      previewPlayer.stop()
      return
    }
    if (!localPreviewVisible) {
      previewPlayer.pause()
      return
    }
    syncPreviewPosition(true)
    if (playing) previewPlayer.play()
    else previewPlayer.pause()
  }

  function syncPreviewPosition(force) {
    if (!previewActive) return
    var target = Math.max(0, Math.round(playbackPosition * 1000))
    if (force || Math.abs(previewPlayer.position - target) > 900) {
      previewPlayer.setPosition(target)
    }
  }

  onPlayingChanged: syncPreviewPlayback()
  onPreviewActiveChanged: syncPreviewPlayback()
  onLocalPreviewVisibleChanged: syncPreviewPlayback()
  onPlaybackPositionChanged: syncPreviewPosition(false)

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

    LacunaIconButton {
      id: tileFavoriteButton

      z: 4
      anchors.top: parent.top
      anchors.topMargin: root.tileInset
      anchors.right: parent.right
      anchors.rightMargin: root.tileInset
      icon: root.currentFavorite ? "heart-filled" : "heart"
      disabled: !root.hasTrack
      opacity: disabled ? 0.42 : 1
      foreground: root.foreground
      muted: root.currentFavorite ? root.accent : root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 24 : 26
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 13 : 14
      iconHoverScale: 1.28
      onTriggered: if (root.service) root.service.toggleFavorite(root.service.currentTrack)
    }

    Rectangle {
      id: previewFrame
      anchors.top: parent.top
      anchors.topMargin: root.previewTopGap
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.previewWidth
      height: root.previewRevealHeight
      radius: root.designTokens.controlRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
      opacity: root.videoReveal
      visible: root.videoReveal > 0.01
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
        onSourceChanged: root.syncPreviewPlayback()
        onPlaybackStateChanged: root.syncPreviewPosition(true)
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
        opacity: root.previewActive && previewPlayer.playbackState !== MediaPlayer.StoppedState ? 0 : 1
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

    Component {
      id: lowerContentComponent

      Item {
        id: contentRoot

        width: parent ? parent.width : 0
        height: root.lowerContentHeight

        Column {
          id: infoColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.rightMargin: root.tileInset + tileFavoriteButton.width
          anchors.top: parent.top
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
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: infoColumn.bottom
          anchors.topMargin: root.compact ? 6 : 7
          spacing: 6

          LacunaIconButton {
            icon: "player-skip-back"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 13 : 14
            iconHoverScale: 1.28
            onTriggered: if (root.service) root.service.previousOrRestart()
          }

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
            iconHoverScale: 1.28
            onTriggered: if (root.service) root.service.togglePause()
          }

          LacunaIconButton {
            icon: "player-stop"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 13 : 14
            iconHoverScale: 1.28
            onTriggered: if (root.service) root.service.stop()
          }

          LacunaIconButton {
            icon: "player-skip-forward"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 13 : 14
            iconHoverScale: 1.28
            onTriggered: if (root.service) root.service.next()
          }

          LacunaIconButton {
            icon: root.repeatMode === "one" ? "repeat-once" : "repeat"
            foreground: root.foreground
            muted: root.repeatMode === "none" ? root.muted : root.accent
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 13 : 14
            iconHoverScale: 1.28
            onTriggered: if (root.service) root.service.cycleRepeatMode()
          }

          LacunaIconButton {
            icon: "background"
            foreground: root.service && root.service.backgroundVideoEnabled ? root.accent : root.foreground
            muted: root.service && root.service.backgroundVideoEnabled ? root.accent : root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 13 : 14
            iconHoverScale: 1.28
            onTriggered: if (root.service) root.service.toggleBackgroundVideo()
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
            iconHoverScale: 1.28
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
            iconHoverScale: 1.28
            onTriggered: root.openRequested()
          }
        }
      }
    }

    Loader {
      id: collapsedContent
      x: root.tileInset
      y: root.collapsedLowerContentY
      width: Math.max(0, parent.width - root.tileInset * 2)
      height: root.lowerContentHeight
      active: root.layoutReveal < 0.45
      opacity: root.collapsedContentOpacity
      enabled: opacity > 0.01
      sourceComponent: lowerContentComponent
      visible: active && opacity > 0.01
    }

    Loader {
      id: expandedContent
      x: root.tileInset
      y: root.expandedLowerContentY
      width: Math.max(0, parent.width - root.tileInset * 2)
      height: root.lowerContentHeight
      active: root.layoutReveal > 0.35
      opacity: root.expandedContentOpacity
      enabled: opacity > 0.01
      sourceComponent: lowerContentComponent
      visible: active && opacity > 0.01
    }


    Row {
      id: volumeRow
      anchors.left: parent.left
      anchors.leftMargin: root.tileInset
      anchors.right: parent.right
      anchors.rightMargin: root.tileInset
      y: Math.round(root.revealedLowerContentY) + root.lowerContentHeight + (root.volumeOpen ? (root.compact ? 6 : 7) : 0)
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

    Timer {
      interval: 1500
      repeat: true
      running: root.previewActive && root.localPreviewVisible && root.playing
      onTriggered: root.syncPreviewPosition(false)
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
