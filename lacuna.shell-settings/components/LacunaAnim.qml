import QtQuick
import "../services"

NumberAnimation {
  property string motion: "normal"
  property MotionTokens motionTokens: MotionTokens {}

  function durationFor(value) {
    if (value === "fast") return motionTokens.quick
    if (value === "slow") return motionTokens.settle
    return motionTokens.reveal
  }

  duration: durationFor(motion)
  easing.type: Easing.OutCubic
}
