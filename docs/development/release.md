# Release Notes

Status: reference

The current suite version is recorded in `README.md`. Release work should keep
versioning, changelog, and validation results aligned.

## Before Release

1. Run `./scripts/check.sh`.
2. Confirm `CHANGELOG.md` has an appropriate entry under `## [Unreleased]` or
   the target version section.
3. Confirm installer profiles still match `docs/plugins/README.md`.
4. Confirm visible UI changes have screenshots in `docs/screenshots/reference/`
   when useful.

## Commit And PR Notes

Use concise imperative commit messages, such as:

- `Add script pill manifest`
- `Port temperature widget shell contract`
- `Organize project documentation`

Pull requests should describe the plugin affected, list manual Omarchy smoke
tests, include screenshots for visible UI changes, and call out any remaining
standalone Lacuna dependencies.
