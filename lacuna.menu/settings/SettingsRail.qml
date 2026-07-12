import QtQuick
import "../components"

Column {
  id: root

  signal sectionSelected(string sectionId)

  property var sections: []
  property string currentSection: "overview"
  property bool compact: false
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property color background: "#101315"
  property var designTokens: null
  property bool showLabels: false

  width: showLabels ? (compact ? 122 : 140) : (compact ? 44 : 48)
  spacing: compact ? 5 : 6

  Repeater {
    model: root.sections

    LacunaRect {
      required property var modelData

      readonly property string sectionId: String(modelData.id || "")
      readonly property bool active: sectionId === root.currentSection
      readonly property color itemColor: active || layer.containsMouse ? root.accent : root.muted

      width: root.width
      height: root.compact ? 34 : 38
      radius: root.designTokens ? root.designTokens.controlRadius : 0
      color: active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, layer.reveal * 0.06)
      border.width: active && root.designTokens && !root.designTokens.lacuna ? 1 : 0
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
      clip: true
      activeFocusOnTab: true
      Accessible.role: Accessible.Button
      Accessible.name: String(modelData.label || sectionId)
      Accessible.selected: active
      Keys.onReturnPressed: root.sectionSelected(sectionId)
      Keys.onEnterPressed: root.sectionSelected(sectionId)
      Keys.onSpacePressed: root.sectionSelected(sectionId)

      LacunaRect {
        visible: active
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 12
        radius: 2
        color: root.accent
        opacity: root.designTokens && root.designTokens.lacuna ? 0.9 : 0.7
      }

      LacunaTablerIcon {
        x: root.showLabels ? 12 : Math.round((parent.width - width) / 2)
        anchors.verticalCenter: parent.verticalCenter
        name: modelData.icon
        color: itemColor
        iconSize: root.compact ? 15 : 17
      }

      LacunaText {
        visible: root.showLabels
        anchors.left: parent.left
        anchors.leftMargin: root.compact ? 34 : 38
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: modelData.label || ""
        color: itemColor
        fontFamily: "Hack Nerd Font Propo"
        font.pixelSize: root.compact ? 10 : 11
        font.weight: active ? Font.DemiBold : Font.Medium
        elide: Text.ElideRight
      }

      LacunaStateLayer {
        id: layer

        stateColor: root.accent
        hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
        pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
        onTriggered: root.sectionSelected(parent.sectionId)
      }
    }
  }
}
