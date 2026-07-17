import json
import shutil
import subprocess
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class PortraitBarModelTests(unittest.TestCase):
    def run_model(self, body: str):
        node = shutil.which("node")
        if not node:
            raise unittest.SkipTest("node is not installed")
        script = 'const model = require("./lacuna.bar/PortraitBarModel.js");\n' + textwrap.dedent(body)
        result = subprocess.run([node, "-e", script], cwd=ROOT, text=True, capture_output=True, check=False)
        if result.returncode != 0:
            raise AssertionError(result.stderr or result.stdout)
        return json.loads(result.stdout)

    def test_routes_canonical_ids_to_standalone_companion_regions(self):
        data = self.run_model(
            """
            const aliases = {
              "legacy.codex": "lacuna.codex-usage",
              "legacy.stats": "lacuna.system-stats",
              "legacy.theme": "lacuna.theme"
            };
            const layout = {
              left: ["legacy.theme", "lacuna.claude-usage", "custom.left"],
              center: ["legacy.codex", "lacuna.temperature", "custom.center"],
              right: ["legacy.stats", "lacuna.wallpaper", "custom.right"]
            };
            console.log(JSON.stringify(model.routeLayout(layout, id => aliases[id] || id)));
            """
        )
        self.assertEqual(["custom.left"], data["primary"]["left"])
        self.assertEqual(["custom.center"], data["primary"]["center"])
        self.assertEqual(["custom.right"], data["primary"]["right"])
        self.assertEqual(["lacuna.claude-usage", "legacy.codex"], data["companion"]["left"])
        self.assertEqual(["lacuna.temperature", "legacy.stats"], data["companion"]["center"])
        self.assertEqual(["legacy.theme", "lacuna.wallpaper"], data["companion"]["right"])

    def test_preserves_order_metadata_unknown_entries_and_exact_membership(self):
        data = self.run_model(
            """
            const layout = {
              left: [
                {id:"custom.a", settings:{n:1}, future:{keep:true}},
                {id:"lacuna.codex-usage", token:"first"},
                {id:"custom.b", token:"last"}
              ],
              center: [
                {id:"lacuna.system-stats", settings:{mode:"cpu"}},
                {id:"lacuna.temperature", metadata:[1,2,3]}
              ],
              right: [
                {id:"lacuna.theme", settings:{variant:"dark"}},
                {id:"lacuna.wallpaper", opaque:{json:true}}
              ]
            };
            const before = JSON.stringify(layout);
            const routed = model.routeLayout(layout, id => id);
            const flattened = ["left","center","right"].flatMap(region =>
              routed.primary[region].concat(routed.companion[region]));
            console.log(JSON.stringify({routed, flattened, unchanged: before === JSON.stringify(layout)}));
            """
        )
        self.assertTrue(data["unchanged"])
        self.assertEqual(7, len(data["flattened"]))
        self.assertEqual(
            ["custom.a", "custom.b"],
            [entry["id"] for entry in data["routed"]["primary"]["left"]],
        )
        self.assertEqual({"n": 1}, data["routed"]["primary"]["left"][0]["settings"])
        self.assertEqual({"keep": True}, data["routed"]["primary"]["left"][0]["future"])
        self.assertEqual([1, 2, 3], data["routed"]["companion"]["center"][1]["metadata"])
        self.assertEqual({"json": True}, data["routed"]["companion"]["right"][1]["opaque"])

    def test_duplicate_entries_are_routed_as_distinct_members(self):
        data = self.run_model(
            """
            const one = {id:"lacuna.codex-usage", instance:1};
            const two = {id:"lacuna.codex-usage", instance:2};
            const routed = model.routeLayout({left:[one,two],center:[],right:[]}, id => id);
            console.log(JSON.stringify(routed.companion.left));
            """
        )
        self.assertEqual([1, 2], [entry["instance"] for entry in data])


if __name__ == "__main__":
    unittest.main()
