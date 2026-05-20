import QtQuick
import "../components"

LacunaRect {
  id: root

  signal triggered()
  signal optionSelected(string value)

  property string icon: ""
  property string label: ""
  property string hint: ""
  property string value: ""
  property string tone: "lacuna"
  property string control: "nav"
  property bool checked: false
  property var options: []
  property string optionValue: ""
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property color toneAccent: accent
  property string titleFontFamily: "Tektur"
  property string bodyFontFamily: "JetBrains Mono"
  property var designTokens: null

  readonly property bool hasHint: hint !== ""
  readonly property bool hasValue: value !== ""
  readonly property int rowHeight: compact ? 44 : 50
  readonly property int trailingWidth: control === "segments" ? Math.min(170, Math.max(92, options.length * (compact ? 48 : 56))) : control === "toggle" ? 38 : control === "button" ? 68 : hasValue ? 86 : 18

  width: parent ? parent.width : implicitWidth
  height: rowHeight
  radius: designTokens ? designTokens.controlRadius : 0
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.025 + stateLayer.reveal * 0.03)
  border.width: designTokens && designTokens.omarchy && stateLayer.containsMouse ? 1 : 0
  border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
  clip: true

  LacunaStateLayer {
    id: stateLayer

    disabled: root.control === "value" || root.control === "segments"
    stateColor: root.toneAccent
    hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
    pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
    showFill: false
    onTriggered: root.triggered()
  }

  LacunaRect {
    visible: designTokens && designTokens.accentStrips
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 3
    color: root.toneAccent
    opacity: root.checked ? 0.78 : 0.22 + stateLayer.reveal * 0.56
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
        color: stateLayer.containsMouse ? root.toneAccent : root.muted
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
        visible: root.hasHint
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

      LacunaText {
        visible: root.control === "value" || (root.control === "nav" && root.hasValue)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        text: root.value
        color: stateLayer.containsMouse ? root.toneAccent : root.muted
        fontFamily: root.bodyFontFamily
        font.pixelSize: root.compact ? 9 : 10
        horizontalAlignment: Text.AlignRight
      }

      LacunaTablerIcon {
        visible: root.control === "nav" && !root.hasValue
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron-right"
        color: stateLayer.containsMouse ? root.toneAccent : root.muted
        iconSize: root.compact ? 12 : 14
      }

      LacunaRect {
        visible: root.control === "toggle"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.compact ? 30 : 34
        height: root.compact ? 16 : 18
        radius: height / 2
        color: root.checked ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.85) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
        border.width: 1
        border.color: root.checked ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.9) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.20)

        LacunaRect {
          width: root.compact ? 10 : 12
          height: width
          radius: height / 2
          anchors.verticalCenter: parent.verticalCenter
          x: root.checked ? parent.width - width - 3 : 3
          color: root.checked ? root.background : root.muted

          Behavior on x {
            LacunaAnim { motion: "fast" }
          }
        }
      }

      LacunaRect {
        visible: root.control === "button"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.compact ? 24 : 26
        radius: root.designTokens ? root.designTokens.controlRadius : 0
        color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.10 + stateLayer.reveal * 0.10)
        border.width: root.designTokens && root.designTokens.carbon ? 0 : 1
        border.color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.30)

        LacunaText {
          anchors.centerIn: parent
          width: parent.width - 10
          text: root.value === "" ? "Open" : root.value
          color: root.toneAccent
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Row {
        visible: root.control === "segments"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.compact ? 24 : 26
        spacing: 2

        Repeater {
          model: root.options

          LacunaRect {
            required property var modelData

            readonly property bool selected: String(modelData.value) === root.optionValue
            width: Math.max(24, (parent.width - Math.max(0, root.options.length - 1) * parent.spacing) / Math.max(1, root.options.length))
            height: parent.height
            radius: root.designTokens ? root.designTokens.controlRadius : 0
            color: selected ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04 + segmentLayer.reveal * 0.04)
            border.width: selected || (root.designTokens && !root.designTokens.carbon) ? 1 : 0
            border.color: selected ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.46) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
            clip: true

            LacunaText {
              anchors.centerIn: parent
              width: parent.width - 8
              text: modelData.label
              color: selected ? root.foreground : root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 8 : 9
              horizontalAlignment: Text.AlignHCenter
            }

            LacunaStateLayer {
              id: segmentLayer

              stateColor: root.toneAccent
              hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
              pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
              onTriggered: root.optionSelected(String(modelData.value))
            }
          }
        }
      }
    }
  }

}
