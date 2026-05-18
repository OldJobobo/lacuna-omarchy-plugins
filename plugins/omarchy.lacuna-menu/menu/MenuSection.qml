import QtQuick
import "../components"

Item {
  id: root

  signal toggled()

  property string title: ""
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property bool band: false
  property bool collapsible: true
  property bool collapsed: false
  property int count: 0
  property string fontFamily: "JetBrains Mono"
  property bool compact: false
  property var designTokens: null
  property real hoverOpacity: 0.06
  property real pressOpacity: 0.11

  width: parent ? parent.width : implicitWidth
  height: compact ? (band ? 28 : 24) : (band ? 34 : 30)
  clip: true

  LacunaRect {
    visible: root.band
    anchors.fill: parent
    color: root.accent
    opacity: 0.035 + (stateLayer.containsMouse ? 0.035 : 0)
  }

  LacunaRect {
    anchors.left: parent.left
    anchors.leftMargin: 2
    anchors.verticalCenter: label.verticalCenter
    width: root.compact ? (root.band ? 20 : 12) : (root.band ? 24 : 16)
    height: 1
    color: root.accent
    opacity: root.band ? 0.78 : 0.6
  }

  LacunaText {
    id: label

    anchors.left: parent.left
    anchors.leftMargin: root.compact ? (root.band ? 28 : 20) : (root.band ? 34 : 26)
    anchors.right: countPill.visible ? countPill.left : chevron.left
    anchors.rightMargin: 8
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.compact ? (root.band ? 7 : 4) : (root.band ? 9 : 5)
    text: root.title.toUpperCase()
    color: stateLayer.containsMouse || root.band ? root.foreground : root.muted
    fontFamily: root.fontFamily
    font.pixelSize: root.compact ? 8 : 9
    font.weight: Font.DemiBold
    font.letterSpacing: 0
  }

  LacunaRect {
    id: countPill

    visible: root.count > 0
    anchors.right: chevron.left
    anchors.rightMargin: 6
    anchors.verticalCenter: label.verticalCenter
    width: Math.max(root.compact ? 18 : 20, countText.implicitWidth + 10)
    height: root.compact ? 14 : 16
    radius: root.designTokens && root.designTokens.material ? height / 2 : (root.designTokens ? root.designTokens.controlRadius : 0)
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.collapsed ? 0.16 : 0.10)
    border.width: 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, stateLayer.containsMouse ? 0.38 : 0.24)

    LacunaText {
      id: countText

      anchors.centerIn: parent
      text: String(root.count)
      color: stateLayer.containsMouse ? root.foreground : root.muted
      fontFamily: root.fontFamily
      font.pixelSize: root.compact ? 8 : 9
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
    }
  }

  LacunaTablerIcon {
    id: chevron

    visible: root.collapsible
    anchors.right: parent.right
    anchors.rightMargin: 4
    anchors.verticalCenter: label.verticalCenter
    name: "chevron-right"
    color: stateLayer.containsMouse ? root.accent : root.muted
    iconSize: root.compact ? 11 : 13
    rotation: root.collapsed ? 0 : 90

    Behavior on rotation {
      LacunaAnim { motion: "fast" }
    }
  }

  LacunaStateLayer {
    id: stateLayer

    disabled: !root.collapsible
    stateColor: root.accent
    hoverOpacity: root.hoverOpacity
    pressOpacity: root.pressOpacity
    onTriggered: root.toggled()
  }
}
