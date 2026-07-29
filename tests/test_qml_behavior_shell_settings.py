import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "requires quickshell and an active Wayland session")
class ShellSettingsBehaviorTests(unittest.TestCase):
    def test_window_rounding_modes_update_state_and_commands(self):
        qml = f'''import QtQuick
import Quickshell

ShellRoot {{
  id: testRoot
  property var service: null
  property var commands: []

  QtObject {{
    id: runner
    function run(command) {{ testRoot.commands = testRoot.commands.concat([command]) }}
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.shell-settings/Service.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      quitTimer.start()
      return
    }}
    service = component.createObject(this, {{ commandRunner: runner }})
    service.setWindowRoundingMode("square")
    var square = {{
      mode: service.state.hypr.windowRoundingMode,
      rounding: service.state.hypr.rounding,
      command: commands[commands.length - 1]
    }}
    service.setWindowRoundingMode("rounded")
    var rounded = {{
      mode: service.state.hypr.windowRoundingMode,
      rounding: service.state.hypr.rounding,
      command: commands[commands.length - 1]
    }}
    service.setWindowRoundingMode("theme")
    var theme = {{
      mode: service.state.hypr.windowRoundingMode,
      command: commands[commands.length - 1]
    }}
    console.log("BEHAVE " + JSON.stringify({{ square: square, rounded: rounded, theme: theme }}))
    quitTimer.start()
  }}

  Timer {{ id: quitTimer; interval: 20; onTriggered: Qt.quit() }}
}}
'''
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        rows = parse_behave(output)
        self.assertTrue(rows, output)
        result = rows[-1]

        self.assertEqual("square", result["square"]["mode"])
        self.assertEqual(0, result["square"]["rounding"])
        self.assertIn("rounding = 0", result["square"]["command"])

        self.assertEqual("rounded", result["rounded"]["mode"])
        self.assertEqual(12, result["rounded"]["rounding"])
        self.assertIn("rounding = 12", result["rounded"]["command"])

        self.assertEqual("theme", result["theme"]["mode"])
        self.assertIn("rm -f", result["theme"]["command"])
        self.assertIn("window-no-gaps.lua", result["theme"]["command"])
        self.assertIn("Preserve disabled gaps", result["theme"]["command"])
