import json
import os
import tempfile
import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


ROOT = Path(__file__).resolve().parents[1]


class SystemUpdateContractTests(unittest.TestCase):
    def test_widget_uses_one_shared_service_for_all_monitor_copies(self):
        manifest = json.loads((ROOT / "lacuna.system-update/manifest.json").read_text(encoding="utf-8"))
        widget = (ROOT / "lacuna.system-update/Widget.qml").read_text(encoding="utf-8")
        service = (ROOT / "lacuna.system-update/Service.qml").read_text(encoding="utf-8")

        self.assertEqual(manifest["kinds"], ["service", "bar-widget"])
        self.assertTrue(manifest["keepLoaded"])
        self.assertEqual(manifest["entryPoints"]["service"], "Service.qml")
        self.assertIn('bar.shell.ensureService("lacuna.system-update")', widget)
        self.assertIn("systemUpdateService.updateAvailable", widget)
        self.assertIn('command: ["omarchy", "update", "available"]', service)


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class SystemUpdateBehaviorTests(unittest.TestCase):
    def test_monitor_widgets_share_state_and_run_one_update_check(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            bin_dir = tmp_path / "bin"
            bin_dir.mkdir()
            log_path = tmp_path / "calls.log"
            fake_omarchy = bin_dir / "omarchy"
            fake_omarchy.write_text(
                "#!/bin/sh\n"
                'printf "check\\n" >> "$SYSTEM_UPDATE_LOG"\n'
                "sleep 0.2\n"
                "exit 0\n",
                encoding="utf-8",
            )
            fake_omarchy.chmod(0o755)

            qml = f'''
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var updateService: null
  property var first: null
  property var second: null

  Component.onCompleted: {{
    var serviceComponent = Qt.createComponent("{qml_url('lacuna.system-update/Service.qml')}", Component.PreferSynchronous)
    var widgetComponent = Qt.createComponent("{qml_url('lacuna.system-update/Widget.qml')}", Component.PreferSynchronous)
    updateService = serviceComponent.createObject(root)
    first = widgetComponent.createObject(root, {{
      systemUpdateService: updateService,
      settings: {{ interval: 999999 }}
    }})
    second = widgetComponent.createObject(root, {{
      systemUpdateService: updateService,
      settings: {{ interval: 999999 }}
    }})
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 500
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        serviceAvailable: updateService.updateAvailable,
        firstAvailable: first.updateAvailable,
        secondAvailable: second.updateAvailable,
        firstWidth: first.implicitWidth,
        secondWidth: second.implicitWidth
      }}))
      Qt.quit()
    }}
  }}
}}
'''
            output = run_quickshell(
                qml,
                timeout=8,
                env_overrides={
                    "PATH": f"{bin_dir}:{os.environ.get('PATH', '')}",
                    "SYSTEM_UPDATE_LOG": str(log_path),
                },
            )
            require_no_qml_errors(output)
            result = parse_behave(output)[-1]

            self.assertEqual(log_path.read_text(encoding="utf-8").splitlines(), ["check"])
            self.assertTrue(result["serviceAvailable"])
            self.assertTrue(result["firstAvailable"])
            self.assertTrue(result["secondAvailable"])
            self.assertGreater(result["firstWidth"], 0)
            self.assertGreater(result["secondWidth"], 0)


if __name__ == "__main__":
    unittest.main()
