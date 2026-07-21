# Release Workflow

Status: active release runbook (updated 2026-07-21)

`VERSION` is the machine-readable source of truth. `README.md`, every plugin
manifest, the changelog section, Git tag, archive name, and release notes must
agree with it.

The current release line is:

```text
0.1.0-beta.N -> 0.1.0-rc.N -> 0.1.0
```

Do not publish `0.0.1-beta` from the current tree; that would move backward
from the repository's existing `0.1.0` version.

## Release Classes

- **Beta:** supported scope is declared and usable, but field testing may find
  product defects.
- **RC:** feature-frozen artifact with no known release-blocking defect.
- **Stable:** promotion of the verified RC lineage without new features.

## Prepare

1. Confirm the target gate in `docs/roadmap.md` and the P1/P2 plans is met.
2. Update `VERSION` and every `manifest.json` to the exact SemVer prerelease or
   stable version.
3. Move relevant changelog entries from `Unreleased` into the target version;
   record migrations, known limitations, and supported environment.
4. Preview the synchronized bump with `scripts/release-version set <version>
   --dry-run`, then use the same command without `--dry-run` to update
   `VERSION`, manifests, `PKGBUILD`, and `.SRCINFO` together. Arch `pkgver`
   removes the supported beta/RC prerelease hyphen.
5. Regenerate `config/release-inventory.json` with `scripts/release-inventory`
   and confirm installer profiles match `docs/plugins/README.md`.
6. Confirm user-visible changes have current screenshots when useful.

## Validate The Tree

```bash
./scripts/check.sh
scripts/release-version check
scripts/release-inventory --check
scripts/build-release-archive --allow-dirty --check-reproducible
scripts/check-aur-package
scripts/rehearse-aur-package
scripts/quattro-compatibility --check
scripts/quattro-p0-smoke
./scripts/lacuna install --dry-run
./scripts/lacuna update --dry-run
./scripts/lacuna status
git diff --check
```

Run opt-in live tests from a real Omarchy session where applicable. Record the
exact Omarchy and Quickshell versions; do not substitute a stale test count for
the current command result.

## Rehearse The Artifact

Build from committed source, not an arbitrary dirty working tree. Run
`scripts/build-release-archive --check-reproducible` to create a deterministic,
single-root archive, checksum, and machine-readable file inventory. Then run
`scripts/rehearse-aur-package` and test the extracted artifact in a clean install
path:

1. Install and activate the core profile.
2. Rescan/restart the shell and smoke the bar, menu, state, and settings.
3. Change and round-trip representative settings.
4. Inject or reproduce an update failure and verify rollback.
5. Verify uninstall preserves user state unless explicitly requested.
6. Verify the documented stock-bar recovery path.

RC additionally requires diagnostics and recovery output to be usable without
private project knowledge.

## Publish

1. Commit the prepared release tree.
2. Tag the exact commit as `v$(cat VERSION)`.
3. Push the commit and tag.
4. Verify the release workflow runs the full project gate, checks tag/version
   and manifest/version parity, rehearses the Arch package, builds the archive,
   checksum, and inventory, and creates the GitHub release. Beta and RC tags
   must be marked as prereleases.
5. Do not submit beta or RC builds to the stable AUR package name. After the
   verified stable release exists, replace the scaffold's `SKIP` with the real
   release-archive checksum, regenerate `.SRCINFO`, and run
   `scripts/check-aur-package --publish-check`.
6. Follow `packaging/aur/SUBMISSION.md`, including the clean-chroot build, exact
   package inspection, dedicated AUR repository, and post-publication smoke.
7. Install the published artifact once; do not treat workflow success alone as
   runtime validation.

## Promotion Discipline

- Beta builds may contain fixes required by beta feedback.
- RC builds accept release blockers only.
- Stable must not add features relative to the verified RC lineage.

## Commit And PR Notes

Use concise imperative commit messages, such as:

- `Add script pill manifest`
- `Port temperature widget shell contract`
- `Organize project documentation`

Pull requests should describe the plugin affected, list manual Omarchy smoke
tests, include screenshots for visible UI changes, and call out any remaining
standalone Lacuna dependencies.
