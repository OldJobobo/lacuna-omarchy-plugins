import QtQuick

// Canonical build-time source for Lacuna curve geometry. Plugins vendor this
// file locally because runtime imports may not cross plugin boundaries.
QtObject {
  id: root

  readonly property real curveKappa: 0.5522847498
}
