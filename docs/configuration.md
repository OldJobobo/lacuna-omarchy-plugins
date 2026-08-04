# Configuration

Status: compatibility entry point

The user configuration documentation is organized by task and settings owner:

- [Configuration overview](configuration/index.md)
- [Lacuna Settings](configuration/lacuna-settings.md)
- [Omarchy Settings](configuration/omarchy-settings.md)
- [Advanced state files](configuration/advanced-state-files.md)

For ordinary changes, use the settings interfaces rather than editing files.
Lacuna Settings owns Lacuna's appearance, layout, preferred applications,
media, desktop clock, and animations. Omarchy Settings owns themes, wallpapers,
windows, monitor scale, bar placement, plugin activation, and individual widget
schema options.

Advanced state is split between:

```text
~/.config/omarchy/shell.json
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/settings.json
${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lacuna/media-player.json
```

Read the advanced guide before editing. Lacuna's installer and settings services
have explicit ownership and preservation contracts; a configuration file is not
an invitation to treat every possible JSON field as public API.
