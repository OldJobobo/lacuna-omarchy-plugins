import QtQuick
import QtQuick.Effects

Item {
  id: root
  required property Item source
  property bool shadowEnabled: false
  property int blurMax: 22
  property real shadowBlur: 1.0
  property real shadowOpacity: 0.55
  property color shadowColor: "black"
  property real shadowHorizontalOffset: 2
  property real shadowVerticalOffset: 3
  property bool autoPaddingEnabled: false
  anchors.fill: parent
  visible: shadowEnabled
  enabled: false
  layer.enabled: visible
  layer.effect: MultiEffect {
    source: root.source
    shadowEnabled: true
    blurMax: root.blurMax
    shadowBlur: root.shadowBlur
    shadowOpacity: root.shadowOpacity
    shadowColor: root.shadowColor
    shadowHorizontalOffset: root.shadowHorizontalOffset
    shadowVerticalOffset: root.shadowVerticalOffset
    autoPaddingEnabled: root.autoPaddingEnabled
  }
}
