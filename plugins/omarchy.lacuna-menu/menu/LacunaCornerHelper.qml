import QtQuick
import QtQuick.Shapes

QtObject {
  function multX(cornerState) {
    return cornerState === 1 ? -1 : 1
  }

  function multY(cornerState) {
    return cornerState === 2 ? -1 : 1
  }

  function arcDirection(multXValue, multYValue) {
    return ((multXValue < 0) !== (multYValue < 0)) ? PathArc.Counterclockwise : PathArc.Clockwise
  }

  function flattenedRadius(dimension, requestedRadius) {
    return dimension < requestedRadius * 2 ? dimension / 2 : requestedRadius
  }
}
