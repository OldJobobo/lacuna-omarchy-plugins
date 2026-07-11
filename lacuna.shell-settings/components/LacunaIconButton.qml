import QtQuick

LacunaRect {
  id: root

  signal triggered()
  signal secondaryTriggered()

  property alias icon: iconLabel.text
  property string iconSource: ""
  property string accessibleName: icon !== "" ? icon : "Button"
  property string accessibleDescription: ""
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
  property real iconHoverScale: 1
  property string fontFamily: tokens.monoFont
  readonly property bool hovered: stateLayer.containsMouse
  readonly property real visualScale: 1 + stateLayer.reveal * Math.max(0, iconHoverScale - 1)
  readonly property bool growsOnHover: iconHoverScale > 1

  implicitWidth: buttonSize
  implicitHeight: buttonSize
  width: implicitWidth
  height: implicitHeight
  radius: buttonRadius
  clip: true
  color: growsOnHover ? Qt.rgba(hoverAccent.r, hoverAccent.g, hoverAccent.b, stateLayer.reveal * 0.16) : "transparent"
  border.width: activeFocus || (growsOnHover && stateLayer.reveal > 0) ? 1 : 0
  border.color: activeFocus ? hoverAccent : Qt.rgba(hoverAccent.r, hoverAccent.g, hoverAccent.b, 0.34)
  y: growsOnHover ? -stateLayer.reveal * 2 : 0
  scale: visualScale
  transformOrigin: Item.Center
  activeFocusOnTab: !disabled

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Accessible.description: accessibleDescription
  Accessible.focusable: !disabled
  Accessible.onPressAction: root.activate()

  function activate() {
    if (!disabled) triggered()
  }

  Keys.onReturnPressed: function(event) {
    root.activate()
    event.accepted = true
  }

  Keys.onEnterPressed: function(event) {
    root.activate()
    event.accepted = true
  }

  Keys.onSpacePressed: function(event) {
    root.activate()
    event.accepted = true
  }

  Behavior on y {
    LacunaAnim { motion: "fast" }
  }

  Behavior on scale {
    LacunaAnim { motion: "fast" }
  }

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
    opacity: 0.86 + stateLayer.reveal * 0.14
  }

  LacunaTablerIcon {
    id: iconShape

    anchors.centerIn: parent
    visible: root.iconSource === "" && valid
    name: iconLabel.text
    color: stateLayer.reveal > 0 ? root.hoverAccent : root.muted
    iconSize: root.iconSize
  }

  LacunaText {
    id: iconLabel

    anchors.centerIn: parent
    visible: (root.iconSource === "" && !iconShape.valid) || (root.iconSource !== "" && iconImage.status !== Image.Ready)
    color: stateLayer.reveal > 0 ? root.hoverAccent : root.muted
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
    onTriggered: root.activate()
    onSecondaryClicked: root.secondaryTriggered()
  }

  LacunaTokens {
    id: tokens
  }
}
