import QtQuick

MouseArea {
  id: root

  signal triggered()
  signal secondaryClicked(real x, real y)
  signal scrolled(int delta)

  property bool disabled: false
  property color stateColor: "#88c0d0"
  property real hoverOpacity: 0.06
  property real pressOpacity: 0.11
  property bool showFill: true
  property real reveal: pressed || containsMouse ? 1 : 0

  anchors.fill: parent
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  enabled: !disabled
  hoverEnabled: true
  cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

  onClicked: function(mouse) {
    if (mouse.button === Qt.RightButton) {
      root.secondaryClicked(mouse.x, mouse.y)
    } else {
      root.triggered()
    }
  }

  onWheel: function(wheel) {
    root.scrolled(wheel.angleDelta.y)
  }

  Rectangle {
    anchors.fill: parent
    color: root.stateColor
    opacity: root.showFill ? root.reveal * (root.pressed ? root.pressOpacity : root.hoverOpacity) : 0

    Behavior on opacity {
      LacunaAnim { motion: "fast" }
    }
  }

  Behavior on reveal {
    LacunaAnim { motion: "fast" }
  }
}
