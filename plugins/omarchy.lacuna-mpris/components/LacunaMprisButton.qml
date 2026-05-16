import QtQuick
import QtQuick.Shapes

Item {
  id: root

  signal triggered()
  signal secondaryTriggered()
  signal scrolled(int delta)

  property string text: ""
  property string iconName: ""
  property string tooltip: ""
  property color accent: "#88c0d0"
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property bool active: false
  property bool showActiveState: false
  property bool compact: false
  property bool accentText: true
  property bool sweepActive: false
  property color sweepColor: background
  property real sweepPosition: -0.35
  property int barSize: 26
  property int minButtonWidth: Math.max(32, barSize)
  property int contentHorizontalPadding: compact ? 8 : 16
  property int labelPixelSize: compact ? 11 : 12
  property int iconSize: compact ? 12 : 13
  property string fontFamily: "JetBrains Mono"
  property int labelFontWeight: active ? Font.DemiBold : Font.Normal
  property real hoverPulseAmount: 0
  property real hoverRevealAmount: 0
  property var tooltipHost: null

  readonly property bool hovered: clickArea.containsMouse
  readonly property real labelAnimatedScale: 1 + hoverRevealAmount * (0.08 + hoverPulseAmount * 0.025)
  readonly property real hoverGlowOpacity: sweepActive ? 0 : hoverRevealAmount * (0.28 + hoverPulseAmount * 0.18)
  readonly property real hoverHighlightOpacity: sweepActive ? 0 : hoverRevealAmount * 0.035

  width: Math.max(minButtonWidth, content.implicitWidth + contentHorizontalPadding)
  height: barSize
  implicitWidth: width
  implicitHeight: height
  clip: true

  Behavior on hoverRevealAmount {
    LacunaAnim { motion: "normal" }
  }

  function showTooltip() {
    if (tooltipHost && tooltip !== "") tooltipHost.showTooltip(root, tooltip)
  }

  function hideTooltip() {
    if (tooltipHost) tooltipHost.hideTooltip(root)
  }

  function baseTextColor() {
    return root.active || root.accentText ? root.accent : root.foreground
  }

  function iconPath(icon) {
    if (icon === "player-play") return "M7 4v16l13 -8z"
    if (icon === "player-pause") return "M6 5h4v14h-4z M14 5h4v14h-4z"
    return ""
  }

  function textSweepColor(index, count) {
    var base = baseTextColor()
    var sweep = root.sweepColor
    var center = (index + 0.5) / Math.max(1, count)
    var distance = Math.abs(center - root.sweepPosition)
    var intensity = Math.max(0, 1 - distance / 0.16) * 0.62

    return Qt.rgba(
      base.r + (sweep.r - base.r) * intensity,
      base.g + (sweep.g - base.g) * intensity,
      base.b + (sweep.b - base.b) * intensity,
      1
    )
  }

  NumberAnimation on sweepPosition {
    from: -0.35
    to: 1.35
    duration: 2400
    loops: Animation.Infinite
    running: root.sweepActive && root.visible
  }

  Rectangle {
    anchors.fill: parent
    color: root.accent
    opacity: root.active && root.showActiveState ? 0.08 : root.hoverHighlightOpacity
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 2
    color: root.accent
    opacity: root.active && root.showActiveState ? 0.9 : 0

    Behavior on opacity {
      LacunaAnim { motion: "fast" }
    }
  }

  Row {
    id: content

    anchors.centerIn: parent
    spacing: root.iconName !== "" ? 4 : 0

    Item {
      visible: root.iconName !== ""
      anchors.verticalCenter: parent.verticalCenter
      width: visible ? root.iconSize : 0
      height: root.iconSize

      Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: root.iconSize / 24
        transformOrigin: Item.Center
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          strokeColor: root.baseTextColor()
          strokeWidth: 2
          fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          joinStyle: ShapePath.RoundJoin
          PathSvg { path: root.iconPath(root.iconName) }
        }
      }
    }

    Item {
      id: labelSlot

      anchors.verticalCenter: parent.verticalCenter
      visible: !root.sweepActive
      implicitWidth: label.implicitWidth
      implicitHeight: label.implicitHeight

      Text {
        id: label

        anchors.centerIn: parent
        z: 2
        text: root.text
        color: root.baseTextColor()
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.labelPixelSize)
        font.weight: root.labelFontWeight
        scale: root.labelAnimatedScale
        transformOrigin: Item.Center
        elide: Text.ElideRight
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
        elide: Text.ElideRight
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
        elide: Text.ElideRight
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
        elide: Text.ElideRight
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
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    Row {
      id: sweepLabel

      anchors.verticalCenter: parent.verticalCenter
      visible: root.sweepActive
      spacing: 0

      Repeater {
        model: label.text.length

        Text {
          required property int index

          text: label.text.charAt(index)
          color: root.textSweepColor(index, label.text.length)
          font.family: label.font.family
          font.pixelSize: label.font.pixelSize
          font.weight: label.font.weight
          maximumLineCount: 1
        }
      }
    }
  }

  LacunaStateLayer {
    id: clickArea

    stateColor: root.accent
    showFill: false
    onContainsMouseChanged: {
      root.hoverRevealAmount = containsMouse ? 1 : 0
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
    running: root.hovered && !root.sweepActive
    loops: Animation.Infinite

    NumberAnimation {
      target: root
      property: "hoverPulseAmount"
      from: 0
      to: 1
      duration: 900
      easing.type: Easing.InOutSine
    }

    NumberAnimation {
      target: root
      property: "hoverPulseAmount"
      from: 1
      to: 0
      duration: 900
      easing.type: Easing.InOutSine
    }

    onStopped: root.hoverPulseAmount = 0
  }
}
