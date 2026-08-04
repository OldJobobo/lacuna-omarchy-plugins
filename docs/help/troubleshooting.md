# Troubleshooting

Status: user guide for the latest beta

Start with the symptom and the health report. Avoid deleting configuration or
reinstalling repeatedly before you know which phase failed.

## Health report

```bash
lacuna-shell status
```

Source users run `./scripts/lacuna status`. The report covers host versions,
paths, configuration/schema health, sidebar monitor policy, prior installer
failure, and missing, disabled, or stale core plugins.

Review the output for secrets or personal paths before sharing it.

## The shell did not return after installation or update

1. Wait briefly for the replacement shell process to answer.
2. Run `omarchy restart shell` once.
3. Run the health report.
4. Follow any operation-specific recovery command it prints.
5. If configuration is malformed, restore the operation backup rather than
   editing several files at once.

Do not start a second Quickshell process.

## Lacuna is installed but the stock bar remains

- Confirm the guided **Full Lacuna install** completed rather than only the AUR
  package transaction.
- Run `lacuna-shell status` and check whether `lacuna.bar` is active.
- Preview a repair with `lacuna-shell install --profile full --reinstall --dry-run`.
- Apply only after reviewing the plan.

## A bar widget is missing

A widget can be absent because:

- it is not in the current Omarchy layout;
- the output is too narrow and responsive layout has hidden it;
- the plugin is disabled or stale;
- its optional provider or command is unavailable.

Check Omarchy Settings → Plugins and the health report. Resize-related hiding
should reverse when space returns.

## The sidebar opens on the wrong monitor

1. Confirm Hyprland reports the expected output names.
2. Return the sidebar monitor policy to automatic.
3. Restart the shell.
4. If needed, select the intended monitor in Lacuna Settings → Layout.

Include monitor names and active workspaces in a bug report, but omit unrelated
window titles if they are private.

## Settings revert or do not apply

- Confirm you changed the correct owner: Lacuna Settings or Omarchy Settings.
- Close both settings surfaces before any manual file edit.
- Validate JSON and restart once.
- Check whether corrupt settings recovery created `settings.json.bak`.
- Use safe reset only after reading what it preserves and replaces.

## Media search or playback is unavailable

- Confirm the provider is enabled.
- Confirm network access and provider details.
- Check `mpv`; for YouTube also check `yt-dlp`.
- Test ordinary playback before background-video presentation.
- Never post cookies, API keys, user IDs, or authenticated URLs.

## Ambience affects performance

Disable the last enabled effect, then reduce effect intensity/count or disable
foreground overlay presentation. Test one monitor at a time and compare after a
shell restart.

## Recovery did not work

Stop changing state and collect:

- Lacuna version;
- Omarchy and Quickshell versions;
- redacted `lacuna-shell status` output;
- command and exact error;
- monitor layout if relevant;
- whether stock-bar restoration works.

Continue to [Support](support.md).
