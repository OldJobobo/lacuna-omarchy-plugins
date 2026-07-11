import json
import shutil
import subprocess
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run_bar_model_script(script):
    node = shutil.which("node")
    if not node:
        raise unittest.SkipTest("node is not installed")

    result = subprocess.run(
        [node, "-e", script],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr or result.stdout)
    return json.loads(result.stdout)


class BarModelTests(unittest.TestCase):
    def test_normalizes_positions_and_entry_shapes(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarModel.js");
            const objectEntry = { id: "lacuna.clock", format: "HH:mm", enabled: true };
            const cases = {
              emptyPosition: model.normalizePosition(""),
              invalidPosition: model.normalizePosition("diagonal"),
              validPosition: model.normalizePosition("right"),
              stringEntryId: model.entryId("lacuna.weather"),
              objectEntryId: model.entryId(objectEntry),
              missingEntryId: model.entryId({ format: "HH:mm" }),
              entrySettings: model.entrySettings(objectEntry),
              nonObjectSettings: model.entrySettings("lacuna.clock")
            };
            console.log(JSON.stringify(cases));
            """
        )

        data = run_bar_model_script(script)

        self.assertEqual("top", data["emptyPosition"])
        self.assertEqual("top", data["invalidPosition"])
        self.assertEqual("right", data["validPosition"])
        self.assertEqual("lacuna.weather", data["stringEntryId"])
        self.assertEqual("lacuna.clock", data["objectEntryId"])
        self.assertEqual("", data["missingEntryId"])
        self.assertEqual({"format": "HH:mm", "enabled": True}, data["entrySettings"])
        self.assertEqual({}, data["nonObjectSettings"])

    def test_tray_pinning_and_entry_lookup_are_stable(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarModel.js");
            const entries = [
              { id: "lacuna.menu-button" },
              { id: "omarchy.tray", pinned: true },
              { id: "lacuna.clock" }
            ];
            const left = model.pinTrayToInner(entries, "left").map(model.entryId);
            const right = model.pinTrayToInner(entries, "right").map(model.entryId);
            const cases = {
              left,
              right,
              indexClock: model.entryIndex(entries, "lacuna.clock"),
              indexMissing: model.entryIndex(entries, "lacuna.missing"),
              beforeClock: model.entriesBefore(entries, "lacuna.clock").map(model.entryId),
              afterMenu: model.entriesAfter(entries, "lacuna.menu-button").map(model.entryId)
            };
            console.log(JSON.stringify(cases));
            """
        )

        data = run_bar_model_script(script)

        self.assertEqual(["lacuna.menu-button", "lacuna.clock", "omarchy.tray"], data["left"])
        self.assertEqual(["omarchy.tray", "lacuna.menu-button", "lacuna.clock"], data["right"])
        self.assertEqual(2, data["indexClock"])
        self.assertEqual(-1, data["indexMissing"])
        self.assertEqual(["lacuna.menu-button", "omarchy.tray"], data["beforeClock"])
        self.assertEqual(["omarchy.tray", "lacuna.clock"], data["afterMenu"])

    def test_custom_module_helpers_keep_paths_bounded(self):
        script = textwrap.dedent(
            """
            const model = require("./lacuna.bar/BarModel.js");
            const home = "/home/example";
            const config = "/home/example/.config/omarchy";
            const cases = {
              tilde: model.expandPath("~/bar.qml", home),
              homeVar: model.expandPath("$HOME/bar.qml", home),
              absolute: model.expandPath("/tmp/bar.qml", home),
              safeName: model.customModuleSafeName("local.clock"),
              parentPath: model.customModuleSafeName("../clock"),
              absoluteName: model.customModuleSafeName("/clock"),
              commandType: model.customModuleType({ id: "local.cmd", exec: "date" }),
              qmlType: model.customModuleType({ id: "local.qml", source: "~/Widget.qml" }),
              explicitType: model.customModuleType({ id: "local.custom", type: "builtin" }),
              defaultPath: model.customModulePath({ id: "local.clock" }, home, config),
              sourcePath: model.customModulePath({ id: "local.qml", source: "~/Widget.qml" }, home, config),
              unsafePath: model.customModulePath({ id: "../clock" }, home, config)
            };
            console.log(JSON.stringify(cases));
            """
        )

        data = run_bar_model_script(script)

        self.assertEqual("/home/example/bar.qml", data["tilde"])
        self.assertEqual("/home/example/bar.qml", data["homeVar"])
        self.assertEqual("/tmp/bar.qml", data["absolute"])
        self.assertTrue(data["safeName"])
        self.assertFalse(data["parentPath"])
        self.assertFalse(data["absoluteName"])
        self.assertEqual("command", data["commandType"])
        self.assertEqual("qml", data["qmlType"])
        self.assertEqual("builtin", data["explicitType"])
        self.assertEqual("/home/example/.config/omarchy/bar/modules/local.clock.qml", data["defaultPath"])
        self.assertEqual("/home/example/Widget.qml", data["sourcePath"])
        self.assertEqual("", data["unsafePath"])

if __name__ == "__main__":
    unittest.main()
