import unittest

from qml_harness import HAVE_SESSION, parse_behave, qml_url, require_no_qml_errors, run_quickshell


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class QmlColorProfileBehaviorTests(unittest.TestCase):
    def test_theme_and_wallpaper_widgets_share_equal_bar_seam_spacing(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var themeWidget: null
  property var wallpaperWidget: null

  QtObject {{
    id: mockBar
    property bool vertical: false
    property int barSize: 30
    property color foreground: "#eeeeee"
    property color background: "#101010"
    property color accent: "#aaaa00"
    property color urgent: "#ef1234"
    property string position: "top"
    property string fontFamily: "Hack Nerd Font Propo"
    function showTooltip(owner, text) {{}}
    function hideTooltip(owner) {{}}
  }}

  Component.onCompleted: {{
    var theme = Qt.createComponent("{qml_url('lacuna.theme/Widget.qml')}", Component.PreferSynchronous)
    var wallpaper = Qt.createComponent("{qml_url('lacuna.wallpaper/Widget.qml')}", Component.PreferSynchronous)
    themeWidget = theme.createObject(root, {{ bar: mockBar, settings: {{ enabled: true }} }})
    wallpaperWidget = wallpaper.createObject(root, {{ bar: mockBar, settings: {{ enabled: true }} }})
    finish.restart()
  }}

  Timer {{
    id: finish
    interval: 40
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        themeSpacing: themeWidget.contentSpacing,
        themePadding: themeWidget.horizontalPadding,
        wallpaperSpacing: wallpaperWidget.contentSpacing,
        wallpaperPadding: wallpaperWidget.horizontalPadding
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]

        for prefix in ("theme", "wallpaper"):
            self.assertEqual(result[f"{prefix}Spacing"], 5)
            self.assertEqual(result[f"{prefix}Padding"], 5)

    def test_theme_and_wallpaper_profiles_color_roles_without_changing_foreground(self):
        qml = f"""
import Quickshell
import QtQuick

ShellRoot {{
  id: root
  property var themeProfile: null
  property var wallpaperProfile: null
  property string themeIcon: ""
  property string themeText: ""
  property string wallpaperIcon: ""
  property string wallpaperText: ""
  Component.onCompleted: {{
    var theme = Qt.createComponent("{qml_url('lacuna.theme/ColorProfile.qml')}", Component.PreferSynchronous)
    var wallpaper = Qt.createComponent("{qml_url('lacuna.wallpaper/ColorProfile.qml')}", Component.PreferSynchronous)
    themeProfile = theme.createObject(root, {{ widgetSettings: {{ colorProfile: "colorful" }} }})
    wallpaperProfile = wallpaper.createObject(root, {{ widgetSettings: {{ colorProfile: "colorful" }} }})
    var colors = 'fg = "#eeeeee"\\nmagenta = "#ab47bc"\\nblue = "#2979ff"'
    themeProfile.loadTheme(colors)
    wallpaperProfile.loadTheme(colors)
    themeIcon = themeProfile.roleColor("theme", themeProfile.foreground).toString()
    themeText = themeProfile.foreground.toString()
    wallpaperIcon = wallpaperProfile.roleColor("wallpaper", wallpaperProfile.foreground).toString()
    wallpaperText = wallpaperProfile.foreground.toString()
    finish.restart()
  }}
  Timer {{
    id: finish
    interval: 20
    onTriggered: {{
      console.log("BEHAVE " + JSON.stringify({{
        themeIcon: root.themeIcon,
        themeText: root.themeText,
        wallpaperIcon: root.wallpaperIcon,
        wallpaperText: root.wallpaperText
      }}))
      Qt.quit()
    }}
  }}
}}
"""
        output = run_quickshell(qml, timeout=8)
        require_no_qml_errors(output)
        result = parse_behave(output)[-1]
        self.assertEqual(result["themeIcon"], "#ab47bc")
        self.assertEqual(result["themeText"], "#eeeeee")
        self.assertEqual(result["wallpaperIcon"], "#2979ff")
        self.assertEqual(result["wallpaperText"], "#eeeeee")

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
