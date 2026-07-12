import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


ROOT = Path(__file__).resolve().parents[1]


class QmlAccessibilitySourceContracts(unittest.TestCase):
    def test_shared_buttons_are_keyboard_focusable_and_accessible(self):
        for relative in [
            "lacuna.menu/components/LacunaIconButton.qml",
            "lacuna.menu/menu/MenuRailButton.qml",
        ]:
            qml = (ROOT / relative).read_text(encoding="utf-8")
            self.assertIn("activeFocusOnTab: !disabled", qml, relative)
            self.assertIn("Accessible.role: Accessible.Button", qml, relative)
            self.assertIn("Accessible.name: accessibleName", qml, relative)
            self.assertIn("Accessible.onPressAction: root.activate()", qml, relative)
            self.assertIn("Keys.onReturnPressed", qml, relative)
            self.assertIn("Keys.onEnterPressed", qml, relative)
            self.assertIn("Keys.onSpacePressed", qml, relative)


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlAccessibilityBehaviorTests(unittest.TestCase):
    def test_shared_icon_button_exposes_focus_and_accessibility_contract(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: shell
  property var button: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/components/LacunaIconButton.qml')}")
    button = component.createObject(shell, {{ accessibleName: "Close settings", icon: "x" }})
    button.forceActiveFocus()
    console.log("BEHAVE " + JSON.stringify({{
      name: button.Accessible.name,
      focusable: button.Accessible.focusable,
      tab: button.activeFocusOnTab
    }}))
    quitTimer.start()
  }}

  Timer {{ id: quitTimer; interval: 20; onTriggered: Qt.quit() }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        row = parse_behave(output)[0]
        self.assertEqual(row["name"], "Close settings")
        self.assertTrue(row["focusable"])
        self.assertTrue(row["tab"])


if __name__ == "__main__":
    unittest.main()
