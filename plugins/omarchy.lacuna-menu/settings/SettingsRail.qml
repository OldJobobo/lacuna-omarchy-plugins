import QtQuick
import "../components"

Column {
  id: root

  signal sectionSelected(string section)

  property var sections: []
  property string currentSection: "overview"
  property bool compact: false
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property color background: "#101315"
  property var designTokens: null

  width: compact ? 44 : 48
  spacing: compact ? 5 : 6

  Repeater {
    model: root.sections

    LacunaRect {
      required property var modelData

      readonly property bool active: modelData.id === root.currentSection
      readonly property color itemColor: active || layer.containsMouse ? root.accent : root.muted

      width: root.width
      height: root.compact ? 34 : 38
      radius: root.designTokens ? root.designTokens.controlRadius : 0
      color: active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, layer.reveal * 0.06)
      border.width: active && root.designTokens && !root.designTokens.carbon ? 1 : 0
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
      clip: true

      LacunaRect {
        visible: active
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 12
        radius: 2
        color: root.accent
        opacity: root.designTokens && root.designTokens.carbon ? 0.9 : 0.7
      }

      LacunaTablerIcon {
        anchors.centerIn: parent
        name: modelData.icon
        color: itemColor
        iconSize: root.compact ? 15 : 17
      }

      LacunaStateLayer {
        id: layer

        stateColor: root.accent
        hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
        pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
        onTriggered: root.sectionSelected(modelData.id)
      }
    }
  }
}
