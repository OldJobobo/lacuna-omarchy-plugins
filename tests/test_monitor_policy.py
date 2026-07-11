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
    def test_sidebar_policies_select_outputs_deterministically(self):
        script = textwrap.dedent(
            """
            const policy = require("./lacuna.menu/menu/MonitorPolicy.js");
            const screens = [{ name: "DP-1" }, { name: "DP-2" }, { name: "DP-3" }];
            const cases = {
              auto: policy.chooseSidebarScreens(screens, "auto", "DP-3", []).map(screen => screen.name),
              pinned: policy.chooseSidebarScreens(screens, "pinned", "DP-3", ["DP-1", "DP-3"]).map(screen => screen.name),
              pinnedPrimary: policy.choosePrimarySidebarScreen(screens, "pinned", "DP-3", ["DP-1", "DP-2"]).name,
              pinnedFlyout: policy.chooseFlyoutScreen(screens, "pinned", "DP-3", ["DP-1", "DP-3"]).name,
              pinnedFallbackFlyout: policy.chooseFlyoutScreen(screens, "pinned", "DP-3", ["DP-1", "DP-2"]).name,
              all: policy.chooseSidebarScreens(screens, "all", "DP-3", []).map(screen => screen.name),
              allFlyout: policy.chooseFlyoutScreen(screens, "all", "DP-3", []).name,
              missingFocus: policy.chooseSidebarScreens(screens, "auto", "DP-9", []).map(screen => screen.name),
              missingFocusFlyout: policy.chooseFlyoutScreen(screens, "auto", "DP-9", []).name,
              emptyFocus: policy.chooseSidebarScreens(screens, "auto", "", []).map(screen => screen.name),
              noScreens: policy.chooseSidebarScreens([], "auto", "DP-3", []),
              normalizedNames: policy.normalizeMonitorNames([" DP-1 ", "DP-1", "", "DP-2"]),
              isTarget: policy.isSidebarScreen([{ name: "DP-2" }], { name: "DP-2" }),
              screenName: policy.screenName({ name: "DP-2" })
            };
            console.log(JSON.stringify(cases));
            """
        )

        data = run_policy_script(script)

        self.assertEqual(["DP-3"], data["auto"])
        self.assertEqual(["DP-1", "DP-3"], data["pinned"])
        self.assertEqual("DP-1", data["pinnedPrimary"])
        self.assertEqual("DP-3", data["pinnedFlyout"])
        self.assertEqual("DP-1", data["pinnedFallbackFlyout"])
        self.assertEqual(["DP-1", "DP-2", "DP-3"], data["all"])
        self.assertEqual("DP-3", data["allFlyout"])
        self.assertEqual(["DP-1"], data["missingFocus"])
        self.assertEqual("DP-1", data["missingFocusFlyout"])
        self.assertEqual(["DP-1"], data["emptyFocus"])
        self.assertEqual([], data["noScreens"])
        self.assertEqual(["DP-1", "DP-2"], data["normalizedNames"])
        self.assertTrue(data["isTarget"])
        self.assertEqual("DP-2", data["screenName"])

    def test_menu_uses_policy_and_refreshes_focus_state(self):
        menu = (ROOT / "lacuna.menu/menu/MenuWindow.qml").read_text(encoding="utf-8")

        self.assertIn('import "MonitorPolicy.js" as MonitorPolicy', menu)
        self.assertIn("MonitorPolicy.chooseSidebarScreens(Quickshell.screens, sidebarMonitorPolicy, activeMonitorName, sidebarMonitorNames)", menu)
        self.assertIn("MonitorPolicy.chooseFlyoutScreen(Quickshell.screens, sidebarMonitorPolicy, activeMonitorName, sidebarMonitorNames)", menu)
        self.assertIn("readonly property var sidebarScreens", menu)
        self.assertIn("readonly property var flyoutScreen", menu)
        self.assertIn("function flyoutVisibleOnScreen(screen)", menu)
        self.assertIn("function flyoutOpenOnScreen(screen)", menu)
        self.assertIn("function flyoutInteractiveOnScreen(screen)", menu)
        self.assertIn('property string requestedInteractionMonitorName: ""', menu)
        self.assertIn("Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor", menu)
        self.assertIn("Hyprland.focusedMonitor.name", menu)
        self.assertIn('property string settledFocusedMonitorName: ""', menu)
        self.assertIn("id: monitorHandoffTimer", menu)
        self.assertIn("interval: root.menuMotionTokensRef.reveal", menu)
        self.assertIn('sidebarMonitorPolicy === "auto" || requestedInteractionMonitorName === ""', menu)
        self.assertIn("? focusedMonitorName : requestedInteractionMonitorName", menu)
        self.assertIn("function flyoutLaneWidthFor(screen)", menu)
        self.assertIn("model: root.sidebarScreens", menu)
        self.assertIn("function setSidebarMonitorPolicy", menu)
        self.assertIn("function toggleSidebarMonitor", menu)
        self.assertIn('name === "focusedmon" || name.indexOf("monitor") >= 0', menu)
        self.assertIn("root.shellSettingsService.refresh()", menu)


if __name__ == "__main__":
    unittest.main()
