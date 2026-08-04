# Advanced state files

Status: advanced user reference for the latest beta

Most users should configure Lacuna through its settings interface. Read files
for diagnosis freely; edit them only after making a backup and closing settings
surfaces that may save concurrently.

## Omarchy shell composition

```text
~/.config/omarchy/shell.json
```

Omarchy owns this path. It stores the active bar host, bar layout, plugin
activation, and per-widget schema values. The normal Lacuna installer owns only
its documented subset when applying or resetting the canonical setup.

## Lacuna runtime settings

```text
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/settings.json
```

This contains Lacuna appearance and runtime preferences, including color
profile, preferred/custom applications, Media Player presentation, frame and
sidebar choices, ambience, and portrait presentation.

The default portrait behavior can be represented as:

```json
{
  "barPresentation": {
    "portraitSplit": true
  }
}
```

Set it to `false` only when you intentionally want a single top or bottom bar on
portrait outputs.

## Media state

```text
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/media-player.json
```

Queue, history, favorites, repeat mode, volume, and mirrored player preferences
live separately from the main settings file. Provider authentication and other
feature state may also use files below the Lacuna state directory.

## Backups

Installer snapshots live below:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/backups/
```

Do not assume every file in that directory is interchangeable. Prefer the
recovery instructions printed by the failed operation or the health report.

## Safe manual-edit procedure

1. Close Lacuna and Omarchy settings surfaces.
2. Copy the file and preserve its mode.
3. Validate the edited file with `jq empty <file>`.
4. Restart the shell once.
5. Run `lacuna-shell status`.
6. Restore the exact backup if the shell reports malformed or unhealthy state.

Lacuna preserves unknown JSON-safe fields in supported installer operations,
but arbitrary manual fields are not a supported public API.

## Corrupt settings recovery

When Lacuna detects corrupt `settings.json`, it preserves a
`settings.json.bak` copy and reports recovery state rather than silently
pretending the file was valid. Keep that file for diagnosis, but remove secrets
before sharing any excerpt.
