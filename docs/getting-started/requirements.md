# Requirements

Status: user guide for the latest beta

## Required platform

Lacuna runs in Omarchy's existing **Quickshell** process. It is not a separate
desktop session or a replacement for Hyprland.

Start by comparing your host with the exact pair reviewed for this beta:

- Omarchy `4.0.0.r1438.g9b693cc-1`
- Quickshell `0.3.0.r18.g10b439f-3`

These are reviewed versions, not declared minimum versions. A nearby version
may work, but the project does not yet promise a broad compatibility range. See
[Compatibility](../help/compatibility.md) for the current policy.

## Package requirements

The AUR package declares the host and runtime packages needed by Lacuna,
including Omarchy, Quickshell, Python, and Qt Multimedia. Omarchy's package
workflow resolves them as part of installation.

The source bootstrap also prepares these dependencies before installing.

## Optional feature packages

These are not required for the core bar, frame, or sidebar:

| Package | Used for |
| --- | --- |
| `mpv` | Media playback |
| `yt-dlp` | YouTube search and stream resolution |
| ImageMagick (`magick`) | Adaptive desktop-clock contrast |

Without an optional package, the related feature should remain unavailable or
fall back without preventing the shell from loading.

## Network and accounts

The shell itself does not require an account. Features that contact external
services—such as weather, YouTube, Jellyfin, or usage providers—may require
network access, local credentials, or an existing authenticated tool. Configure
only the providers you intend to use.

## Before installing

- Do not update Omarchy solely to install Lacuna. Compare your installed host
  with the reviewed pair before deciding whether to update it.
- Keep your existing Omarchy configuration available; the installer also creates
  scoped Lacuna backups before mutation.
- If using the source bootstrap, make sure its checkout path is not occupied by
  unrelated files or local changes.
- Review [Known limitations](../help/known-limitations.md).
