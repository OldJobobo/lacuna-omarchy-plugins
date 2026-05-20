import QtQuick

QtObject {
  id: root

  property bool animationDisabled: false
  property real animationSpeed: 1.0

  readonly property real safeSpeed: Math.max(0.1, animationSpeed)

  // Existing Lacuna timings. Keep these stable until the panel host refactor
  // intentionally changes motion behavior.
  readonly property int legacyFast: duration(120)
  readonly property int legacyNormal: duration(180)
  readonly property int legacySlow: duration(260)
  readonly property int legacyColor: duration(160)

  // Noctalia-style timing scale for the upcoming geometry-driven panel host.
  readonly property int animationFaster: duration(75)
  readonly property int animationFast: duration(150)
  readonly property int animationNormal: duration(300)
  readonly property int animationSlow: duration(450)
  readonly property int animationSlowest: duration(750)

  readonly property var panelBezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

  function duration(baseMs) {
    return animationDisabled ? 0 : Math.round(baseMs / safeSpeed)
  }

  function legacyDurationFor(motion) {
    if (motion === "fast") return legacyFast
    if (motion === "slow") return legacySlow
    return legacyNormal
  }
}
