import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: "lacuna.idle-inhibitor"
  property var settings: ({})
  property var idleService: null

  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property bool serviceLoaded: idleService !== null
  readonly property bool stayAwake: idleService ? idleService.stayAwake : false
  readonly property bool idleEnabled: idleService ? idleService.idleEnabled : !stayAwake
  readonly property color moduleColor: colorProfile.statusColor(stayAwake ? "active" : "normal", "idle")
  readonly property int topbarIconSize: barSize >= 30 ? 16 : 14
  readonly property bool showInactive: boolSetting("showInactive", false)

  visible: stayAwake || showInactive || mouseArea.containsMouse
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function boolSetting(name, fallback) {
    var value = setting(name, fallback)
    return value === true || String(value).toLowerCase() === "true"
  }

  function tooltip() {
    return stayAwake ? "Stay Awake active<br/>Click to allow idle lock" : "Idle locking enabled<br/>Click to stay awake"
  }

  function resolveService() {
    if (idleService) return
    if (bar && bar.shell && typeof bar.shell.ensureService === "function") {
      var ensured = bar.shell.ensureService("omarchy.idle")
      if (ensured) {
        idleService = ensured
        return
      }
    }
    if (bar && bar.shell && typeof bar.shell.serviceFor === "function") {
      var existing = bar.shell.serviceFor("omarchy.idle")
      if (existing) idleService = existing
    }
  }

  function toggleIdle() {
    if (idleService && typeof idleService.setIdleEnabled === "function") {
      idleService.setIdleEnabled(!idleEnabled)
      return
    }
    if (bar) bar.run("omarchy toggle idle")
  }

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "idle"
  }

  MotionTokens {
    id: motionTokens
  }

  Component.onCompleted: resolveService()
  onBarChanged: resolveService()

  Timer {
    interval: 500
    running: root.idleService === null
    repeat: true
    onTriggered: root.resolveService()
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

    Text {
      anchors.centerIn: parent
      text: "Zz"
      color: root.moduleColor
      opacity: root.stayAwake || mouseArea.containsMouse ? 1 : 0.55
      font.family: root.bar ? root.bar.fontFamily : "Hack Nerd Font Propo"
      font.pixelSize: Math.max(9, root.topbarIconSize - 3)
      font.bold: true
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
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
      onExited: if (root.bar) root.bar.hideTooltip(root)
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.MiddleButton) root.resolveService()
        else root.toggleIdle()
      }
    }
  }
}
