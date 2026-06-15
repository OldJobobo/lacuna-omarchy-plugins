import QtQuick

Item {
  property var bar: null
  property var anchorItem: null
  property bool opened: false

  function open() {
    opened = false
  }

  function close() {
    opened = false
  }

  function toggle() {
    opened = false
  }
}
