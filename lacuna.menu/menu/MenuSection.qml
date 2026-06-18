import QtQuick
import "../components"

Item {
  id: root

  signal toggled()
  signal optionSelected(string value)
  signal actionTriggered()

  property string title: ""
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property bool band: false
  property bool collapsible: true
  property bool collapsed: false
  property int count: 0
  property var options: []
  property string optionValue: ""
  property string actionIcon: ""
  property string actionTooltip: ""
  property string fontFamily: "Hack Nerd Font Propo"
  property bool compact: false
  property var designTokens: null
  property real hoverOpacity: 0.06
  property real pressOpacity: 0.11

  width: parent ? parent.width : implicitWidth
  height: compact ? (band ? 28 : 24) : (band ? 34 : 30)
  clip: true

  LacunaStateLayer {
    id: stateLayer

    disabled: !root.collapsible
    stateColor: root.accent
    hoverOpacity: root.hoverOpacity
    pressOpacity: root.pressOpacity
    onTriggered: root.toggled()
  }

  LacunaRect {
    visible: root.band
    anchors.fill: parent
    color: root.accent
    opacity: 0.035 + stateLayer.reveal * 0.035
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

  // Section seam: a hairline along the header baseline, broken by a centered
  // gap — the repeating lacuna mark that carries the identity. Lacuna only.
  Item {
    visible: root.designTokens && root.designTokens.lacuna
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1

    readonly property int gap: root.designTokens ? root.designTokens.dividerGap : 0

    LacunaRect {
      anchors.left: parent.left
      height: 1
      width: parent.gap > 0 ? (parent.width - parent.gap) / 2 : parent.width
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
    }

    LacunaRect {
      visible: parent.gap > 0
      anchors.right: parent.right
      height: 1
      width: (parent.width - parent.gap) / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
    }
  }

  LacunaText {
    id: label

    anchors.left: parent.left
    anchors.leftMargin: root.compact ? (root.band ? 28 : 20) : (root.band ? 34 : 26)
    anchors.right: controlRow.visible ? controlRow.left : parent.right
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

  Row {
    id: controlRow

    // Derive visibility from the section's own source properties, NOT from the
    // children's `.visible`. In Qt Quick a child's `visible` reports *effective*
    // visibility (it already factors in this Row's visibility), so referencing
    // it here forms a feedback loop — `controlRow.visible = controlRow.visible &&
    // (...)`, for which `false` is a stable solution. That latched the whole
    // control cluster (count pill, grid/list toggles, action button, chevron)
    // invisible on open until a model rebuild happened to settle it true, which
    // is why clicking a toggle made them all suddenly appear.
    visible: (root.options && root.options.length > 0) || root.actionIcon !== "" || root.collapsible
    anchors.right: parent.right
    anchors.rightMargin: 4
    anchors.verticalCenter: label.verticalCenter
    width: implicitWidth
    height: root.compact ? 18 : 20
    spacing: 6

    Row {
      id: optionRow

      visible: root.options.length > 0
      y: (controlRow.height - height) / 2
      width: root.options.length * height + Math.max(0, root.options.length - 1) * spacing
      height: parent.height
      spacing: 2

      Repeater {
        model: root.options

        LacunaRect {
          required property var modelData

          readonly property bool selected: String(modelData.value) === root.optionValue
          width: optionRow.height
          height: optionRow.height
          radius: root.designTokens && root.designTokens.material ? height / 2 : (root.designTokens ? root.designTokens.controlRadius : 0)
          color: selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20) : "transparent"
          border.width: selected && root.designTokens && !root.designTokens.lacuna ? 1 : 0
          border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.34)

          LacunaTablerIcon {
            anchors.centerIn: parent
            name: modelData.icon || ""
            color: parent.selected ? root.foreground : root.muted
            iconSize: root.compact ? 11 : 12
          }

          LacunaStateLayer {
            anchors.fill: parent
            stateColor: root.accent
            hoverOpacity: root.hoverOpacity
            pressOpacity: root.pressOpacity
            onTriggered: root.optionSelected(String(parent.modelData.value || ""))
          }
        }
      }
    }

    LacunaIconButton {
      id: actionButton

      visible: root.actionIcon !== ""
      y: (controlRow.height - height) / 2
      icon: root.actionIcon
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: parent.height
      iconSize: root.compact ? 11 : 12
      buttonRadius: root.designTokens && root.designTokens.material ? height / 2 : (root.designTokens ? root.designTokens.controlRadius : 0)
      hoverOpacity: root.hoverOpacity
      pressOpacity: root.pressOpacity
      fontFamily: root.fontFamily
      onTriggered: root.actionTriggered()
    }

    LacunaTablerIcon {
      id: chevron

      visible: root.collapsible
      y: (controlRow.height - height) / 2
      name: "chevron-right"
      color: stateLayer.containsMouse ? root.accent : root.muted
      iconSize: root.compact ? 11 : 13
      rotation: root.collapsed ? 0 : 90

      Behavior on rotation {
        LacunaAnim { motion: "fast" }
      }
    }
  }
}
