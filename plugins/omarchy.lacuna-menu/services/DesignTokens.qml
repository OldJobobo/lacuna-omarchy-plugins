import QtQuick

QtObject {
  id: root

  property string designStyle: "carbon"
  property bool compact: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color accent: "#88c0d0"

  readonly property string style: normalize(designStyle)
  readonly property bool carbon: style === "carbon"
  readonly property bool omarchy: style === "omarchy"
  readonly property bool material: style === "material"

  readonly property int radius: carbon ? 0 : omarchy ? 2 : 8
  readonly property int controlRadius: carbon ? 0 : omarchy ? 2 : 9
  readonly property int borderWidth: carbon ? 0 : 1
  readonly property real surfaceOpacity: carbon ? 1.0 : omarchy ? 0.98 : 0.96
  readonly property real surfaceBorderOpacity: carbon ? 0.0 : omarchy ? 0.24 : 0.16
  readonly property real hoverOpacity: carbon ? 0.06 : omarchy ? 0.08 : 0.10
  readonly property real activeOpacity: carbon ? 0.11 : omarchy ? 0.12 : 0.16
  readonly property int itemHeight: compact ? (material ? 34 : 32) : (material ? 40 : 38)
  readonly property int primaryItemHeight: compact ? (material ? 36 : 34) : (material ? 42 : 40)
  readonly property int featuredItemHeight: compact ? (material ? 44 : 42) : (material ? 50 : 48)
  readonly property int compactItemHeight: compact ? 28 : 32
  readonly property string headerTreatment: carbon ? "accent-line" : omarchy ? "body-border" : "tonal"
  readonly property string switchStyle: carbon ? "compact" : omarchy ? "native" : "material"
  readonly property string railTreatment: carbon ? "linework" : omarchy ? "contained" : "tonal"
  readonly property string tooltipTreatment: carbon ? "accent-strip" : omarchy ? "bordered" : "tonal"
  readonly property bool decorativeLinework: carbon
  readonly property bool accentStrips: carbon
  readonly property int contentInset: compact ? (material ? 12 : 10) : (material ? 16 : 14)
  readonly property int topInset: compact ? (material ? 8 : 6) : (material ? 10 : 8)
  readonly property int bottomInset: compact ? (material ? 12 : 10) : (material ? 18 : 16)
  readonly property int itemSpacing: compact ? (material ? 4 : 2) : (material ? 5 : 2)
  readonly property int sectionSpacing: compact ? (material ? 8 : 7) : (material ? 11 : 10)
  readonly property int railSpacing: compact ? (material ? 6 : 5) : (material ? 8 : 7)
  readonly property int railLeftInset: compact ? (material ? 8 : 7) : (material ? 10 : 9)
  readonly property int railRightInset: railLeftInset
  readonly property int joinRadius: carbon ? (compact ? 14 : 18) : omarchy ? 0 : (compact ? 12 : 16)
  readonly property int connectorOverlap: carbon ? (compact ? 25 : 33) : omarchy ? 0 : (compact ? 20 : 28)
  readonly property color borderColor: Qt.rgba(foreground.r, foreground.g, foreground.b, surfaceBorderOpacity)
  readonly property color stateColor: material ? foreground : accent

  function normalize(value) {
    var styleName = String(value || "").toLowerCase()
    if (styleName === "omarchy" || styleName === "material") return styleName
    return "carbon"
  }
}
