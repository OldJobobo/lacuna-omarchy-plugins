import QtQuick

// Level-gated, prefixed logging for Lacuna plugins. Instantiate with an id and
// call log.warn("..."), log.info("..."), log.debug("...") instead of bare
// console.warn so messages share a consistent "<prefix>: <message>" shape and
// can be quieted as a group.
//
//   level: 0 silent, 1 warn, 2 info, 3 debug (defaults to warn so genuine
//   problems surface without debug noise).
QtObject {
  id: root

  property string prefix: "Lacuna"
  property int level: 1

  readonly property int levelSilent: 0
  readonly property int levelWarn: 1
  readonly property int levelInfo: 2
  readonly property int levelDebug: 3

  function format(message) {
    return prefix + ": " + String(message)
  }

  function warn(message) {
    if (level >= levelWarn) console.warn(format(message))
  }

  function info(message) {
    if (level >= levelInfo) console.info(format(message))
  }

  function debug(message) {
    if (level >= levelDebug) console.debug(format(message))
  }
}
