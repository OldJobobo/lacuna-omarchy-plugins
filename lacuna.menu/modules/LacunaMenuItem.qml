import QtQuick
import Quickshell.Widgets
import "../components"
import "../services"

LacunaRect {
  id: root

  signal triggered()
  signal contextRequested(real x, real y)
  signal optionSelected(string value)
  signal trailingActionTriggered(string action)
  signal reorderDragStarted(real sceneY)
  signal reorderDragged(real sceneY)
  signal reorderDropped(real sceneY)

  property string kind: "item"
  property string icon: ""
  property string iconSource: ""
  property string label: ""
  property string hint: ""
  property string tone: "nav"
  property string priority: "normal"
  property string layout: "row"
  property bool danger: false
  property bool hasChildren: false
  property bool switchVisible: false
  property bool switchChecked: false
  property string badgeText: ""
  property string trailingAction: ""
  property string trailingIcon: ""
  property string trailingTooltip: ""
  property string optionValue: ""
  property var options: []
  property bool reorderHandleVisible: false
  property bool reorderActive: false
  property color foreground: "#d8dee9"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color accent: "#88c0d0"
  property color toneAccent: accent
  property color background: "#101315"
  property string fontFamily: "Hack Nerd Font"
  property string labelFontFamily: fontFamily
  property int iconRailWidth: 32
  property bool compact: false
  property var designTokens: fallbackDesignTokens
  readonly property bool hovered: stateLayer.containsMouse
  readonly property bool pressed: stateLayer.pressed
  readonly property real reveal: stateLayer.reveal
  readonly property bool header: kind === "header"
  readonly property bool featured: layout === "featured"
  readonly property bool optionControl: layout === "design-style-control"
  readonly property bool compactRow: layout === "compact"
  readonly property bool primary: priority === "primary"
  readonly property bool badgeVisible: badgeText !== ""
  readonly property bool trailingActionVisible: trailingAction !== ""
  property bool trailingActionHovered: false
  readonly property int badgeWidth: badgeVisible ? Math.max(compact ? 22 : 24, badgeText.length * (compact ? 6 : 7) + (compact ? 10 : 12)) : 0
  readonly property int trailingActionWidth: trailingActionVisible ? (compact ? 22 : 24) : 0
  readonly property int reorderHandleWidth: reorderHandleVisible ? (compact ? 18 : 20) : 0
  readonly property bool trailingTooltipVisible: trailingActionHovered && trailingTooltip !== ""
  readonly property int trailingTooltipWidth: trailingTooltipVisible ? Math.max(88, Math.min(150, trailingTooltip.length * (compact ? 7 : 8) + 18)) : 0
  readonly property int rowHeight: optionControl ? (compact ? 38 : 42) : featured ? designTokens.featuredItemHeight : primary ? designTokens.primaryItemHeight : compactRow ? designTokens.compactItemHeight : designTokens.itemHeight
  readonly property int iconLeftPadding: designTokens.accentStrips ? (compact ? 5 : 6) : 0
  property int contentLeftMargin: Math.round(reveal * (featured ? 3 : 2))
  property bool reorderHandlePressed: false
  property real lineworkProgress: 0
  readonly property int lineworkWidth: compact ? 26 : 34
  readonly property int lineworkHeight: 2

  width: parent ? parent.width : implicitWidth
  height: header ? (compact ? 24 : 30) : rowHeight
  radius: header ? 0 : designTokens.radius
  border.width: !header && designTokens.omarchy && (hovered || primary) ? designTokens.borderWidth : 0
  border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, hovered ? 0.18 : 0.10)
  clip: true
  opacity: reorderActive ? 0.76 : 1

  Behavior on contentLeftMargin {
    LacunaAnim { motion: "fast" }
  }

  Behavior on opacity {
    LacunaAnim { motion: "fast" }
  }

  LacunaRect {
    visible: !root.header && root.designTokens.lacuna
    anchors.fill: parent
    color: root.toneAccent
    opacity: root.featured ? 0.045 + root.reveal * 0.065 : root.primary ? 0.025 + root.reveal * 0.06 : root.reveal * 0.055
  }

  LacunaRect {
    visible: !root.header && root.designTokens.accentStrips
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.featured ? 5 : root.primary ? 4 : 3
    color: root.toneAccent
    opacity: root.featured ? 0.7 + root.reveal * 0.3 : root.primary ? 0.42 + root.reveal * 0.42 : root.reveal * 0.95
  }

  LacunaRect {
    id: topLinework

    visible: !root.header && root.designTokens.decorativeLinework && root.reveal > 0
    x: 9 + Math.round(Math.max(0, root.width - width - 18) * root.lineworkProgress)
    y: 0
    width: root.lineworkWidth
    height: root.lineworkHeight
    color: root.toneAccent
    opacity: root.reveal * 0.42
  }

  LacunaRect {
    id: bottomLinework

    visible: !root.header && root.designTokens.decorativeLinework && root.reveal > 0
    x: 8 + Math.round(Math.max(0, root.width - width - 16) * (1 - root.lineworkProgress))
    y: root.height - height
    width: root.lineworkWidth
    height: root.lineworkHeight
    color: root.toneAccent
    opacity: root.reveal * 0.32
  }

  SequentialAnimation {
    running: !root.header && root.designTokens.decorativeLinework && root.reveal > 0.01 && root.visible
    loops: Animation.Infinite

    NumberAnimation {
      target: root
      property: "lineworkProgress"
      from: 0
      to: 1
      duration: root.compact ? 2800 : 3400
      easing.type: Easing.InOutSine
    }

    NumberAnimation {
      target: root
      property: "lineworkProgress"
      from: 1
      to: 0
      duration: root.compact ? 2800 : 3400
      easing.type: Easing.InOutSine
    }
  }

  Row {
    visible: root.header
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: 2
    anchors.rightMargin: 4
    anchors.bottomMargin: 5
    spacing: 8

    LacunaRect {
      width: 16
      height: 1
      anchors.verticalCenter: parent.verticalCenter
      color: root.toneAccent
      opacity: 0.6
    }

    LacunaText {
      width: parent.width - 24
      text: root.label.toUpperCase()
      color: root.muted
      fontFamily: root.fontFamily
      font.pixelSize: 9
      font.weight: Font.DemiBold
    }
  }

  Row {
    id: content
    visible: !root.header
    anchors.left: parent.left
    anchors.right: trailing.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: root.contentLeftMargin + root.iconLeftPadding
    anchors.rightMargin: 8
    spacing: root.compact ? (root.featured ? 6 : 5) : (root.featured ? 8 : root.primary ? 7 : 6)

    Item {
      width: root.iconRailWidth
      height: root.rowHeight
      anchors.verticalCenter: parent.verticalCenter

      IconImage {
        id: iconImage

        anchors.centerIn: parent
        width: root.compact ? (root.featured ? 19 : root.primary ? 16 : 14) : (root.featured ? 22 : root.primary ? 19 : 17)
        height: width
        implicitSize: width
        source: root.iconSource
        visible: root.iconSource !== "" && status !== Image.Error
        opacity: root.hovered ? 1 : 0.88
      }

      LacunaTablerIcon {
        id: iconShape

        anchors.centerIn: parent
        visible: root.iconSource === "" && valid
        name: root.icon
        color: root.tone === "nav" && !root.hovered ? root.muted : root.toneAccent
        iconSize: root.compact ? (root.featured ? 17 : root.primary ? 15 : 13) : (root.featured ? 20 : root.primary ? 17 : 15)
      }

      LacunaText {
        anchors.centerIn: parent
        width: parent.width
        visible: (root.iconSource === "" && !iconShape.valid) || (root.iconSource !== "" && iconImage.status === Image.Error)
        text: root.icon
        color: root.tone === "nav" && !root.hovered ? root.muted : root.toneAccent
        fontFamily: root.fontFamily
        font.pixelSize: root.compact ? (root.featured ? 15 : root.primary ? 13 : 12) : (root.featured ? 17 : root.primary ? 15 : 13)
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, parent.width - root.iconLeftPadding - root.iconRailWidth - content.spacing)
      spacing: 1

      LacunaText {
        width: parent.width
        text: root.label
        color: root.foreground
        fontFamily: root.labelFontFamily
        font.pixelSize: root.compact ? (root.featured ? 13 : root.primary ? 12 : 11) : (root.featured ? 15 : root.primary ? 14 : 13)
        font.weight: root.hovered || root.primary || root.featured ? Font.DemiBold : Font.Normal
        font.letterSpacing: root.compact ? 0.6 : 0.9
      }
    }
  }

  Item {
    id: trailing

    z: 2
    visible: !root.header && (root.hasChildren || root.switchVisible || root.optionControl || root.badgeVisible || root.trailingActionVisible || root.reorderHandleVisible)
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: root.optionControl ? segmentControl.width : root.switchVisible ? (root.compact ? 32 : 36) : root.trailingActionVisible ? root.trailingActionWidth + root.trailingTooltipWidth + (root.trailingTooltipVisible ? 6 : 0) + root.reorderHandleWidth + (root.reorderHandleVisible ? 5 : 0) : root.badgeVisible ? root.badgeWidth + (root.hasChildren ? 18 : 0) + root.reorderHandleWidth + (root.reorderHandleVisible ? 5 : 0) : root.hasChildren ? 12 + root.reorderHandleWidth + (root.reorderHandleVisible ? 5 : 0) : root.reorderHandleWidth
    height: root.rowHeight

    LacunaRect {
      id: reorderHandleButton

      visible: root.reorderHandleVisible
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: root.reorderHandleWidth
      height: width
      radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
      color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, reorderHandleArea.containsMouse || root.reorderHandlePressed ? 0.16 : 0.07)

      LacunaTablerIcon {
        anchors.centerIn: parent
        name: "grip-vertical"
        color: reorderHandleArea.containsMouse || root.reorderHandlePressed ? root.foreground : root.muted
        iconSize: root.compact ? 12 : 13
      }

      MouseArea {
        id: reorderHandleArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.SizeVerCursor

        function sceneY(mouse) {
          return mapToItem(null, mouse.x, mouse.y).y
        }

        onPressed: function(mouse) {
          root.reorderHandlePressed = true
          root.reorderDragStarted(sceneY(mouse))
        }
        onPositionChanged: function(mouse) {
          if (pressed) root.reorderDragged(sceneY(mouse))
        }
        onReleased: function(mouse) {
          root.reorderHandlePressed = false
          root.reorderDropped(sceneY(mouse))
        }
        onCanceled: root.reorderHandlePressed = false
      }
    }

    Item {
      id: childArrow

      visible: root.hasChildren && !root.switchVisible
      anchors.right: root.reorderHandleVisible ? reorderHandleButton.left : parent.right
      anchors.rightMargin: root.reorderHandleVisible ? 5 : 0
      anchors.verticalCenter: parent.verticalCenter
      width: root.compact ? 12 : 14
      height: root.compact ? 12 : 14

      LacunaTablerIcon {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron-right"
        color: root.hovered ? root.toneAccent : root.muted
        iconSize: root.compact ? 12 : 14
      }
    }

    LacunaRect {
      id: trailingActionButton

      visible: root.trailingActionVisible && !root.switchVisible && !root.optionControl
      anchors.right: root.reorderHandleVisible ? reorderHandleButton.left : parent.right
      anchors.rightMargin: root.reorderHandleVisible ? 5 : 0
      anchors.verticalCenter: parent.verticalCenter
      width: root.trailingActionWidth
      height: width
      radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
      color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.08 + trailingActionLayer.reveal * 0.10)
      border.width: root.designTokens.lacuna ? 0 : 1
      border.color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.22 + trailingActionLayer.reveal * 0.24)

      LacunaTablerIcon {
        anchors.centerIn: parent
        name: root.trailingIcon !== "" ? root.trailingIcon : "plus"
        color: trailingActionLayer.containsMouse ? root.foreground : root.toneAccent
        iconSize: root.compact ? 12 : 13
      }

      LacunaStateLayer {
        id: trailingActionLayer

        anchors.fill: parent
        stateColor: root.toneAccent
        hoverOpacity: root.designTokens.hoverOpacity
        pressOpacity: root.designTokens.activeOpacity
        onContainsMouseChanged: root.trailingActionHovered = containsMouse
        onTriggered: root.trailingActionTriggered(root.trailingAction)
      }
    }

    LacunaRect {
      visible: root.trailingTooltipVisible && !root.switchVisible && !root.optionControl
      anchors.right: trailingActionButton.left
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      width: root.trailingTooltipWidth
      height: root.compact ? 18 : 20
      radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
      color: root.background
      border.width: 1
      border.color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.32)
      clip: true

      LacunaText {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.trailingTooltip
        color: root.foreground
        fontFamily: root.fontFamily
        font.pixelSize: root.compact ? 8 : 9
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    LacunaRect {
      visible: root.badgeVisible && !root.switchVisible && !root.optionControl
      anchors.right: root.hasChildren ? childArrow.left : parent.right
      anchors.rightMargin: root.reorderHandleVisible && !root.hasChildren ? root.reorderHandleWidth + 5 : root.hasChildren ? 6 : 0
      anchors.verticalCenter: parent.verticalCenter
      width: root.badgeWidth
      height: root.compact ? 16 : 18
      radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
      color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, root.designTokens.material ? 0.20 : 0.13)
      border.width: root.designTokens.lacuna ? 0 : 1
      border.color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, root.hovered ? 0.48 : 0.28)

      LacunaText {
        anchors.centerIn: parent
        text: root.badgeText
        color: root.hovered ? root.foreground : root.muted
        fontFamily: root.fontFamily
        font.pixelSize: root.compact ? 8 : 9
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
      }
    }

    LacunaRect {
      id: switchTrack

      visible: root.switchVisible && !root.optionControl
      anchors.centerIn: parent
      width: root.designTokens.switchStyle === "material" ? (root.compact ? 34 : 38) : root.compact ? 30 : 34
      height: root.designTokens.switchStyle === "material" ? (root.compact ? 18 : 20) : root.compact ? 14 : 16
      radius: height / 2
      color: root.switchChecked ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, root.designTokens.material ? 0.42 : 0.32) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.designTokens.omarchy ? 0.09 : 0.12)
      border.width: 1
      border.color: root.switchChecked ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, root.designTokens.material ? 0.85 : 0.65) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.designTokens.omarchy ? 0.24 : 0.18)

      LacunaRect {
        width: root.designTokens.switchStyle === "material" ? (root.compact ? 12 : 14) : root.compact ? 8 : 10
        height: width
        radius: width / 2
        x: root.switchChecked ? switchTrack.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        color: root.switchChecked ? root.toneAccent : root.muted

        Behavior on x {
          LacunaAnim { motion: "fast" }
        }
      }
    }

    Row {
      id: segmentControl

      visible: root.optionControl
      anchors.verticalCenter: parent.verticalCenter
      width: implicitWidth
      height: root.compact ? 24 : 26
      spacing: 2

      Repeater {
        model: root.options

        LacunaRect {
          required property var modelData

          readonly property bool selected: modelData.value === root.optionValue
          width: root.compact ? 54 : 62
          height: segmentControl.height
          radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
          color: selected ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, root.designTokens.material ? 0.34 : 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.designTokens.omarchy ? 0.06 : 0.08)
          border.width: 1
          border.color: selected ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.78) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
          clip: true

          LacunaText {
            anchors.centerIn: parent
            text: modelData.label
            color: parent.selected ? root.foreground : root.muted
            fontFamily: root.fontFamily
            font.pixelSize: root.compact ? 8 : 9
            font.weight: parent.selected ? Font.DemiBold : Font.Normal
          }

          LacunaStateLayer {
            anchors.fill: parent
            stateColor: root.toneAccent
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            onTriggered: root.optionSelected(modelData.value)
          }
        }
      }
    }
  }

  LacunaStateLayer {
    id: stateLayer

    disabled: root.header || root.optionControl
    stateColor: root.toneAccent
    hoverOpacity: root.designTokens.hoverOpacity
    pressOpacity: root.designTokens.activeOpacity
    showFill: !root.designTokens.lacuna
    onTriggered: root.triggered()
    onSecondaryClicked: function(x, y) {
      root.contextRequested(x, y)
    }
  }

  DesignTokens {
    id: fallbackDesignTokens
    designStyle: "lacuna"
    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }
}
