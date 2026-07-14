from __future__ import annotations

import math
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def frame_geometry(
    *,
    width: int = 1920,
    height: int = 1080,
    active: bool,
    bar_position: str,
    bar_size: int,
    thickness: int,
    radius: int,
    left_occupied: int = 0,
    right_occupied: int = 0,
) -> dict[str, float]:
    t = max(1, thickness)
    r = max(t, radius)
    top_bar = bar_position == "top"
    bottom_bar = bar_position == "bottom"
    left_bar = bar_position == "left"
    right_bar = bar_position == "right"
    top_inset = max(0, bar_size) if top_bar else t
    bottom_inset = max(0, bar_size) if bottom_bar else t
    left_inset = max(0, bar_size) if left_bar else t
    right_inset = max(0, bar_size) if right_bar else t
    outer_x = max(0, bar_size) if left_bar else 0
    outer_y = max(0, bar_size) if top_bar else 0
    outer_right = max(outer_x + 1, width - max(0, bar_size)) if right_bar else width
    outer_bottom = max(outer_y + 1, height - max(0, bar_size)) if bottom_bar else height
    hole_x = max(0, left_occupied if left_occupied > 0 else left_inset)
    hole_y = max(0, top_inset)
    hole_right = max(hole_x + 1, width - (right_occupied if right_occupied > 0 else right_inset))
    hole_bottom = max(hole_y + 1, height - bottom_inset)
    hole_width = max(1, hole_right - hole_x)
    hole_height = max(1, hole_bottom - hole_y)
    min_arc_radius = 0.01
    hole_radius = max(min_arc_radius, min(r, hole_width / 2, hole_height / 2))
    is_renderable = active and width > 0 and height > 0 and hole_width > 0 and hole_height > 0
    caster_hole_x = hole_x if is_renderable else (max(0, bar_size) if left_bar else 0)
    caster_hole_y = hole_y if is_renderable else (max(0, bar_size) if top_bar else 0)
    caster_hole_right = (
        hole_right
        if is_renderable
        else (max(caster_hole_x + 1, width - max(0, bar_size)) if right_bar else width)
    )
    caster_hole_bottom = (
        hole_bottom
        if is_renderable
        else (max(caster_hole_y + 1, height - max(0, bar_size)) if bottom_bar else height)
    )
    return {
        "outerX": outer_x,
        "outerY": outer_y,
        "outerRight": outer_right,
        "outerBottom": outer_bottom,
        "holeX": hole_x,
        "holeY": hole_y,
        "holeRight": hole_right,
        "holeBottom": hole_bottom,
        "holeRadius": hole_radius,
        "casterHoleX": caster_hole_x,
        "casterHoleY": caster_hole_y,
        "casterHoleRight": caster_hole_right,
        "casterHoleBottom": caster_hole_bottom,
    }


def content_rect(
    *,
    screen_width: int,
    screen_height: int,
    frame_enabled: bool,
    position: str,
    bar_size: int,
    thickness: int,
    radius: int,
    corner_pieces: bool = True,
    sidebar_on_left: int = 0,
    sidebar_on_right: int = 0,
) -> dict[str, float | bool]:
    t = max(1, thickness)
    top_inset = max(0, bar_size) if position == "top" else t
    bottom_inset = max(0, bar_size) if position == "bottom" else t
    left_inset = max(0, bar_size) if position == "left" else t
    right_inset = max(0, bar_size) if position == "right" else t
    x = max(0, sidebar_on_left if sidebar_on_left > 0 else left_inset)
    y = max(0, top_inset)
    right = max(x + 1, screen_width - (sidebar_on_right if sidebar_on_right > 0 else right_inset))
    bottom = max(y + 1, screen_height - bottom_inset)
    bleed = max(t + 2, int((radius * 0.5) + 0.999999)) if frame_enabled else 0
    if not frame_enabled or screen_width <= 0 or screen_height <= 0:
        return {"x": 0, "y": 0, "width": max(1, screen_width), "height": max(1, screen_height), "framed": False}
    return {
        "x": max(0, x - bleed),
        "y": max(0, y - bleed),
        "width": max(1, min(screen_width, right + bleed) - max(0, x - bleed)),
        "height": max(1, min(screen_height, bottom + bleed) - max(0, y - bleed)),
        "radius": max(t, radius) if corner_pieces else 0,
        "bleed": bleed,
        "framed": True,
        "innerX": x,
        "innerY": y,
        "innerWidth": max(1, right - x),
        "innerHeight": max(1, bottom - y),
    }


