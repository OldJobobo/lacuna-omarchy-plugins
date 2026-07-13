import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_module(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ResourceSnapshotTests(unittest.TestCase):
    def test_memory_snapshot_separates_available_cache_and_swap(self):
        module = load_module("system_snapshot", "lacuna.system-stats/scripts/system-stats-snapshot.py")
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "meminfo"
            path.write_text(
                "MemTotal: 1000 kB\nMemAvailable: 400 kB\nCached: 200 kB\n"
                "SReclaimable: 50 kB\nSwapTotal: 300 kB\nSwapFree: 100 kB\n",
                encoding="utf-8",
            )
            result = module.read_meminfo(path)
        self.assertEqual(result["used"], 600 * 1024)
        self.assertEqual(result["cached"], 250 * 1024)
        self.assertEqual(result["swapUsed"], 200 * 1024)

    def test_thermal_snapshot_prefers_cpu_package_over_hotter_gpu(self):
        module = load_module("thermal_snapshot", "lacuna.temperature/scripts/thermal-snapshot.py")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cpu = root / "hwmon0"
            gpu = root / "hwmon1"
            cpu.mkdir(); gpu.mkdir()
            (cpu / "name").write_text("k10temp\n")
            (cpu / "temp1_input").write_text("52000\n")
            (cpu / "temp1_label").write_text("Tctl\n")
            (gpu / "name").write_text("amdgpu\n")
            (gpu / "temp1_input").write_text("70000\n")
            (gpu / "temp1_label").write_text("junction\n")
            result = module.snapshot(root)
        self.assertEqual(result["primary"]["device"], "k10temp")
        self.assertEqual(result["hottest"]["device"], "amdgpu")
        self.assertEqual([row["group"] for row in result["sensors"]], ["CPU", "GPU"])


if __name__ == "__main__":
    unittest.main()
