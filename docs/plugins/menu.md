# Menu And Sidebar Plugins

Status: reference

The Lacuna sidebar/menu is a small bundle, not one isolated plugin.

## Core Bundle

- `lacuna.menu`: sidebar, menu surfaces, flyouts, app picker, and menu-local
  services.
- `lacuna.menu-button`: bar button that opens the Lacuna menu.
- `lacuna.state`: persistent shared Lacuna state service.
- `lacuna.shell-settings`: standalone Lacuna settings surface.
- `lacuna.bar`: host that can own frame/sidebar choreography when active.

## Summon Compatibility

`lacuna.menu` remains a compatibility summon target. When `lacuna.bar` is
active and frame hosting is enabled, the menu delegates to the bar-hosted
surface.

## Geometry

Attached flyouts follow the Lacuna seam/connector geometry rules in
`docs/lacuna-design-system/02-geometry.md`. The attachment edge stays square;
only exposed corners are rounded.
