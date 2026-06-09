import QtQuick
import Quickshell.Widgets
import "../components"

LacunaRect {
  id: root

  signal triggered()

  property string shape: "apps"
  property string iconSource: ""
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

    stateColor: root.hoverAccent
    hoverOpacity: root.hoverOpacity
    pressOpacity: root.pressOpacity
    onTriggered: root.triggered()
  }
}
