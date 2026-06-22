import QtQuick

Item {
  id: root

  signal edited(real value)

  property real value: 0
  property real minimum: 0
  property real maximum: 1
  property int emitDecimals: 2
  property int displayDecimals: 0
  property real displayScale: 100
  property string displaySuffix: "%"
  property string valueText: ""
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property color toneAccent: "#88c0d0"
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property var designTokens: null

  function tokenBool(name, fallback) {
    if (!designTokens || designTokens[name] === undefined || designTokens[name] === null) return fallback
    return designTokens[name] === true
  }

  function tokenNumber(name, fallback) {
    if (!designTokens || designTokens[name] === undefined || designTokens[name] === null) return fallback
    var numeric = Number(designTokens[name])
    return isFinite(numeric) ? numeric : fallback
  }

  property bool editing: false
  readonly property bool engaged: sliderMouse.containsMouse || sliderMouse.pressed || editing
  readonly property int valueWidth: compact ? 34 : 40
  readonly property real normalizedValue: maximum <= minimum ? 0 : Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum)))
  property real dragNormalizedValue: normalizedValue
  readonly property real visualNormalizedValue: editing ? dragNormalizedValue : normalizedValue
  readonly property real visualValue: valueForRatio(visualNormalizedValue)

  width: parent ? parent.width : 150
  height: compact ? 24 : 26
  clip: false

  function ratioAt(mouseX) {
    var usable = Math.max(1, sliderTrack.width)
    return Math.max(0, Math.min(1, mouseX / usable))
  }

  function valueForRatio(ratio) {
    var raw = minimum + ratio * (maximum - minimum)
    return Math.max(minimum, Math.min(maximum, raw))
  }

  function roundTo(value, decimals) {
    var scale = Math.pow(10, Math.max(0, decimals))
    return Math.round(value * scale) / scale
  }

  function formattedVisualValue() {
    var scaled = roundTo(visualValue * displayScale, displayDecimals)
    return String(scaled) + displaySuffix
  }

  function shownValue() {
    if (editing) return formattedVisualValue()
    return valueText === "" ? formattedVisualValue() : valueText
  }

  function previewAt(mouseX) {
    editing = true
    dragNormalizedValue = ratioAt(mouseX)
  }

  function commitEdit() {
    root.edited(roundTo(valueForRatio(dragNormalizedValue), emitDecimals))
  }

  function cancelEdit() {
    editing = false
    dragNormalizedValue = normalizedValue
  }

  onNormalizedValueChanged: {
    if (editing && Math.abs(normalizedValue - dragNormalizedValue) < 0.001) {
      editing = false
    }
  }

  LacunaRect {
    id: sliderValuePill

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: root.valueWidth
    height: root.compact ? 18 : 20
    radius: root.tokenNumber("controlRadius", 0)
    color: root.engaged ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.13) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.045)
    border.width: root.engaged || !root.tokenBool("lacuna", false) ? 1 : 0
    border.color: root.engaged ? Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, 0.34) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.11)

    LacunaText {
      anchors.centerIn: parent
      width: parent.width - 8
      text: root.shownValue()
      color: root.engaged ? root.toneAccent : root.muted
      fontFamily: root.bodyFontFamily
      font.pixelSize: root.compact ? 8 : 9
      horizontalAlignment: Text.AlignHCenter
    }
  }

  Item {
    id: sliderHitArea

    anchors.left: parent.left
    anchors.right: sliderValuePill.left
    anchors.rightMargin: root.compact ? 8 : 10
    anchors.verticalCenter: parent.verticalCenter
    height: parent.height

    LacunaRect {
      id: sliderTrack

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      height: root.engaged ? 6 : 4
      radius: height / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.engaged ? 0.18 : 0.12)

      Behavior on height {
        LacunaAnim { motion: "fast" }
      }

      LacunaRect {
        id: sliderFill

        width: parent.width * root.visualNormalizedValue
        height: parent.height
        radius: parent.radius
        color: Qt.rgba(root.toneAccent.r, root.toneAccent.g, root.toneAccent.b, sliderMouse.pressed ? 0.96 : 0.78)

        Behavior on width {
          enabled: !sliderMouse.pressed
          LacunaAnim { motion: "fast" }
        }
      }

      LacunaRect {
        id: sliderThumb

        width: root.compact ? 11 : 13
        height: width
        radius: height / 2
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.visualNormalizedValue - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: root.toneAccent
        border.width: 1
        border.color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.75)
        scale: sliderMouse.pressed ? 1.22 : sliderMouse.containsMouse ? 1.10 : 1.0

        Behavior on x {
          enabled: !sliderMouse.pressed
          LacunaAnim { motion: "fast" }
        }

        Behavior on scale {
          LacunaAnim { motion: "fast" }
        }
      }
    }

    MouseArea {
      id: sliderMouse

      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      hoverEnabled: true
      preventStealing: true
      cursorShape: Qt.PointingHandCursor
      onPressed: function(mouse) {
        mouse.accepted = true
        root.previewAt(mouse.x)
      }
      onPositionChanged: function(mouse) {
        if (pressed) root.previewAt(mouse.x)
      }
      onReleased: function(mouse) {
        mouse.accepted = true
        root.previewAt(mouse.x)
        root.commitEdit()
      }
      onCanceled: root.cancelEdit()
      onExited: {
        if (!pressed && !root.editing) root.dragNormalizedValue = root.normalizedValue
      }
    }
  }
}
