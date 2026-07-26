import json
import unittest
from pathlib import Path

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class VoxtypeResourceContractTests(unittest.TestCase):
    def test_only_shared_service_owns_status_follower(self):
        service = read("lacuna.voxtype/Service.qml")
        widget = read("lacuna.voxtype/Widget.qml")
        indicators = read("lacuna.indicators/Widget.qml")
        manifest = json.loads(read("lacuna.voxtype/manifest.json"))
        inventory = json.loads(read("config/release-inventory.json"))
        inventory_entry = next(item for item in inventory["plugins"] if item["id"] == "lacuna.voxtype")

        self.assertEqual(service.count('["omarchy", "voxtype", "status"]'), 1)
        self.assertNotIn('["omarchy", "voxtype", "status"]', widget)
        self.assertNotIn('["omarchy", "voxtype", "status"]', indicators)
        self.assertIn('ensureService("lacuna.voxtype")', widget)
        self.assertIn('ensureService("lacuna.voxtype")', indicators)
        self.assertIn('readonly property string dictationState: voxtypeService ? String(voxtypeService.dictationState || "idle") : "idle"', indicators)
        self.assertIn("service", manifest["kinds"])
        self.assertEqual(manifest["entryPoints"]["service"], "Service.qml")
        self.assertTrue(manifest["keepLoaded"])
        self.assertIn("Service.qml", inventory_entry["files"])


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class VoxtypeServiceBehaviorTests(unittest.TestCase):
    def test_multiple_widgets_observe_one_shared_service(self):
        qml = f'''\nimport Quickshell\nimport QtQuick\n\nShellRoot {{\n  id: root\n  property var first: null\n  property var second: null\n  QtObject {{ id: shared; property string dictationState: "idle" }}\n  Component.onCompleted: {{\n    var component = Qt.createComponent("{qml_url('lacuna.voxtype/Widget.qml')}", Component.PreferSynchronous)\n    first = component.createObject(root, {{ voxtypeService: shared, settings: {{ showInactive: true }} }})\n    second = component.createObject(root, {{ voxtypeService: shared, settings: {{ showInactive: true }} }})\n    shared.dictationState = "recording"\n    probe.restart()\n  }}\n  Timer {{\n    id: probe\n    interval: 10\n    onTriggered: {{\n      console.log("BEHAVE " + JSON.stringify({{\n        sameService: root.first.voxtypeService === root.second.voxtypeService,\n        first: root.first.dictationState,\n        second: root.second.dictationState\n      }}))\n      Qt.quit()\n    }}\n  }}\n}}\n'''
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertTrue(row["sameService"], output[-2000:])
        self.assertEqual(row["first"], "recording", output[-2000:])
        self.assertEqual(row["second"], "recording", output[-2000:])

    def test_service_normalizes_shared_status(self):
        qml = f'''
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var service: null
  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.voxtype/Service.qml')}", Component.PreferSynchronous)
    if (component.status !== Component.Ready) {{
      console.log("BEHAVE_ERR " + component.errorString())
      Qt.quit()
      return
    }}
    service = component.createObject(root)
    probe.restart()
  }}
  Timer {{
    id: probe
    interval: 10
    onTriggered: {{
      root.service.handleStatus('{{"alt":"recording"}}')
      var first = root.service.dictationState
      root.service.handleStatus('{{"class":"transcribing"}}')
      console.log("BEHAVE " + JSON.stringify({{
        first: first,
        second: root.service.dictationState,
        active: root.service.active
      }}))
      Qt.quit()
    }}
  }}
}}
'''
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(row["first"], "recording", output[-2000:])
        self.assertEqual(row["second"], "transcribing", output[-2000:])
        self.assertTrue(row["active"], output[-2000:])


if __name__ == "__main__":
    unittest.main()
