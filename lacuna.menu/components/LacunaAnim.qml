import QtQuick
import "../services"

NumberAnimation {
  property string motion: "normal"

  // Durations mirror the named reveal scale (03-motion.md):
  // fast = quick, normal = reveal, slow = settle.
  function durationFor(value) {
    if (value === "fast") return 150
    if (value === "slow") return 450
    return 300
  }

  duration: durationFor(motion)
  easing.type: Easing.OutCubic
}
