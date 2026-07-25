import QtQuick

// Lacuna motion (bar-widget layer) — the named reveal scale.
// See docs/lacuna-design-system/03-motion.md.
QtObject {
  property bool animationDisabled: false
  property real animationSpeed: 1.0

  readonly property real safeSpeed: Math.max(0.1, animationSpeed)
  readonly property int instant: duration(75)
  readonly property int quick: duration(150)    // hover/press recess, small reveals
  readonly property int color: duration(160)    // color transitions
  readonly property int reveal: duration(300)   // attached panel/flyout disclosure
  readonly property int settle: duration(450)   // large geometry and layout reflow
  readonly property int ambient: duration(750)  // slow background motion

  // Deprecated aliases — identical values — for existing widget consumers.
  readonly property int hoverDuration: quick
  readonly property int colorDuration: color

  function duration(baseMs) {
    return animationDisabled ? 0 : Math.round(Number(baseMs) / safeSpeed)
  }
}
