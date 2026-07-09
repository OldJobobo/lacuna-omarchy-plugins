import QtQuick
import QtQuick.Controls
import "../components"

LacunaRect {
  id: root

  signal accepted(string value)

  property string icon: ""
  property string label: ""
  property string hint: ""
  property string textValue: ""
  property string placeholder: ""
  property bool masked: false
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color toneAccent: "#88c0d0"
  property string titleFontFamily: "Tektur"
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property var designTokens: null

  function tokenBool(name, fallback) {
    if (!designTokens || designTokens[name] === undefined || designTokens[name] === null) return fallback
    return designTokens[name] === true
  }

  function tokenNumber(name, fallback) {
    if (!designTokens || designTokens[name] === undefined || designTokens[name] === null) return fallback
    var value = Number(designTokens[name])
    return isFinite(value) ? value : fallback
  }

  readonly property int rowHeight: compact ? 48 : 54
  readonly property int inputWidth: compact ? 154 : 196

  width: parent ? parent.width : implicitWidth
  height: rowHeight
  radius: tokenNumber("controlRadius", 0)
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.025 + stateLayer.reveal * 0.03)
  border.width: tokenBool("omarchy", false) && stateLayer.containsMouse ? 1 : 0
  border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
  clip: true

  LacunaStateLayer {
    id: stateLayer
    disabled: true
    stateColor: root.toneAccent
    hoverOpacity: root.tokenNumber("hoverOpacity", 0.06)
    pressOpacity: root.tokenNumber("activeOpacity", 0.11)
    showFill: false
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
      anchors.verticalCenter: parent.verticalCenter

      LacunaTablerIcon {
        anchors.centerIn: parent
        name: root.icon
        color: input.activeFocus ? root.toneAccent : root.muted
        iconSize: root.compact ? 14 : 16
      }
    }

    Column {
      width: Math.max(0, parent.width - (root.compact ? 24 : 28) - root.inputWidth - parent.spacing * 2)
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

    LacunaRect {
      width: root.inputWidth
      height: root.compact ? 28 : 30
      anchors.verticalCenter: parent.verticalCenter
      radius: root.tokenNumber("controlRadius", 0)
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.045)
      border.width: 1
      border.color: input.activeFocus ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.44) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.13)
      clip: true

      TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        text: root.textValue
        color: root.foreground
        selectionColor: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.35)
        selectedTextColor: root.foreground
        font.family: root.bodyFontFamily
        font.pixelSize: root.compact ? 10 : 11
        echoMode: root.masked ? TextInput.Password : TextInput.Normal
        passwordCharacter: "*"
        clip: true
        onEditingFinished: root.accepted(text)
        Keys.onReturnPressed: root.accepted(text)
        Keys.onEnterPressed: root.accepted(text)
        Text {
          visible: input.text === "" && !input.activeFocus && root.placeholder !== ""
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: root.placeholder
          color: root.muted
          font.family: root.bodyFontFamily
          font.pixelSize: root.compact ? 10 : 11
        }
      }
    }
  }
}
