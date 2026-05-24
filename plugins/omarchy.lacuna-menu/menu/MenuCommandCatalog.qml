import Quickshell
import QtQuick

Item {
  id: root

  property string lacunaPath: ""

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function shellDoubleQuote(value) {
    return "\"" + String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$").replace(/`/g, "\\`") + "\""
  }

  function hyprExec(command) {
    return "hyprctl dispatch " + shellDoubleQuote("hl.dsp.exec_cmd([[" + command + "]])")
  }

  function shellIpcCommand(target, method) {
    var path = Quickshell.env("OMARCHY_PATH") || ((Quickshell.env("HOME") || "") + "/.local/share/omarchy")
    return "OMARCHY_PATH=" + shellQuote(path) + " " + shellQuote(path + "/bin/omarchy-shell") + " " + shellQuote(target) + " " + shellQuote(method)
  }

  function terminalCommand(command, title, holdOpen) {
    var terminalBody = command
    if (holdOpen) {
      terminalBody = command + "; status=$?; printf '\\nCommand exited with status %s. Press Enter to close...' \"$status\"; read -r _; exit \"$status\""
    }
    return "foot --app-id=org.omarchy.terminal --title=" + shellQuote(title || "Lacuna") + " -e bash -lc " + shellQuote(terminalBody)
  }

  function terminalLaunchCommand(command, title) {
    return hyprExec("foot --app-id=org.omarchy.terminal --title=" + shellQuote(title || "Lacuna") + " -e bash -lc " + shellQuote("exec " + command))
  }

  function desktopExecCommand(execLine) {
    var command = String(execLine || "").trim()
    if (command === "") return ""

    command = command.replace(/%%/g, "__LACUNA_PERCENT__")
    command = command.replace(/%[fFuUdDnNickvm]/g, "")
    command = command.replace(/__LACUNA_PERCENT__/g, "%")
    return command.trim()
  }

  function openTerminalCommand() {
    return hyprExec("omarchy launch terminal")
  }

  function restartLacunaCommand() {
    return "omarchy restart shell"
  }

  function omarchyShellPath() {
    var omarchyPath = Quickshell.env("OMARCHY_PATH") || ((Quickshell.env("HOME") || "") + "/.local/share/omarchy")
    return omarchyPath + "/shell"
  }

  function openLogCommand() {
    return terminalCommand("quickshell log --path " + shellQuote(omarchyShellPath()) + " --tail 200 --newest", "Omarchy Shell Log", false)
  }

  function editPluginCommand() {
    return terminalCommand("cd " + shellQuote(root.lacunaPath) + " && ${EDITOR:-nvim} .", "Lacuna Plugin", false)
  }

  function editShellConfigCommand() {
    var path = (Quickshell.env("HOME") || "") + "/.config/omarchy/shell.json"
    return terminalCommand("${EDITOR:-nvim} " + shellQuote(path), "Omarchy Shell Config", false)
  }

  function fontListCommand() {
    return terminalCommand("omarchy font current; printf '\\n'; omarchy font list; printf '\\nCommand exited. Press Enter to close...'; read -r _", "Omarchy Fonts", false)
  }

  function debugCommand() {
    return terminalCommand("omarchy debug --print --no-sudo; printf '\\nCommand exited. Press Enter to close...'; read -r _", "Omarchy Debug", false)
  }

  function debugIdleCommand() {
    return terminalCommand("omarchy debug idle; printf '\\nCommand exited. Press Enter to close...'; read -r _", "Omarchy Idle Debug", false)
  }

  function refreshThemeBackgroundCommand(themeVariable) {
    var variable = String(themeVariable || "theme")
    return "{ fixer=\"$HOME/.config/omarchy/plugins/omarchy.lacuna-theme-preloader/scripts/refresh-theme-background.sh\"; [ -x \"$fixer\" ] && \"$fixer\" \"$" + variable + "\" || true; }"
  }

  function switchThemeCommand() {
    return "theme=$(omarchy theme switcher); [ -n \"$theme\" ] && omarchy theme set \"$theme\" && " + refreshThemeBackgroundCommand("theme")
  }

  function switchBackgroundCommand() {
    return "background=$(omarchy theme bg-switcher); [ -n \"$background\" ] && omarchy theme bg set \"$background\" && " + applyCurrentBackgroundCommand()
  }

  function applyCurrentBackgroundCommand() {
    return "current=$(readlink -f \"$HOME/.config/omarchy/current/background\" 2>/dev/null || true); [ -n \"$current\" ] && omarchy-shell -q background setInstant \"$current\""
  }
}
