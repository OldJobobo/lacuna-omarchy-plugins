import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property string name: ""
  property color color: "#d8dee9"
  property int iconSize: 18
  property real strokeWidth: 2
  readonly property string pathData: iconPath(name)
  readonly property bool valid: pathData !== ""
  readonly property bool filled: name === "gear"

  implicitWidth: iconSize
  implicitHeight: iconSize
  width: iconSize
  height: iconSize

  function iconPath(icon) {
    if (icon === "lacuna") return "M6 5h12l3 5l-8.5 9.5a.7 .7 0 0 1 -1 0l-8.5 -9.5l3 -5 M10 12l-2 -2.2l.6 -1"
    if (icon === "apps") return "M4 5a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z M4 15a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z M14 15a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z M14 7l6 0 M17 4l0 6"
    if (icon === "gamepad") return "M6 12h4 M8 10v4 M15 13h.01 M18 11h.01 M4 9a5 5 0 0 1 5 -5h6a5 5 0 0 1 5 5v4a5 5 0 0 1 -5 5h-6a5 5 0 0 1 -5 -5z"
    if (icon === "world" || icon === "browser") return "M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0 M3.6 9h16.8 M3.6 15h16.8 M11.5 3a17 17 0 0 0 0 18 M12.5 3a17 17 0 0 1 0 18"
    if (icon === "code") return "M7 8l-4 4l4 4 M17 8l4 4l-4 4 M14 4l-4 16"
    if (icon === "music") return "M6 17a3 3 0 1 0 6 0a3 3 0 0 0 -6 0 M18 15a3 3 0 1 0 0 6a3 3 0 0 0 0 -6 M9 17v-12l12 -2v12 M9 9l12 -2"
    if (icon === "palette" || icon === "theme" || icon === "customize") return "M12 21a9 9 0 1 1 0 -18c4.97 0 9 3.58 9 8c0 2.21 -1.79 4 -4 4h-2a2 2 0 0 0 -1 3.73a1.3 1.3 0 0 1 -1 2.27z M7.5 10.5h.01 M10.5 7.5h.01 M14.5 7.5h.01 M17.5 10.5h.01"
    if (icon === "file-text" || icon === "office") return "M14 3v4a1 1 0 0 0 1 1h4 M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z M9 9h1 M9 13h6 M9 17h6"
    if (icon === "settings" || icon === "system") return "M4 6h8 M16 6h4 M14 4a2 2 0 1 0 0 4a2 2 0 0 0 0 -4 M4 12h2 M10 12h10 M8 10a2 2 0 1 0 0 4a2 2 0 0 0 0 -4 M4 18h11 M19 18h1 M17 16a2 2 0 1 0 0 4a2 2 0 0 0 0 -4"
    if (icon === "gear") return "M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"
    if (icon === "tool") return "M7 10h3v-3l-3.5 -3.5a6 6 0 0 1 8 8l6 6a2 2 0 0 1 -3 3l-6 -6a6 6 0 0 1 -8 -8z"
    if (icon === "dots") return "M5 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0 M12 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0 M19 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"
    if (icon === "folder" || icon === "files") return "M5 4h4l2 2h8a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2"
    if (icon === "edit" || icon === "editor") return "M7 7h-1a2 2 0 0 0 -2 2v9a2 2 0 0 0 2 2h9a2 2 0 0 0 2 -2v-1 M16 3l5 5l-11 11h-5v-5z M14 5l5 5"
    if (icon === "mail" || icon === "email") return "M3 7a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z M3 7l9 6l9 -6"
    if (icon === "message" || icon === "discord") return "M8 9h8 M8 13h6 M7 18l-4 3v-15a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2z"
    if (icon === "terminal") return "M8 9l3 3l-3 3 M13 15l3 0 M3 6a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z"
    if (icon === "refresh" || icon === "update") return "M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4 M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4"
    if (icon === "search") return "M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0 M21 21l-6 -6"
    if (icon === "file-search" || icon === "log") return "M14 3v4a1 1 0 0 0 1 1h4 M11 21h-4a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v4 M16 17m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0 M20 20l-2 -2"
    if (icon === "list-check" || icon === "preferred-apps") return "M9 6h11 M9 12h11 M9 18h11 M5 6l.01 0 M5 12l.01 0 M5 18l.01 0"
    if (icon === "clock") return "M12 7v5l3 3 M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0"
    if (icon === "color-swatch") return "M19 7l-8.5 8.5a2.1 2.1 0 0 1 -3 0l-1 -1a2.1 2.1 0 0 1 0 -3l8.5 -8.5 M7 13l4 4 M3 21h18"
    if (icon === "density-compact") return "M5 5h14 M7 12h10 M9 19h6"
    if (icon === "density-normal") return "M5 4h14 M5 12h14 M5 20h14"
    if (icon === "sidebar-expand" || icon === "sidebar-toggle") return "M4 5a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z M9 3v18 M13 9l3 3l-3 3"
    if (icon === "sidebar-collapse") return "M4 5a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z M9 3v18 M16 9l-3 3l3 3"
    if (icon === "sidebar-overlay") return "M4 5a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z M9 3v18 M13 8h4 M13 12h4 M13 16h4"
    if (icon === "corners") return "M4 10v-4a2 2 0 0 1 2 -2h4 M14 4h4a2 2 0 0 1 2 2v4 M20 14v4a2 2 0 0 1 -2 2h-4 M10 20h-4a2 2 0 0 1 -2 -2v-4"
    if (icon === "photo" || icon === "wallpaper" || icon === "background") return "M15 8h.01 M3 6a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v12a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z M3 16l5 -5c.93 -.89 2.07 -.89 3 0l5 5 M14 14l1 -1c.93 -.89 2.07 -.89 3 0l3 3"
    if (icon === "moon" || icon === "idle") return "M12 3c.132 0 .263 .003 .393 .01a7.5 7.5 0 0 0 8.598 8.597a9 9 0 1 1 -8.991 -8.607z"
    if (icon === "lock") return "M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2z M8 11v-4a4 4 0 1 1 8 0v4"
    if (icon === "logout") return "M14 8v-2a2 2 0 0 0 -2 -2h-7a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2 -2v-2 M9 12h12 M18 9l3 3l-3 3"
    if (icon === "power") return "M7 6a7.75 7.75 0 1 0 10 0 M12 4l0 8"
    if (icon === "wifi") return "M12 18l.01 0 M9.172 15.172a4 4 0 0 1 5.656 0 M6.343 12.343a8 8 0 0 1 11.314 0 M3.515 9.515a12 12 0 0 1 16.97 0"
    if (icon === "bluetooth") return "M7 7l10 10l-5 4v-18l5 4l-10 10"
    if (icon === "volume") return "M15 8a5 5 0 0 1 0 8 M17.7 5a9 9 0 0 1 0 14 M6 15h-2a1 1 0 0 1 -1 -1v-4a1 1 0 0 1 1 -1h2l4 -4v14z"
    if (icon === "video" || icon === "record") return "M15 10l4.553 -2.276a1 1 0 0 1 1.447 .894v6.764a1 1 0 0 1 -1.447 .894l-4.553 -2.276v-4z M3 6m0 2a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2z"
    if (icon === "plus") return "M12 5v14 M5 12h14"
    if (icon === "check") return "M5 12l5 5l10 -10"
    if (icon === "x" || icon === "close") return "M18 6l-12 12 M6 6l12 12"
    if (icon === "arrow-left" || icon === "back") return "M5 12h14 M5 12l6 6 M5 12l6 -6"
    if (icon === "arrow-up") return "M12 5v14 M12 5l-6 6 M12 5l6 6"
    if (icon === "arrow-down") return "M12 19v-14 M12 19l-6 -6 M12 19l6 -6"
    if (icon === "chevron-right") return "M9 6l6 6l-6 6"
    if (icon === "player-play") return "M7 4v16l13 -8z"
    if (icon === "player-pause") return "M6 5h4v14h-4z M14 5h4v14h-4z"
    return ""
  }

  Shape {
    visible: root.valid
    anchors.centerIn: parent
    width: 24
    height: 24
    scale: Math.min(root.width, root.height) / 24
    transformOrigin: Item.Center
    asynchronous: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.filled ? "transparent" : root.color
      strokeWidth: root.filled ? 0 : root.strokeWidth
      fillColor: root.filled ? root.color : "transparent"
      fillRule: root.filled ? ShapePath.OddEvenFill : ShapePath.WindingFill
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: root.pathData }
    }
  }
}
