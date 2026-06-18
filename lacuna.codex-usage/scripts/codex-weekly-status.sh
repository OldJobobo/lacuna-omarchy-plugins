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

python3 - "$output" <<'PYEOF'
import json
import re
import sys
from datetime import datetime, timezone
from html import escape

raw = sys.argv[1].strip()


def fields(raw_text):
    parsed = {}
    for line in raw_text.splitlines():
        if ": " not in line:
            continue
        key, value = line.split(": ", 1)
        parsed[key.strip().lower()] = value.strip()
    return parsed


def percent_value(value):
    text = str(value or "").strip()
    match = re.search(r"([0-9]+(?:[.][0-9]+)?)", text)
    if not match:
        return None
    return max(0.0, min(100.0, float(match.group(1))))


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
session_left = percent_value(data.get("5h limit left"))
session_used = percent_value(data.get("5h used"))
week_left = percent_value(data.get("weekly limit left"))
week_used = percent_value(data.get("weekly used"))

if session_left is None and session_used is not None:
    session_left = max(0.0, 100.0 - session_used)
if session_used is None and session_left is not None:
    session_used = max(0.0, 100.0 - session_left)
if week_left is None and week_used is not None:
    week_left = max(0.0, 100.0 - week_used)
if week_used is None and week_left is not None:
    week_used = max(0.0, 100.0 - week_left)

if session_left is None and week_left is None:
    print(json.dumps({"text": "", "tooltip": "", "class": "hidden"}, separators=(",", ":")))
    raise SystemExit

session_active = session_left is not None
active_left = session_left if session_active else week_left
active_used = session_used if session_active else week_used
left_text = f"{active_left:g}%"
used_text = f"{active_used:g}%"
reset_text = clean_reset(data.get("5h resets") or data.get("resets") or data.get("weekly resets") or "unknown")
week_reset_text = clean_reset(data.get("weekly resets") or data.get("resets") or "")
plan_text = clean_plan(data.get("plan", "unknown"))
event_text = clean_event_time(data.get("source event", ""))
source_file = data.get("source file", "")

def class_for(left):
    if left <= 10:
        return "alert", "#bf616a"
    if left <= 25:
        return "low", "#ebcb8b"
    return "normal", "#8cbfb8"


klass, left_color = class_for(active_left)
week_class, week_left_color = class_for(week_left) if week_left is not None else ("hidden", "#8cbfb8")

if session_active:
    text = f"{left_text} 5h"
else:
    text = f"{left_text} left"

if week_left is not None:
    week_left_text = f"{week_left:g}%"
    week_used_text = f"{week_used:g}%"
else:
    week_left_text = ""
    week_used_text = ""

tooltip_lines = [
    "<b>Codex Usage</b>",
]

if session_active:
    tooltip_lines.append(
        f"<font color='{left_color}'><b>{escape(left_text)} left</b></font> "
        f"<font color='#9aa3ad'>({escape(used_text)} used)</font> - 5h"
    )
    if reset_text:
        tooltip_lines.append(f"5h resets: {escape(reset_text)}")

if week_left is not None:
    tooltip_lines.append(
        f"<font color='{week_left_color}'><b>{escape(week_left_text)} left</b></font> "
        f"<font color='#9aa3ad'>({escape(week_used_text)} used)</font> - weekly"
    )
    if week_reset_text:
        tooltip_lines.append(f"Weekly resets: {escape(week_reset_text)}")

tooltip_lines.extend([
    f"Plan: {escape(plan_text)}",
])

if event_text:
    tooltip_lines.append(f"Updated: {escape(event_text)}")

payload = {
    "text": text,
    "shortText": left_text,
    "tooltip": "<br/>".join(tooltip_lines),
    "class": klass,
    "leftPercent": round(active_left),
    "usedPercent": round(active_used),
    "active": session_active,
    "resetText": reset_text,
    "planText": plan_text,
    "sourceEventText": event_text,
    "sourceFileText": source_file,
    "source": "local Codex token_count event",
    "weekActive": week_left is not None,
    "weekLeftPercent": round(week_left) if week_left is not None else 100,
    "weekUsedPercent": round(week_used) if week_used is not None else 0,
    "weekClass": week_class,
    "weekText": f"{week_left_text} wk" if week_left_text else "",
    "weekShortText": week_left_text,
    "weekResetText": week_reset_text,
}

print(json.dumps(payload, separators=(",", ":")))
PYEOF
