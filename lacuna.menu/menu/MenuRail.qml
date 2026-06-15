import QtQuick
import Quickshell
import "../components"
import "../services"

Column {
  id: root

  signal activated(var entry)
  signal expandRequested()
  signal settingsRequested()
  signal shellSettingsRequested()

  required property var menuState
  required property var registry
  property bool compact: false
  property bool open: true
  property color foreground: "#d8dee9"
  property color accent: "#88c0d0"
  property color shellAccent: "#88c0d0"
  property color sessionAccent: "#ebcb8b"
  property color dangerAccent: "#bf616a"
  property color navAccent: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color panelColor: "#101315"
  property string bodyFontFamily: "JetBrains Mono"
  property int railWidth: 32
  property var panelWindow: null
  property var tooltipTarget: null
  property string tooltipText: ""
  property color tooltipAccent: accent
  property int tooltipX: 0
  property int tooltipY: 0
  property int tooltipWidth: 118
  property int tooltipHeight: 30
  property bool tooltipVisible: false
  property var designTokens: fallbackDesignTokens

  function toneAccent(tone) {
    if (tone === "danger") return root.dangerAccent
    return root.accent
  }

  function railItems() {
    return root.registry.railItems()
  }

  function iconShape(entry) {
    if (entry && entry.icon) return entry.icon
    if (!entry || !entry.label) return "apps"
    if (entry.label === "Lacuna") return "lacuna"
    if (entry.label === "Customize") return "palette"
    if (entry.label === "System") return "system"
    if (entry.label === "Terminal") return "terminal"
    if (entry.label === "Browser") return "world"
    return "apps"
  }

  function showTooltip(item, entry) {
    if (!item || !entry || !entry.label) return
    showTooltipText(item, entry.label, toneAccent(entry.tone))
  }

  function showTooltipText(item, text, accentColor) {
    if (!item || !text) return

    tooltipTarget = item
    tooltipText = text
    tooltipAccent = accentColor || root.accent
    tooltipWidth = Math.max(82, Math.min(154, text.length * 9 + 30))
    positionTooltip()
    tooltipVisible = true
  }

  function itemAccent(entry) {
    return root.toneAccent(entry ? entry.tone : "")
  }

  function hideTooltip(item) {
    if (item && tooltipTarget !== item) return
    tooltipVisible = false
    tooltipTarget = null
    tooltipText = ""
  }

  function positionTooltip() {
    if (!panelWindow || !tooltipTarget) return

    var point = panelWindow.mapFromItem(tooltipTarget, tooltipTarget.width, tooltipTarget.height / 2)
    tooltipX = Math.round(point.x + 8)
    tooltipY = Math.round(Math.max(8, Math.min(point.y - tooltipHeight / 2, panelWindow.height - tooltipHeight - 8)))
  }

  spacing: designTokens.railSpacing
  opacity: open ? 1 : 0

  Behavior on opacity {
    LacunaAnim { motion: "normal" }
  }

  Repeater {
    model: root.railItems()

    MenuRailButton {
      shape: root.iconShape(modelData)
      iconSource: modelData.iconSource || ""
      muted: root.muted
      hoverAccent: root.itemAccent(modelData)
      buttonSize: root.railWidth
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 16 : 18
      onHoveredChanged: if (hovered) root.showTooltip(this, modelData)
                      else root.hideTooltip(this)
      onTriggered: root.activated(modelData)
    }
  }

  Item {
    width: root.railWidth
    height: Math.max(0, root.height - y - expandButton.height - settingsDivider.height - shellSettingsButton.height - settingsButton.height - root.spacing * 4)
  }

  MenuRailButton {
    id: expandButton

    shape: "sidebar-expand"
    muted: root.muted
    hoverAccent: root.accent
    buttonSize: root.railWidth
    buttonRadius: root.designTokens.controlRadius
    hoverOpacity: root.designTokens.hoverOpacity
    pressOpacity: root.designTokens.activeOpacity
    iconSize: root.compact ? 16 : 18
    onHoveredChanged: if (hovered) root.showTooltipText(this, "Expand sidebar", root.accent)
                    else root.hideTooltip(this)
    onTriggered: root.expandRequested()
  }

  LacunaRect {
    id: settingsDivider

    width: root.railWidth
    height: 1
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
  }

  MenuRailButton {
    id: shellSettingsButton

    shape: "settings"
    muted: root.muted
    hoverAccent: root.accent
    buttonSize: root.railWidth
    buttonRadius: root.designTokens.controlRadius
    hoverOpacity: root.designTokens.hoverOpacity
    pressOpacity: root.designTokens.activeOpacity
    iconSize: root.compact ? 20 : 22
    onHoveredChanged: if (hovered) root.showTooltipText(this, "Omarchy Shell Settings", root.accent)
                    else root.hideTooltip(this)
    onTriggered: root.shellSettingsRequested()
  }

  MenuRailButton {
    id: settingsButton

    shape: "gear"
    muted: root.muted
    hoverAccent: root.accent
    buttonSize: root.railWidth
    buttonRadius: root.designTokens.controlRadius
    hoverOpacity: root.designTokens.hoverOpacity
    pressOpacity: root.designTokens.activeOpacity
    iconSize: root.compact ? 20 : 22
    onHoveredChanged: if (hovered) root.showTooltipText(this, "Lacuna Settings", root.accent)
                    else root.hideTooltip(this)
    onTriggered: root.settingsRequested()
  }

  PopupWindow {
    anchor {
      window: root.panelWindow
      rect {
        x: root.tooltipX
        y: root.tooltipY
        width: root.tooltipWidth
        height: root.tooltipHeight
      }
    }

    visible: root.tooltipVisible && root.tooltipText !== ""
    color: "transparent"
    grabFocus: false
    implicitWidth: root.tooltipWidth
    implicitHeight: root.tooltipHeight

    LacunaRect {
      anchors.fill: parent
      color: root.panelColor
      opacity: 1
      radius: root.designTokens.tooltipTreatment === "tonal" ? root.designTokens.radius : 0
      border.width: root.designTokens.tooltipTreatment === "accent-strip" ? 1 : root.designTokens.borderWidth
      border.color: root.designTokens.tooltipTreatment === "bordered" ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.tooltipAccent.r, root.tooltipAccent.g, root.tooltipAccent.b, 0.24)

      LacunaRect {
        visible: root.designTokens.tooltipTreatment === "accent-strip"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.tooltipAccent
        opacity: 0.82
      }

      LacunaText {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.tooltipText
        color: root.foreground
        fontFamily: root.bodyFontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
      }
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    designStyle: "lacuna"
    compact: root.compact
    foreground: root.foreground
    background: root.panelColor
    accent: root.accent
  }
}
