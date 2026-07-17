#!/usr/bin/env python3
import fcntl
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys


_active_process = None
_single_flight_lock = None


def terminate_process_group(proc):
  if proc is None or proc.poll() is not None:
    return
  try:
    os.killpg(proc.pid, signal.SIGTERM)
    proc.wait(timeout=0.5)
  except (ProcessLookupError, subprocess.TimeoutExpired):
    try:
      os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
      pass
  except Exception:
    try:
      proc.kill()
    except Exception:
      pass


def handle_termination(signum, _frame):
  terminate_process_group(_active_process)
  raise SystemExit(128 + signum)


def run_command(args, timeout=2):
  global _active_process
  try:
    proc = subprocess.Popen(
      args,
      stdout=subprocess.PIPE,
      stderr=subprocess.DEVNULL,
      text=True,
      start_new_session=True,
    )
    _active_process = proc
    stdout, _stderr = proc.communicate(timeout=timeout)
  except subprocess.TimeoutExpired:
    terminate_process_group(_active_process)
    return ""
  except Exception:
    return ""
  finally:
    _active_process = None

  if proc.returncode != 0:
    return ""
  return stdout.strip()


def run(args, timeout=2):
  return run_command(args, timeout=timeout)


def run_redirected(command, timeout=2):
  return run_command(shlex.split(command), timeout=timeout)


def acquire_single_flight_lock():
  global _single_flight_lock
  runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
  lock_path = os.environ.get(
    "LACUNA_SHELL_SETTINGS_LOCK",
    os.path.join(runtime_dir, "lacuna-shell-settings-state.lock"),
  )
  try:
    lock_file = open(lock_path, "w", encoding="utf-8")
    fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
  except (OSError, IOError):
    try:
      lock_file.close()
    except Exception:
      pass
    return False
  _single_flight_lock = lock_file
  return True


def available(*commands):
  return any(shutil.which(command) for command in commands)


def command_matrix():
  return {
    "terminal": {
      "foot": available("foot"),
      "ghostty": available("ghostty"),
      "alacritty": available("alacritty"),
      "kitty": available("kitty"),
    },
    "browser": {
      "chromium": available("chromium"),
      "chrome": available("google-chrome-stable", "google-chrome", "chrome"),
      "brave": available("brave", "brave-browser"),
      "brave-origin": available("brave-browser"),
      "edge": available("microsoft-edge-stable", "microsoft-edge"),
      "firefox": available("firefox"),
      "zen": available("zen-browser", "zen"),
    },
    "editor": {
      "code": available("code"),
      "cursor": available("cursor"),
      "zed": available("zed"),
      "sublime_text": available("subl", "sublime_text"),
      "helix": available("hx", "helix"),
      "vim": available("vim"),
      "emacs": available("emacs"),
      "nvim": available("nvim"),
    },
  }


def focused_monitor():
  raw = run_redirected("hyprctl monitors -j")
  if not raw:
    return {"name": "", "scale": ""}

  try:
    monitors = json.loads(raw)
  except Exception:
    return {"name": "", "scale": ""}

  if not isinstance(monitors, list):
    return {"name": "", "scale": ""}

  chosen = None
  for monitor in monitors:
    if monitor.get("focused"):
      chosen = monitor
      break
  if chosen is None and monitors:
    chosen = monitors[0]

  if not chosen:
    return {"name": "", "scale": ""}

  scale = chosen.get("scale", "")
  if isinstance(scale, (int, float)):
    scale = f"{scale:g}"
  return {"name": str(chosen.get("name", "")), "scale": str(scale)}


def idle_status():
  raw = run_redirected("omarchy toggle idle status")
  if not raw:
    return {}
  try:
    parsed = json.loads(raw)
  except Exception:
    return {}
  return parsed if isinstance(parsed, dict) else {}


def nightlight_on():
  raw = run_redirected("omarchy toggle nightlight --status")
  if raw:
    try:
      parsed = json.loads(raw)
      if isinstance(parsed, dict) and isinstance(parsed.get("enabled"), bool):
        return parsed.get("enabled")
    except Exception:
      pass

  raw = run_redirected("hyprctl hyprsunset temperature")
  match = re.search(r"\d+", raw)
  if not match:
    return False
  try:
    return int(match.group(0)) < 6000
  except ValueError:
    return False


def hypr_option(name):
  return run_redirected("hyprctl getoption " + shlex.quote(name))


def first_int(raw, prefix):
  for line in raw.splitlines():
    if line.strip().startswith(prefix):
      match = re.search(r"-?\d+", line)
      if match:
        return int(match.group(0))
  return None


