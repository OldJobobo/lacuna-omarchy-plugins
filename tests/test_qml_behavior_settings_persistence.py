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

    def test_state_saves_are_destination_local_and_latest_write_wins(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            self._write_executable(
                bin_dir / "omarchy",
                "#!/bin/sh\ncase \"$*\" in *nightlight*) printf '{\"enabled\":false,\"temperature\":6000}\\n' ;; *) printf '{\"enabled\":true}\\n' ;; esac\n",
            )
            self._write_executable(bin_dir / "omarchy-shell", "#!/bin/sh\nexit 0\n")
            self._write_executable(bin_dir / "pgrep", "#!/bin/sh\nexit 0\n")
            self._write_executable(bin_dir / "hyprctl", "#!/bin/sh\nexit 0\n")

            qml = f'''import QtQuick
import Quickshell

ShellRoot {{
  property var service: null
  property bool issued: false

  function issue() {{
    if (issued || !service || !service.loaded) return
    issued = true
    service.manageIdle = true
    service.manageNightlight = false
    service.desiredIdleEnabled = false
    service.saveState()
    service.desiredIdleEnabled = true
    service.saveState()
    service.desiredIdleEnabled = false
    service.saveState()
    settle.start()
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.settings-persistence/Service.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    service = component.createObject(this)
    Qt.callLater(issue)
  }}

  Timer {{
    id: kickoff
    interval: 20
    repeat: true
    running: true
    onTriggered: issue()
  }}

  Timer {{
    id: settle
    interval: 20
    repeat: true
    property int attempts: 0
    onTriggered: {{
      attempts += 1
      if (service.persistenceState === "saved"
          && service.confirmedSaveRevision === service.requestedSaveRevision
          && service.requestedSaveRevision >= 3) {{
        console.log("BEHAVE " + JSON.stringify({{
          state: service.persistenceState,
          requested: service.requestedSaveRevision,
          confirmed: service.confirmedSaveRevision,
          queued: service.queuedSaveRevision,
          idle: service.desiredIdleEnabled
        }}))
        Qt.quit()
      }} else if (attempts > 300) {{
        console.log("BEHAVE_ERR save timeout " + service.persistenceState)
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
                timeout=12,
            )
            require_no_qml_errors(output)
            row = parse_behave(output)[-1]
            self.assertEqual("saved", row["state"], output[-2000:])
            self.assertEqual(row["requested"], row["confirmed"])
            self.assertEqual(0, row["queued"])
            self.assertFalse(row["idle"])
            state_file = tmp / "state/omarchy/lacuna/settings-persistence.json"
            payload = json.loads(state_file.read_text(encoding="utf-8"))
            self.assertFalse(payload["idleEnabled"])
            self.assertEqual(0o600, state_file.stat().st_mode & 0o777)
            self.assertFalse(list(state_file.parent.glob(".settings-persistence.json.tmp.*")))

    def test_failed_state_save_is_retryable_after_destination_recovers(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            blocked_state = tmp / "blocked-state"
            blocked_state.write_text("not-a-directory", encoding="utf-8")
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            self._write_executable(
                bin_dir / "omarchy",
                "#!/bin/sh\ncase \"$*\" in *nightlight*) printf '{\"enabled\":false,\"temperature\":6000}\\n' ;; *) printf '{\"enabled\":true}\\n' ;; esac\n",
            )

            qml = f'''import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {{
  property var service: null
  property bool issued: false
  property bool observedFailure: false

  function issue() {{
    if (issued || !service || !service.loaded) return
    issued = true
    service.desiredIdleEnabled = false
    service.saveState()
    watch.start()
  }}

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.settings-persistence/Service.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    service = component.createObject(this)
    Qt.callLater(issue)
  }}

  Timer {{ interval: 20; repeat: true; running: true; onTriggered: issue() }}

  Process {{
    id: recover
    command: ["bash", "-c", "rm -f '{blocked_state.as_posix()}'; mkdir -p '{blocked_state.as_posix()}'"]
    onExited: function(exitCode) {{
      if (exitCode !== 0) {{ console.log("BEHAVE_ERR recovery failed"); Qt.quit(); return }}
      service.retryPersistence()
    }}
  }}

  Timer {{
    id: watch
    interval: 20
    repeat: true
    property int attempts: 0
    onTriggered: {{
      attempts += 1
      if (!observedFailure && service.persistenceState === "failed") {{
        observedFailure = service.retrySavePayload !== "" && service.persistenceError !== ""
        recover.running = true
      }} else if (observedFailure && service.persistenceState === "saved") {{
        console.log("BEHAVE " + JSON.stringify({{
          failed: observedFailure,
          state: service.persistenceState,
          requested: service.requestedSaveRevision,
          confirmed: service.confirmedSaveRevision,
          retryAvailable: service.retrySavePayload !== ""
        }}))
        Qt.quit()
      }} else if (attempts > 300) {{
        console.log("BEHAVE_ERR retry timeout " + service.persistenceState)
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
                    "XDG_STATE_HOME": str(blocked_state),
                },
                timeout=12,
            )
            require_no_qml_errors(output)
            row = parse_behave(output)[-1]
            self.assertTrue(row["failed"], output[-2000:])
            self.assertEqual("saved", row["state"])
            self.assertEqual(row["requested"], row["confirmed"])
            self.assertFalse(row["retryAvailable"])
            state_file = blocked_state / "omarchy/lacuna/settings-persistence.json"
            self.assertTrue(state_file.exists())
            self.assertEqual(0o600, state_file.stat().st_mode & 0o777)

    @staticmethod
    def _write_executable(path: Path, content: str) -> None:
        path.write_text(content, encoding="utf-8")
        path.chmod(0o755)


if __name__ == "__main__":
    unittest.main()
