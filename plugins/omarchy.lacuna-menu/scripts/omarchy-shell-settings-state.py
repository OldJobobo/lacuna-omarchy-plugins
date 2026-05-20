#!/usr/bin/env python3
import json
import os
import shutil
import subprocess


def run(args, timeout=2):
  try:
    proc = subprocess.run(args, check=False, capture_output=True, text=True, timeout=timeout)
  except Exception:
    return ""

  if proc.returncode != 0:
    return ""
  return proc.stdout.strip()


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
  raw = run(["hyprctl", "monitors", "-j"])
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
  raw = run(["omarchy-shell", "idle", "status"])
  if not raw:
    return {}
  try:
    parsed = json.loads(raw)
  except Exception:
    return {}
  return parsed if isinstance(parsed, dict) else {}


def notification_dnd():
  value = run(["omarchy-shell", "notifications", "isDnd"]).lower()
  if value == "on":
    return True
  if value == "off":
    return False
  return None


def nightlight_on():
  raw = run(["hyprctl", "hyprsunset", "temperature"])
  digits = "".join(ch for ch in raw if ch.isdigit())
  if digits == "4000":
    return True
  if digits == "6000":
    return False
  return None


def main():
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
    "toggles": {
      "barVisible": not os.path.exists(os.path.join(toggles_dir, "bar-off")),
      "screensaverEnabled": not os.path.exists(os.path.join(toggles_dir, "screensaver-off")),
      "suspendEnabled": not os.path.exists(os.path.join(toggles_dir, "suspend-off")),
      "idleEnabled": idle.get("enabled") if isinstance(idle.get("enabled"), bool) else None,
      "notificationSilencing": notification_dnd(),
      "nightlight": nightlight_on(),
    },
  }

  print(json.dumps(result))


if __name__ == "__main__":
  main()
