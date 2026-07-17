import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DocsContractTests(unittest.TestCase):
    def test_root_design_entry_point_links_authoritative_design_system(self):
        design = (ROOT / "DESIGN.md").read_text(encoding="utf-8")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("docs/lacuna-design-system/README.md", design)
        for name in ["00-philosophy.md", "01-color.md", "02-geometry.md", "03-motion.md", "04-typography.md", "05-components.md"]:
            self.assertIn(name, design)
        self.assertIn("[design-system entry point](DESIGN.md)", readme)

    def test_typography_spec_defines_distinct_tracking_roles(self):
        typography = (ROOT / "docs/lacuna-design-system/04-typography.md").read_text(encoding="utf-8")
        self.assertIn("## Tracking roles", typography)
        self.assertIn("`trackingTitle` | `2.0px` | `1.4px`", typography)
        self.assertIn("`trackingMenuItem` | `0.9px` | `0.6px`", typography)
        self.assertIn("`trackingSection` | `0px` | `0px`", typography)
        self.assertIn("`trackingBody` | `0px` | `0px`", typography)

    def test_docs_have_status_markers(self):
        for path in sorted((ROOT / "docs").glob("*.md")):
            head = "\n".join(path.read_text(encoding="utf-8").splitlines()[:8])
            self.assertIn("Status:", head, str(path.relative_to(ROOT)))

    def test_first_class_docs_structure_exists(self):
        for name in [
            "docs/README.md",
            "docs/install.md",
            "docs/configuration.md",
            "docs/architecture/overview.md",
            "docs/architecture/plugin-contracts.md",
            "docs/architecture/services-and-state.md",
            "docs/architecture/omarchy-integration.md",
            "docs/development/setup.md",
            "docs/development/testing.md",
            "docs/development/release.md",
            "docs/development/troubleshooting.md",
            "docs/plugins/README.md",
            "docs/plugins/bar.md",
            "docs/plugins/menu.md",
            "docs/plugins/widgets.md",
            "docs/plugins/overlays.md",
        ]:
            self.assertTrue((ROOT / name).exists(), name)

    def test_plan_docs_are_separated_from_reference_docs(self):
        root_plan_docs = sorted((ROOT / "docs").glob("*plan*.md"))
        self.assertEqual([], root_plan_docs)

        plan_docs = sorted((ROOT / "docs" / "plans").glob("*.md"))
        self.assertTrue(plan_docs, "docs/plans should contain implementation plans")
        for path in plan_docs:
            head = "\n".join(path.read_text(encoding="utf-8").splitlines()[:8])
            self.assertIn("Status:", head, str(path.relative_to(ROOT)))

    def test_lacuna_bar_refactor_plan_tracks_current_architecture_decisions(self):
        plan = (ROOT / "docs" / "plans" / "lacuna-bar-refactor-plan.md").read_text(encoding="utf-8")

        self.assertIn("Status: complete", plan)
        self.assertIn("Keep `lacuna.bar` as the Lacuna Bar plugin ID", plan)
        self.assertIn("Keep `shell.json` as the public composition interface", plan)
        self.assertIn("Keep `lacuna.menu` as a compatibility summon target", plan)
        self.assertIn("Use Noctalia as an architectural reference", plan)
        self.assertIn("Keep reusable plugin extraction evaluative", plan)
        self.assertIn("- [x] Pin current `lacuna.bar` host behavior with tests.", plan)
        self.assertIn('- [x] Keep installer activation aligned with `bar.id = "lacuna.bar"`', plan)
        self.assertIn("- [x] Move any remaining frame/sidebar ownership assumptions", plan)
        self.assertIn("- [x] Preserve flyout geometry rules", plan)
        self.assertIn("- [x] Run `python3 -m pytest` after each meaningful slice.", plan)
        self.assertIn("- [x] Run `./scripts/check.sh` before publishing the refactor.", plan)

    def test_plugin_dependency_docs_identify_reusable_candidates(self):
        docs = (ROOT / "docs" / "plugins" / "README.md").read_text(encoding="utf-8")

        self.assertIn("## Reusable Extraction Candidates", docs)
        for plugin_id in [
            "lacuna.theme",
            "lacuna.wallpaper",
            "lacuna.claude-usage",
            "lacuna.codex-usage",
        ]:
            self.assertIn(f"- `{plugin_id}`", docs)
        self.assertIn("keep the current plugin IDs", docs)

    def test_lacuna_bar_docs_define_the_opaque_surface_contract(self):
        bar = (ROOT / "docs" / "plugins" / "bar.md").read_text(encoding="utf-8")
        configuration = (ROOT / "docs" / "configuration.md").read_text(encoding="utf-8")

        self.assertIn("The Lacuna bar is deliberately opaque", bar)
        self.assertIn("normalizes `bar.transparent` to `false`", bar)
        self.assertIn("stock bar's double-click", bar)
        self.assertIn("transparency gesture is not part of the Lacuna bar contract", bar)
        self.assertIn("writes `bar.transparent` as `false`", configuration)

    def test_completed_panel_and_frame_plans_are_not_left_active(self):
        for path in [
            ROOT / "docs" / "plans" / "lacuna-panel-ui-overhaul-plan.md",
            ROOT / "docs" / "plans" / "lacuna-panel-control-refactor-plan.md",
            ROOT / "docs" / "plans" / "lacuna-fake-fullscreen-frame-plan.md",
        ]:
            text = path.read_text(encoding="utf-8")
            head = "\n".join(text.splitlines()[:8])
            self.assertNotIn("Status: active", head, path.name)
            self.assertIn("Completion note 2026-06-14", text, path.name)

    def test_quattro_roadmap_and_phase_plans_are_canonical(self):
        roadmap = (ROOT / "docs" / "roadmap.md").read_text(encoding="utf-8")
        plans_index = (ROOT / "docs" / "plans" / "README.md").read_text(encoding="utf-8")
        historical_tracker = (ROOT / "docs" / "plans" / "lacuna-suite-improvement-plan.md").read_text(encoding="utf-8")

        self.assertIn("Status: active project control (updated 2026-07-16)", roadmap)
        self.assertIn("`lacuna.bar` is the intentional custom bar host", roadmap)
        self.assertIn("P0 — Core foundation", roadmap)
        self.assertIn("P1 — Product integration", roadmap)
        self.assertIn("P2 — Release and evolution", roadmap)
        self.assertIn("0.1.0-beta.1", roadmap)
        self.assertIn("0.1.0-rc.1", roadmap)
        self.assertIn("Optional visual-surface work is not a beta gate.", roadmap)
        self.assertIn("The semi-persistent sidebar remains pointer-driven", roadmap)
        self.assertIn("Interactive flyouts may take", roadmap)
        self.assertIn("unconsumed Backspace", roadmap)
        self.assertIn("must not expose general keyboard", roadmap)
        self.assertIn("canonical omakase setup", roadmap)
        self.assertIn("provider-capability-aware usage widgets", roadmap)
        self.assertIn("Codex currently reports a weekly-only quota window", roadmap)
        self.assertNotIn("`core`, `native`, and `advanced` profiles have documented boundaries", roadmap)
        self.assertIn("## Active Release Tracks", plans_index)
        self.assertIn("## Separate Non-Blocking Proposals", plans_index)
        self.assertIn("lacuna-clock-calendar-flyout-plan.md", plans_index)
        self.assertIn("lacuna-weather-flyout-plan.md", plans_index)
        self.assertIn("Implemented and live-verified 2026-07-13", plans_index)
        self.assertIn("Clock And Calendar Flyout", roadmap)

        for name in [
            "sidebar-settings-flyout-stability-plan.md",
            "quattro-p0-core-foundation-plan.md",
            "quattro-p1-product-integration-plan.md",
            "quattro-p2-release-and-evolution-plan.md",
            "lacuna-clock-calendar-flyout-plan.md",
            "lacuna-weather-flyout-plan.md",
        ]:
            self.assertIn(name, plans_index)
            self.assertTrue((ROOT / "docs" / "plans" / name).exists(), name)

        stability_plan = (ROOT / "docs" / "plans" / "sidebar-settings-flyout-stability-plan.md").read_text(encoding="utf-8")
        self.assertIn("Status: completed and user-verified", stability_plan)
        self.assertIn("flyoutLaneWidthFor(screen)", stability_plan)
        self.assertIn("the user visually confirmed", stability_plan)
        self.assertIn("Do not add another timeout, debounce, delayed reopen", stability_plan)
        self.assertIn("LACUNA_LIVE_VISUAL=1", stability_plan)

        self.assertIn("Status: superseded historical tracker (2026-07-10)", historical_tracker)
        self.assertIn("Use [`../roadmap.md`](../roadmap.md)", historical_tracker)

        p1 = (ROOT / "docs" / "plans" / "quattro-p1-product-integration-plan.md").read_text(encoding="utf-8")
        p2 = (ROOT / "docs" / "plans" / "quattro-p2-release-and-evolution-plan.md").read_text(encoding="utf-8")
        release = (ROOT / "docs" / "development" / "release.md").read_text(encoding="utf-8")
        self.assertIn("Status: in progress; beta product-readiness track", p1)
        self.assertIn("quattro-p1-closeout-execution-plan.md", p1)
        closeout = (ROOT / "docs" / "plans" / "quattro-p1-closeout-execution-plan.md").read_text(encoding="utf-8")
        self.assertIn("The execution must use pi subagents.", closeout)
        self.assertIn("## Reusable Parent-Orchestrator Prompt", closeout)
        self.assertIn("Delivered Checkpoint — 2026-07-16", p1)
        self.assertIn("never present stale historical windows", p1)
        self.assertIn("never claim suppression", p1)
        self.assertIn("General keyboard navigation, Tab", p1)
        self.assertIn("intentional text entry", p1)
        self.assertIn("Support `Escape` dismissal", p1)
        self.assertIn("unconsumed Backspace", p1)
        self.assertIn("click-away dismissal", p1)
        self.assertIn("## Workstream 5 — Omakase setup and customization", p1)
        self.assertIn("choose between architectural profiles", p1)
        self.assertIn("tests/test_qml_behavior_video.py", p1)
        self.assertNotIn("tests/test_media_player_worker.py", p1)
        self.assertIn("Status: in progress; beta/RC release-readiness track", p2)
        self.assertIn("P2 runs alongside P1", p2)
        self.assertIn("Current development target accepted", p2)
        self.assertIn("Accepted Omarchy `4.0.0.r1054.g2f7a07e-1`", p2)
        self.assertIn("0.1.0-beta.N -> 0.1.0-rc.N -> 0.1.0", release)

    def test_quattro_compatibility_docs_match_reviewed_baseline(self):
        compatibility = json.loads((ROOT / "config" / "quattro-compatibility.json").read_text(encoding="utf-8"))
        ledger = (ROOT / "docs" / "architecture" / "quattro-compatibility.md").read_text(encoding="utf-8")
        roadmap = (ROOT / "docs" / "roadmap.md").read_text(encoding="utf-8")

        version = compatibility["reviewedOmarchyVersion"]
        self.assertIn(version, ledger)
        self.assertIn(version, roadmap)
        for digest in compatibility["upstreamFiles"].values():
            self.assertIn(digest, ledger)
        self.assertIn("r1043 to r1054 review", ledger)
        self.assertIn("`surfaceFormat.opaque: false`", ledger)

    def test_distribution_scaffolding_exists(self):
        for name in [
            "CHANGELOG.md",
            "CONTRIBUTING.md",
            ".github/PULL_REQUEST_TEMPLATE.md",
            ".github/ISSUE_TEMPLATE/bug_report.md",
            ".github/ISSUE_TEMPLATE/feature_request.md",
            ".pre-commit-config.yaml",
            ".shellcheckrc",
            "ruff.toml",
        ]:
            self.assertTrue((ROOT / name).exists(), name)
        self.assertIn("## [Unreleased]", (ROOT / "CHANGELOG.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
