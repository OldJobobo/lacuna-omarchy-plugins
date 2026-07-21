# AUR Publication Readiness Plan

Status: readiness tooling implemented and validated 2026-07-21; publication intentionally blocked

## Goal

Make Lacuna reproducibly buildable, inspectable, and rehearseable as an Arch
package without creating a Git tag, GitHub release, AUR repository, or AUR
submission before the release candidate is approved.

## Policy

- Publish beta and RC artifacts on GitHub only. Submit the stable
  `lacuna-omarchy-plugins` package to AUR after the verified `0.1.0` release.
- Convert supported SemVer versions by removing the prerelease hyphen:
  `0.1.0-beta.1` → `0.1.0beta.1`. Arch `vercmp` must prove
  `beta < rc < stable`.
- Require `omarchy`, `python`, and `qt6-multimedia`; `omarchy-dev` satisfies
  the host requirement through `provides=('omarchy')`.
- The eventual AUR recipe consumes the immutable, deterministic GitHub release
  archive and a real SHA-256. `SKIP` is allowed only in the unpublished
  scaffold and must fail the publish gate.
- Package transactions install an immutable payload under
  `/usr/share/lacuna-omarchy-plugins`; they never edit user configuration.
  Activation and payload refresh remain explicit `lacuna-omarchy` operations.

## Execution Phases

1. **Version authority** — add prerelease-aware version checking and a single
   dry-runnable bump command covering `VERSION`, manifests, PKGBUILD, and
   `.SRCINFO`.
2. **Release inventory** — generate a checked manifest inventory containing
   plugin kinds, stability, bundles, relationships, entry points, and shipped
   roots.
3. **Deterministic archive** — build a committed-content, single-root archive,
   checksum, and machine-readable file inventory; prove reproducibility.
4. **Package rehearsal** — build a temporary local-source PKGBUILD with
   `makepkg`, run `namcap`, inspect paths and modes, and exercise the packaged
   installer without requiring a published tag.
5. **AUR contracts** — enforce dependency metadata, `.SRCINFO` parity,
   immutable release-source shape, clean payload boundaries, and a strict
   publish gate that rejects missing tags/assets and `SKIP`.
6. **Release safety** — prevent selective uninstall from breaking installed
   reverse dependencies unless the user explicitly requests a cascade.
7. **CI and release gates** — align the Omarchy source pin with the compatibility
   ledger, run package rehearsal in Arch CI, use the deterministic archive
   builder, and classify beta/RC GitHub releases as prereleases.
8. **Maintainer handoff** — document clean-chroot validation, AUR repository
   creation, evidence capture, publication, rollback, and stop conditions.

## Acceptance Gates

- Version, manifests, PKGBUILD, and `.SRCINFO` agree.
- Inventory regeneration is clean and covers every plugin exactly once.
- Two archives from the same source have identical SHA-256 and one versioned
  top-level directory.
- Local `makepkg` rehearsal passes; package contents are limited to `/usr`,
  modes and symlinks are correct, and no user state is written.
- `namcap` has no errors; warnings are reviewed.
- Full repository checks, Quattro compatibility, and live P0 smoke pass.
- The publish gate stops clearly until an approved immutable release and real
  checksum exist.

## Publication Stop Conditions

Do not tag, create a GitHub release, create/push an AUR repository, or submit a
package until explicitly approved. Do not publish if the source checksum is
`SKIP`, package ownership is unavailable, `.SRCINFO` drifts, the worktree is
unreviewed, compatibility requires review, or clean-chroot/package/live smoke,
rollback, uninstall, or stock-bar recovery fails.
