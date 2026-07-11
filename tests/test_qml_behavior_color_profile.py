import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlColorProfileBehaviorTests(unittest.TestCase):
    def test_colorful_profile_uses_named_role_hues_for_active_widgets(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var profile: null
  Component.onCompleted: {{
    var c = Qt.createComponent("{qml_url('shared/qml/simple-bar/ColorProfile.qml')}", Component.PreferSynchronous)
    profile = c.createObject(root, {{
      role: "network",
      widgetSettings: {{ colorProfile: "colorful" }}
    }})
    profile.loadTheme('background = "#101010"\\nforeground = "#eeeeee"\\naccent = "#aaaa00"\\ngreen = "#12ab34"\\nred = "#ef1234"')
    finish.restart()
  }}
  Timer {{
    id: finish
    interval: 20
    onTriggered: {{
      profile.loadTheme('background = "#101010"\\nforeground = "#eeeeee"\\naccent = "#aaaa00"\\ngreen = "#12ab34"\\nred = "#ef1234"')
      console.log("BEHAVE " + JSON.stringify({{
        profile: profile.profile,
        role: profile.roleColor("network", "#eeeeee").toString(),
        active: profile.statusColor("active", "network").toString(),
        critical: profile.statusColor("critical", "network").toString()
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]
        self.assertEqual(result["profile"], "colorful")
        self.assertEqual(result["role"], "#12ab34")
        self.assertEqual(result["active"], "#12ab34")
        self.assertEqual(result["critical"], "#ef1234")
