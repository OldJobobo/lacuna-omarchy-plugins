import QtQuick

// Shared geometric constants for Lacuna panel and flyout surfaces.
//
// curveKappa is the cubic-Bezier control-point multiplier that makes a
// quarter turn approximate a circular arc: kappa = 4/3 * (sqrt(2) - 1).
// Every Omarchy-style molding connector and rounded surface corner derives
// its control points from this value, so it must stay defined in exactly one
// place. See AGENTS.md "Flyout Surface Geometry".
QtObject {
  id: root

  readonly property real curveKappa: 0.5522847498
}
