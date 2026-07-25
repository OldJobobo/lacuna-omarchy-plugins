# Omarchy Integration

Status: reference

Lacuna runs inside Omarchy shell (Quickshell). To avoid reinventing system surfaces — the
`CLAUDE.md` "prefer Omarchy-native" rule — this is the inventory of what Omarchy exposes, how a
Lacuna plugin can reach it, the current alignment status, and the standing policy for new work.

## What Omarchy exposes

### Singletons (`import qs.Commons`)
| Singleton | Path | Key surface |
|---|---|---|
| `Color` | `Commons/Color.qml` | theme palette + per-surface roles (`bar`/`menu`/`popups`/`tooltip`/…); `pick()`, `pickAlpha()`, `composed()`, `flatColor()` |
| `Style` | `Commons/Style.qml` | `cornerRadius`, `gapsOut`, state tokens (normal/hover/selected/pressed), `font.*`, `space()`, bar sizes |
| `Util` | `Commons/Util.qml` | `alpha()`, `clamp()`, `parseModuleJson()`, `fileUrl()`, layout/id helpers |
| `Border` | `Commons/Border.qml` | border geometry |

### Services (via `shell.serviceFor(id)` / `shell.ensureService(id)`)
| Service id | Backed by | Exposes |
|---|---|---|
| `omarchy.battery` | `Quickshell.Services.UPower` | `batteryPercentage()`, `isDischarging()`, low-battery notification |
| `omarchy.media` | `Mpris` + `Pipewire` | `players`, `activePlayer`, `hasMedia`, `title`/`artist`/`album`/`artUrl`, playback-capability helpers |
| `omarchy.idle` | `Hyprland`/`Wayland` | `idleEnabled`, `stayAwake`, timeouts, `startIdleCycle()`, `lockSystem()`, `launchScreensaver()` |

### Native bar widgets (add via `shell.json` layout)
`clock`, `active-window`, `workspaces`, `keyboard-layout`, `lock-keys`, `microphone`,
`system-stats`, `system-update`, `tray`, `indicators`, `spacer`.

Lacuna's indicator parity set covers DND/pending notifications, reminders,
night light, stay-awake, screen recording, and dictation. Stateful widgets must
derive intrinsic size from their logical state (`shown`, `active`, availability),
not from effective `Item.visible`: the Omarchy bar slot also derives its own
visibility from widget size, so using effective visibility creates a circular
hide that prevents inactive widgets from revealing when their state changes.

`lacuna.screen-recording` verifies the recorder process locally in addition to
the long-running service, shows a short `REC` heads-up when recording begins,
then collapses to a continuously pulsing Lacuna icon. `lacuna.reminders` uses
the native `omarchy-reminder show --json` state and delegates show/create
actions back to `omarchy-reminder`.

## The injection rule (who can reach what)

- **`menu` / `bar` / `service` / `panel`** plugins receive a **`shell`** reference → they can call
  `shell.serviceFor("omarchy.*")` and import `qs.Commons`.
- **Simple bar-widgets** receive only **`bar` + `moduleName` + `settings`** — **no `shell`**. They
  read `Quickshell.Services.*` directly. **This is the Omarchy-native widget pattern** (Omarchy's
  own Microphone widget reads `Pipewire` directly). Reading raw Quickshell services from a widget
  is aligned, *not* a violation.

## Current Lacuna status

| Surface | Omarchy provides | Lacuna today | Verdict |
|---|---|---|---|
| Battery | `omarchy.battery` (UPower) | `lacuna.power` reads `UPower` directly | **Aligned** (native widget pattern). Don't re-implement low-battery notify. |
| Media | `omarchy.media` (Mpris) | `lacuna.mpris` reads `Mpris` directly | **Aligned**. If a sidebar *display* of now-playing is added, source it from `omarchy.media`. |
| Idle | `omarchy.idle` | `lacuna.idle-inhibitor` + menu CONTROLS shell `omarchy toggle idle` | **Aligned** (uses Omarchy commands). |
| CONTROLS actions | `omarchy <subcommand>` CLI | menu shells `omarchy network status` / `omarchy audio output switch` / `omarchy toggle idle` / bluetoothctl | **Aligned** (command launchers, not reinvented state). |
| Audio / Bluetooth / Temperature / Network | (none) | `lacuna.*` read Pipewire / Bluetooth / hwmon / `omarchy` CLI | Lacuna fills a real gap. |
| System stats | `omarchy.system-stats` widget | `lacuna.system-stats` reads `/proc` | Parallel widget; kept for the Lacuna look. |
| Theme palette | `Color` / `Style` singletons + IPC updates | structural/base roles from `Color` or injected `bar`; settled `colors.toml` reload for extended Quattro hues | **Aligned** — native theme timing with a retained extended-palette supplement (see policy #5). |

## Policy (for new work)

1. **`shell`-having plugins (menu/bar):** reach live system state via
   `shell.serviceFor("omarchy.battery" | "omarchy.media" | "omarchy.idle")`. Mirror the existing
   `resolveLacunaSettings()` pattern in `lacuna.menu/menu/MenuWindow.qml` / `lacuna.bar/Bar.qml`.
2. **Simple bar-widgets:** read `Quickshell.Services.*` directly (native). **Do not** re-implement
   Omarchy orchestration (low-battery notifications, the idle cycle) — display only.
3. **Actions:** prefer `omarchy <subcommand>` CLI commands. The menu CONTROLS already do this for
   Wi-Fi / audio / idle / Bluetooth — keep that pattern.
4. **Prefer native widgets** for rich surfaces where a distinct Lacuna visual isn't needed
   (`script-pill` is the experiment path; promote only durable non-native workflows).
5. **Theme-source consolidation:** use Omarchy `Color` (or the injected bar derived from it) for
   foundational colors, shell roles, and every structural surface. Omarchy updates `Color` from the
   theme IPC payload after atomically replacing the runtime directory; do not independently watch
   `current/theme/colors.toml` or `shell.toml` for those roles. `Color` does not expose Quattro's
   named role hues, so `ColorProfile` still parses `colors.toml` as a supplement for the `colorful`
   profile. Trigger that read from native `Color` changes, retain the last valid palette on failure,
   and retry after the path settles.
