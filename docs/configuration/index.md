# Configuration

Status: user guide for the latest beta

Lacuna has two settings owners. Choosing the right one prevents a shell change
from being overwritten or appearing to have no effect.

## Use Lacuna Settings for the experience

Open the gear control in the sidebar. Lacuna Settings owns the shell experience
that Lacuna adds:

- design style, color profile, frame, and appearance;
- background and foreground animations;
- bar density, sidebar presentation, and portrait behavior;
- Jellyfin provider details and Media Player integration;
- preferred applications and desktop clock;
- Lacuna maintenance tools and menu behavior.

[Open the Lacuna Settings guide](lacuna-settings.md).

## Use Omarchy Settings for the host

Omarchy remains the owner of system and shell composition:

- default applications;
- theme, wallpaper, and font;
- windows, gaps, monitor scale, and bar placement;
- power, idle, nightlight, and notifications;
- plugin activation and widget options.

[Open the Omarchy Settings guide](omarchy-settings.md).

## Use state files only for advanced recovery

Most changes should go through one of the settings interfaces. State files are
useful for backup, diagnostics, unsupported bulk editing, or recovery when the
interface cannot load.

[Read the advanced state-file guide](advanced-state-files.md) before editing.

## Quick ownership table

| I want to… | Open… |
| --- | --- |
| Change Lacuna's frame or color profile | Lacuna Settings → Appearance |
| Reorder ambience effects | Lacuna Settings → Animations |
| Choose the sidebar mode or bar density | Lacuna Settings → Layout |
| Configure Jellyfin | Lacuna Settings → Media Player |
| Connect a YouTube account | Media Player account control |
| Choose role-based launch applications | Lacuna Settings → Preferred Apps |
| Change the Omarchy theme or wallpaper | Omarchy Settings → Appearance |
| Move the bar or change monitor scale | Omarchy Settings → Windows |
| Enable, disable, or configure a plugin | Omarchy Settings → Plugins |
