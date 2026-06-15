import QtQuick

// Lacuna motion — the single "reveal" timing scale.
// See docs/lacuna-design-system/03-motion.md. Every duration flows through
// duration() so the central reduced-motion switch (animationDisabled /
// animationSpeed) applies uniformly across the shell.
QtObject {
  id: root

  // Central reduced-motion / speed switch. Bind animationDisabled to a
  // reduced-motion preference to collapse every duration to 0; animationSpeed
  // scales the whole scale at once.
  property bool animationDisabled: false
  property real animationSpeed: 1.0

  readonly property real safeSpeed: Math.max(0.1, animationSpeed)

  // The reveal scale — one named set of durations for the whole shell.
  readonly property int instant: duration(75)    // micro-feedback, immediate state
  readonly property int quick: duration(150)      // hover/press recess, small reveals
  readonly property int color: duration(160)      // color transitions (ColorAnimation)
  readonly property int reveal: duration(300)     // standard panel/flyout disclosure
  readonly property int settle: duration(450)     // large geometry / layout reflow
  readonly property int ambient: duration(750)    // slow background motion
  readonly property int pulse: duration(900)      // attention loops
  readonly property int sweep: duration(2400)     // long decorative sweeps

  // Deprecated panel-host aliases — identical values to the named scale above.
  // Prefer the names above; these remain so existing panel/surface consumers
  // keep working until they are migrated.
  readonly property int animationFaster: instant
  readonly property int animationFast: quick
  readonly property int animationNormal: reveal
  readonly property int animationSlow: settle
  readonly property int animationSlowest: ambient

  // The signature panel-open curve (03-motion.md): a quick commit, a long settle.
  readonly property var panelBezierCurve: [0.20, 0, 0.32, 1, 1, 1]

  function duration(baseMs) {
    return animationDisabled ? 0 : Math.round(baseMs / safeSpeed)
  }
}