def frame_border_geometry(
    *,
    width: int = 1920,
    height: int = 1080,
    bar_position: str = "top",
    bar_size: int = 32,
    thickness: int = 24,
    radius: int = 32,
    border_width: int = 2,
    left_occupied: int = 0,
    right_occupied: int = 0,
    attached_flyout_visible: bool = False,
    attached_flyout_y: int = 0,
    attached_flyout_height: int = 0,
) -> dict[str, float | bool]:
    base = frame_geometry(
        width=width,
        height=height,
        active=True,
        bar_position=bar_position,
        bar_size=bar_size,
        thickness=thickness,
        radius=radius,
        left_occupied=left_occupied,
        right_occupied=right_occupied,
    )
    border_inset = max(0, border_width / 2)
    border_top = base["holeY"] + border_inset
    border_bottom = base["holeBottom"] - border_inset
    border_radius = max(0.01, base["holeRadius"] - border_inset)
    left_gap_visible = left_occupied > 0 and attached_flyout_visible and attached_flyout_height > 0
    right_gap_visible = right_occupied > 0 and attached_flyout_visible and attached_flyout_height > 0
    gap_top = max(border_top + border_radius, attached_flyout_y - border_inset)
    gap_bottom = min(border_bottom - border_radius, attached_flyout_y + attached_flyout_height + border_inset)
    gap_renderable = gap_bottom > gap_top + border_width
    return {
        "leftAttachmentGapVisible": left_gap_visible,
        "rightAttachmentGapVisible": right_gap_visible,
        "attachmentGapTop": gap_top,
        "attachmentGapBottom": gap_bottom,
        "attachmentGapRenderable": gap_renderable,
        "rightVerticalUpperEndY": gap_top if right_gap_visible and gap_renderable else border_bottom - border_radius,
        "rightVerticalLowerStartY": gap_bottom if right_gap_visible and gap_renderable else border_bottom - border_radius,
        "leftVerticalLowerEndY": gap_bottom if left_gap_visible and gap_renderable else border_top + border_radius,
        "leftVerticalUpperStartY": gap_top if left_gap_visible and gap_renderable else border_top + border_radius,
    }


def clamped_popup_x(
    *,
    target_width: int,
    window_width: int,
    implicit_width: int,
    margin: int,
    join_radius: int,
    panel_width: int,
    shadow_margin: int = 0,
    target_window_x: int,
) -> int:
    local_x = target_width / 2 - (shadow_margin + join_radius + panel_width / 2)
    point_x = target_window_x + local_x
    return round(max(margin, min(point_x, window_width - implicit_width - margin)))


def interpolated_flyout_geometry(
    *,
    progress: float,
    from_y: float,
    from_width: float,
    from_height: float,
    from_connector_width: float,
    to_y: float,
    to_width: float,
    to_height: float,
    to_connector_width: float,
) -> dict[str, float]:
    p = max(0.0, min(1.0, progress))
    blend = lambda start, end: start + (end - start) * p
    return {
        "y": blend(from_y, to_y),
        "width": blend(from_width, to_width),
        "height": blend(from_height, to_height),
        "connectorWidth": blend(from_connector_width, to_connector_width),
    }


