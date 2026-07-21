# AUR Submission Runbook

This runbook is for the first stable `lacuna-omarchy-plugins` publication.
Beta and RC artifacts remain GitHub prereleases and are not pushed to the
stable AUR package name.

## Preconditions

Stop unless all of these are true:

- the exact stable tag and GitHub release archive exist;
- `_source_sha256` is the real archive checksum, never `SKIP`;
- `scripts/check-aur-package --publish-check` passes from a clean tree;
- `scripts/rehearse-aur-package`, `./scripts/check.sh`, Quattro compatibility,
  and live P0 smoke pass;
- package-name availability and ownership have been confirmed on AUR;
- clean-chroot build, `namcap`, install/update/rollback/uninstall, and stock-bar
  recovery evidence has been recorded.

## Prepare The Dedicated AUR Repository

1. Configure an AUR account and SSH key according to the current AUR account
   documentation.
2. Confirm `lacuna-omarchy-plugins` is available and is not an existing package
   that requires a merge, orphan adoption, or maintainer discussion.
3. Clone the dedicated repository:

   ```bash
   git clone ssh://aur@aur.archlinux.org/lacuna-omarchy-plugins.git
   ```

4. Copy only `packaging/aur/PKGBUILD` and `packaging/aur/.SRCINFO` into it.
5. Review `git diff`; the AUR repository must not contain the plugin payload,
   generated packages, screenshots, or project documentation.

## Validate The Exact Recipe

From the dedicated AUR checkout:

```bash
makepkg --verifysource
makepkg --cleanbuild --syncdeps
namcap PKGBUILD lacuna-omarchy-plugins-*.pkg.tar.zst
pacman -Qlp lacuna-omarchy-plugins-*.pkg.tar.zst
```

Also build with the current Arch clean-chroot tooling (`extra-x86_64-build` or
its documented successor). Install that exact package on the approved Omarchy
host, run `lacuna-omarchy install --profile full`, restart the shell, and repeat
the release smoke, update rollback, uninstall, and stock-bar recovery checks.

Record the project commit/tag, release archive SHA-256, package SHA-256,
PKGBUILD and package `namcap` output, clean-chroot output, installed-file
inventory, Omarchy/Quickshell versions, and live smoke results.

## Publish

Commit with an AUR-style subject such as `Initial import: 0.1.0-1`, then push
normally. Never force-push the AUR repository.

After publication, verify the rendered AUR metadata, clone/build as a new user,
and install once through the documented package path.

## Packaging-Only Fixes And Rollback

For recipe-only corrections, increment `pkgrel`, regenerate `.SRCINFO`, rebuild,
and push a normal follow-up commit. For a bad package, publish a corrected
higher `pkgrel`; do not rewrite AUR history. If the upstream artifact itself is
bad, stop publication, fix upstream, issue a new version, and point the recipe
to that immutable release.
