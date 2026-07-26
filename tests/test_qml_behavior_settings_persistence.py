import json
import os
import tempfile
import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "requires quickshell and an active Wayland session")
class SettingsPersistenceBehaviorTests(unittest.TestCase):
    def test_failed_nightlight_apply_is_not_persisted_as_success(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            refresh_marker = tmp / "indicator-refresh"

            self._write_executable(bin_dir / "pgrep", "#!/bin/sh\nexit 0\n")
            self._write_executable(bin_dir / "hyprctl", "#!/bin/sh\nexit 7\n")
            self._write_executable(
                bin_dir / "omarchy-shell",
                f"#!/bin/sh\nprintf refresh > {refresh_marker}\nexit 0\n",
            )
            self._write_executable(
                bin_dir / "omarchy",
                "#!/bin/sh\nprintf '{\"enabled\":false,\"temperature\":6000}\\n'\n",
            )

            qml = f'''import QtQuick
import Quickshell

ShellRoot {{
  property var service: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.settings-persistence/Service.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    service = component.createObject(this)
    kickoff.start()
  }}

  Timer {{
    id: kickoff
    interval: 250
    repeat: false
    onTriggered: {{
      service.haveCurrentNightlight = false
      service.nightlightRestoreComplete = false
      service.lastError = ""
      service.applyNightlightEnabled(true, "behavior-test")
      resultTimer.start()
    }}
  }}

  Timer {{
    id: resultTimer
    interval: 50
    repeat: true
    property int attempts: 0
    onTriggered: {{
      attempts += 1
      if (service && !service.applyingNightlight) {{
        console.log("BEHAVE " + JSON.stringify({{
          status: service.lastStatus,
          error: service.lastError,
          haveCurrent: service.haveCurrentNightlight,
          restoreComplete: service.nightlightRestoreComplete
        }}))
        Qt.quit()
      }} else if (attempts > 100) {{
        console.log("BEHAVE_ERR apply timeout")
        Qt.quit()
      }}
    }}
  }}
}}
'''
            output = run_quickshell(
                qml,
                config_home=tmp / "config",
                env_overrides={
                    "PATH": f"{bin_dir}:{os.environ.get('PATH', '/usr/bin')}",
                    "XDG_STATE_HOME": str(tmp / "state"),
                },
            )
            require_no_qml_errors(output)
            rows = parse_behave(output)
            self.assertTrue(rows, output)
            result = rows[-1]
            self.assertEqual(result["status"], "failed")
            self.assertIn("nightlight enable failed", result["error"])
            self.assertFalse(result["haveCurrent"])
            self.assertFalse(result["restoreComplete"])
            self.assertTrue(refresh_marker.exists(), output)

    @staticmethod
    def _write_executable(path: Path, content: str) -> None:
        path.write_text(content, encoding="utf-8")
        path.chmod(0o755)


if __name__ == "__main__":
    unittest.main()
