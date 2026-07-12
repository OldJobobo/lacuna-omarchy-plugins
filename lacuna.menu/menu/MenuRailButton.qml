import QtQuick
import Quickshell.Widgets
import "../components"

LacunaRect {
  id: root

  signal triggered()

  property string shape: "apps"
  property string iconSource: ""
  property string accessibleName: shape !== "" ? shape : "Menu action"
  property string accessibleDescription: ""
  property bool disabled: false
  property color muted: "#8b949e"
  property color hoverAccent: "#88c0d0"
  property int buttonSize: 32
  property int iconSize: 18
  property int buttonRadius: 0
  property real hoverOpacity: 0.06
  property real pressOpacity: 0.11
  readonly property bool hovered: stateLayer.containsMouse
  readonly property color iconColor: hovered ? hoverAccent : muted

  implicitWidth: buttonSize
  implicitHeight: buttonSize
  width: implicitWidth
  height: implicitHeight
  radius: buttonRadius
  clip: true
  activeFocusOnTab: !disabled
  border.width: activeFocus ? 1 : 0
  border.color: activeFocus ? hoverAccent : "transparent"

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

  LacunaTablerIcon {
    id: iconShape

    visible: root.iconSource.length === 0 || themedIcon.status === Image.Error
    anchors.centerIn: parent
    name: root.shape
    color: root.iconColor
    iconSize: root.iconSize
  }

  IconImage {
    id: themedIcon

    anchors.centerIn: parent
    visible: root.iconSource.length > 0 && status !== Image.Error
    source: root.iconSource
    implicitSize: root.iconSize
    width: root.iconSize
    height: root.iconSize
  }

  LacunaStateLayer {
    id: stateLayer

    disabled: root.disabled
    stateColor: root.hoverAccent
    hoverOpacity: root.hoverOpacity
    pressOpacity: root.pressOpacity
    onTriggered: root.activate()
  }
}
