import QtQuick

// Baseline gap-seam glow shown on hover — mirrors the menu's hover signature
// (lacuna.menu/modules/LacunaMenuItem.qml): a bottom hairline broken by a
// centered gap (the lacuna mark) with a layered accent glow sitting ON that
// line, fading in with hover and slowly breathing. Drop into a bar widget's
// button:
//
//   BarHoverSeam { anchors.fill: parent; reveal: parent.hoverReveal
//                  seam: ...; accent: colorProfile.accent }
//
// Theme-derived; intensity scales with `reveal` (0..1), so it is invisible at
// rest and costs nothing until hovered.
Item {
  id: root

  // Hover progress, 0..1. Bind to the widget's hoverReveal.
  property real reveal: 0
  // Seam hairline color (ink-derived) and the accent used for the glow.
  property color seam: "#888888"
  property color accent: "#88c0d0"
  // Centered break in the baseline hairline (the lacuna gap).
  property int notch: 10

  property real breath: 0

  // The seam sits just off the bottom edge so the glow can sit centered ON the
  // hairline (and clear of the bar frame). The line and glow share one center
  // line, so the pulse rides the seam rather than floating above it.
  Item {
    id: seamRow

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2
    height: 6

    // Baseline hairline, two segments split by the centered notch.
    Rectangle {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, (parent.width - root.notch) / 2)
      height: 1
      color: root.seam
      opacity: root.reveal
    }

    Rectangle {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, (parent.width - root.notch) / 2)
      height: 1
      color: root.seam
      opacity: root.reveal
    }

    // Layered glow centered on the hairline, filling the gap — the breathing core.
    Rectangle {
      anchors.centerIn: parent
      width: Math.round(parent.width * 0.6)
      height: 5
      radius: 2.5
      color: root.accent
      opacity: root.reveal * (0.06 + root.breath * 0.16)
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.round(parent.width * 0.3)
      height: 3
      radius: 1.5
      color: root.accent
      opacity: root.reveal * (0.16 + root.breath * 0.3)
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.max(5, Math.round(parent.width * 0.14))
      height: 2
      radius: 1
      color: root.accent
      opacity: root.reveal * (0.34 + root.breath * 0.5)
    }
  }

  // Breathe only while hovered (declarative SequentialAnimation does not run in
  // this context; a Timer does). breath oscillates 0..1 on a ~3.9s sine.
  Timer {
    running: root.reveal > 0.01
    interval: 50
    repeat: true
    onTriggered: root.breath = 0.5 + 0.5 * Math.sin(Date.now() / 620)
  }
}
