import QtQuick

LacunaRect {
  id: root

  signal triggered()
  signal secondaryTriggered()

  property alias icon: iconLabel.text
  property string iconSource: ""
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property color hoverAccent: accent
  property bool disabled: false
  property int iconSize: 15
  property int buttonSize: tokens.controlSmall
  property int buttonRadius: 0
  property real hoverOpacity: 0.06
  property real pressOpacity: 0.11
  property string fontFamily: tokens.monoFont
  readonly property bool hovered: stateLayer.containsMouse

  implicitWidth: buttonSize
  implicitHeight: buttonSize
  width: implicitWidth
  height: implicitHeight
  radius: buttonRadius
  clip: true

  Image {
    id: iconImage

    anchors.centerIn: parent
    width: Math.max(12, root.iconSize + 1)
    height: width
    source: root.iconSource
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    mipmap: true
    smooth: true
    visible: root.iconSource !== "" && status === Image.Ready
    opacity: stateLayer.containsMouse ? 1 : 0.86
  }

  LacunaTablerIcon {
    id: iconShape

    anchors.centerIn: parent
    visible: root.iconSource === "" && valid
    name: iconLabel.text
    color: stateLayer.containsMouse ? root.hoverAccent : root.muted
    iconSize: root.iconSize
  }

  LacunaText {
    id: iconLabel

    anchors.centerIn: parent
    visible: (root.iconSource === "" && !iconShape.valid) || (root.iconSource !== "" && iconImage.status !== Image.Ready)
    color: stateLayer.containsMouse ? root.hoverAccent : root.muted
    fontFamily: root.fontFamily
    font.pixelSize: root.iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  LacunaStateLayer {
    id: stateLayer

    disabled: root.disabled
    stateColor: root.hoverAccent
    hoverOpacity: root.hoverOpacity
    pressOpacity: root.pressOpacity
    onTriggered: root.triggered()
    onSecondaryClicked: root.secondaryTriggered()
  }

  LacunaTokens {
    id: tokens
  }
}
