"""Structural contracts for plugin kinds that lacked direct coverage:
ambience overlays, the desktop clock, the settings-persistence service/panel,
and the experimental script pill.
"""

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def manifest(plugin_id: str) -> dict:
    return json.loads(read(f"{plugin_id}/manifest.json"))


OVERLAY_PLUGINS = [
    "lacuna.aurora-drift",
    "lacuna.crt-overlay",
    "lacuna.vhs-overlay",
    "lacuna.rainfall-overlay",
    "lacuna.cinematic-light-overlay",
    "lacuna.god-rays-overlay",
    "lacuna.background-vignette",
]


class PluginKindContractTests(unittest.TestCase):
    def test_overlays_declare_overlay_kind_with_item_root(self):
        for plugin_id in OVERLAY_PLUGINS:
            data = manifest(plugin_id)
            self.assertIn("overlay", data.get("kinds", []), plugin_id)
            self.assertEqual(data["entryPoints"].get("overlay"), "Overlay.qml", plugin_id)
            self.assertEqual(data.get("activation"), "persistent", plugin_id)
            # The overlay root is a bare Item (column 0), per the overlay contract.
            self.assertIn("\nItem {", read(f"{plugin_id}/Overlay.qml"), plugin_id)

    def test_effect_overlays_expose_settings_and_effect_toggle(self):
        for plugin_id in OVERLAY_PLUGINS:
            qml = read(f"{plugin_id}/Overlay.qml")
            self.assertIn("settings", qml, plugin_id)
            # The always-on vignette has no enable toggle; the animated effects do.
            if plugin_id != "lacuna.background-vignette":
                self.assertIn("effectEnabled", qml, plugin_id)

    def test_desktop_clock_overlay_contract(self):
        data = manifest("lacuna.desktop-clock")
        self.assertEqual(data["entryPoints"].get("overlay"), "Clock.qml")
        self.assertIn("\nItem {", read("lacuna.desktop-clock/Clock.qml"))

    def test_settings_persistence_service_and_panel_contract(self):
        data = manifest("lacuna.settings-persistence")
        self.assertEqual(data["entryPoints"].get("service"), "Service.qml")
        self.assertEqual(data["entryPoints"].get("panel"), "Panel.qml")
        self.assertEqual(data.get("activation"), "persistent")
        self.assertEqual(sorted(data.get("kinds", [])), ["panel", "service"])
        self.assertIn("function hydrate", read("lacuna.settings-persistence/Service.qml"))

    def test_script_pill_widget_honors_bar_widget_injection_contract(self):
        data = manifest("lacuna.script-pill")
        self.assertEqual(data["entryPoints"].get("barWidget"), "Widget.qml")
        self.assertEqual(data.get("lacuna", {}).get("stability"), "experimental")
        qml = read("lacuna.script-pill/Widget.qml")
        self.assertIn("\nItem {", qml)
        self.assertIn("property var bar: null", qml)
        self.assertIn('property string moduleName: "lacuna.script-pill"', qml)
        self.assertIn("property var settings: ({})", qml)


if __name__ == "__main__":
    unittest.main()
