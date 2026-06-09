import QtQuick

NumberAnimation {
  property string motion: "normal"

  function durationFor(value) {
    if (value === "fast") return 120
    if (value === "slow") return 260
    return 180
  }

  duration: durationFor(motion)
  easing.type: Easing.OutCubic
}
