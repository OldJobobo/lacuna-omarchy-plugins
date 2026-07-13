import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlBarIconSizeBehaviorTests(unittest.TestCase):
    def test_first_party_icon_widgets_resolve_to_shared_large_bar_size(self):
        component_urls = [
            qml_url("lacuna.audio/Widget.qml"),
            qml_url("lacuna.bar-size-pill/Widget.qml"),
            qml_url("lacuna.bluetooth/Widget.qml"),
            qml_url("lacuna.compact-pill/Widget.qml"),
            qml_url("lacuna.idle-inhibitor/Widget.qml"),
            qml_url("lacuna.indicators/Widget.qml"),
            qml_url("lacuna.menu-button/Widget.qml"),
            qml_url("lacuna.network/Widget.qml"),
            qml_url("lacuna.nightlight/Widget.qml"),
            qml_url("lacuna.notifications/Widget.qml"),
            qml_url("lacuna.power/Widget.qml"),
            qml_url("lacuna.reminders/Widget.qml"),
            qml_url("lacuna.screen-recording/Widget.qml"),
            qml_url("lacuna.system-update/Widget.qml"),
            qml_url("lacuna.voxtype/Widget.qml"),
        ]
        urls = ",\n      ".join(f'"{url}"' for url in component_urls)
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var widgets: []

  QtObject {{
    id: mockBar
    property bool vertical: false
    property int barSize: 30
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#2979ff"
    property color urgent: "#ef1234"
    property string fontFamily: "Hack Nerd Font Propo"
    property string position: "top"
    property var shell: null
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
    function run(command) {{}}
    function shellQuote(value) {{ return "'" + value + "'" }}
  }}

  Component.onCompleted: {{
    var urls = [
      {urls}
    ]
    var created = []
    for (var i = 0; i < urls.length; i++) {{
      var component = Qt.createComponent(urls[i], Component.PreferSynchronous)
      created.push(component.createObject(root, {{
        bar: mockBar,
        settings: {{ interval: 999999, showInactive: true }}
      }}))
    }}
    widgets = created
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 40
    onTriggered: {{
      var sizes = []
      for (var i = 0; i < widgets.length; i++) sizes.push(widgets[i].topbarIconSize)
      console.log("BEHAVE " + JSON.stringify({{
        sizes: sizes,
        idleGlyphSizes: [widgets[4].idleGlyphSize, widgets[5].idleGlyphSize]
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        self.assertEqual(result["sizes"], [15] * len(component_urls))
        self.assertEqual(result["idleGlyphSizes"], [12, 12])
