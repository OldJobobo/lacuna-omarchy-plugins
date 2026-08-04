# Media Player

Status: user guide for the latest beta

Lacuna's Media Player can present local MPRIS activity and optional online
provider results inside the connected shell. The normal installation includes
both media surfaces; provider credentials are not required for the shell to
load.

## Open the player

Use the media route in the sidebar or the media widget in the bar. Playback
availability depends on the active source and installed feature tools.

The player remembers user-owned playback state such as queue, history,
favorites, repeat mode, and volume separately from the main appearance
settings.

## Choose presentation behavior

Use the controls in the Media Player to choose inline, background, or automatic
video presentation. Start with **Auto**. Presentation, quality, and provider
filter preferences persist as player state; they do not prove that every
provider is configured.

## Configure providers

Provider setup is optional:

- **YouTube** uses public resolution first. Use the account control in the
  Media Player only when you want an authenticated fallback.
- **Jellyfin** is configured in **Lacuna Settings → Media Player**. It requires
  a server URL and API key. The advanced `userId` field is optional library
  scoping and is not required by the normal settings interface.

Enter credentials only in the relevant Lacuna control. Do not post them in
issue reports or terminal screenshots.

## Optional media tools

- `mpv` provides playback.
- `yt-dlp` provides YouTube search and stream resolution.

If either tool is absent, the related capability may be unavailable while the
rest of Lacuna continues to work.

## Background video

When enabled and supported by the selected media, Lacuna can use video as a
background layer. Source changes and shutdown are covered by black transitions
so frames do not flash over the sidebar. If video fails, disable the background
presentation first and confirm ordinary playback before changing credentials.

## Recover from a provider failure

1. Confirm ordinary network access.
2. Confirm the provider is enabled in Lacuna Settings.
3. Recheck provider details without sharing secrets.
4. Confirm `mpv` and, for YouTube, `yt-dlp` are installed.
5. Restart the shell.
6. Run `lacuna-shell status` and follow
   [Troubleshooting](../help/troubleshooting.md).

A temporary provider failure should not rewrite your selected provider filter
or erase media preferences.
