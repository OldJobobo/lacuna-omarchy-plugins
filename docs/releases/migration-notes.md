# Migration notes

Status: migration guide for the current beta line

## Updating within `0.1.0-beta`

Use the normal update path. Package users update through Omarchy and then apply
the payload with `lacuna-shell update --yes`; source users update their checkout
and run the source command.

Existing settings, provider configuration, credentials, Media Player state,
reminders, and unrelated Omarchy configuration remain user-owned during normal
install, update, and safe reset workflows.

## Compact control migration

`lacuna.compact-pill` is deprecated and excluded from the normal setup. Use the
current `lacuna.bar-size-pill` control. The deprecated plugin remains available
only for migration compatibility and is targeted for removal in `0.2.0`.

## Media state

Older Media Player state is migrated when loaded. Player queue, history,
favorites, repeat mode, and volume remain in `media-player.json`; presentation
preferences are preserved across supported reset/update operations.

A temporary YouTube or Jellyfin failure should not rewrite the selected
provider filter. Beta.2 and beta.3 include provider-resolution fixes; update
before diagnosing an older cached media URL.

## Canonical layout changes

The normal installer owns the selected Lacuna bar host, canonical bar layout,
center anchor, and opaque bar setting. A safe reset intentionally restores those
owned values while preserving unrelated Omarchy entries.

If you assembled an a-la-carte layout, preview reset before using it. Restore
the stock bar instead when your goal is to leave the canonical Lacuna layout:

```bash
omarchy bar reset
```

## Before a future `0.2.0`

Remove deprecated compact-pill usage and read the release-specific migration
entry before updating. No other `0.2.0` migration is promised by the current
beta documentation.
