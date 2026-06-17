import QtQuick

// A vertical gap-seam that brackets a cluster of bar widgets. Separation is
// done by space (gapWidth reserves the room); the seam is a thin theme-derived
// line broken by a centered gap (the lacuna mark), with a slow breathing accent
// glow in the break — mirroring the menu header's gap glow (MenuHeader.qml).
Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.bar-seam"
  property var settings: ({})

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color accent: bar && bar.accent ? bar.accent : foreground
  // Seam role: ink @ 0.18 (docs/lacuna-design-system/01-color.md).
  readonly property color seam: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)

  // Reserved horizontal space — this is the "island" gap separating clusters.
  readonly property int gapWidth: Math.max(8, Number(setting("gapWidth", 28)))
  // Vertical break in the seam line — the lacuna gap mark.
  readonly property int seamGap: Math.max(0, Number(setting("seamGap", 12)))
  readonly property bool breathing: setting("breathing", true) !== false
                                    && String(setting("breathing", "true")) !== "false"

  property real gapBreath: 0

  implicitWidth: gapWidth
  implicitHeight: barSize

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "foreground"
  }

  MotionTokens {
    id: motionTokens
  }

  // The seam line: a vertical hairline broken by a centered gap.
  Item {
    anchors.centerIn: parent
    width: 1
    height: root.barSize

    readonly property int gap: root.seamGap

    Rectangle {
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      width: 1
      height: parent.gap > 0 ? (parent.height - parent.gap) / 2 : parent.height
      color: root.seam
    }

    Rectangle {
      visible: parent.gap > 0
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      width: 1
      height: (parent.height - parent.gap) / 2
      color: root.seam
    }
  }

  // The breathing glow, centered in the gap — a layered vertical streak that
  // fades in/out, matching the menu's signature gap motion.
  Item {
    visible: root.seamGap > 0
    anchors.centerIn: parent
    width: 6
    height: Math.max(6, root.seamGap)

    Rectangle {
      anchors.centerIn: parent
      width: 5
      height: parent.height
      radius: 2.5
      color: root.accent
      opacity: 0.03 + root.gapBreath * 0.2
    }

    Rectangle {
      anchors.centerIn: parent
      width: 3
      height: Math.round(parent.height * 0.6)
      radius: 1.5
      color: root.accent
      opacity: 0.1 + root.gapBreath * 0.34
    }

    Rectangle {
      anchors.centerIn: parent
      width: 2
      height: Math.max(4, Math.round(parent.height * 0.3))
      radius: 1
      color: root.accent
      opacity: 0.28 + root.gapBreath * 0.62
    }
  }

  // Drive the breathing glow from a Timer (declarative SequentialAnimation does
  // not run in this context). gapBreath oscillates 0..1 on a ~3.9s sine.
  Timer {
    running: root.breathing && root.visible
    interval: 50
    repeat: true
    onTriggered: root.gapBreath = 0.5 + 0.5 * Math.sin(Date.now() / 620)
  }
}
