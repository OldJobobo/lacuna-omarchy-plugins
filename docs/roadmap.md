# Lacuna Roadmap

Status: active project control

This is the high-level operating roadmap for `OldJobobo/lacuna-omarchy-plugins`.
It connects the stable design-system docs, implementation plans, GitHub issues,
and validation loop without replacing any of them.

## Source Of Truth Map

| Surface | Purpose |
| --- | --- |
| `docs/lacuna-design-system/` | Product/design language: what Lacuna is allowed to feel like. |
| `docs/architecture/` | Current technical architecture and runtime boundaries. |
| `docs/plugins/` | Plugin catalog and install grouping. |
| `docs/development/` | Setup, testing, troubleshooting, and release workflow. |
| `docs/plans/` | Historical plans, implementation trackers, and deep work packets. |
| `docs/issues.md` | GitHub issue grouping and milestone mapping. |
| Vault note | Cross-session project control note outside the repo. |

## Operating Rule

Use the smallest durable surface that matches the decision:

- **Design principle or aesthetic rule:** update `docs/lacuna-design-system/`.
- **Runtime architecture or boundary:** update `docs/architecture/`.
- **User-facing install/config behavior:** update `docs/install.md` or `docs/configuration.md`.
- **Plugin catalog behavior:** update `docs/plugins/`.
- **Implementation plan or historical tracker:** update `docs/plans/`.
- **Actionable bug/feature work:** create or update GitHub issues and mirror grouping in `docs/issues.md`.
- **Personal/project memory across sessions:** update the Obsidian vault control note.

## Now: M1 State Model Stabilization

Goal: make Lacuna settings state, menu normalization, and visible bar behavior agree.

Tracked issues:

- [#4 Persist per-style bar layout settings in Lacuna settings state](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/4)
- [#5 Normalize per-style bar layout entries consistently across menu and state services](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/5)
- [#6 Preserve JSON-safe metadata on bar layout entries instead of dropping valid fields](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/6)
- [#7 Handle string-form bar layout entries consistently or reject them explicitly](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/7)
- [#8 Do not collapse active bar items solely because the loaded item reports visible false](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/8)
- [#9 Add contract tests for bar slot measurement and settings normalization regressions](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/9)

Exit criteria:

- One canonical layout-entry schema exists and is documented or discoverable from tests.
- Menu and state services normalize the same settings shape.
- Valid JSON-safe metadata is preserved or explicitly rejected by policy.
- String-form layout entries are either supported consistently or rejected explicitly.
- Bar slot measurement does not collapse measurable items solely because `visible` is false.
- Contract tests cover the above so the behavior cannot silently drift.

Validation:

```bash
python3 -m pytest tests/test_qml_contracts.py
python3 -m pytest tests/test_vendored_files.py
./scripts/check.sh
```

Manual/live validation when behavior is visible:

```bash
./scripts/dev deploy lacuna.bar
./scripts/dev deploy lacuna.menu
./scripts/dev deploy lacuna.state
omarchy plugin rescan
omarchy restart shell
```

Then confirm settings survive shell restart and bar layout remains stable.

## Next: Reduced Motion Setting Hookup

Goal: expose the already-existing reduced-motion hook (`animationDisabled` /
`animationSpeed`) as a durable user setting.

Recommended action:

- Create or update a GitHub issue if none exists.
- Tie it back to `docs/lacuna-design-system/06-roadmap.md`.
- Verify reduced motion collapses timing while preserving Lacuna's edge-origin reveal structure.

## Soon: Visual Regression And Two-Theme Smoke

Goal: make Lacuna's core promise testable: **theme owns hue, Lacuna owns form**.

Recommended action:

- Advance `docs/plans/lacuna-visual-regression-test-plan.md`.
- Keep live visual tests gated behind `LACUNA_LIVE_VISUAL=1`.
- Maintain at least two reference-theme smoke checks for menu/sidebar/bar surfaces.

## Later: Feature Expansion Queue

Candidate work should stay behind stabilization unless urgent:

- media player rebrand
- workspaces plugin
- YouTube video transition polish
- theme preloader
- animation pipeline/performance work
- additional ambiance overlays

Before promoting a feature, check whether it belongs in:

1. an existing plan in `docs/plans/`,
2. a new GitHub issue,
3. a plugin catalog update, or
4. the design-system docs.

## Maintenance Cadence

When doing project-organizing passes:

1. Check `git status --short`.
2. Review open GitHub issues and labels.
3. Review `docs/plans/README.md` for active vs completed trackers.
4. Update `docs/issues.md` if issue grouping changed.
5. Update this roadmap if priorities changed.
6. Update the vault control note with a short cross-session summary.
