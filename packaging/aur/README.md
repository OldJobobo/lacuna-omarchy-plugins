# AUR packaging

This directory is the publication scaffold for the `lacuna-omarchy-plugins`
AUR package. The package installs the immutable Lacuna plugin payload under
`/usr/share/lacuna-omarchy-plugins` and exposes the installer as
`/usr/bin/lacuna-omarchy`. It never writes to a user's home directory during
`makepkg` or package installation.

After installing the package, users choose and activate plugins explicitly:

```bash
lacuna-omarchy install --profile full
```

Package upgrades refresh the payload in `/usr/share`; they intentionally do
not mutate a running user's Omarchy configuration. Apply an upgraded payload
with:

```bash
lacuna-omarchy update --yes
```

## Publishing

The recipe consumes the immutable upstream tag matching `pkgver`. Before
publishing a release:

1. Update root `VERSION`, every plugin manifest, `PKGBUILD`'s
   `_upstream_version`, and `.SRCINFO`.
2. Run `./scripts/check.sh` or `./scripts/check-aur-package`.
3. Tag the same commit as `v<pkgver>` and let the GitHub release workflow pass.
4. Copy `PKGBUILD` and `.SRCINFO` into the dedicated AUR package repository.
5. Build in a clean Arch chroot, inspect the package contents, then push the AUR
   repository.

For packaging-only revisions, increment `pkgrel` and regenerate `.SRCINFO`:

```bash
cd packaging/aur
makepkg --printsrcinfo > .SRCINFO
```

The optional dependencies correspond to optional Lacuna surfaces; the base
package only requires Python to run the installer and bundled helper scripts.
Omarchy remains an optional package dependency because supported Omarchy
systems may be installed outside pacman's package database.