def css_gap_value(raw):
  for line in raw.splitlines():
    if "css gap data:" not in line:
      continue
    values = [int(item) for item in re.findall(r"-?\d+", line)]
    if values:
      return max(values)
  return None


def vec2_value(raw):
  for line in raw.splitlines():
    if "vec2:" not in line:
      continue
    values = [int(item) for item in re.findall(r"-?\d+", line)]
    if len(values) >= 2:
      return values[:2]
  return None


def read_file(path):
  try:
    with open(path, "r", encoding="utf-8") as handle:
      return handle.read()
  except Exception:
    return ""


def hypr_state(toggles_dir):
  hypr_toggles = os.path.join(toggles_dir, "hypr")
  stock_no_gaps_flag = os.path.exists(os.path.join(hypr_toggles, "window-no-gaps.lua"))
  lacuna_gaps_file = os.path.join(hypr_toggles, "zz-lacuna-window-gaps.lua")
  lacuna_gaps_text = read_file(lacuna_gaps_file)
  single_aspect_flag = os.path.exists(os.path.join(hypr_toggles, "single-window-aspect-ratio.lua"))
  lacuna_aspect_file = os.path.join(hypr_toggles, "zz-lacuna-single-window-aspect.lua")
  lacuna_aspect_text = read_file(lacuna_aspect_file)
  rounded_text = read_file(os.path.join(hypr_toggles, "zz-lacuna-window-rounded.lua"))

  gaps_in = css_gap_value(hypr_option("general:gaps_in"))
  gaps_out = css_gap_value(hypr_option("general:gaps_out"))
  border_size = first_int(hypr_option("general:border_size"), "int:")
  rounding = first_int(hypr_option("decoration:rounding"), "int:")
  aspect = vec2_value(hypr_option("layout:single_window_aspect_ratio"))

  live_gaps_enabled = any(value and value > 0 for value in [gaps_in, gaps_out])
  if stock_no_gaps_flag:
    gaps_enabled = False
  elif lacuna_gaps_text:
    gaps_enabled = not ("gaps_in = 0" in lacuna_gaps_text and "gaps_out = 0" in lacuna_gaps_text)
  else:
    gaps_enabled = live_gaps_enabled

  if rounded_text:
    rounded_windows = "rounding = 0" not in rounded_text
  else:
    rounded_windows = rounding is not None and rounding > 0

  if lacuna_aspect_text:
    single_aspect = "{ 1, 1 }" in lacuna_aspect_text
  else:
    single_aspect = single_aspect_flag or aspect == [1, 1]

  return {
    "windowGapsEnabled": gaps_enabled,
    "roundedWindows": rounded_windows,
    "singleWindowAspect": single_aspect,
    "gapsIn": -1 if gaps_in is None else gaps_in,
    "gapsOut": -1 if gaps_out is None else gaps_out,
    "borderSize": -1 if border_size is None else border_size,
    "rounding": -1 if rounding is None else rounding,
  }


def main():
  if not acquire_single_flight_lock():
    return 75

  signal.signal(signal.SIGTERM, handle_termination)
  signal.signal(signal.SIGINT, handle_termination)

  home = os.environ.get("HOME", "")
  toggles_dir = os.path.join(home, ".local", "state", "omarchy", "toggles")
  idle = idle_status()

  result = {
    "defaults": {
      "terminal": run(["omarchy", "default", "terminal"]),
      "browser": run(["omarchy", "default", "browser"]),
      "editor": run(["omarchy", "default", "editor"]),
    },
    "available": command_matrix(),
    "font": run(["omarchy", "font", "current"]),
    "fonts": [line.strip() for line in run(["omarchy", "font", "list"], timeout=4).splitlines() if line.strip()],
    "monitor": focused_monitor(),
    "powerProfile": run(["powerprofilesctl", "get"]) if available("powerprofilesctl") else "",
    "powerAvailable": available("powerprofilesctl"),
    "hypr": hypr_state(toggles_dir),
    "toggles": {
      "barVisible": not os.path.exists(os.path.join(toggles_dir, "bar-off")),
      "screensaverEnabled": not os.path.exists(os.path.join(toggles_dir, "screensaver-off")),
      "suspendEnabled": not os.path.exists(os.path.join(toggles_dir, "suspend-off")),
      "idleEnabled": idle.get("enabled") if isinstance(idle.get("enabled"), bool) else False,
      # DND is live shell state. Querying the host through a nested qs IPC
      # client made shell failure fan out into a process storm. The QML service
      # owns optimistic DND state and only invokes IPC for an explicit user
      # action, so an unavailable host remains an unknown value here.
      "notificationSilencing": None,
      "nightlight": nightlight_on(),
    },
  }

  print(json.dumps(result))
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
