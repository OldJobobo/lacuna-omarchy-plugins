import QtQuick

// A bar label that swaps its value with a Lacuna fade — the outgoing value
// dissolves out, the value is exchanged at the empty midpoint, then the new
// value dissolves in. Opacity only: calm, no roll, no bounce (OutCubic on the
// `reveal` scale; docs/lacuna-design-system/03-motion.md). Used to cycle the
// Claude widget between its 5h-block and 7-day readouts. Self-contained.
Item {
  id: root

  property string text: ""
  property color color: "#d8dee9"
  property string fontFamily: "monospace"
  property int pixelSize: 14
  property int fontWeight: Font.Normal
  // Full fade = out + in, on the `settle` (450) reveal step for a slow dissolve.
  property int duration: 450
  property int colorDuration: 160

  property string shownText: ""

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Behavior on implicitWidth {
    NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
  }

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    text: root.shownText
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: root.pixelSize
    font.weight: root.fontWeight
    maximumLineCount: 1
    renderType: Text.NativeRendering

    Behavior on color { ColorAnimation { duration: root.colorDuration } }
  }

  SequentialAnimation {
    id: fade
    NumberAnimation {
      target: label
      property: "opacity"
      to: 0
      duration: root.duration / 2
      easing.type: Easing.OutCubic
    }
    ScriptAction { script: root.shownText = root.text }
    NumberAnimation {
      target: label
      property: "opacity"
      to: 1
      duration: root.duration / 2
      easing.type: Easing.OutCubic
    }
  }

  onTextChanged: {
    if (root.text === root.shownText) return
    if (root.shownText.length === 0) {
      // First paint — just show it, no fade.
      root.shownText = root.text
      return
    }
    fade.restart()
  }

  Component.onCompleted: shownText = text
}
