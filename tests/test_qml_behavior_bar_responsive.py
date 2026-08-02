import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "requires a live Wayland Quickshell session")
class BarResponsiveBehaviorTests(unittest.TestCase):
    def test_logical_monitor_width_and_density_recompute_independently(self):
        qml = f'''
import Quickshell
import QtQuick
import "{qml_url("lacuna.bar/BarResponsiveModel.js")}" as BarResponsiveModel

ShellRoot {{
  QtObject {{
    id: probe
    property real logicalWidth: 1920
    property real outputScale: 1
    property int barSize: 32
    readonly property bool compact: barSize <= 26
    readonly property var plan: BarResponsiveModel.horizontalPlan(
      logicalWidth,
      compact ? 2 : 8,
      compact ? 6 : 4,
      compact ? 108 : 115,
      barSize
    )

    function kept(items) {{
      var result = BarResponsiveModel.fit(items, plan.sideLength)
      var ids = []
      for (var i = 0; i < items.length; i++) {{
        if (result.visible[i]) ids.push(items[i].id)
      }}
      return ids
    }}

    function snapshot(label, items) {{
      console.log("BEHAVE " + JSON.stringify({{
        label: label,
        logicalWidth: logicalWidth,
        outputScale: outputScale,
        widthClass: plan.widthClass,
        sideLength: plan.sideLength,
        centerLength: plan.centerLength,
        kept: kept(items)
      }}))
    }}

    Component.onCompleted: {{
      var full = [
        {{ id: "menu", length: 32, priority: 1000 }},
        {{ id: "workspaces", length: 236, priority: 960 }},
        {{ id: "codex", length: 104, priority: 700 }},
        {{ id: "claude", length: 104, priority: 700 }},
        {{ id: "mpris", length: 130, priority: 600 }}
      ]
      var compactItems = [
        {{ id: "menu", length: 26, priority: 1000 }},
        {{ id: "workspaces", length: 180, priority: 960 }},
        {{ id: "codex", length: 70, priority: 700 }},
        {{ id: "claude", length: 77, priority: 700 }},
        {{ id: "mpris", length: 121, priority: 600 }}
      ]

      snapshot("full-1x", full)
      logicalWidth = 960
      outputScale = 2
      snapshot("full-2x", full)
      barSize = 26
      snapshot("compact-2x", compactItems)
      logicalWidth = 1920
      outputScale = 1
      snapshot("compact-1x", compactItems)
      Qt.callLater(Qt.quit)
    }}
  }}
}}
'''
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        rows = parse_behave(output)

        self.assertEqual(
            ["full-1x", "full-2x", "compact-2x", "compact-1x"],
            [row["label"] for row in rows],
        )
        self.assertEqual([1920, 960, 960, 1920], [row["logicalWidth"] for row in rows])
        self.assertEqual([1, 2, 2, 1], [row["outputScale"] for row in rows])
        self.assertEqual(["wide", "constrained", "constrained", "wide"], [row["widthClass"] for row in rows])
        self.assertEqual(
            ["menu", "workspaces", "codex", "claude", "mpris"],
            rows[0]["kept"],
        )
        self.assertEqual(["menu", "workspaces", "codex"], rows[1]["kept"])
        self.assertEqual(["menu", "workspaces", "codex", "claude"], rows[2]["kept"])
        self.assertEqual(
            ["menu", "workspaces", "codex", "claude", "mpris"],
            rows[3]["kept"],
        )
        for row in rows:
            self.assertGreater(row["sideLength"], 0)
            self.assertGreater(row["centerLength"], 0)

    def test_hiding_a_slot_closes_owned_interaction_state(self):
        qml = f'''
import Quickshell
import QtQuick
import "{qml_url("lacuna.bar/BarResponsiveModel.js")}" as BarResponsiveModel

ShellRoot {{
  id: shell
  property bool closed: false
  property bool tooltipCleared: false
  property bool dragCleared: false
  property var slot: null

  QtObject {{
    id: item
    function close() {{ shell.closed = true }}
  }}

  QtObject {{
    id: host
    property var activePopout: item
    property var tooltipTarget: item
    property var pendingTooltipTarget: null
    property var barDragSource: null
    function clearTooltip() {{
      tooltipTarget = null
      tooltipCleared = true
    }}
    function clearBarDrag() {{
      barDragSource = null
      dragCleared = true
    }}
  }}

  Component.onCompleted: {{
    slot = {{ activeItem: item }}
    host.barDragSource = slot
    BarResponsiveModel.prepareSlotForHide(host, slot)
    console.log("BEHAVE " + JSON.stringify({{
      closed: closed,
      popoutCleared: host.activePopout === null,
      tooltipCleared: tooltipCleared,
      dragCleared: dragCleared
    }}))
    Qt.callLater(Qt.quit)
  }}
}}
'''
        output = run_quickshell(qml)
        require_no_qml_errors(output)
        row = parse_behave(output)[-1]
        self.assertEqual(
            {
                "closed": True,
                "popoutCleared": True,
                "tooltipCleared": True,
                "dragCleared": True,
            },
            row,
        )


if __name__ == "__main__":
    unittest.main()