def calendar_surface_geometry(edge: str, panel_width: int = 350, panel_height: int = 440, join_radius: int = 13) -> dict[str, int]:
    horizontal = edge in {"top", "bottom"}
    return {
        "width": panel_width + (join_radius * 2 if horizontal else join_radius),
        "height": panel_height + (join_radius if horizontal else join_radius * 2),
        "panelLeft": join_radius if edge in {"top", "bottom", "left"} else 0,
        "panelTop": join_radius if edge in {"top", "left", "right"} else 0,
    }


def calendar_shadow_margins(edge: str, blur_max: int = 28, offset_x: int = 2, offset_y: int = 3) -> dict[str, int]:
    margin = math.ceil(blur_max + max(abs(offset_x), abs(offset_y)))
    far_left = math.ceil(margin + blur_max * 0.6 + max(0, -offset_x))
    far_right = math.ceil(margin + blur_max * 0.6 + max(0, offset_x))
    far_top = math.ceil(margin + blur_max * 0.6 + max(0, -offset_y))
    far_bottom = math.ceil(margin + blur_max * 0.6 + max(0, offset_y))
    return {
        "left": 0 if edge == "left" else (far_left if edge == "right" else margin),
        "right": 0 if edge == "right" else (far_right if edge == "left" else margin),
        "top": 0 if edge == "top" else (far_top if edge == "bottom" else margin),
        "bottom": 0 if edge == "bottom" else (far_bottom if edge == "top" else margin),
    }


