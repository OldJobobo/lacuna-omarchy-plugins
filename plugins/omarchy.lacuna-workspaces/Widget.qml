import QtQuick
import Quickshell.Hyprland
import "components"

Item {
  id: root

  property var bar: null
  property string moduleName: "omarchy.lacuna-workspaces"
  property var settings: ({})
  property int workspaceSerial: 0
  property int hoveredWorkspace: 0

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property color foreground: bar ? bar.foreground : "#d8dee9"
  readonly property color background: bar ? bar.background : "#101315"
  readonly property color urgent: colorProfile.roleColor("urgent", bar ? bar.urgent : "#d42b5b")
  readonly property color activeColor: colorProfile.roleColor("active", colorProfile.accent)
  readonly property color occupiedColor: colorProfile.roleColor("occupied", colorProfile.occupied)
  readonly property color emptyColor: colorProfile.empty
  readonly property color hoverColor: colorProfile.hover
  readonly property string designStyle: colorProfile.designStyle
  readonly property int workspaceCount: Math.max(1, Math.min(10, Number(setting("workspaceCount", 7))))
  readonly property bool showDynamicExtra: setting("showDynamicExtra", false) === true

  implicitWidth: workspaceGrid.implicitWidth
  implicitHeight: workspaceGrid.implicitHeight

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function workspaceFor(id) {
    workspaceSerial

    var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
    for (var i = 0; i < workspaces.length; i++) {
      if (Number(workspaces[i].id) === Number(id)) return workspaces[i]
    }

    return null
  }

  function workspaceWindowCount(workspace) {
    if (!workspace) return 0
    if (workspace.toplevels && workspace.toplevels.values) return Number(workspace.toplevels.values.length || 0)
    if (workspace.lastIpcObject) return Number(workspace.lastIpcObject.windows || 0)
    return 0
  }

  function workspaceOccupied(id) {
    var workspace = workspaceFor(id)
    return !!workspace && workspaceWindowCount(workspace) > 0
  }

  function workspaceUrgent(id) {
    var workspace = workspaceFor(id)
    return !!workspace && workspace.urgent
  }

  function workspaceColor(id) {
    if (designStyle === "omarchy") return foreground
    if (workspaceUrgent(id)) return urgent
    if (activeWorkspace() === id) return activeColor
    if (workspaceOccupied(id)) return occupiedColor
    return emptyColor
  }

  function workspaceText(id) {
    if (designStyle === "omarchy" && activeWorkspace() === id) return "󱓻"
    return String(id === 10 ? 0 : id)
  }

  function workspaceSpacing() {
    if (designStyle === "material") return vertical ? 4 : 5
    if (designStyle === "omarchy") return 2
    return vertical ? 2 : 2
  }

  function activeWorkspace() {
    workspaceSerial
    return Hyprland.focusedWorkspace ? Number(Hyprland.focusedWorkspace.id) : 1
  }

  function workspaceIds() {
    workspaceSerial

    var ids = []
    for (var i = 1; i <= workspaceCount; i++) ids.push(i)

    if (showDynamicExtra) {
      var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
      for (var j = 0; j < workspaces.length; j++) {
        var id = Number(workspaces[j].id)
        if (id > 0 && ids.indexOf(id) === -1) ids.push(id)
      }
      ids.sort(function(left, right) { return left - right })
    }

    return ids
  }

  function switchToWorkspace(workspace) {
    Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + workspace + " })" : "workspace " + workspace)
  }

  function refreshWorkspaceState() {
    Hyprland.refreshWorkspaces()
    workspaceSerial += 1
  }

  function tooltipFor(id) {
    var parts = ["Workspace " + id]
    if (activeWorkspace() === id) parts.push("Active")
    if (workspaceOccupied(id)) parts.push(workspaceWindowCount(workspaceFor(id)) + " windows")
    else parts.push("Empty")
    if (workspaceUrgent(id)) parts.push("Urgent")
    return parts.join("<br/>")
  }

  Component.onCompleted: refreshWorkspaceState()

  ColorProfile {
    id: colorProfile
    bar: root.bar
    widgetSettings: root.settings
    role: "workspaces"
  }

  Timer {
    id: workspaceRefreshTimer
    interval: 80
    repeat: false
    onTriggered: root.refreshWorkspaceState()
  }

  Timer {
    id: hoverRestoreTimer
    interval: 120
    repeat: false
    onTriggered: root.hoveredWorkspace = 0
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      var name = event.name
      if (name.indexOf("workspace") >= 0 || name === "focusedmon" || name.indexOf("window") >= 0 || name === "urgent") {
        workspaceRefreshTimer.restart()
      }
    }

    function onFocusedWorkspaceChanged() {
      root.workspaceSerial += 1
    }
  }

  Connections {
    target: Hyprland.workspaces

    function onValuesChanged() {
      root.workspaceSerial += 1
    }
  }

  Grid {
    id: workspaceGrid

    columns: root.vertical ? 1 : root.workspaceIds().length
    rows: root.vertical ? root.workspaceIds().length : 1
    rowSpacing: root.vertical ? root.workspaceSpacing() : 0
    columnSpacing: root.vertical ? 0 : root.workspaceSpacing()

    Repeater {
      model: root.workspaceIds()

      LacunaWorkspaceButton {
        required property int modelData

        readonly property int workspaceId: modelData
        readonly property bool workspaceActive: root.activeWorkspace() === workspaceId
        readonly property bool workspaceOccupied: root.workspaceOccupied(workspaceId)

        text: root.workspaceText(workspaceId)
        designStyle: root.designStyle
        barSize: root.barSize
        vertical: root.vertical
        foreground: root.workspaceColor(workspaceId)
        neutralForeground: root.foreground
        background: root.background
        accent: root.workspaceColor(workspaceId)
        hoverColor: root.hoverColor
        active: workspaceActive
        activeExpanded: workspaceActive && (root.hoveredWorkspace === 0 || root.hoveredWorkspace === workspaceId)
        occupied: workspaceOccupied
        urgent: root.workspaceUrgent(workspaceId)
        accentText: workspaceOccupied || workspaceActive
        fontFamily: bar ? bar.fontFamily : "BlexMono Nerd Font Propo"
        tooltip: root.tooltipFor(workspaceId)
        tooltipHost: root.bar
        onHoveredChanged: {
          if (hovered) {
            hoverRestoreTimer.stop()
            root.hoveredWorkspace = workspaceId
          } else if (root.hoveredWorkspace === workspaceId) {
            hoverRestoreTimer.restart()
          }
        }
        onTriggered: root.switchToWorkspace(workspaceId)
      }
    }
  }
}
