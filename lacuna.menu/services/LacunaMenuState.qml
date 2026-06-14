import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/lacuna"
  readonly property string stateFile: stateDir + "/menu.state"
  property bool open: false
  property var stack: ["main"]
  readonly property string currentView: stack.length > 0 ? stack[stack.length - 1] : "main"

  function load() {
    stateFileView.reload()
  }

  function save() {
    stateFileView.setText(savePayload())
  }

  function savePayload() {
    // Open/closed is runtime-only. Persisting "open" can make the plugin host
    // revive the sidebar on a shell restart, sometimes on the wrong monitor.
    var lines = ["closed"].concat(stack)
    return lines.join("\n") + "\n"
  }

  function show() {
    open = true
    save()
  }

  function close() {
    open = false
    stack = ["main"]
    save()
  }

  function toggle() {
    if (open) close()
    else show()
  }

  function push(view) {
    if (!view) return
    stack = stack.concat([view])
    save()
  }

  function back() {
    if (stack.length <= 1) {
      close()
      return
    }

    stack = stack.slice(0, stack.length - 1)
    save()
  }

  Component.onCompleted: load()

  FileView {
    id: stateFileView

    path: root.stateFile
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: {
      var lines = text().trim().split(/\r?\n/)
      var wasOpen = root.open
      var restoredStack = lines.slice(1).filter(function(view) {
        return view !== ""
      })

      root.stack = restoredStack.length > 0 ? restoredStack : ["main"]
      root.open = wasOpen
    }
    onLoadFailed: {
      root.stack = ["main"]
    }
  }
}
