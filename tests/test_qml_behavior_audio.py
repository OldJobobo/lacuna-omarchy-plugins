import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlAudioBehaviorTests(unittest.TestCase):
    def test_audio_snapshot_rows_do_not_retain_transient_pipewire_objects(self):
        qml = f"""
import Quickshell
import QtQuick
import "{qml_url('lacuna.audio/AudioModel.js')}" as AudioModel

ShellRoot {{
  Timer {{
    interval: 20
    running: true
    repeat: false
    onTriggered: {{
      var node = {{
      id: 42,
      ready: true,
      name: "music-player",
      description: "Music Player",
      properties: {{ "application.name": "Player" }},
      audio: {{ muted: false, volume: 0.73 }}
    }}
    var row = AudioModel.snapshotRow(node, "stream", false)
    node.audio.muted = true
    node.audio.volume = 0.12
    node = null
    console.log("BEHAVE " + JSON.stringify({{
      key: row.key,
      label: row.label,
      muted: row.muted,
      percent: row.percent,
      enabled: row.enabled,
      keys: Object.keys(row).sort(),
      json: JSON.stringify(row)
    }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual("42", result["key"])
        self.assertEqual("Player", result["label"])
        self.assertFalse(result["muted"])
        self.assertEqual(73, result["percent"])
        self.assertTrue(result["enabled"])
        self.assertEqual(
            ["enabled", "key", "kind", "label", "muted", "percent", "selected"],
            result["keys"],
        )
        self.assertNotIn("audio", result["json"])
