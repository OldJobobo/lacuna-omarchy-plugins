import Quickshell.Services.Mpris
import QtQuick
import "components"

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.mpris"
  property var settings: ({})

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color background: bar ? bar.background : "#101315"
  readonly property color moduleColor: colorProfile.roleColor(cssClass === "playing" ? "playing" : cssClass === "paused" ? "paused" : "mpris", colorProfile.soft)
  readonly property bool compact: barSize <= 26
  readonly property int maxTextLength: Math.max(8, Number(setting("maxTextLength", compact ? 18 : 34)))
  readonly property bool sweepOnPlaying: setting("sweepOnPlaying", true) === true
  readonly property bool hideWhenVertical: setting("hideWhenVertical", true) === true
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var player: selectPlayer()
  readonly property bool hasMedia: player !== null && (player.trackTitle || player.trackArtist || player.isPlaying)
  readonly property string cssClass: !hasMedia ? "hidden" : player.isPlaying ? "playing" : "paused"
  readonly property string displayIcon: cssClass === "playing" ? "player-play" : "player-pause"
  readonly property string displayText: {
    if (!hasMedia) return ""

    var nextText = clipped(playerLabel(player))
    if (!nextText) return ""

    return nextText
  }
  readonly property string rawTooltip: {
    if (!hasMedia) return ""

    var state = cssClass === "playing" ? "Playing" : "Paused"
    var stateColor = cssClass === "playing" ? "#8cbfb8" : "#ab9191"
    var identity = player.identity || player.desktopEntry || "Media"
    var label = playerLabel(player) || state

    return "<b>" + htmlEscape(identity) + "</b><br/>State: <font color='" + stateColor + "'>" + state + "</font><br/>Track: " + htmlEscape(label) + "<br/><br/>Left click: play/pause<br/>Right click: next"
  }
  readonly property bool shown: cssClass !== "hidden" && displayText.length > 0 && (!vertical || !hideWhenVertical)

  visible: shown
  implicitWidth: shown ? button.implicitWidth : 0
  implicitHeight: shown ? button.implicitHeight : 0

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function selectPlayer() {
    var available = root.players
    var fallback = null

    for (var i = 0; i < available.length; i++) {
      var candidate = available[i]
      if (!candidate) continue

      if (candidate.isPlaying) return candidate
      if (!fallback && (candidate.trackTitle || candidate.trackArtist)) fallback = candidate
    }

    return fallback
  }

  function playerLabel(candidate) {
    if (!candidate) return ""

    var artist = candidate.trackArtist || candidate.trackArtists || ""
    var title = candidate.trackTitle || ""

    if (artist && title) return artist + " - " + title
    if (title) return title
    return candidate.isPlaying ? "Playing" : "Paused"
  }

  function clipped(value) {
    var text = String(value || "")
    if (text.length <= maxTextLength) return text
    return text.slice(0, Math.max(1, maxTextLength - 1)) + "..."
  }

  function htmlEscape(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  function togglePlayer() {
    if (!player) return

    if (player.canTogglePlaying) player.togglePlaying()
    else if (player.isPlaying && player.canPause) player.pause()
    else if (player.canPlay) player.play()
  }

  function nextTrack() {
    if (player && player.canGoNext) player.next()
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "mpris"
  }

  LacunaMprisButton {
    id: button

    iconName: root.displayIcon
    text: root.displayText
    tooltip: root.rawTooltip
    accent: root.moduleColor
    foreground: root.foreground
    background: root.background
    compact: root.compact
    barSize: root.barSize
    active: root.cssClass === "playing"
    showActiveState: false
    accentText: false
    sweepActive: root.sweepOnPlaying && root.cssClass === "playing"
    sweepColor: root.background
    contentHorizontalPadding: 10
    labelPixelSize: 12
    iconSize: root.barSize >= 30 ? 15 : 13
    fontFamily: bar ? bar.fontFamily : "Hack Nerd Font Propo"
    labelFontWeight: Font.DemiBold
    tooltipHost: root.bar
    onTriggered: root.togglePlayer()
    onSecondaryTriggered: root.nextTrack()
  }
}
