## Summary

<!-- What does this change and why? -->

## Plugins touched

<!-- e.g. lacuna.menu, lacuna.bar -->

## Checklist

- [ ] `./scripts/check.sh` passes (JSON, qmllint, shellcheck, vendored parity, pytest)
- [ ] Vendored copies synced (`scripts/sync-vendored --check` clean)
- [ ] Contract tests added/updated for changed QML/scripts
- [ ] QML changes smoke-tested live (`omarchy plugin rescan`) where applicable
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
