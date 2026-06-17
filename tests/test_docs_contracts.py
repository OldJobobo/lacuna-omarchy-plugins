import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DocsContractTests(unittest.TestCase):
    def test_docs_have_status_markers(self):
        for path in sorted((ROOT / "docs").glob("*.md")):
            head = "\n".join(path.read_text(encoding="utf-8").splitlines()[:8])
            self.assertIn("Status:", head, str(path.relative_to(ROOT)))

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
        docs = (ROOT / "docs" / "plugin-dependencies.md").read_text(encoding="utf-8")

        self.assertIn("## Reusable Extraction Candidates", docs)
        for plugin_id in [
            "lacuna.theme",
            "lacuna.wallpaper",
            "lacuna.claude-usage",
            "lacuna.codex-usage",
        ]:
            self.assertIn(f"- `{plugin_id}`", docs)
        self.assertIn("keep the current plugin IDs", docs)

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

    def test_suite_tracker_matches_current_validation_baseline(self):
        tracker = (ROOT / "docs" / "plans" / "lacuna-suite-improvement-plan.md").read_text(encoding="utf-8")

        self.assertIn("Status: active implementation tracker (updated 2026-06-14)", tracker)
        self.assertIn("Current full suite result: 86 Python tests passing.", tracker)
        self.assertIn("Architecture update 2026-06-14", tracker)

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
