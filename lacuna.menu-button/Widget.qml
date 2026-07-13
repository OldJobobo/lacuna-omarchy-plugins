import QtQuick
import QtQuick.Effects
import Quickshell

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.menu-button"
  property var settings: ({})

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("menu", foreground)
  readonly property string tooltipText: String(setting("tooltip", "Lacuna"))
  readonly property int topbarIconSize: barSize >= 30 ? 15 : 13
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/circle-dotted-letter-l.svg")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function shellQuote(value) {
    if (bar && bar.shellQuote) return bar.shellQuote(value)
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function omarchyPath() {
    if (bar && bar.omarchyPath) return bar.omarchyPath
    return Quickshell.env("OMARCHY_PATH") || (Quickshell.env("HOME") + "/.local/share/omarchy")
  }

  function shellIpcCommand(target, method, args) {
    var path = omarchyPath()
    var command = "OMARCHY_PATH=" + shellQuote(path) + " omarchy shell"
      + " " + shellQuote(target) + " " + shellQuote(method)
    for (var i = 0; i < args.length; i++) command += " " + shellQuote(args[i])
    return command
  }

  function openMenu() {
    if (bar && typeof bar.activateInteraction === "function") bar.activateInteraction(root, moduleName)
    if (bar && bar.lacunaFrameHost === true && typeof bar.toggleMenu === "function") {
      bar.toggleMenu("{}")
      return
    }
    if (bar) bar.run(shellIpcCommand("shell", "toggle", ["lacuna.menu", "{}"]))
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "menu"
  }

  MotionTokens {
    id: motionTokens
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    BarHoverSeam {
      anchors.fill: parent
      reveal: parent.hoverReveal
      seam: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
      accent: colorProfile.accent
    }

    width: root.barSize
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.07
    }

    Image {
      anchors.centerIn: parent
      source: root.iconSource
      width: root.topbarIconSize
      height: root.topbarIconSize
      sourceSize.width: width
      sourceSize.height: height
      smooth: true
      mipmap: true
      opacity: 0.88 + button.hoverReveal * 0.12
      layer.enabled: true
      layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: root.moduleColor
      }
    }

    Behavior on hoverReveal {
      NumberAnimation {
        duration: motionTokens.hoverDuration
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      onEntered: if (bar && root.tooltipText) bar.showTooltip(root, root.tooltipText)
      onExited: if (bar) bar.hideTooltip(root)
      onClicked: root.openMenu()
    }
  }
}
