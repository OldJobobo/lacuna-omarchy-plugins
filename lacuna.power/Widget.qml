import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.power"
  property var settings: ({})
  property var powerService: null
  property bool flyoutOpen: false
  readonly property bool opened: flyoutOpen

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool hasBattery: powerService ? powerService.hasBattery : false
  readonly property bool low: powerService ? powerService.low : false
  readonly property bool charging: powerService ? powerService.charging : false
  readonly property color moduleColor: colorProfile.statusColor(low ? "critical" : charging ? "active" : "normal", "power")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string icon: powerService ? powerService.icon : ""

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function tooltip() {
    if (powerService && typeof powerService.tooltip === "function") return powerService.tooltip()
    return "Power"
  }

  function resolveService() {
    if (powerService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("lacuna.power")
      if (ensured) {
        powerService = ensured
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("lacuna.power")
      if (existing) powerService = existing
    }
  }

  function close() {
    flyoutOpen = false
  }

  function open() {
    flyoutOpen = true
  }

  function togglePanel() {
    flyoutOpen = !flyoutOpen
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "power"
  }

  MotionTokens {
    id: motionTokens
  }

  Component.onCompleted: resolveService()
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.powerService === null
    repeat: true
    onTriggered: root.resolveService()
  }

  Item {
    id: button

    property real hoverReveal: mouseArea.containsMouse || mouseArea.pressed ? 1 : 0

    width: root.barSize
    height: root.barSize
    implicitWidth: width
    implicitHeight: height

    Rectangle {
      anchors.fill: parent
      color: root.moduleColor
      opacity: button.hoverReveal * 0.07
    }

    Text {
      anchors.centerIn: parent
      text: root.icon
      color: root.moduleColor
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: root.topbarIconSize
      renderType: Text.NativeRendering
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton && root.powerService) root.powerService.refresh()
        else {
          root.bar.hideTooltip(root)
          root.togglePanel()
        }
      }
    }
  }

  PowerFlyout {
    anchorItem: root
    owner: root
    bar: root.bar
    service: root.powerService
    accentColor: root.moduleColor
    open: root.flyoutOpen
  }
}
