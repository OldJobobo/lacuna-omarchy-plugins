# TODO

A lightweight working list for Lacuna. The canonical priority queue remains
[`docs/roadmap.md`](docs/roadmap.md); GitHub Issues remains the actionable issue
tracker. Keep this file focused on the next decisions and release gates rather
than duplicating the detailed plans.

## Now — `0.1.0-beta.1`

- [ ] Complete the P1 product-decision checkpoint:
  - [ ] freeze canonical omakase membership;
  - [ ] decide whether media is part of the normal beta setup;
  - [ ] define the reset ownership boundary;
  - [ ] finalize the manifest stability vocabulary;
  - [ ] approve a safe release-rehearsal target.
- [ ] Execute the remaining P1 closeout phases in order:
  - [ ] native Omarchy service ownership matrix;
  - [ ] checked settings inventory;
  - [ ] deterministic settings persistence, migration, reset, and failure handling;
  - [ ] pointer-first sidebar and bounded flyout focus contract;
  - [ ] media reliability, recovery, and credential-redaction validation;
  - [ ] canonical omakase install and safe reset;
  - [ ] packaged Beta Exit rehearsal and evidence record.
- [ ] Finish P2 beta readiness:
  - [ ] declare minimum-supported and release-tested Omarchy/Quickshell pairs;
  - [ ] expand `scripts/lacuna status` with core health, host, migration, monitor,
        failure, and recovery details;
  - [ ] reconcile release claims, links, commands, migrations, and known limitations;
  - [ ] run and record the beta artifact install/update/rollback/uninstall matrix.
- [ ] Set `VERSION` and every manifest to `0.1.0-beta.1` only when the beta
      candidate is approved.
- [ ] Publish the immutable GitHub prerelease, then complete the checksum,
      clean-chroot, installed-lifecycle, and AUR publication gates.

Detailed execution:
[`docs/plans/active/quattro-p1-closeout-execution-plan.md`](docs/plans/active/quattro-p1-closeout-execution-plan.md),
[`docs/plans/active/quattro-p2-release-and-evolution-plan.md`](docs/plans/active/quattro-p2-release-and-evolution-plan.md),
and [`docs/plans/active/aur-publication-readiness-plan.md`](docs/plans/active/aur-publication-readiness-plan.md).

## Open Issue Batch

- [ ] [#9](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/9) Add regression contracts for bar slot measurement and settings normalization.
- [ ] [#4](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/4) Persist per-style bar layout settings.
- [ ] [#5](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/5) Normalize per-style bar layout entries consistently.
- [ ] [#6](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/6) Preserve JSON-safe layout-entry metadata.
- [ ] [#7](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/7) Define policy for string-form layout entries.
- [ ] [#8](https://github.com/OldJobobo/lacuna-omarchy-plugins/issues/8) Keep active bar slots measurable when an item reports `visible: false`.

See [`docs/issues.md`](docs/issues.md) for sequencing and label guidance.

## Later — Non-Blocking Work

- [ ] Bind the design system's reduced-motion hook to a user setting.
- [ ] Repair the optional surface-transition pipeline.
- [ ] Implement the portrait split-bar proposal.
- [ ] Explore shell layout presets and Agent Orchestration mode.
- [ ] Perform bounded structural cleanup only behind focused behavior tests.
- [ ] Remove deprecated `lacuna.compact-pill` in `0.2.0` with migration notes.

Proposal status and historical context live in
[`docs/plans/README.md`](docs/plans/README.md).

## Release Discipline

- [ ] Run `./scripts/check.sh` before considering a repository change complete.
- [ ] Deploy user-visible or stateful QML changes with
      `./scripts/dev deploy <plugin-id>` and verify the installed copy.
- [ ] Record exact versions, commands, artifact hashes, outcomes, limitations,
      and evidence locations for release rehearsals.
- [ ] Do not tag, publish a GitHub release, or push an AUR package without
      explicit approval and all publication stop conditions cleared.
