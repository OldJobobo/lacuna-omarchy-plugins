# AUR packaging

This directory is the unpublished scaffold for the eventual stable
`lacuna-omarchy-plugins` AUR package. Beta and RC artifacts are published as
GitHub prereleases only; the stable AUR package is submitted after the verified
`0.1.0` release.

The package installs an immutable payload under
`/usr/share/lacuna-omarchy-plugins` and exposes `/usr/bin/lacuna-omarchy`.
Neither `makepkg` nor package installation writes to a user's home directory.
Users activate the payload explicitly:

```bash
lacuna-omarchy install --profile full
```

Package upgrades refresh `/usr/share` only. Apply an upgraded payload through
the transactional installer:

```bash
lacuna-omarchy update --yes
```

## Package policy

- `omarchy`, Python, and Qt Multimedia are required. The development package
  may satisfy the host requirement through `provides=('omarchy')`.
- mpv, yt-dlp, and ImageMagick remain optional feature dependencies.
- SemVer prereleases map to Arch versions by removing the hyphen, for example
  `0.1.0-rc.1` → `0.1.0rc.1`; tests enforce beta/RC/stable ordering.
- The final recipe consumes the versioned GitHub release archive with a real
  SHA-256. `_source_sha256=SKIP` marks this checked-in recipe as an unpublished
  scaffold and is rejected by `--publish-check`.

## Maintainer checks

Safe checks that do not require a published tag:

```bash
scripts/release-version check
scripts/release-inventory --check
scripts/check-aur-package
scripts/rehearse-aur-package
```

The rehearsal builds a deterministic local archive, substitutes it into a
temporary PKGBUILD, runs `makepkg` and `namcap`, inspects package paths and
modes, and smokes the packaged installer. It never edits the checked-in recipe.

Current reviewed `namcap` warnings are limited to host-provided Quickshell/Qt
modules (`qs.Commons`, `qs.Ui`, Quickshell, and Qt Declarative), Python shebang
detection despite the explicit `python` dependency, implicit base `bash`, and
`omarchy` not being inferable from static payload inspection. Any `namcap`
error or new warning class requires review; Qt Multimedia is declared directly.

## Release preparation

1. Use `scripts/release-version set <version> --dry-run`, then perform the real
   bump only after the release gate is approved.
2. Regenerate and review `config/release-inventory.json`.
3. Run the complete repository, archive, package, compatibility, and live gates.
4. Tag and publish the approved GitHub release.
5. Set `_source_sha256` to the released archive checksum, regenerate `.SRCINFO`,
   and run `scripts/check-aur-package --publish-check`.
6. Follow [SUBMISSION.md](SUBMISSION.md) for clean-chroot validation and the
   dedicated AUR repository workflow.

For packaging-only revisions, increment `pkgrel`, regenerate `.SRCINFO`, and
repeat package validation. Never publish while the checksum is `SKIP`, the
release asset is absent, or any clean-chroot/live recovery gate is incomplete.
