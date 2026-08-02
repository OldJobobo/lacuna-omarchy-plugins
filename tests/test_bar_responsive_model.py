import textwrap
import unittest
from pathlib import Path

from test_bar_model import run_bar_model_script


ROOT = Path(__file__).resolve().parents[1]


class BarResponsiveModelTests(unittest.TestCase):
    def test_width_classes_follow_logical_monitor_width(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarResponsiveModel.js");
            const widths = [799, 800, 1199, 1200, 1679, 1680];
            console.log(JSON.stringify(widths.map(model.widthClass)));
            """
        )

        self.assertEqual(
            ["minimal", "constrained", "constrained", "standard", "standard", "wide"],
            run_bar_model_script(script),
        )

    def test_horizontal_corridors_never_overlap_at_common_monitor_scales(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarResponsiveModel.js");
            const physicalWidths = [1280, 1920, 2560, 3440];
            const scales = [1, 1.25, 1.5, 1.75, 2];
            const modes = [
              { name: "compact", size: 26, margin: 2, gap: 6 },
              { name: "full", size: 32, margin: 8, gap: 4 }
            ];
            const rows = [];
            for (const physical of physicalWidths) {
              for (const scale of scales) {
                for (const mode of modes) {
                  const logical = Math.floor(physical / scale);
                  const plan = model.horizontalPlan(logical, mode.margin, mode.gap, 115, mode.size);
                  rows.push({ physical, scale, mode: mode.name, logical, plan });
                }
              }
            }
            console.log(JSON.stringify(rows));
            """
        )

        for row in run_bar_model_script(script):
            plan = row["plan"]
            occupied = (
                plan["sideLength"] * 2
                + plan["centerLength"]
                + plan["gap"] * 2
                + (4 if row["mode"] == "compact" else 16)
            )
            self.assertEqual(row["logical"], occupied, row)
            self.assertGreaterEqual(plan["centerLength"], plan["anchorLength"], row)
            self.assertGreaterEqual(plan["centerHalfLength"], 0, row)
            self.assertGreaterEqual(plan["sideLength"], 0, row)

    def test_full_and_compact_modes_both_fit_by_priority(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarResponsiveModel.js");
            const full = [
              { id: "menu", length: 32, priority: 1000 },
              { id: "workspaces", length: 236, priority: 960 },
              { id: "codex", length: 104, priority: 700 },
              { id: "claude", length: 104, priority: 700 },
              { id: "mpris", length: 130, priority: 600 }
            ];
            const compact = [
              { id: "menu", length: 26, priority: 1000 },
              { id: "workspaces", length: 180, priority: 960 },
              { id: "codex", length: 70, priority: 700 },
              { id: "claude", length: 77, priority: 700 },
              { id: "mpris", length: 121, priority: 600 }
            ];
            function kept(items, limit) {
              const result = model.fit(items, limit);
              return items.filter((item, index) => result.visible[index]).map(item => item.id);
            }
            console.log(JSON.stringify({
              fullWide: kept(full, 717),
              fullScaled: kept(full, 391),
              compactScaled: kept(compact, 395)
            }));
            """
        )

        result = run_bar_model_script(script)
        self.assertEqual(["menu", "workspaces", "codex", "claude", "mpris"], result["fullWide"])
        self.assertEqual(["menu", "workspaces", "codex"], result["fullScaled"])
        self.assertEqual(["menu", "workspaces", "codex", "claude"], result["compactScaled"])

    def test_density_control_remains_reachable_at_two_x_full_width(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarResponsiveModel.js");
            const items = [
              { id: "model-usage", length: 27, priority: 500 },
              { id: "tray", length: 161, priority: 800 },
              { id: "theme", length: 146, priority: 440 },
              { id: "wallpaper", length: 161, priority: 440 },
              { id: "bluetooth", length: 32, priority: 820 },
              { id: "network", length: 32, priority: 840 },
              { id: "audio", length: 32, priority: 860 },
              { id: "power", length: 32, priority: 880 },
              { id: "system-stats", length: 190, priority: 620 },
              { id: "temperature", length: 67, priority: 640 },
              { id: "bar-size-pill", length: 32, priority: 950 }
            ];
            const result = model.fit(items, 391);
            console.log(JSON.stringify({
              kept: items.filter((item, index) => result.visible[index]).map(item => item.id),
              usedLength: result.usedLength
            }));
            """
        )

        result = run_bar_model_script(script)
        self.assertIn("bar-size-pill", result["kept"])
        self.assertLessEqual(result["usedLength"], 391)
        qml = (ROOT / "lacuna.bar" / "OmarchyBar.qml").read_text(encoding="utf-8")
        self.assertIn('if (id === "lacuna.bar-size-pill") return 950', qml)

    def test_oversized_modules_are_hidden_and_ties_keep_layout_order(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarResponsiveModel.js");
            const oversized = model.fit([{ length: 240, priority: 1000 }], 120);
            const ties = model.fit([
              { id: "first", length: 70, priority: 500 },
              { id: "second", length: 70, priority: 500 }
            ], 70);
            console.log(JSON.stringify({ oversized, ties }));
            """
        )

        result = run_bar_model_script(script)
        self.assertEqual([False], result["oversized"]["visible"])
        self.assertEqual(1, result["oversized"]["hiddenCount"])
        self.assertEqual([True, False], result["ties"]["visible"])


if __name__ == "__main__":
    unittest.main()
