import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class ReducedMotionAndTypographyContracts(unittest.TestCase):
    def test_vendored_motion_and_color_profiles_expose_reduced_motion(self):
        color = read("shared/qml/simple-bar/ColorProfile.qml")
        motion = read("shared/qml/simple-bar/MotionTokens.qml")
        self.assertIn("property bool reduceMotion: false", color)
        self.assertIn("reduceMotion = data.reduceMotion === true", color)
        self.assertIn("property bool animationDisabled: false", motion)
        self.assertIn("return animationDisabled ? 0", motion)

        for widget in ROOT.glob("lacuna.*/Widget.qml"):
            text = widget.read_text(encoding="utf-8")
            if "id: colorProfile" in text and "id: motionTokens" in text:
                self.assertIn("animationDisabled: colorProfile.reduceMotion", text, widget.as_posix())

    def test_menu_motion_tokens_are_pure_and_owner_injected(self):
        motion = read("lacuna.menu/services/MotionTokens.qml")
        self.assertNotIn("FileView", motion)
        self.assertNotIn("settingsPath", motion)
        menu = read("lacuna.menu/menu/MenuWindow.qml")
        self.assertIn("animationDisabled: root.reduceMotionEnabled", menu)
        self.assertIn("motionTokens: root.menuMotionTokensRef", menu)
        content = read("lacuna.menu/menu/MenuContent.qml")
        self.assertIn('LacunaAnim { motion: "normal"; motionTokens: root.motionTokens }', content)
        self.assertIn("motionTokens: root.motionTokens", content)
        self.assertNotIn("FileView", read("lacuna.shell-settings/services/MotionTokens.qml"))

    def test_rich_flyouts_consume_reduced_motion_tokens(self):
        flyouts = [
            "lacuna.audio/AudioFlyout.qml",
            "lacuna.bluetooth/BluetoothFlyout.qml",
            "lacuna.claude-usage/ClaudeUsageFlyout.qml",
            "lacuna.codex-usage/CodexUsageFlyout.qml",
            "lacuna.clock/CalendarFlyout.qml",
            "lacuna.network/NetworkFlyout.qml",
            "lacuna.notifications/NotificationsFlyout.qml",
            "lacuna.power/PowerFlyout.qml",
            "lacuna.system-stats/TelemetryFlyout.qml",
            "lacuna.temperature/ThermalFlyout.qml",
            "lacuna.theme/ThemeFlyout.qml",
            "lacuna.wallpaper/WallpaperFlyout.qml",
            "lacuna.weather/WeatherFlyout.qml",
        ]
        for relative in flyouts:
            text = read(relative)
            self.assertIn("property bool reduceMotion: false", text, relative)
            self.assertIn("animationDisabled: root.reduceMotion", text, relative)
            self.assertNotRegex(text, r"duration:\s*(190|220)\b", relative)

    def test_status_flyouts_receive_theme_urgent_role(self):
        for relative in ["lacuna.power/Widget.qml", "lacuna.network/Widget.qml"]:
            self.assertIn("urgentColor: colorProfile.urgent", read(relative), relative)

    def test_ambient_overlays_stop_infinite_motion_without_unmapping(self):
        overlays = [
            "lacuna.aurora-drift/Overlay.qml",
            "lacuna.cinematic-light-overlay/Overlay.qml",
            "lacuna.crt-overlay/Overlay.qml",
            "lacuna.dust-motes-overlay/Overlay.qml",
            "lacuna.film-grain-overlay/Overlay.qml",
            "lacuna.god-rays-overlay/Overlay.qml",
            "lacuna.rainfall-overlay/Overlay.qml",
            "lacuna.vhs-overlay/Overlay.qml",
        ]
        hosted = [
            "lacuna.ambience-host/effects/AuroraDriftEffect.qml",
            "lacuna.ambience-host/effects/CinematicLightEffect.qml",
            "lacuna.ambience-host/effects/CrtEffect.qml",
            "lacuna.ambience-host/effects/DustMotesEffect.qml",
            "lacuna.ambience-host/effects/FilmGrainEffect.qml",
            "lacuna.ambience-host/effects/GodRaysEffect.qml",
            "lacuna.ambience-host/effects/RainfallEffect.qml",
            "lacuna.ambience-host/effects/VhsEffect.qml",
        ]
        for relative in overlays + hosted:
            text = read(relative)
            self.assertIn("readonly property bool reducedMotion", text, relative)
            self.assertNotIn("running: root.effectVisible\n", text, relative)
            self.assertIn("running: root.effectVisible && !root.reducedMotion", text, relative)

    def test_menu_and_settings_use_canonical_type_tokens(self):
        canonical = read("shared/qml/LacunaTokens.qml")
        self.assertIn("readonly property int textFeature: 18", canonical)
        self.assertIn("readonly property int iconHero: 46", canonical)
        self.assertEqual(canonical, read("lacuna.menu/components/LacunaTokens.qml"))
        self.assertEqual(canonical, read("lacuna.shell-settings/components/LacunaTokens.qml"))

        migrated = [
            "lacuna.menu/modules/LacunaMenuItem.qml",
            "lacuna.menu/menu/FlyoutAppPickerContent.qml",
            "lacuna.menu/menu/FlyoutMediaPlayerContent.qml",
            "lacuna.menu/menu/MenuContent.qml",
            "lacuna.menu/menu/MenuRail.qml",
            "lacuna.menu/menu/MenuSection.qml",
        ] + [p.relative_to(ROOT).as_posix() for p in (ROOT / "lacuna.menu/settings").glob("*.qml")]
        for relative in migrated:
            text = read(relative)
            self.assertNotRegex(text, r'font(?:Family|\.family):\s*"', relative)
            self.assertNotRegex(text, r"font\.pixelSize:\s*\d", relative)
            self.assertNotRegex(text, r"font\.letterSpacing:\s*\d", relative)


if __name__ == "__main__":
    unittest.main()
