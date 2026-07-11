import json
import subprocess
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run_policy_script(script: str) -> dict:
    result = subprocess.run(
        ["node", "-e", script],
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr or result.stdout)
    return json.loads(result.stdout)


class MonitorPolicyTests(unittest.TestCase):
    def test_sidebar_follows_focus_and_falls_back_deterministically(self):
        script = textwrap.dedent(
            """
            const policy = require("./lacuna.menu/menu/MonitorPolicy.js");
            const screens = [{ name: "DP-1" }, { name: "DP-2" }, { name: "DP-3" }];
            const cases = {
              focused: policy.chooseSidebarScreen(screens, "DP-3").name,
              missingFocus: policy.chooseSidebarScreen(screens, "DP-9").name,
              emptyFocus: policy.chooseSidebarScreen(screens, "").name,
              noScreens: policy.chooseSidebarScreen([], "DP-3"),
              screenName: policy.screenName({ name: "DP-2" })
            };
            console.log(JSON.stringify(cases));
            """
        )

        data = run_policy_script(script)

        self.assertEqual("DP-3", data["focused"])
        self.assertEqual("DP-1", data["missingFocus"])
        self.assertEqual("DP-1", data["emptyFocus"])
        self.assertIsNone(data["noScreens"])
        self.assertEqual("DP-2", data["screenName"])

    def test_menu_uses_policy_and_refreshes_focus_state(self):
        menu = (ROOT / "lacuna.menu/menu/MenuWindow.qml").read_text(encoding="utf-8")

        self.assertIn('import "MonitorPolicy.js" as MonitorPolicy', menu)
        self.assertIn("MonitorPolicy.chooseSidebarScreen(Quickshell.screens, focusedMonitorName)", menu)
        self.assertIn('name === "focusedmon" || name.indexOf("monitor") >= 0', menu)
        self.assertIn("root.shellSettingsService.refresh()", menu)


if __name__ == "__main__":
    unittest.main()
