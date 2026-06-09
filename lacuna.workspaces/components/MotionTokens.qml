import QtQuick

QtObject {
  property bool animationDisabled: false
  property real animationSpeed: 1.0

  readonly property real safeSpeed: Math.max(0.1, animationSpeed)
  readonly property int animationFast: duration(120)
  readonly property int animationNormal: duration(180)
  readonly property int animationSlow: duration(260)
  readonly property int colorDuration: duration(140)
  readonly property int pulseDuration: duration(900)

  function duration(baseMs) {
    return animationDisabled ? 0 : Math.round(baseMs / safeSpeed)
  }

  function durationFor(motion) {
    if (motion === "fast") return animationFast
    if (motion === "slow") return animationSlow
    return animationNormal
  }
}
