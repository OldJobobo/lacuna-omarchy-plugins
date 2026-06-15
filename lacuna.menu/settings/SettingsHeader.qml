import QtQuick
import "../components"

Item {
  id: root

  signal closeRequested()

  property string title: "Settings"
  property string subtitle: "Lacuna Settings"
  property bool compact: false
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property string titleFontFamily: "Tektur"
  property string bodyFontFamily: "Hack Nerd Font"
  property var designTokens: null

  height: compact ? 42 : 48

  Row {
    anchors.fill: parent
    spacing: compact ? 8 : 10

    Column {
      width: parent.width - closeButton.width - parent.spacing
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      LacunaText {
        width: parent.width
        text: root.title
        color: root.foreground
        fontFamily: root.titleFontFamily
        font.pixelSize: root.compact ? 16 : 18
        font.weight: Font.DemiBold
      }

      LacunaText {
        width: parent.width
        text: root.subtitle
        color: root.muted
        fontFamily: root.bodyFontFamily
        font.pixelSize: root.compact ? 9 : 10
      }
    }

    LacunaIconButton {
      id: closeButton

      anchors.verticalCenter: parent.verticalCenter
      icon: "x"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 26 : 30
      buttonRadius: root.designTokens ? root.designTokens.controlRadius : 0
      hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
      pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
      iconSize: root.compact ? 13 : 15
      onTriggered: root.closeRequested()
    }
  }
}