class QmlGeometryTests(unittest.TestCase):
    def test_calendar_surface_orients_attachment_and_reveal_on_all_bar_edges(self):
        surface = read("lacuna.clock/BarFlyoutSurface.qml")
        flyout = read("lacuna.clock/CalendarFlyout.qml")

        self.assertEqual(
            {"width": 376, "height": 453, "panelLeft": 13, "panelTop": 13},
            calendar_surface_geometry("top"),
        )
        self.assertEqual(
            {"width": 376, "height": 453, "panelLeft": 13, "panelTop": 0},
            calendar_surface_geometry("bottom"),
        )
        self.assertEqual(
            {"width": 363, "height": 466, "panelLeft": 13, "panelTop": 13},
            calendar_surface_geometry("left"),
        )
        self.assertEqual(
            {"width": 363, "height": 466, "panelLeft": 0, "panelTop": 13},
            calendar_surface_geometry("right"),
        )

        for edge in ("top", "bottom", "left", "right"):
            self.assertIn(f'visible: root.attachmentEdge === "{edge}"', surface)
        self.assertEqual(4, surface.count("strokeWidth: 0"))
        self.assertNotIn("radius:", surface)
        self.assertIn("readonly property real curveKappa: lacunaGeometry.curveKappa", surface)
        self.assertIn('x: root.attachmentEdge === "right" ? root.implicitWidth - width : 0', flyout)
        self.assertIn('y: root.attachmentEdge === "bottom" ? root.implicitHeight - height : 0', flyout)
        self.assertIn("point.x = Math.max(root.margin", flyout)
        self.assertIn("point.y = Math.max(root.margin", flyout)

    def test_calendar_shadow_padding_stays_off_the_attached_edge(self):
        flyout = read("lacuna.clock/CalendarFlyout.qml")

        self.assertEqual({"left": 31, "right": 31, "top": 0, "bottom": 51}, calendar_shadow_margins("top"))
        self.assertEqual({"left": 31, "right": 31, "top": 48, "bottom": 0}, calendar_shadow_margins("bottom"))
        self.assertEqual({"left": 0, "right": 50, "top": 31, "bottom": 31}, calendar_shadow_margins("left"))
        self.assertEqual({"left": 48, "right": 0, "top": 31, "bottom": 31}, calendar_shadow_margins("right"))
        self.assertIn('readonly property int shadowLeftMargin: attachmentEdge === "left"', flyout)
        self.assertIn('readonly property int shadowRightMargin: attachmentEdge === "right"', flyout)
        self.assertIn('readonly property int shadowTopMargin: attachmentEdge === "top"', flyout)
        self.assertIn('readonly property int shadowBottomMargin: attachmentEdge === "bottom"', flyout)
        self.assertIn("implicitWidth: surface.fullWidth + shadowLeftMargin + shadowRightMargin", flyout)
        self.assertIn("implicitHeight: surface.fullHeight + shadowTopMargin + shadowBottomMargin", flyout)

    def test_weather_surface_and_shadow_follow_all_bar_edges(self):
        surface = read("lacuna.weather/BarFlyoutSurface.qml")
        flyout = read("lacuna.weather/WeatherFlyout.qml")

        self.assertEqual(
            {"width": 456, "height": 393, "panelLeft": 13, "panelTop": 13},
            calendar_surface_geometry("top", 430, 380),
        )
        self.assertEqual(
            {"width": 456, "height": 393, "panelLeft": 13, "panelTop": 0},
            calendar_surface_geometry("bottom", 430, 380),
        )
        self.assertEqual(
            {"width": 443, "height": 406, "panelLeft": 13, "panelTop": 13},
            calendar_surface_geometry("left", 430, 380),
        )
        self.assertEqual(
            {"width": 443, "height": 406, "panelLeft": 0, "panelTop": 13},
            calendar_surface_geometry("right", 430, 380),
        )
        for edge in ("top", "bottom", "left", "right"):
            self.assertIn(f'visible: root.attachmentEdge === "{edge}"', surface)
        self.assertEqual(4, surface.count("strokeWidth: 0"))
        self.assertNotIn("radius:", surface)
        self.assertIn("readonly property real curveKappa: lacunaGeometry.curveKappa", surface)
        self.assertIn('x: root.attachmentEdge === "right" ? root.implicitWidth - width : 0', flyout)
        self.assertIn('y: root.attachmentEdge === "bottom" ? root.implicitHeight - height : 0', flyout)
        self.assertIn("point.x = Math.max(root.margin", flyout)
        self.assertIn("point.y = Math.max(root.margin", flyout)

        self.assertEqual({"left": 31, "right": 31, "top": 0, "bottom": 51}, calendar_shadow_margins("top"))
        self.assertEqual({"left": 31, "right": 31, "top": 48, "bottom": 0}, calendar_shadow_margins("bottom"))
        self.assertEqual({"left": 0, "right": 50, "top": 31, "bottom": 31}, calendar_shadow_margins("left"))
        self.assertEqual({"left": 48, "right": 0, "top": 31, "bottom": 31}, calendar_shadow_margins("right"))
        self.assertIn('readonly property int shadowLeftMargin: attachmentEdge === "left"', flyout)
        self.assertIn('readonly property int shadowRightMargin: attachmentEdge === "right"', flyout)
        self.assertIn('readonly property int shadowTopMargin: attachmentEdge === "top"', flyout)
        self.assertIn('readonly property int shadowBottomMargin: attachmentEdge === "bottom"', flyout)

    def test_panel_host_switch_geometry_uses_one_interpolated_set(self):
        host = read("lacuna.menu/menu/LacunaPanelHost.qml")
        self.assertIn("property bool geometrySwitchActive: false", host)
        self.assertIn("function captureEffectiveGeometryForSwitch()", host)
        self.assertIn("readonly property real effectiveFlyoutY: geometrySwitchActive ? interpolate(fromFlyoutY, flyoutY)", host)
        self.assertIn("readonly property real flyoutMaskWidth: flyoutRenderable ? flyoutCurrentWidth : 0", host)

        start = interpolated_flyout_geometry(
            progress=0, from_y=80, from_width=560, from_height=620, from_connector_width=18,
            to_y=160, to_width=420, to_height=440, to_connector_width=0,
        )
        middle = interpolated_flyout_geometry(
            progress=0.5, from_y=80, from_width=560, from_height=620, from_connector_width=18,
            to_y=160, to_width=420, to_height=440, to_connector_width=0,
        )
        end = interpolated_flyout_geometry(
            progress=1, from_y=80, from_width=560, from_height=620, from_connector_width=18,
            to_y=160, to_width=420, to_height=440, to_connector_width=0,
        )
        self.assertEqual(start, {"y": 80, "width": 560, "height": 620, "connectorWidth": 18})
        self.assertEqual(middle, {"y": 120, "width": 490, "height": 530, "connectorWidth": 9})
        self.assertEqual(end, {"y": 160, "width": 420, "height": 440, "connectorWidth": 0})
    def test_frame_geometry_never_paints_under_owning_bar_edge(self):
        frame = read("lacuna.bar/LacunaFrameWindow.qml")
        self.assertIn("readonly property real outerY: topBar ? Math.max(0, barSize) : 0", frame)
        self.assertIn("readonly property real outerX: leftBar ? Math.max(0, barSize) : 0", frame)
        self.assertIn("id: shadowClip", frame)

        for position in ("top", "bottom", "left", "right"):
            g = frame_geometry(active=True, bar_position=position, bar_size=32, thickness=8, radius=14)
            if position == "top":
                self.assertEqual(g["outerY"], 32)
                self.assertEqual(g["holeY"], 32)
            if position == "bottom":
                self.assertEqual(g["outerBottom"], 1048)
                self.assertEqual(g["holeBottom"], 1048)
            if position == "left":
                self.assertEqual(g["outerX"], 32)
                self.assertEqual(g["holeX"], 32)
            if position == "right":
                self.assertEqual(g["outerRight"], 1888)
                self.assertEqual(g["holeRight"], 1888)

    def test_frame_shadow_caster_collapses_to_bar_edge_when_frame_off(self):
        for position in ("top", "bottom", "left", "right"):
            g = frame_geometry(active=False, bar_position=position, bar_size=32, thickness=8, radius=14)
            if position == "top":
                self.assertEqual(g["casterHoleY"], 32)
                self.assertEqual(g["casterHoleX"], 0)
                self.assertEqual(g["casterHoleRight"], 1920)
            elif position == "bottom":
                self.assertEqual(g["casterHoleBottom"], 1048)
            elif position == "left":
                self.assertEqual(g["casterHoleX"], 32)
                self.assertEqual(g["casterHoleBottom"], 1080)
            elif position == "right":
                self.assertEqual(g["casterHoleRight"], 1888)

    def test_frame_shadow_caster_matches_paint_hole_when_frame_on(self):
        g = frame_geometry(
            active=True,
            bar_position="top",
            bar_size=32,
            thickness=24,
            radius=32,
            left_occupied=248,
        )
        self.assertEqual(g["casterHoleX"], g["holeX"])
        self.assertEqual(g["casterHoleY"], g["holeY"])
        self.assertEqual(g["casterHoleRight"], g["holeRight"])
        self.assertEqual(g["casterHoleBottom"], g["holeBottom"])
        self.assertEqual(g["holeX"], 248)

    def test_lacuna_frame_content_rect_accounts_for_bleed_and_sidebar_occlusion(self):
        bar = read("lacuna.bar/Bar.qml")
        self.assertIn("function lacunaFrameContentRect(screen)", bar)
        self.assertIn("hostedSidebarFrameOcclusionWidth", bar)

        unframed = content_rect(
            screen_width=1920,
            screen_height=1080,
            frame_enabled=False,
            position="top",
            bar_size=32,
            thickness=24,
            radius=32,
        )
        self.assertFalse(unframed["framed"])
        self.assertEqual(unframed["width"], 1920)
        framed = content_rect(
            screen_width=1920,
            screen_height=1080,
            frame_enabled=True,
            position="top",
            bar_size=32,
            thickness=24,
            radius=32,
            sidebar_on_left=248,
        )
        self.assertTrue(framed["framed"])
        self.assertEqual(framed["innerX"], 248)
        self.assertEqual(framed["innerY"], 32)
        self.assertEqual(framed["bleed"], 26)
        self.assertEqual(framed["x"], 222)
        self.assertEqual(framed["y"], 6)

    def test_multi_monitor_matrix_keeps_sidebar_occlusion_on_selected_output(self):
        outputs = [
            {"name": "DP-1", "width": 2560, "height": 1440, "transform": 0},
            {"name": "DP-2", "width": 1920, "height": 1080, "transform": 0},
            {"name": "DP-3", "width": 2560, "height": 1440, "transform": 1},
        ]

        for focused_name in ("DP-1", "DP-3"):
            for output in outputs:
                selected = output["name"] == focused_name
                geometry = content_rect(
                    screen_width=output["width"],
                    screen_height=output["height"],
                    frame_enabled=True,
                    position="top",
                    bar_size=32,
                    thickness=8,
                    radius=14,
                    sidebar_on_left=310 if selected else 0,
                )

                self.assertTrue(geometry["framed"], output["name"])
                self.assertEqual(310 if selected else 8, geometry["innerX"], output["name"])
                self.assertGreater(geometry["innerWidth"], 0, output["name"])
                self.assertGreater(geometry["innerHeight"], 0, output["name"])

    def test_frame_border_attachment_gap_only_when_flyout_attached_and_renderable(self):
        border = read("lacuna.bar/LacunaFrameBorderWindow.qml")
        self.assertIn("readonly property bool leftAttachmentGapVisible", border)
        self.assertIn("readonly property bool rightAttachmentGapVisible", border)
        self.assertIn("readonly property bool attachmentGapRenderable", border)
        self.assertIn("PathMove", border)

        closed = frame_border_geometry(left_occupied=248, attached_flyout_visible=False)
        self.assertFalse(closed["leftAttachmentGapVisible"])
        self.assertFalse(closed["attachmentGapRenderable"])

        too_short = frame_border_geometry(
            left_occupied=248,
            attached_flyout_visible=True,
            attached_flyout_y=40,
            attached_flyout_height=2,
        )
        self.assertTrue(too_short["leftAttachmentGapVisible"])
        self.assertFalse(too_short["attachmentGapRenderable"])

        attached = frame_border_geometry(
            right_occupied=248,
            attached_flyout_visible=True,
            attached_flyout_y=180,
            attached_flyout_height=360,
        )
        self.assertTrue(attached["rightAttachmentGapVisible"])
        self.assertTrue(attached["attachmentGapRenderable"])
        self.assertEqual(attached["rightVerticalUpperEndY"], attached["attachmentGapTop"])
        self.assertEqual(attached["rightVerticalLowerStartY"], attached["attachmentGapBottom"])

    def test_notification_and_usage_popup_x_positions_are_clamped_to_window(self):
        notifications = read("lacuna.notifications/NotificationsFlyout.qml")
        claude = read("lacuna.claude-usage/ClaudeUsageFlyout.qml")
        codex = read("lacuna.codex-usage/CodexUsageFlyout.qml")
        for text in (notifications, claude, codex):
            self.assertIn("point.x = Math.max(root.margin, Math.min(point.x, window.width - root.implicitWidth - root.margin))", text)
            self.assertIn("popupAnchor.rect.x = Math.round(point.x)", text)

        self.assertEqual(
            clamped_popup_x(
                target_width=32,
                window_width=800,
                implicit_width=420,
                margin=8,
                join_radius=13,
                panel_width=420,
                target_window_x=4,
            ),
            8,
        )
        self.assertEqual(
            clamped_popup_x(
                target_width=32,
                window_width=800,
                implicit_width=420,
                margin=8,
                join_radius=13,
                panel_width=420,
                target_window_x=760,
            ),
            372,
        )
        self.assertEqual(
            clamped_popup_x(
                target_width=32,
                window_width=1000,
                implicit_width=360,
                margin=8,
                join_radius=13,
                panel_width=292,
                shadow_margin=36,
                target_window_x=500,
            ),
            321,
        )


if __name__ == "__main__":
    unittest.main()
