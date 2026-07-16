import Quickshell.Io
import QtQuick

Item {
  id: root

  property var queue: []
  property string currentCommand: ""
  property string stdoutText: ""
  property string stderrText: ""
  property var failureQueue: []

  signal queueDrained()

  function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function failureText() {
    var detail = stderrText.trim()
    if (detail === "") detail = stdoutText.trim()
    if (detail === "") detail = "Command exited without output."

    return detail.length > 220 ? detail.substring(0, 217) + "..." : detail
  }

  function run(command) {
    if (!command) return

    queue = queue.concat([command])
    drain()
  }

  function shouldDetach(command) {
    return command.indexOf("foot ") === 0 || command.indexOf("xdg-terminal-exec ") === 0
  }

  function drain() {
    if (proc.running || queue.length === 0) return

    var command = queue[0]
    queue = queue.slice(1)
    currentCommand = command
    stdoutText = ""
    stderrText = ""

    proc.command = shouldDetach(command) ? ["setsid", "-f", "bash", "-c", command] : ["bash", "-c", command]
    proc.running = true
  }

  function notifyFailure(message) {
    failureQueue = failureQueue.concat([message])
    drainFailures()
  }

  function drainFailures() {
    if (failProc.running || failureQueue.length === 0) return

    var message = failureQueue[0]
    failureQueue = failureQueue.slice(1)
    failProc.command = ["notify-send", "Lacuna command failed", message]
    failProc.running = true
  }

  Process {
    id: proc

    stdout: SplitParser {
      onRead: function(data) {
        root.stdoutText += data + "\n"
      }
    }

    stderr: SplitParser {
      onRead: function(data) {
        root.stderrText += data + "\n"
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        var message = root.failureText()
        console.warn("lacuna command failed:", exitCode, message)
        root.notifyFailure(message)
      }

      root.drain()
      if (!proc.running && root.queue.length === 0) root.queueDrained()
    }
  }

  Process {
    id: failProc

    onExited: root.drainFailures()
  }
}
