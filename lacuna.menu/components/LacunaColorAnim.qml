import QtQuick
import "../services"

ColorAnimation {
  property MotionTokens motionTokens: MotionTokens {}
  duration: motionTokens.color
  easing.type: Easing.OutCubic
}
