import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.network"
  property var settings: ({})
  property var networkService: null
  property bool flyoutOpen: false
  readonly property bool opened: flyoutOpen

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property string kind: networkService ? networkService.kind : "disconnected"
  readonly property string label: networkService ? networkService.label : ""
  readonly property int signalStrength: networkService ? networkService.signalStrength : -1
  readonly property string frequency: networkService ? networkService.frequency : ""
  readonly property color moduleColor: colorProfile.statusColor(kind === "disconnected" ? "warning" : "normal", "network")
  readonly property int intervalMs: Math.max(1000, Number(setting("interval", 5000)))
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property string icon: networkService ? networkService.icon : "󰤮"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() {
    if (networkService && typeof networkService.refresh === "function") networkService.refresh(true)
  }

  function close() {
    flyoutOpen = false
  }

  function open() {
    flyoutOpen = true
    refresh()
  }

  function tooltip() {
    if (networkService && typeof networkService.tooltip === "function") return networkService.tooltip()
    var title = kind === "wifi" ? "Wi-Fi" : kind === "ethernet" ? "Ethernet" : "Network disconnected"
    var body = label ? label : "No active connection"
    if (kind === "wifi" && signalStrength >= 0) body += "<br/>Signal: " + signalStrength + "%"
    if (frequency) body += "<br/>" + frequency
    return title + "<br/>" + body
  }

  function resolveService() {
    if (networkService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("lacuna.network")
      if (ensured) {
        networkService = ensured
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("lacuna.network")
      if (existing) networkService = existing
    }
  }

  function togglePanel() {
    flyoutOpen = !flyoutOpen
    if (flyoutOpen) refresh()
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "network"
  }

  MotionTokens {
    id: motionTokens
  }

  Component.onCompleted: {
    resolveService()
    refresh()
  }
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.networkService === null
    repeat: true
    onTriggered: root.resolveService()
  }

  Timer {
    interval: root.intervalMs
    running: root.networkService !== null
    repeat: true
    onTriggered: root.refresh()
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
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton && root.networkService) root.networkService.toggleWifi()
        else if (mouse.button === Qt.MiddleButton) root.refresh()
        else {
          root.bar.hideTooltip(root)
          root.togglePanel()
        }
      }
    }
  }

  NetworkFlyout {
    id: flyout
    anchorItem: root
    owner: root
    bar: root.bar
    service: root.networkService
    accentColor: root.moduleColor
    open: root.flyoutOpen
  }
}
