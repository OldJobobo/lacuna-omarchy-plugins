import QtQuick

NumberAnimation {
  property string motion: "normal"

  duration: motion === "fast" ? 120 : motion === "slow" ? 260 : 180
  easing.type: Easing.OutCubic
}
