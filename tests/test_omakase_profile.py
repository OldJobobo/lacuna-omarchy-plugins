import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROFILE_PATH = ROOT / "config" / "omakase-profile.json"

EXPECTED_BAR_LAYOUT = {
    "left": [
        {"id": "lacuna.menu-button"},
        {"id": "lacuna.workspaces", "workspaceCount": 7},
        {"id": "lacuna.codex-usage"},
        {"id": "lacuna.claude-usage"},
        {"id": "lacuna.mpris"},
    ],
    "center": [
        {"id": "lacuna.voxtype"},
        {
            "id": "lacuna.clock",
            "format": "ddd d h:mm AP",
            "dateFormat": "ddd d",
            "timeFormat": "h:mm AP",
            "verticalFormat": "HH\n-\nmm",
        },
        {"id": "lacuna.weather"},
        {"id": "lacuna.system-update"},
        {"id": "lacuna.notifications"},
        {"id": "lacuna.nightlight"},
        {"id": "lacuna.idle-inhibitor"},
        {"id": "lacuna.screen-recording"},
    ],
    "right": [
        {"id": "lacuna.tray"},
        {"id": "lacuna.theme"},
        {"id": "lacuna.wallpaper"},
        {"id": "lacuna.bluetooth"},
        {"id": "lacuna.network"},
        {"id": "lacuna.audio"},
        {"id": "lacuna.power"},
        {"id": "lacuna.system-stats"},
        {"id": "lacuna.temperature"},
        {"id": "lacuna.bar-size-pill"},
    ],
}


class OmakaseProfileContractTests(unittest.TestCase):
    def test_exact_profile_matches_supported_manifests_and_activation_contract(self):
        profile = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
        manifests = {
            data["id"]: data
            for path in ROOT.glob("lacuna.*/manifest.json")
            for data in [json.loads(path.read_text(encoding="utf-8"))]
        }
        supported = {
            plugin_id
            for plugin_id, manifest in manifests.items()
            if manifest["lacuna"]["stability"] in {"beta", "experimental"}
        }
        deprecated = {
            plugin_id
            for plugin_id, manifest in manifests.items()
            if manifest["lacuna"]["stability"] == "deprecated"
        }

        self.assertEqual(len(supported), 46)
        self.assertEqual(profile["installRoots"], sorted(supported))
        self.assertEqual(deprecated, {"lacuna.compact-pill"})
        self.assertEqual(profile["excludedRoots"]["deprecated"], ["lacuna.compact-pill"])

        layout = profile["shell"]["bar"]["layout"]
        self.assertEqual(layout, EXPECTED_BAR_LAYOUT)
        self.assertEqual(sum(len(entries) for entries in layout.values()), 23)

        expected_activation = {
            plugin_id
            for plugin_id in supported
            if set(manifests[plugin_id].get("kinds", [])) & {"service", "menu", "overlay"}
        }
        activation_ids = [entry["id"] for entry in profile["shell"]["activationEntries"]]
        self.assertEqual(len(expected_activation), 26)
        self.assertEqual(activation_ids, sorted(expected_activation))

        self.assertTrue({"lacuna.media-player", "lacuna.media-player-video", "lacuna.script-pill"} <= supported)
        self.assertEqual(
            profile["media"]["installRoots"],
            ["lacuna.media-player", "lacuna.media-player-video"],
        )
        self.assertTrue(set(profile["media"]["installRoots"]) <= set(activation_ids))
        self.assertNotIn("lacuna.script-pill", activation_ids)
        self.assertNotIn("lacuna.compact-pill", profile["installRoots"])

        settings_contract = profile["settings"]
        self.assertNotIn("mediaPlayer", settings_contract["ownedKeys"])
        self.assertIn("mediaPlayer", settings_contract["preservedKeys"])
        self.assertIn("media-player.json", settings_contract["untouchedExternalState"])


if __name__ == "__main__":
    unittest.main()
