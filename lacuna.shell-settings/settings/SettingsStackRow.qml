import QtQuick
import "../components"

LacunaRect {
  id: root

  signal toggled()
  signal moveUp()
  signal moveDown()

  property string icon: "background"
  property string label: ""
  property string hint: ""
  property string value: ""
  property bool checked: false
  property bool canMoveUp: false
  property bool canMoveDown: false
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color toneAccent: "#88c0d0"
  property string titleFontFamily: "Tektur"
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property var designTokens: null

  function tokenNumber(name, fallback) {
    if (!designTokens || designTokens[name] === undefined || designTokens[name] === null) return fallback
    var value = Number(designTokens[name])
    return isFinite(value) ? value : fallback
  }

  readonly property int rowHeight: compact ? 44 : 50
  readonly property int trailingWidth: checked ? (compact ? 108 : 120) : (compact ? 48 : 56)

  width: parent ? parent.width : implicitWidth
  height: rowHeight
  radius: tokenNumber("controlRadius", 0)
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, checked ? 0.040 + stateLayer.reveal * 0.032 : 0.025 + stateLayer.reveal * 0.03)
  border.width: checked ? 1 : 0
  border.color: checked ? Qt.rgba(toneAccent.r, toneAccent.g, toneAccent.b, 0.28) : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
  clip: true

  LacunaStateLayer {
    id: stateLayer

    stateColor: root.toneAccent
    hoverOpacity: root.tokenNumber("hoverOpacity", 0.06)
    pressOpacity: root.tokenNumber("activeOpacity", 0.11)
    showFill: false
    onTriggered: root.toggled()
  }

  Row {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: root.compact ? 8 : 10
    anchors.rightMargin: root.compact ? 8 : 10
    spacing: root.compact ? 7 : 9

    Item {
      width: root.compact ? 24 : 28
      height: root.rowHeight

      LacunaTablerIcon {
        anchors.centerIn: parent
        name: root.icon
        color: root.checked || stateLayer.containsMouse ? root.toneAccent : root.muted
        iconSize: root.compact ? 14 : 16
      }
    }

    Column {
      width: Math.max(0, parent.width - (root.compact ? 24 : 28) - root.trailingWidth - parent.spacing * 2)
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      LacunaText {
        width: parent.width
        text: root.label
        color: root.foreground
        fontFamily: root.titleFontFamily
        font.pixelSize: root.compact ? 12 : 13
        font.weight: Font.DemiBold
      }

      LacunaText {
        visible: root.hint !== ""
        width: parent.width
        text: root.hint
        color: root.muted
        fontFamily: root.bodyFontFamily
        font.pixelSize: root.compact ? 9 : 10
      }
    }

    Item {
      width: root.trailingWidth
      height: root.rowHeight
      anchors.verticalCenter: parent.verticalCenter

      LacunaRect {
        visible: !root.checked
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.compact ? 22 : 24
        radius: root.tokenNumber("controlRadius", 0)
        color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.10 + stateLayer.reveal * 0.08)
        border.width: 1
        border.color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.28)

        Row {
          anchors.centerIn: parent
          spacing: 4

          LacunaTablerIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "plus"
            color: root.toneAccent
            iconSize: root.compact ? 10 : 11
          }

          LacunaText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Add"
            color: root.toneAccent
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 8 : 9
          }
        }
      }

      Row {
        visible: root.checked
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.compact ? 22 : 24
        spacing: root.compact ? 4 : 5

        LacunaRect {
          width: root.compact ? 30 : 34
          height: parent.height
          radius: root.tokenNumber("controlRadius", 0)
          color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.16)
          border.width: 1
          border.color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.34)

          LacunaText {
            anchors.centerIn: parent
            text: root.value
            color: root.toneAccent
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 8 : 9
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }
        }

        LacunaIconButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "arrow-up"
          buttonSize: root.compact ? 22 : 24
          iconSize: root.compact ? 10 : 11
          foreground: root.foreground
          muted: root.muted
          accent: root.toneAccent
          hoverAccent: root.toneAccent
          disabled: !root.canMoveUp
          onTriggered: root.moveUp()
        }

        LacunaIconButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "arrow-down"
          buttonSize: root.compact ? 22 : 24
          iconSize: root.compact ? 10 : 11
          foreground: root.foreground
          muted: root.muted
          accent: root.toneAccent
          hoverAccent: root.toneAccent
          disabled: !root.canMoveDown
          onTriggered: root.moveDown()
        }

        LacunaTablerIcon {
          anchors.verticalCenter: parent.verticalCenter
          name: "check"
          color: root.toneAccent
          iconSize: root.compact ? 12 : 13
        }
      }
    }
  }
}
