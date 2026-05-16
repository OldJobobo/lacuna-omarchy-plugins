#!/usr/bin/env bash

set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
weekly_left_bin="$plugin_dir/scripts/codex-weekly-left"

hide() {
  printf '%s\n' '{"text":"","tooltip":"","class":"hidden"}'
  exit 0
}

command -v python3 >/dev/null 2>&1 || hide
[[ -x "$weekly_left_bin" ]] || hide

output="$("$weekly_left_bin" 2>/dev/null)" || hide

left="$(printf '%s\n' "$output" | awk -F': ' '/^Weekly limit left:/ {print $2; exit}')"
[[ -n "${left:-}" ]] || hide

left="${left%%%}"
left="${left%%.0}"
[[ "$left" =~ ^[0-9]+([.][0-9]+)?$ ]] || hide

python3 - "$left" "$output" <<'PYEOF'
import json
import re
import sys
from datetime import datetime, timezone
from html import escape

left = float(sys.argv[1])
raw = sys.argv[2].strip()


def fields(raw_text):
    parsed = {}
    for line in raw_text.splitlines():
        if ": " not in line:
            continue
        key, value = line.split(": ", 1)
        parsed[key.strip().lower()] = value.strip()
    return parsed


def clean_percent(value, fallback):
    text = str(value or "").strip()
    match = re.search(r"([0-9]+(?:[.][0-9]+)?)", text)
    if not match:
        return f"{fallback:g}%"
    amount = float(match.group(1))
    return f"{amount:g}%"


def clean_reset(value):
    text = str(value or "").strip()
    return re.sub(r"(:[0-9]{2}) ([AP]M )", r" \2", text)


def clean_event_time(value):
    text = str(value or "").strip()
    if not text:
        return ""
    try:
        dt = datetime.fromisoformat(text.replace("Z", "+00:00")).astimezone()
        return dt.strftime("%Y-%m-%d %I:%M %p %Z")
    except ValueError:
        return text


def clean_plan(value):
    text = str(value or "").strip()
    labels = {
        "prolite": "Pro Lite",
        "pro": "Pro",
        "plus": "Plus",
        "team": "Team",
        "enterprise": "Enterprise",
    }
    return labels.get(text.lower(), text or "Unknown")


data = fields(raw)
used_text = clean_percent(data.get("weekly used"), max(0.0, 100.0 - left))
left_text = f"{left:g}%"
reset_text = clean_reset(data.get("resets", "unknown"))
plan_text = clean_plan(data.get("plan", "unknown"))
event_text = clean_event_time(data.get("source event", ""))

if left <= 10:
    klass = "alert"
    left_color = "#bf616a"
elif left <= 25:
    klass = "low"
    left_color = "#ebcb8b"
else:
    klass = "normal"
    left_color = "#8cbfb8"

tooltip_lines = [
    "<b>Codex Weekly Usage</b>",
    f"<font color='{left_color}'><b>{escape(left_text)} left</b></font> <font color='#9aa3ad'>({escape(used_text)} used)</font>",
    f"Resets: {escape(reset_text)}",
    f"Plan: {escape(plan_text)}",
]

if event_text:
    tooltip_lines.append(f"Updated: {escape(event_text)}")

print(json.dumps({
    "text": f"{left_text} left",
    "tooltip": "<br/>".join(tooltip_lines),
    "class": klass,
}, separators=(",", ":")))
PYEOF
