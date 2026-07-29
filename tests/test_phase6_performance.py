import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def load_script(path, name):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class Phase6PerformanceTests(unittest.TestCase):
    def test_system_stats_has_one_consumer_gated_process_owner(self):
        service = read("lacuna.system-stats/Service.qml")
        widget = read("lacuna.system-stats/Widget.qml")
        manifest = json.loads(read("lacuna.system-stats/manifest.json"))

        self.assertEqual("Service.qml", manifest["entryPoints"]["service"])
        self.assertIn("service", manifest["kinds"])
        self.assertEqual(1, service.count("system-stats-snapshot.py"))
        self.assertIn("readonly property bool polling: consumerCount > 0", service)
        self.assertIn("running: root.polling", service)
        self.assertIn("function subscribe(consumer)", service)
        self.assertIn("function unsubscribe(consumer)", service)
        self.assertIn("rootFilesystem", service)
        self.assertNotIn('command: ["df"', widget)
        self.assertNotIn("system-stats-snapshot.py", widget)
        self.assertNotIn("Process {", widget)
        self.assertIn("Component.onDestruction: if (subscribed && statsService) statsService.unsubscribe(root)", widget)

    def test_screen_recording_service_is_settled_polling_authority(self):
        service = read("lacuna.screen-recording/Service.qml")
        widget = read("lacuna.screen-recording/Widget.qml")
        indicators = read("lacuna.indicators/Widget.qml")

        self.assertIn('command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]', service)
        self.assertIn("running: root.recordingService === null", widget)
        self.assertIn("recordingService ? recordingService.recording : fallbackRecording", widget)
        self.assertNotIn("polledRecording ||", widget)
        self.assertIn("if (!recordingService && !recordingProc.running) recordingProc.running = true", indicators)
        self.assertNotIn('if (recordingService && typeof recordingService.refresh === "function") recordingService.refresh()\n    else', indicators)
        self.assertIn('ensureService("lacuna.screen-recording")', indicators)
        self.assertIn("recordingService.toggleRecording()", indicators)

    def test_media_players_are_unloaded_when_stopped(self):
        tile = read("lacuna.menu/menu/MediaPlayerTile.qml")
        overlay = read("lacuna.media-player-video/Overlay.qml")

        self.assertIn("active: false", tile)
        self.assertIn('previewPlayerLoader.active = assignedPreviewSource !== ""', tile)
        self.assertIn("readonly property bool previewPlayerLoaded: previewPlayerLoader.item !== null", tile)
        self.assertIn("active: videoWindow.renderable", overlay)
        self.assertIn("Component.onDestruction", overlay)

    def test_shell_settings_supports_scoped_collection_and_reconciliation(self):
        service = read("lacuna.shell-settings/Service.qml")
        script = load_script("lacuna.shell-settings/scripts/omarchy-shell-settings-state.py", "phase6_shell_state")

        self.assertEqual({"hypr", "toggles"}, script.requested_domains(["--domains", "hypr,toggles"]))
        with self.assertRaises(ValueError):
            script.requested_domains(["--domains", "unknown"])
        self.assertIn('loadProc.command.concat(["--domains", scope])', service)
        self.assertIn("function mergeCollectedState(nextState)", service)
        self.assertIn("activeRefreshDomains = mergeDomains(activeRefreshDomains, pendingRefreshDomains)", service)
        self.assertIn("interval: 60000", service)
        self.assertIn('run("omarchy toggle screensaver", ["toggles"])', service)
        self.assertNotIn("function onQueueDrained() { root.scheduleRefresh() }", service)

    def test_canonical_settings_persistence_is_watcher_based(self):
        for path in ["lacuna.state/Service.qml", "lacuna.menu/services/LacunaSettings.qml"]:
            qml = read(path)
            self.assertIn("watchChanges: true", qml)
            self.assertIn("atomicWrites: true", qml)
            self.assertNotIn("interval: 3000", qml)

    def test_benchmark_quick_mode_emits_thresholds_and_statistics(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "sample.json"
            subprocess.run(
                [sys.executable, str(ROOT / "scripts/lacuna-performance-benchmark"), "--quick", "--pid", str(os.getpid()), "--output", str(output)],
                check=True,
                timeout=20,
                capture_output=True,
                text=True,
                env={**os.environ, "PATH": temp},
            )
            payload = json.loads(output.read_text(encoding="utf-8"))
            self.assertFalse(payload["promotable"])
            self.assertEqual(2, len(payload["samples"]))
            self.assertEqual(50, payload["thresholds"]["systemStatsLaunchReductionPercent"])
            self.assertEqual(4, payload["thresholds"]["settingsPersistenceLaunchesPerMinuteMax"])
            for key in ["cpuPercent", "rssKiB", "childLaunches", "wakeups"]:
                self.assertEqual(2, len(payload["metrics"][key]["raw"]))
                self.assertIsNotNone(payload["metrics"][key]["median"])
                self.assertIsNotNone(payload["metrics"][key]["p95"])


if __name__ == "__main__":
    unittest.main()
