import QtQuick

Item {
  id: root

  signal triggered()
  signal secondaryTriggered()
  signal scrolled(int delta)

  property string text: ""
  property string tooltip: ""
  property color accent: "#88c0d0"
  property color foreground: "#d8dee9"
  property color neutralForeground: "#d8dee9"
  property color background: "#101315"
  property color hoverColor: "#2a2f38"
  property bool active: false
  property bool activeExpanded: active
  property bool occupied: false
  property bool urgent: false
  property bool accentText: true
  property bool vertical: false
  property string designStyle: "lacuna"
  property int barSize: 26
  property bool compact: !vertical && barSize <= 26
  property int minButtonWidth: Math.max(compact ? 20 : 24, compact ? barSize - 2 : barSize)
  property int contentHorizontalPadding: compact ? 5 : 16
  property int labelPixelSize: barSize <= 26 ? 12 : 13
  property string fontFamily: "BlexMono Nerd Font Propo"
  property int labelFontWeight: Font.DemiBold
  property real hoverPulseAmount: 0
  property var tooltipHost: null
  property MotionTokens motionTokens: defaultMotionTokens

  MotionTokens {
    id: defaultMotionTokens
  }

  readonly property bool hovered: clickArea.containsMouse
  readonly property bool tooltipHovered: visible && opacity > 0 && clickArea.containsMouse
  readonly property real hoverRevealAmount: clickArea.reveal
  readonly property bool omarchyStyle: designStyle === "omarchy"
  readonly property bool materialStyle: designStyle === "material"
  readonly property real labelAnimatedScale: omarchyStyle ? 1 : 1 + hoverRevealAmount * ((materialStyle ? 0.035 : 0.18) + hoverPulseAmount * (materialStyle ? 0 : 0.045))
  readonly property real hoverGlowOpacity: omarchyStyle || materialStyle ? 0 : hoverRevealAmount * (0.34 + hoverPulseAmount * 0.22)
  readonly property real hoverHighlightOpacity: omarchyStyle ? 0 : hoverRevealAmount * (materialStyle ? 1 : 0.035)
  readonly property real labelOpacity: omarchyStyle && !active && !occupied ? 0.5 : materialStyle && !active && !occupied ? 0.88 : 1
  readonly property int materialCollapsedWidth: Math.max(compact ? 20 : 24, barSize - (compact ? 4 : 2))
  readonly property int materialExpandedWidth: Math.max(compact ? 28 : 34, barSize + (compact ? 2 : 8))
  readonly property int materialShapeWidth: activeExpanded || hovered ? materialExpandedWidth : materialCollapsedWidth
  readonly property int effectiveWidth: omarchyStyle && !vertical ? 22 : materialStyle && !vertical ? materialExpandedWidth : vertical ? barSize : Math.max(minButtonWidth, label.implicitWidth + contentHorizontalPadding)
  readonly property int materialInset: Math.max(5, Math.round(barSize * 0.28))
  readonly property int shapeHeight: materialStyle ? Math.max(14, barSize - materialInset * 2) : barSize
  readonly property int effectiveRadius: materialStyle ? Math.round(shapeHeight / 2) : 0
  readonly property color materialContainerColor: materialContainer()
  readonly property color materialOutlineColor: mix(background, accent, active || urgent ? 0.62 : 0.36)

  width: effectiveWidth
  height: barSize
  implicitWidth: width
  implicitHeight: height
  clip: true

  function showTooltip() {
    if (tooltipHost && tooltip !== "") tooltipHost.showTooltip(root, tooltip)
  }

  function hideTooltip() {
    if (tooltipHost) tooltipHost.hideTooltip(root)
  }

  function baseTextColor() {
    if (root.omarchyStyle) return root.foreground
    if (root.materialStyle && (root.active || root.urgent)) return root.neutralForeground
    return root.active || root.accentText ? root.accent : root.foreground
  }

  function mix(from, to, amount) {
    return Qt.rgba(
      from.r + (to.r - from.r) * amount,
      from.g + (to.g - from.g) * amount,
      from.b + (to.b - from.b) * amount,
      1
    )
  }

  function materialContainer() {
    if (!root.materialStyle) return root.accent
    if (root.urgent) return mix(root.background, root.accent, 0.52)
    if (root.active) return mix(root.background, root.accent, 0.38)
    if (root.occupied) return mix(root.background, root.accent, 0.16)
    if (root.hovered) return root.hoverColor
    return "transparent"
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    width: root.materialStyle ? root.materialShapeWidth : parent.width
    height: root.shapeHeight
    color: root.materialStyle ? root.materialContainerColor : root.accent
    radius: root.effectiveRadius
    opacity: root.omarchyStyle ? 0 : root.materialStyle ? (root.active || root.occupied || root.urgent || root.hovered ? 1 : 0) : root.hoverHighlightOpacity

    Behavior on color {
      ColorAnimation {
        duration: root.motionTokens.colorDuration
        easing.type: Easing.OutCubic
      }
    }

    Behavior on width {
      enabled: root.materialStyle
      NumberAnimation {
        duration: root.motionTokens.animationNormal
        easing.type: Easing.OutCubic
      }
    }
  }

  Rectangle {
    visible: root.materialStyle && (root.active || root.occupied || root.urgent)
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    width: root.materialShapeWidth
    height: root.shapeHeight
    radius: root.effectiveRadius
    color: "transparent"
    border.width: 1
    border.color: root.materialOutlineColor

    Behavior on width {
      NumberAnimation {
        duration: root.motionTokens.animationNormal
        easing.type: Easing.OutCubic
      }
    }
  }

  Rectangle {
    visible: root.materialStyle && root.hovered && (root.active || root.occupied || root.urgent)
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    width: root.materialShapeWidth
    height: root.shapeHeight
    radius: root.effectiveRadius
    color: root.hoverColor
    opacity: root.active || root.urgent ? 0.46 : 0.64

    Behavior on width {
      NumberAnimation {
        duration: root.motionTokens.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: root.motionTokens.animationFast
        easing.type: Easing.OutCubic
      }
    }
  }

  Text {
    id: label

    anchors.centerIn: parent
    z: 2
    text: root.text
    color: root.baseTextColor()
    opacity: root.labelOpacity
    font.family: root.fontFamily
    font.pixelSize: root.labelPixelSize
    font.weight: root.labelFontWeight
    scale: root.labelAnimatedScale
    transformOrigin: Item.Center
    maximumLineCount: 1
  }

  Text {
    anchors.centerIn: label
    anchors.horizontalCenterOffset: -1
    z: 1
    text: label.text
    color: root.accent
    opacity: root.hoverGlowOpacity
    font.family: label.font.family
    font.pixelSize: label.font.pixelSize
    font.weight: label.font.weight
    scale: root.labelAnimatedScale + 0.08
    transformOrigin: Item.Center
    maximumLineCount: 1
  }

  Text {
    anchors.centerIn: label
    anchors.horizontalCenterOffset: 1
    z: 1
    text: label.text
    color: root.accent
    opacity: root.hoverGlowOpacity
    font.family: label.font.family
    font.pixelSize: label.font.pixelSize
    font.weight: label.font.weight
    scale: root.labelAnimatedScale + 0.08
    transformOrigin: Item.Center
    maximumLineCount: 1
  }

  Text {
    anchors.centerIn: label
    anchors.verticalCenterOffset: -1
    z: 1
    text: label.text
    color: root.accent
    opacity: root.hoverGlowOpacity
    font.family: label.font.family
    font.pixelSize: label.font.pixelSize
    font.weight: label.font.weight
    scale: root.labelAnimatedScale + 0.08
    transformOrigin: Item.Center
    maximumLineCount: 1
  }

  Text {
    anchors.centerIn: label
    anchors.verticalCenterOffset: 1
    z: 1
    text: label.text
    color: root.accent
    opacity: root.hoverGlowOpacity
    font.family: label.font.family
    font.pixelSize: label.font.pixelSize
    font.weight: label.font.weight
    scale: root.labelAnimatedScale + 0.08
    transformOrigin: Item.Center
    maximumLineCount: 1
  }

  LacunaStateLayer {
    id: clickArea

    stateColor: root.accent
    showFill: false
    onContainsMouseChanged: {
      if (containsMouse) root.showTooltip()
      else root.hideTooltip()
    }
    onTriggered: root.triggered()
    onSecondaryClicked: root.secondaryTriggered()
    onScrolled: function(delta) {
      root.scrolled(delta)
    }
  }

  SequentialAnimation {
    running: root.hovered && !root.omarchyStyle
    loops: Animation.Infinite

    NumberAnimation {
      target: root
      property: "hoverPulseAmount"
      from: 0
      to: 1
      duration: root.motionTokens.pulseDuration
      easing.type: Easing.InOutSine
    }

    NumberAnimation {
      target: root
      property: "hoverPulseAmount"
      from: 1
      to: 0
      duration: root.motionTokens.pulseDuration
      easing.type: Easing.InOutSine
    }
  }
}
