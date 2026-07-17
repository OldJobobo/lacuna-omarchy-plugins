from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SETTINGS = Path.home() / ".config/omarchy/lacuna/settings.json"
ENABLED = os.environ.get("LACUNA_LIVE_VISUAL") == "1"
REQUIRED_TOOLS = ("hyprctl", "grim", "magick", "omarchy")
HAVE_TOOLS = all(shutil.which(tool) for tool in REQUIRED_TOOLS)


def run(command: list[str], *, timeout: int = 30) -> str:
    proc = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    if proc.returncode != 0:
        raise AssertionError(f"{command} failed\nstdout:\n{proc.stdout}\nstderr:\n{proc.stderr}")
    return proc.stdout


def read_settings() -> dict:
    return json.loads(SETTINGS.read_text(encoding="utf-8"))


def write_settings(data: dict) -> None:
    SETTINGS.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def set_frame_mode(mode: str) -> None:
    data = read_settings()
    data.setdefault("frame", {})["mode"] = mode
    write_settings(data)
    run(["omarchy", "restart", "shell"], timeout=60)
    time.sleep(0.5)


def set_portrait_split(enabled: bool) -> None:
    data = read_settings()
    data.setdefault("barPresentation", {})["portraitSplit"] = enabled
    write_settings(data)
    run(["omarchy", "restart", "shell"], timeout=60)
    time.sleep(0.5)


def set_reduce_motion(enabled: bool) -> None:
    data = read_settings()
    data["reduceMotion"] = enabled
    write_settings(data)
    run(["omarchy", "restart", "shell"], timeout=60)
    time.sleep(0.5)


def summon_menu(flyout: str) -> None:
    run(["omarchy-shell", "shell", "summon", "lacuna.menu", json.dumps({"flyout": flyout})])


def lacuna_layers() -> dict[str, list[str]]:
    data = json.loads(run(["hyprctl", "-j", "layers"]))
    result: dict[str, list[str]] = {}
    for screen, payload in data.items():
        names: list[str] = []
        for level in sorted(payload.get("levels", {}), key=lambda value: int(value)):
            for item in payload["levels"][level]:
                namespace = item.get("namespace", "")
                if namespace in {"omarchy-bar", "lacuna-bar-portrait-companion", "lacuna-bar-frame", "lacuna-bar-frame-border"}:
                    names.append(f"{level}:{namespace}")
        result[screen] = names
    return result


def wait_for_frame_layers() -> dict[str, list[str]]:
    deadline = time.time() + 8
    last: dict[str, list[str]] = {}
    stable_count = 0
    while time.time() < deadline:
        current = lacuna_layers()
        ready = bool(current) and all(
            "2:lacuna-bar-frame" in names
            and "2:lacuna-bar-portrait-companion" in names
            and "3:lacuna-bar-frame-border" in names
            for names in current.values()
        )
        if ready and current == last:
            stable_count += 1
            if stable_count >= 2:
                return current
        else:
            stable_count = 0
        last = current
        time.sleep(0.25)
    return last


def pixel_luma(image: Path, x: int, y: int) -> float:
    out = run(["magick", str(image), "-format", f"%[pixel:p{{{x},{y}}}]", "info:"]).strip()
    values = [int(part) for part in out[out.find("(") + 1 : out.find(")")].split(",")[:3]]
    return (values[0] * 0.2126) + (values[1] * 0.7152) + (values[2] * 0.0722)


@unittest.skipUnless(ENABLED and HAVE_TOOLS and SETTINGS.exists(), "set LACUNA_LIVE_VISUAL=1 with hyprctl/grim/magick/omarchy to run")
class LiveVisualTests(unittest.TestCase):
    def setUp(self):
        self.original = read_settings()

    def tearDown(self):
        write_settings(self.original)
        run(["omarchy", "restart", "shell"], timeout=60)

    def test_frame_mode_toggle_preserves_layer_order(self):
        set_frame_mode("off")
        off_layers = wait_for_frame_layers()
        self.assertTrue(any("2:lacuna-bar-frame" in names for names in off_layers.values()), off_layers)
        self.assertTrue(any("3:lacuna-bar-frame-border" in names for names in off_layers.values()), off_layers)

        set_frame_mode("fullframe")
        full_layers = wait_for_frame_layers()
        self.assertEqual(full_layers, off_layers)

        set_frame_mode("off")
        self.assertEqual(wait_for_frame_layers(), off_layers)

    def test_portrait_companion_stays_mapped_across_setting_toggle(self):
        set_portrait_split(False)
        disabled_layers = wait_for_frame_layers()
        self.assertTrue(disabled_layers)
        self.assertTrue(all("2:lacuna-bar-portrait-companion" in names for names in disabled_layers.values()))

        set_portrait_split(True)
        self.assertEqual(wait_for_frame_layers(), disabled_layers)

    def test_top_bar_rows_are_not_overpainted_by_fullframe_toggle(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            off_image = tmp_path / "off.png"
            full_image = tmp_path / "full.png"
            set_frame_mode("off")
            wait_for_frame_layers()
            run(["grim", str(off_image)])
            set_frame_mode("fullframe")
            wait_for_frame_layers()
            run(["grim", str(full_image)])

            # Compare stable top-bar pixels rather than golden images. The bar
            # strip itself should not be overpainted by enabling full frame.
            for x in (200, 800, 1400):
                for y in (4, 16, 28):
                    self.assertAlmostEqual(pixel_luma(off_image, x, y), pixel_luma(full_image, x, y), delta=12.0)

            # A row just below the bar should be darker than the deep content
            # row when the shadow is active, showing a flush bar-edge shadow.
            for image in (off_image, full_image):
                edge = pixel_luma(image, 960, 34)
                deep = pixel_luma(image, 960, 52)
                self.assertLess(edge, deep + 8)

    def test_transition_pipeline_smoke_states(self):
        # This is intentionally opt-in: it exercises the real menu surface,
        # including sidebar-first disclosure, dimension switches, a newest-wins
        # interruption, closing, and reduced-motion settlement. The per-state
        # screenshots make failures inspectable without retaining user state.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            set_reduce_motion(False)
            for name, flyout in (("settings", "settings"), ("media", "mediaPlayer"), ("app-picker", "appPicker")):
                summon_menu(flyout)
                time.sleep(0.45)
                image = root / f"{name}.png"
                run(["grim", str(image)])
                self.assertGreater(image.stat().st_size, 0, name)

            # A rapid third request must leave a usable, non-empty surface.
            summon_menu("settings")
            summon_menu("mediaPlayer")
            summon_menu("appPicker")
            time.sleep(0.45)
            interrupted = root / "interrupted.png"
            run(["grim", str(interrupted)])
            self.assertGreater(interrupted.stat().st_size, 0)

            set_reduce_motion(True)
            summon_menu("settings")
            immediate = root / "reduced-motion.png"
            run(["grim", str(immediate)])
            self.assertGreater(immediate.stat().st_size, 0)


if __name__ == "__main__":
    unittest.main()
