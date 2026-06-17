import QtQuick

// Lacuna motion (bar-widget layer) — the named reveal scale.
// See docs/lacuna-design-system/03-motion.md.
QtObject {
  readonly property int instant: 75
  readonly property int quick: 150    // hover/press recess, small reveals
  readonly property int color: 160    // color transitions

  // Deprecated aliases — identical values — for existing widget consumers.
  readonly property int hoverDuration: quick
  readonly property int colorDuration: color
}
