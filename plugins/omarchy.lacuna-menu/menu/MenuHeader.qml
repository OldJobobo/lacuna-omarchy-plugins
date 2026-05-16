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
  property string bodyFontFamily: "JetBrains Mono"
  property bool compact: false
  property var designTokens: fallbackDesignTokens
  readonly property bool hasSubtitle: subtitle !== ""
  readonly property bool hasVersion: version !== ""
  readonly property int controlSize: compact ? 24 : tokens.controlSmall
  readonly property int backButtonWidth: canGoBack ? controlSize : 0

  width: parent ? parent.width : implicitWidth
  height: compact ? (hasSubtitle || hasVersion ? 50 : 36) : (hasSubtitle || hasVersion ? 62 : 46) + (designTokens.material ? 2 : 0)

  FontLoader {
    id: headingFont

    source: "../assets/fonts/Tektur-SemiBold.ttf"
  }

  Item {
    id: headerGlyph

    anchors.left: backButton.right
    anchors.leftMargin: root.canGoBack ? tokens.spaceSmall : 0
    anchors.top: parent.top
    anchors.topMargin: 2
    width: root.controlSize
    height: root.controlSize

    Image {
      anchors.centerIn: parent
      width: root.compact ? 18 : 20
      height: width
      source: Qt.resolvedUrl("../assets/tabler/circle-dotted-letter-l.svg")
      sourceSize.width: width
      sourceSize.height: height
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      layer.enabled: true
      layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: root.accent
      }
    }
  }

  LacunaIconButton {
    id: backButton

    visible: root.canGoBack
    anchors.left: parent.left
    anchors.top: headerGlyph.top
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

  Column {
    anchors.left: headerGlyph.right
    anchors.leftMargin: root.compact ? tokens.spaceSmall : tokens.spaceNormal
    anchors.right: headerControls.left
    anchors.rightMargin: tokens.spaceLarge
    anchors.verticalCenter: headerGlyph.verticalCenter
    spacing: root.hasSubtitle ? tokens.spaceTiny : 0

    LacunaText {
      width: parent.width
      text: root.title
      color: root.foreground
      fontFamily: headingFont.name !== "" ? headingFont.name : "Tektur"
      font.pixelSize: root.compact ? 14 : tokens.textTitle
      font.weight: Font.DemiBold
      font.letterSpacing: root.compact ? 0.6 : 0.9
    }

    LacunaText {
      visible: root.hasSubtitle
      width: parent.width
      text: root.subtitle
      color: root.muted
      fontFamily: root.bodyFontFamily
      font.pixelSize: root.compact ? 8 : tokens.textHint
    }
  }

  LacunaText {
    visible: root.hasVersion
    anchors.right: parent.right
    anchors.rightMargin: 2
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.compact ? 7 : 9
    text: root.version
    color: root.muted
    fontFamily: root.bodyFontFamily
    font.pixelSize: root.compact ? 9 : 10
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

  LacunaRect {
    anchors.left: headerGlyph.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: root.accent
    opacity: root.designTokens.headerTreatment === "body-border" ? 0.12 : root.designTokens.headerTreatment === "tonal" ? 0.18 : 0.24
  }

  LacunaRect {
    visible: root.designTokens.decorativeLinework
    anchors.left: headerGlyph.left
    anchors.bottom: parent.bottom
    width: root.compact ? 26 : 34
    height: 2
    color: root.accent
    opacity: 0.75
  }

  LacunaTokens {
    id: tokens
  }

  DesignTokens {
    id: fallbackDesignTokens
    designStyle: "carbon"
    compact: root.compact
    foreground: root.foreground
    accent: root.accent
  }
}
