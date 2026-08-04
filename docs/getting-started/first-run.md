# First-run tour

Status: user guide for the latest beta

After installation, Omarchy reloads into Lacuna's connected layout. Take a
minute to verify the main surfaces before changing settings.

## 1. Open the sidebar

Use the Lacuna menu control on the bar. The sidebar is the main route to:

- application launchers and preferred apps;
- media and system controls;
- shell and session actions;
- Lacuna configuration.

Attached flyouts open beside the sidebar rather than as unrelated windows. See
[Sidebar and launchers](../guides/sidebar-and-launchers.md).

## 2. Find Lacuna Settings

Open the gear control near the bottom of the sidebar. Lacuna Settings owns:

- appearance and color profile;
- frame and sidebar presentation;
- preferred and quick-launch applications;
- media presentation and providers;
- desktop ambience and effect order.

Do not edit JSON for ordinary customization. Start with
[Lacuna Settings](../configuration/lacuna-settings.md).

## 3. Find Omarchy Settings

Use Omarchy Settings for:

- which screen edge owns the bar;
- the bar's widget layout;
- individual widget options exposed by plugin schemas.

Lacuna follows the current Omarchy theme and wallpaper. Continue using normal
Omarchy theme tools. See [Omarchy Settings](../configuration/omarchy-settings.md).

## 4. Check the default presentation

- On landscape screens, the bar stays on its configured edge.
- A portrait screen with a top or bottom bar may show a companion band on the
  opposite edge; this is the default portrait split presentation.
- The sidebar chooses a monitor automatically unless you select one.
- True fullscreen applications suppress Lacuna surfaces and reserved zones on
  that output.

Read [Multiple monitors](../guides/multiple-monitors.md) before overriding the
monitor policy.

## 5. Run the health report

```bash
lacuna-shell status
```

Source users run `./scripts/lacuna status` from their checkout. Keep the output
when asking for support; review it first for paths or values you prefer not to
share.

## Next steps

- [Choose an appearance and color profile](../guides/appearance-and-themes.md)
- [Learn the bar and widgets](../guides/bar-and-widgets.md)
- [Configure the Media Player](../guides/media-player.md)
- [Enable or reorder ambience](../guides/desktop-ambience.md)
