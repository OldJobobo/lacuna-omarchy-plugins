import QtQuick
import QtQuick.Effects
import Quickshell

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-menu-button"
  property var settings: ({})

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color moduleColor: colorProfile.roleColor("menu", foreground)
  readonly property string tooltipText: String(setting("tooltip", "Lacuna"))
  readonly property url iconSource: Qt.resolvedUrl("assets/tabler/layout-sidebar-left-expand-filled.svg")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function openMenu() {
    if (bar) bar.run("omarchy-shell-ipc shell toggle omarchy.lacuna-menu '{}'")
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "menu"
  }

  Item {
    id: button

    width: root.barSize
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Image {
      anchors.centerIn: parent
      source: root.iconSource
      width: 15
      height: 15
      sourceSize.width: width
      sourceSize.height: height
      smooth: true
      mipmap: true
      opacity: mouseArea.containsMouse ? 1.0 : 0.9
      layer.enabled: true
      layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: root.moduleColor
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
