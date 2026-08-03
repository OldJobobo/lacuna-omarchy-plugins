import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class FullscreenGuardBehaviorTests(unittest.TestCase):
    def test_workspace_fullscreen_shapes_are_normalized(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  Loader {{
    id: guardLoader
    source: "{qml_url('shared/qml/FullscreenGuard.qml')}"
    onLoaded: settle.start()
  }}

  Timer {{
    id: settle
    interval: 20
    onTriggered: {{
      var guard = guardLoader.item
      console.log("BEHAVE " + JSON.stringify({{
        missing: guard.workspaceHasFullscreen(null),
        direct: guard.workspaceHasFullscreen({{ hasFullscreen: true }}),
        ipcLower: guard.workspaceHasFullscreen({{ lastIpcObject: {{ hasfullscreen: true }} }}),
        ipcCamel: guard.workspaceHasFullscreen({{ lastIpcObject: {{ hasFullscreen: true }} }}),
        ipcNumber: guard.workspaceHasFullscreen({{ lastIpcObject: {{ fullscreen: 2 }} }}),
        ordinary: guard.workspaceHasFullscreen({{ hasFullscreen: false, lastIpcObject: {{ fullscreen: 0 }} }})
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]
        self.assertFalse(result["missing"])
        self.assertTrue(result["direct"])
        self.assertTrue(result["ipcLower"])
        self.assertTrue(result["ipcCamel"])
        self.assertTrue(result["ipcNumber"])
        self.assertFalse(result["ordinary"])


if __name__ == "__main__":
    unittest.main()
