import importlib.machinery
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SMOKE = ROOT / "scripts" / "quattro-p0-smoke"


def load_smoke_module():
    loader = importlib.machinery.SourceFileLoader("lacuna_quattro_p0_smoke_test", str(SMOKE))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class QuattroP0SmokePolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.smoke = load_smoke_module()

    def test_bar_geometry_rejects_duplicate_live_slots(self):
        base = {
            "id": "lacuna.clock",
            "section": "center",
            "band": "primary",
            "screenName": "DP-1",
            "barPosition": "top",
        }
        unique = [base, {**base, "screenName": "DP-2"}, {**base, "id": ""}]
        self.assertEqual([], self.smoke.check_bar_geometry(unique))

        failures = self.smoke.check_bar_geometry([base, dict(base)])
        self.assertEqual(
            ["duplicate live bar slot: DP-1/top/primary/center/lacuna.clock"],
            failures,
        )

    def test_bar_geometry_rejects_cross_section_overlap(self):
        def slot(plugin_id, section, x, width):
            return {
                "id": plugin_id,
                "section": section,
                "band": "primary",
                "screenName": "DP-1",
                "barPosition": "top",
                "visible": True,
                "x": x,
                "width": width,
            }

        fitting = [
            slot("lacuna.menu-button", "left", 0, 100),
            slot("lacuna.clock", "center", 120, 80),
            slot("lacuna.power", "right", 220, 100),
        ]
        self.assertEqual([], self.smoke.check_bar_geometry(fitting))

        overlapping = [*fitting[:2], slot("lacuna.power", "right", 198, 100)]
        self.assertEqual(
            ["overlapping live bar sections: DP-1/top/primary/center-right (200>198)"],
            self.smoke.check_bar_geometry(overlapping),
        )

    def test_bar_geometry_leaves_vertical_flow_outside_horizontal_policy(self):
        vertical = [
            {
                "id": "lacuna.menu-button",
                "section": "left",
                "band": "primary",
                "screenName": "DP-1",
                "barPosition": "left",
                "visible": True,
                "y": 0,
                "height": 100,
            },
            {
                "id": "lacuna.clock",
                "section": "center",
                "band": "primary",
                "screenName": "DP-1",
                "barPosition": "left",
                "visible": True,
                "y": 50,
                "height": 100,
            },
        ]
        self.assertEqual([], self.smoke.check_bar_geometry(vertical))

    def test_current_layer_policy_handles_landscape_sidebar_and_portrait_split(self):
        monitors = [
            {"name": "DP-1", "width": 2560, "height": 1440, "scale": 1, "transform": 0},
            {"name": "DP-3", "width": 2560, "height": 1440, "scale": 1, "transform": 1},
        ]
        layers = """Monitor DP-1:
  namespace: lacuna-bar-frame
  namespace: lacuna-bar-frame-reserve-DP-1-bottom
  namespace: lacuna-bar-frame-reserve-DP-1-right
  namespace: lacuna.menu-sidebar-reserve-DP-1-left
Monitor DP-3:
  namespace: lacuna-bar-frame
  namespace: lacuna-bar-portrait-companion
  namespace: lacuna-bar-frame-reserve-DP-3-left
  namespace: lacuna-bar-frame-reserve-DP-3-right
"""
        self.assertEqual(
            [],
            self.smoke.check_layers(
                monitors,
                layers,
                bar_position="top",
                portrait_split_enabled=True,
                frame_enabled=True,
            ),
        )

    def test_frame_reserve_does_not_satisfy_frame_surface_requirement(self):
        monitors = [{"name": "DP-1", "width": 1920, "height": 1080, "scale": 1, "transform": 0}]
        layers = """Monitor DP-1:
  namespace: lacuna-bar-frame-reserve-DP-1-bottom
  namespace: lacuna-bar-frame-reserve-DP-1-left
  namespace: lacuna-bar-frame-reserve-DP-1-right
"""
        failures = self.smoke.check_layers(monitors, layers, frame_enabled=True)
        self.assertIn("DP-1 is missing lacuna-bar-frame", failures)

    def test_removed_border_and_wrong_companion_are_rejected(self):
        monitors = [{"name": "DP-1", "width": 1920, "height": 1080, "scale": 1, "transform": 0}]
        layers = """Monitor DP-1:
  namespace: lacuna-bar-frame
  namespace: lacuna-bar-frame-border
  namespace: lacuna-bar-portrait-companion
  namespace: lacuna-bar-frame-reserve-DP-1-bottom
  namespace: lacuna-bar-frame-reserve-DP-1-left
  namespace: lacuna-bar-frame-reserve-DP-1-right
"""
        failures = self.smoke.check_layers(monitors, layers, frame_enabled=True)
        self.assertIn("DP-1 still maps removed lacuna-bar-frame-border", failures)
        self.assertIn("DP-1 has unexpected portrait companion", failures)

    def test_reserve_policy_follows_bar_edge_and_frame_mode(self):
        monitors = [{"name": "HDMI A-1", "width": 1920, "height": 1080, "scale": 1, "transform": 0}]
        frame_off = """Monitor HDMI A-1:
  namespace: lacuna-bar-frame
"""
        self.assertEqual(
            [],
            self.smoke.check_layers(
                monitors,
                frame_off,
                bar_position="left",
                portrait_split_enabled=True,
                frame_enabled=False,
            ),
        )

        stale_reserve = frame_off + "  namespace: lacuna-bar-frame-reserve-HDMI-A-1-left\n"
        failures = self.smoke.check_layers(
            monitors,
            stale_reserve,
            bar_position="left",
            portrait_split_enabled=True,
            frame_enabled=False,
        )
        self.assertIn("HDMI A-1 has unexpected left frame reserve", failures)


if __name__ == "__main__":
    unittest.main()
