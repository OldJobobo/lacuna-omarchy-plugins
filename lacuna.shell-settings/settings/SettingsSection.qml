import QtQuick
import "../components"

Item {
  id: root

  property string title: ""
  property string note: ""
  property bool compact: false
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property string fontFamily: "Hack Nerd Font Propo"

  height: note === "" ? (compact ? 24 : 28) : (compact ? 38 : 44)

  Column {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3

    Row {
      width: parent.width
      spacing: 8

      LacunaRect {
        width: 18
        height: 1
        anchors.verticalCenter: parent.verticalCenter
        color: root.accent
        opacity: 0.65
      }

      LacunaText {
        width: parent.width - 26
        text: root.title.toUpperCase()
        color: root.muted
        fontFamily: root.fontFamily
        font.pixelSize: root.compact ? 9 : 10
        font.weight: Font.DemiBold
      }
    }

    LacunaText {
      visible: root.note !== ""
      width: parent.width
      text: root.note
      color: root.muted
      fontFamily: root.fontFamily
      font.pixelSize: root.compact ? 9 : 10
    }
  }

  // Mirror the menu's gapped seam (the lacuna mark) under settings sections.
  Item {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1

    readonly property int gap: 22

    LacunaRect {
      anchors.left: parent.left
      height: 1
      width: (parent.width - parent.gap) / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
    }

    LacunaRect {
      anchors.right: parent.right
      height: 1
      width: (parent.width - parent.gap) / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
    }
  }
}
