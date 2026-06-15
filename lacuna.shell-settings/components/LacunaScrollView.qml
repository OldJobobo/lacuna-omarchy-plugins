import QtQuick
import QtQuick.Controls
import "../services"

Flickable {
  id: root

  default property alias content: contentHost.data

  property alias spacing: contentHost.spacing
  property bool smoothWheel: true
  property bool showEdgeMasks: false
  property real wheelMultiplier: 1.0
  property int wheelDuration: motionTokens.quick
  property int edgeMaskHeight: 14
  property color edgeMaskColor: "#101315"
  property real targetContentY: 0
  property MotionTokens motionTokens: defaultMotionTokens

  MotionTokens {
    id: defaultMotionTokens
  }

  contentWidth: width
  contentHeight: contentHost.implicitHeight
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  flickableDirection: Flickable.VerticalFlick
  interactive: true
  ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

  WheelHandler {
    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function(event) {
      var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y
      if (delta === 0) return

      root.scrollBy(delta)
      event.accepted = true
    }
  }

  function clampContentY(value) {
    return Math.max(0, Math.min(value, Math.max(0, contentHeight - height)))
  }

  function scrollBy(delta) {
    if (!smoothWheel) {
      contentY = clampContentY(contentY - delta * wheelMultiplier)
      targetContentY = contentY
      return
    }

    if (!wheelAnimation.running) targetContentY = contentY
    targetContentY = clampContentY(targetContentY - delta * wheelMultiplier)
    wheelAnimation.to = targetContentY
    wheelAnimation.restart()
  }

  Column {
    id: contentHost

    width: root.width
  }

  Rectangle {
    id: topEdgeMask

    y: root.contentY
    z: 10
    width: root.width
    height: root.edgeMaskHeight
    visible: root.showEdgeMasks && root.contentHeight > root.height
    opacity: root.contentY > 1 ? 1 : 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.edgeMaskColor }
      GradientStop { position: 1.0; color: "transparent" }
    }

    Behavior on opacity {
      LacunaAnim { motion: "fast" }
    }
  }

  Rectangle {
    id: bottomEdgeMask

    y: root.contentY + root.height - height
    z: 10
    width: root.width
    height: root.edgeMaskHeight
    visible: root.showEdgeMasks && root.contentHeight > root.height
    opacity: root.contentY + root.height < root.contentHeight - 1 ? 1 : 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: root.edgeMaskColor }
    }

    Behavior on opacity {
      LacunaAnim { motion: "fast" }
    }
  }

  NumberAnimation {
    id: wheelAnimation

    target: root
    property: "contentY"
    duration: root.wheelDuration
    easing.type: Easing.OutCubic
  }
}
