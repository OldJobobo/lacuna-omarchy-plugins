import Quickshell.Hyprland
import QtQuick

Item {
  id: root

  property int revision: 0

  visible: false
  width: 0
  height: 0

  function workspaceHasFullscreen(workspace) {
    if (!workspace) return false
    if (workspace.hasFullscreen === true) return true
    var ipc = workspace.lastIpcObject || {}
    return ipc.hasfullscreen === true
      || ipc.hasFullscreen === true
      || Number(ipc.fullscreen || 0) > 0
  }

  function activeWorkspaceForScreen(screen) {
    root.revision
    var monitor = screen && Hyprland.monitorFor ? Hyprland.monitorFor(screen) : null
    if (monitor && monitor.activeWorkspace) return monitor.activeWorkspace
    return screen ? null : (Hyprland.focusedWorkspace || null)
  }

  function activeOnScreen(screen) {
    return workspaceHasFullscreen(activeWorkspaceForScreen(screen))
  }

  function refresh() {
    if (Hyprland.refreshWorkspaces) Hyprland.refreshWorkspaces()
    if (Hyprland.refreshToplevels) Hyprland.refreshToplevels()
    root.revision += 1
  }

  Timer {
    id: refreshTimer
    interval: 40
    repeat: false
    onTriggered: root.refresh()
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      var name = String(event && event.name || "")
      if (name === "fullscreen" || name.indexOf("workspace") >= 0
          || name.indexOf("window") >= 0 || name === "focusedmon")
        refreshTimer.restart()
    }

    function onFocusedWorkspaceChanged() {
      root.revision += 1
    }
  }

  Connections {
    target: Hyprland.workspaces

    function onValuesChanged() {
      root.revision += 1
    }
  }
}
