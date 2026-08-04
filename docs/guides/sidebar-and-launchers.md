# Sidebar and launchers

Status: user guide for the latest beta

The sidebar is Lacuna's main command surface. It keeps launchers, controls,
media, and shell actions attached to the desktop frame instead of scattering
them across separate popups.

## Open and close it

Use the Lacuna menu button in the bar. Select a sidebar route to open its
attached content. Use the close control, click away from an interactive flyout,
or press `Escape` where the flyout accepts focus.

The visible sidebar itself is pointer-first and should not take keyboard focus
from the application you are using. Text-entry surfaces can take bounded focus
while active and return it when dismissed.

## Launch applications

The sidebar offers normal application discovery plus Lacuna's preferred and
quick-launch application slots. Open **Lacuna Settings → Preferred Apps** to
choose the applications you want Lacuna to use for common roles and launchers.

Choose applications from the catalog when possible. Custom application entries
are useful for applications that do not appear normally, but verify the command
before saving it.

## Choose the layout

Lacuna Settings includes layout choices for quick launch, daily launch,
shortcuts, and controls. These change presentation without changing the
underlying installed applications. Preferred application roles are managed in
**Lacuna Settings → Preferred Apps**.

On a narrow output, attached surfaces are clamped to the available screen. An
expanded sidebar is treated as an exclusion zone for bar flyouts on that
monitor; a collapsed rail is not.

## System and session actions

Power and session actions are deliberately separated from ordinary launchers.
Destructive actions use Lacuna's danger treatment. Read the confirmation and
avoid enabling instant restart unless that behavior is intentional.

## If an application is missing

1. Confirm it has a desktop entry and launches normally outside Lacuna.
2. Reopen the sidebar so the application catalog refreshes.
3. Select it as a preferred application in Lacuna Settings.
4. If it still does not appear, collect a health report and follow
   [Troubleshooting](../help/troubleshooting.md).
