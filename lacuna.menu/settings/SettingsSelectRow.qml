import QtQuick
import "../components"

Item {
  id: root

  signal selected(string value)

  property string icon: ""
  property string label: ""
  property string hint: ""
  property string currentValue: ""
  property string placeholder: "Select"
  property string tone: "shell"
  property var options: []
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color toneAccent: "#88c0d0"
  property string titleFontFamily: "Tektur"
  property string bodyFontFamily: "Hack Nerd Font"
  property var designTokens: null
  property bool expanded: false

  readonly property int rowHeight: compact ? 46 : 52
  readonly property int optionHeight: compact ? 28 : 31
  readonly property int maxVisibleOptions: 5
  readonly property int dropHeight: expanded ? Math.min(options.length, maxVisibleOptions) * optionHeight + 8 : 0
  readonly property int trailingWidth: compact ? 118 : 142

  function optionLabel(value) {
    for (var i = 0; i < options.length; i++) {
      if (String(options[i].value) === String(value)) return options[i].label || String(value)
    }
    return placeholder
  }

  width: parent ? parent.width : implicitWidth
  height: rowHeight + dropHeight
  clip: true

  LacunaRect {
    id: rowShell
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.rowHeight
    radius: root.designTokens ? root.designTokens.controlRadius : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025 + stateLayer.reveal * 0.03)
    border.width: root.expanded || (root.designTokens && root.designTokens.omarchy && stateLayer.containsMouse) ? 1 : 0
    border.color: root.expanded ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.38) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

    LacunaStateLayer {
      id: stateLayer
      stateColor: root.toneAccent
      hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
      pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
      showFill: false
      onTriggered: root.expanded = !root.expanded
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
          color: stateLayer.containsMouse || root.expanded ? root.toneAccent : root.muted
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

      LacunaRect {
        width: root.trailingWidth
        height: root.compact ? 26 : 28
        anchors.verticalCenter: parent.verticalCenter
        radius: root.designTokens ? root.designTokens.controlRadius : 0
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.045)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.13)
        clip: true

        LacunaText {
          anchors.left: parent.left
          anchors.right: chevron.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: 8
          anchors.rightMargin: 4
          text: root.optionLabel(root.currentValue)
          color: root.currentValue === "" ? root.muted : root.foreground
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
        }

        LacunaTablerIcon {
          id: chevron
          anchors.right: parent.right
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          name: root.expanded ? "chevron-up" : "chevron-down"
          color: root.toneAccent
          iconSize: root.compact ? 12 : 14
        }
      }
    }
  }

  LacunaRect {
    visible: root.expanded
    anchors.top: rowShell.bottom
    anchors.topMargin: 4
    anchors.left: parent.left
    anchors.right: parent.right
    height: Math.max(0, root.dropHeight - 4)
    radius: root.designTokens ? root.designTokens.controlRadius : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.035)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)
    clip: true

    ListView {
      anchors.fill: parent
      anchors.margins: 4
      clip: true
      model: root.options
      boundsBehavior: Flickable.StopAtBounds

      delegate: LacunaRect {
        required property var modelData

        width: ListView.view.width
        height: root.optionHeight
        radius: root.designTokens ? root.designTokens.controlRadius : 0
        color: String(modelData.value) === root.currentValue
          ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.18)
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, optionLayer.reveal * 0.04)
        opacity: modelData.enabled === false ? 0.42 : 1

        Row {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          spacing: 8

          Column {
            width: parent.width - check.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            LacunaText {
              width: parent.width
              text: modelData.label || modelData.value
              color: root.foreground
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
            }

            LacunaText {
              visible: modelData.description !== ""
              width: parent.width
              text: modelData.description || ""
              color: root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 8 : 9
            }
          }

          LacunaTablerIcon {
            id: check
            anchors.verticalCenter: parent.verticalCenter
            name: String(modelData.value) === root.currentValue ? "check" : "circle"
            color: String(modelData.value) === root.currentValue ? root.toneAccent : root.muted
            iconSize: root.compact ? 12 : 14
          }
        }

        LacunaStateLayer {
          id: optionLayer
          disabled: modelData.enabled === false
          stateColor: root.toneAccent
          hoverOpacity: root.designTokens ? root.designTokens.hoverOpacity : 0.06
          pressOpacity: root.designTokens ? root.designTokens.activeOpacity : 0.11
          onTriggered: {
            root.selected(String(modelData.value))
            root.expanded = false
          }
        }
      }
    }
  }
}
