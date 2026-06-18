import QtQuick
import QtQuick.Effects
import "../components"
import "../services"

Item {
  id: root

  signal backRequested()
  signal collapseRequested()
  signal closeRequested()

  property string title: "Lacuna Menu"
  property string version: ""
  property string subtitle: "Quickshell / control aperture"
  property bool canGoBack: false
  property bool canCollapse: true
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property color danger: "#bf616a"
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property bool compact: false
  property var designTokens: fallbackDesignTokens
  readonly property bool hasSubtitle: subtitle !== ""
  readonly property bool hasVersion: version !== ""
  readonly property int controlSize: compact ? 24 : tokens.controlSmall
  readonly property int backButtonWidth: canGoBack ? controlSize : 0
  property real gapBreath: 0

  width: parent ? parent.width : implicitWidth
  height: (compact ? 30 : 36) + (designTokens.material ? 2 : 0)

  FontLoader {
    id: headingFont

    source: "../assets/fonts/Tektur-SemiBold.ttf"
  }

  LacunaIconButton {
    id: backButton

    visible: root.canGoBack
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.topMargin: root.compact ? 2 : 3
    width: root.backButtonWidth
    icon: "arrow-left"
    foreground: root.foreground
    muted: root.muted
    accent: root.accent
    hoverAccent: root.accent
    fontFamily: root.bodyFontFamily
    buttonSize: root.controlSize
    buttonRadius: root.designTokens.controlRadius
    hoverOpacity: root.designTokens.hoverOpacity
    pressOpacity: root.designTokens.activeOpacity
    iconSize: root.compact ? 13 : 15
    disabled: !visible
    onTriggered: root.backRequested()
  }

  // Slim wordmark: the contextual title as a wide-tracked wordmark, with the
  // version as a faint monospace tag trailing it. No glyph (the top-bar menu
  // button already carries the mark).
  LacunaText {
    id: wordmark

    anchors.left: root.canGoBack ? backButton.right : parent.left
    anchors.leftMargin: root.canGoBack ? tokens.spaceSmall : 0
    anchors.right: versionTag.left
    anchors.rightMargin: tokens.spaceNormal
    anchors.verticalCenter: backButton.verticalCenter
    text: root.title.toUpperCase()
    color: root.foreground
    fontFamily: headingFont.name !== "" ? headingFont.name : "Tektur"
    font.pixelSize: root.compact ? 13 : tokens.textTitle
    font.weight: Font.DemiBold
    font.letterSpacing: root.compact ? 1.4 : 2.0
  }

  LacunaText {
    id: versionTag

    visible: root.hasVersion
    anchors.right: headerControls.left
    anchors.rightMargin: tokens.spaceSmall
    anchors.baseline: wordmark.baseline
    text: root.version
    color: root.muted
    fontFamily: root.bodyFontFamily
    font.pixelSize: root.compact ? 8 : 9
    font.weight: Font.DemiBold
  }

  Row {
    id: headerControls

    anchors.right: parent.right
    anchors.top: parent.top
    width: collapseButton.width
    height: root.controlSize

    MenuRailButton {
      id: collapseButton

      visible: root.canCollapse
      width: visible ? implicitWidth : 0
      shape: "sidebar-collapse"
      muted: root.muted
      hoverAccent: root.accent
      buttonSize: root.controlSize
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 15 : 17
      onTriggered: root.collapseRequested()
    }
  }

  // Notched header rule (the lacuna mark, matching the section seams) with a
  // soft accent glow at the gap that slowly breathes — the signature motion.
  Item {
    id: headerRule

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1

    readonly property real ruleOpacity: root.designTokens.headerTreatment === "body-border" ? 0.12 : root.designTokens.headerTreatment === "tonal" ? 0.18 : 0.24
    readonly property int gap: root.designTokens.gappedDividers ? root.designTokens.dividerGap : 0

    LacunaRect {
      anchors.left: parent.left
      height: 1
      width: parent.gap > 0 ? (parent.width - parent.gap) / 2 : parent.width
      color: root.accent
      opacity: parent.ruleOpacity
    }

    LacunaRect {
      visible: parent.gap > 0
      anchors.right: parent.right
      height: 1
      width: (parent.width - parent.gap) / 2
      color: root.accent
      opacity: parent.ruleOpacity
    }

    // "The gap breathes": a layered glow centered in the gap, fading in/out.
    Item {
      visible: parent.gap > 0 && root.designTokens.decorativeLinework
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: Math.round(parent.width * 0.6)
      height: 8

      LacunaRect {
        anchors.centerIn: parent
        width: parent.width
        height: 5
        radius: 2.5
        color: root.accent
        opacity: 0.03 + root.gapBreath * 0.2
      }

      LacunaRect {
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.45)
        height: 3
        radius: 1.5
        color: root.accent
        opacity: 0.1 + root.gapBreath * 0.34
      }

      LacunaRect {
        anchors.centerIn: parent
        width: Math.max(6, Math.round(parent.width * 0.16))
        height: 2
        radius: 1
        color: root.accent
        opacity: 0.28 + root.gapBreath * 0.62
      }
    }
  }

  // Drive the breathing glow from a Timer. The declarative SequentialAnimation
  // would not run in this context; a Timer reliably does. gapBreath oscillates
  // 0..1 on a ~3.9s sine.
  Timer {
    running: root.designTokens.decorativeLinework && root.visible
    interval: 50
    repeat: true
    onTriggered: root.gapBreath = 0.5 + 0.5 * Math.sin(Date.now() / 620)
  }

  LacunaTokens {
    id: tokens
  }

  DesignTokens {
    id: fallbackDesignTokens
    designStyle: "lacuna"
    compact: root.compact
    foreground: root.foreground
    accent: root.accent
  }
}
