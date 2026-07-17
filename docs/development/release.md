# Release Workflow

Status: active release runbook (updated 2026-07-11)

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
4. Update `packaging/aur/PKGBUILD` and regenerate `packaging/aur/.SRCINFO`;
   `_upstream_version` must match `VERSION` exactly (`pkgver` removes SemVer's
   prerelease hyphen to satisfy Arch version syntax).
5. Confirm installer profiles match `docs/plugins/README.md` and generate or
   review the release plugin inventory.
6. Confirm user-visible changes have current screenshots when useful.

## Validate The Tree

```bash
./scripts/check.sh
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

Build from committed source, not an arbitrary dirty working tree. Verify the
archive inventory against the committed file list, then test the artifact in a
clean install path:

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
   and manifest/version parity, builds the archive and checksum, and creates the
   GitHub release.
5. Copy the validated AUR recipe into its dedicated AUR repository and build it
   in a clean Arch chroot before publishing.
6. Install the published artifact once; do not treat workflow success alone as
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
