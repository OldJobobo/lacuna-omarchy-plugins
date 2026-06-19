import QtQuick
import Quickshell.Widgets
import "../components"
import "../services"

Column {
  id: root

  signal closeRequested()

  property var service: null
  property bool compact: false
  property bool open: false
  property bool contentVisible: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color accent: "#88c0d0"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property var designTokens: fallbackDesignTokens
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property string query: ""

  function forceSearchFocus() {
    searchInput.forceActiveFocus()
  }

  function search() {
    if (service) service.search(searchInput.text)
  }

  function durationText(track) {
    return track && track.duration ? String(track.duration) : ""
  }

  visible: contentVisible
  enabled: open
  opacity: open ? 1 : 0
  anchors.margins: compact ? 10 : 12
  spacing: compact ? 8 : 10

  Behavior on opacity {
    LacunaAnim { motion: "fast" }
  }

  Row {
    width: parent.width
    height: root.compact ? 26 : 30
    spacing: 8

    LacunaText {
      width: parent.width - closeButton.width - parent.spacing
      anchors.verticalCenter: parent.verticalCenter
      text: "YouTube Music"
      color: root.foreground
      fontFamily: "Tektur"
      font.pixelSize: root.compact ? 13 : 15
      font.weight: Font.DemiBold
    }

    LacunaIconButton {
      id: closeButton
      icon: "x"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 24 : 28
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 13 : 15
      onTriggered: root.closeRequested()
    }
  }

  LacunaRect {
    width: parent.width
    height: root.compact ? 28 : 32
    radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

    LacunaText {
      visible: searchInput.text === ""
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: "Search YouTube"
      color: root.muted
      fontFamily: root.bodyFontFamily
      font.pixelSize: root.compact ? 10 : 11
    }

    TextInput {
      id: searchInput
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: searchButton.width + 12
      color: root.foreground
      selectedTextColor: root.background
      selectionColor: root.accent
      font.family: root.bodyFontFamily
      font.pixelSize: root.compact ? 10 : 11
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      onTextChanged: root.query = text
      Keys.onReturnPressed: root.search()
      Keys.onEnterPressed: root.search()
    }

    LacunaIconButton {
      id: searchButton
      anchors.right: parent.right
      anchors.rightMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      icon: "search"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 22 : 24
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 12 : 13
      onTriggered: root.search()
    }
  }

  Row {
    width: parent.width
    height: root.compact ? 32 : 38
    spacing: 6

    LacunaIconButton {
      icon: root.service && root.service.playing && !root.service.paused ? "player-pause" : "player-play"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 28 : 32
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 14 : 16
      onTriggered: if (root.service) root.service.togglePause()
    }

    LacunaIconButton {
      icon: "arrow-left"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 28 : 32
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 14 : 16
      onTriggered: if (root.service) root.service.previousOrRestart()
    }

    LacunaIconButton {
      icon: "chevron-right"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 28 : 32
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 14 : 16
      onTriggered: if (root.service) root.service.next()
    }

    LacunaText {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 108
      text: root.service && root.service.displayTitle ? root.service.displayTitle : (root.service ? root.service.statusText() : "Service disabled")
      color: root.foreground
      fontFamily: root.bodyFontFamily
      font.pixelSize: root.compact ? 10 : 11
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  LacunaText {
    visible: root.service && root.service.errorText !== ""
    width: parent.width
    text: root.service ? root.service.errorText : ""
    color: root.muted
    fontFamily: root.bodyFontFamily
    font.pixelSize: root.compact ? 9 : 10
    maximumLineCount: 2
    wrapMode: Text.WordWrap
  }

  LacunaScrollView {
    id: resultScroll
    width: parent.width
    height: Math.max(0, parent.height - y)
    spacing: root.compact ? 4 : 5
    showEdgeMasks: true
    edgeMaskColor: root.background

    Repeater {
      model: root.service && root.service.results ? root.service.results : []

      LacunaRect {
        required property var modelData
        readonly property color rowAccent: root.accent
        width: parent.width
        height: root.compact ? 46 : 54
        radius: root.designTokens.radius
        color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, rowMouse.reveal * 0.08)
        border.width: root.designTokens.lacuna ? 0 : 1
        border.color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, 0.22)
        clip: true

        Image {
          id: thumb
          anchors.left: parent.left
          anchors.leftMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          width: root.compact ? 34 : 40
          height: width
          source: modelData.thumbnail || ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: source !== "" && status !== Image.Error
        }

        LacunaTablerIcon {
          anchors.centerIn: thumb
          visible: thumb.source === "" || thumb.status === Image.Error
          name: "music"
          color: root.accent
          iconSize: root.compact ? 16 : 18
        }

        Column {
          anchors.left: thumb.right
          anchors.leftMargin: 8
          anchors.right: actionRow.left
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          LacunaText {
            width: parent.width
            text: modelData.title || "Untitled video"
            color: root.foreground
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            font.weight: Font.DemiBold
            maximumLineCount: 1
            elide: Text.ElideRight
          }

          LacunaText {
            width: parent.width
            text: [modelData.uploader || "", modelData.duration || ""].filter(function(v) { return String(v).length > 0 }).join(" / ")
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 8 : 9
            maximumLineCount: 1
            elide: Text.ElideRight
          }
        }

        Row {
          id: actionRow
          anchors.right: parent.right
          anchors.rightMargin: 5
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          LacunaIconButton {
            icon: "player-play"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 12 : 13
            onTriggered: if (root.service) root.service.playNow(modelData)
          }

          LacunaIconButton {
            icon: "plus"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 24 : 26
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 12 : 13
            onTriggered: if (root.service) root.service.addToQueue(modelData)
          }
        }

        LacunaStateLayer {
          id: rowMouse
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: actionRow.left
          stateColor: root.accent
          hoverOpacity: root.designTokens.hoverOpacity
          pressOpacity: root.designTokens.activeOpacity
          acceptWheel: true
          showFill: false
          onTriggered: if (root.service) root.service.playNow(modelData)
          onScrolled: function(delta) { resultScroll.scrollBy(delta) }
        }
      }
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
