import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlWorkspaceBarStyleBehaviorTests(unittest.TestCase):
    def test_workspace_numbers_use_shared_bar_size_and_weight_in_all_states(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var inactive: null
  property var active: null
  property var large: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.workspaces/components/LacunaWorkspaceButton.qml')}", Component.PreferSynchronous)
    inactive = component.createObject(root, {{ text: "1", barSize: 26, active: false }})
    active = component.createObject(root, {{ text: "2", barSize: 26, active: true }})
    large = component.createObject(root, {{ text: "3", barSize: 30, active: false }})
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        inactiveSize: inactive.labelPixelSize,
        inactiveWeight: inactive.labelFontWeight,
        activeSize: active.labelPixelSize,
        activeWeight: active.labelFontWeight,
        largeSize: large.labelPixelSize,
        largeWeight: large.labelFontWeight,
        demiBold: Font.DemiBold
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["inactiveSize"], 12)
        self.assertEqual(result["activeSize"], 12)
        self.assertEqual(result["largeSize"], 13)
        self.assertEqual(result["inactiveWeight"], result["demiBold"])
        self.assertEqual(result["activeWeight"], result["demiBold"])
        self.assertEqual(result["largeWeight"], result["demiBold"])

    def test_active_only_mode_projects_one_workspace_without_losing_count(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var multi: null
  property var activeOnly: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.workspaces/Widget.qml')}", Component.PreferSynchronous)
    multi = component.createObject(root, {{ settings: {{ workspaceCount: 3, showDynamicExtra: false }} }})
    activeOnly = component.createObject(root, {{
      settings: {{ workspaceCount: 3, showDynamicExtra: true, activeWorkspaceOnly: true }}
    }})
    probe.restart()
  }}

  Timer {{
    id: probe
    interval: 30
    onTriggered: {{
      var defaultIds = root.multi.workspaceIds()
      var activeId = root.activeOnly.activeWorkspace()
      var activeIds = root.activeOnly.workspaceIds()
      root.activeOnly.settings = ({{
        workspaceCount: 3,
        showDynamicExtra: false,
        activeWorkspaceOnly: false
      }})
      var restoredIds = root.activeOnly.workspaceIds()
      console.log("BEHAVE " + JSON.stringify({{
        defaultIds: defaultIds,
        activeId: activeId,
        activeIds: activeIds,
        restoredIds: restoredIds
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["defaultIds"], [1, 2, 3])
        self.assertEqual(result["activeIds"], [result["activeId"]])
        self.assertEqual(result["restoredIds"], [1, 2, 3])

    def test_settings_registry_reads_active_only_from_bar_layout(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var registry: null

  Component.onCompleted: {{
    var component = Qt.createComponent("{qml_url('lacuna.menu/menu/MenuRegistry.qml')}", Component.PreferSynchronous)
    registry = component.createObject(root)
    registry.shellBarConfig = ({{
      layout: {{
        left: [{{ id: "lacuna.menu-button" }}, {{ id: "lacuna.workspaces", activeWorkspaceOnly: true }}],
        center: [],
        right: []
      }}
    }})
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 30
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        activeOnly: root.registry.workspacesActiveOnly(),
        missingDefaultsOff: root.registry.shellBarWidgetSettings("missing.widget").activeWorkspaceOnly === undefined
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertTrue(result["activeOnly"])
        self.assertTrue(result["missingDefaultsOff"])
