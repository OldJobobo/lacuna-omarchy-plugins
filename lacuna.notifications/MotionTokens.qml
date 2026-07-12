import QtQuick

// Lacuna motion (bar-widget layer) — the named reveal scale.
// See docs/lacuna-design-system/03-motion.md.
QtObject {
  readonly property int instant: 75
  readonly property int quick: 150    // hover/press recess, small reveals
  readonly property int color: 160    // color transitions
  readonly property int reveal: 300   // attached panel/flyout disclosure
  readonly property int settle: 450   // large geometry and layout reflow
  readonly property int ambient: 750  // slow background motion

  // Deprecated aliases — identical values — for existing widget consumers.
  readonly property int hoverDuration: quick
  readonly property int colorDuration: color
}
