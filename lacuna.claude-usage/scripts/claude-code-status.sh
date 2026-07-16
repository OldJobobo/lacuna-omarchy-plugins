#!/usr/bin/env bash

set -euo pipefail

# Prefer Claude's authenticated usage endpoint so optional provider windows can
# be detected directly. If it is unavailable, fall back to ccusage's calibrated
# cost estimates without claiming that a missing window has been suppressed.
#
#   session% = active-5h-block cost  / SESSION_BUDGET
#   week%    = trailing-7-day cost    / WEEK_BUDGET
#
# Calibrated 2026-06-17: block $14.59 = 12% used, 7-day $344 = 26% used.
SESSION_BUDGET="${CLAUDE_USAGE_SESSION_BUDGET:-121.6}"
WEEK_BUDGET="${CLAUDE_USAGE_WEEK_BUDGET:-1324}"
WEEK_RESET_DOW="${CLAUDE_USAGE_WEEK_RESET_DOW:-2}"   # 0=Mon .. 6=Sun (Wed default)
WEEK_RESET_HOUR="${CLAUDE_USAGE_WEEK_RESET_HOUR:-18}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CACHE_TTL="${CLAUDE_CODE_STATUS_CACHE_TTL:-90}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/lacuna"
cache_file="$cache_dir/claude-code-status.json"

hide() {
  printf '%s\n' '{"text":"","tooltip":"","class":"hidden"}'
  exit 0
}

serve_cache_or_hide() {
  [[ -f "$cache_file" ]] && { cat "$cache_file"; exit 0; }
  hide
}

resolve_ccusage() {
  if [[ -n "${CCUSAGE_BIN:-}" ]]; then
    [[ -x "$CCUSAGE_BIN" ]] && { printf '%s' "$CCUSAGE_BIN"; return 0; }
    return 1
  fi
  local found
  found="$(command -v ccusage 2>/dev/null)" && { printf '%s' "$found"; return 0; }
  local candidate
  for candidate in \
    "$HOME/.local/bin/ccusage" \
    "$HOME/.local/share/mise/shims/ccusage"; do
    [[ -x "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}

command -v python3 >/dev/null 2>&1 || hide

# Serve a fresh cache without spawning ccusage.
if [[ -f "$cache_file" ]]; then
  now_epoch=$(date +%s)
  file_epoch=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
  if ((now_epoch - file_epoch < CACHE_TTL)); then
    cat "$cache_file"
    exit 0
  fi
fi

ccusage_bin="$(resolve_ccusage)" || serve_cache_or_hide

mkdir -p "$cache_dir" 2>/dev/null || true
blocks_file="$cache_dir/blocks.json"
timeout 30 "$ccusage_bin" blocks --json --offline >"$blocks_file" 2>/dev/null || true
[[ -s "$blocks_file" ]] || serve_cache_or_hide

payload="$(CLAUDE_HOME="$CLAUDE_HOME" \
  SESSION_BUDGET="$SESSION_BUDGET" WEEK_BUDGET="$WEEK_BUDGET" \
  WEEK_RESET_DOW="$WEEK_RESET_DOW" WEEK_RESET_HOUR="$WEEK_RESET_HOUR" \
  python3 - "$blocks_file" <<'PYEOF'
import datetime as dt
import glob
import html
import json
import os
import sys
import urllib.request

claude_home = os.environ["CLAUDE_HOME"]
session_budget = max(0.01, float(os.environ.get("SESSION_BUDGET") or 0) or 0.01)
week_budget = max(0.01, float(os.environ.get("WEEK_BUDGET") or 0) or 0.01)
week_dow = int(os.environ.get("WEEK_RESET_DOW") or 2)
week_hour = int(os.environ.get("WEEK_RESET_HOUR") or 18)


def emit(payload):
    print(json.dumps(payload, separators=(",", ":")))
    raise SystemExit


try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    emit({"text": "", "tooltip": "", "class": "hidden"})

blocks = data.get("blocks") or []
now = dt.datetime.now(dt.timezone.utc)


def parse(value):
    try:
        return dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None


def local_time(value, fmt="%-I:%M %p"):
    return value.astimezone().strftime(fmt) if value else ""


def usage_api_payload():
    fixture = os.environ.get("CLAUDE_USAGE_API_FILE", "").strip()
    if fixture:
        try:
            with open(fixture, encoding="utf-8") as handle:
                payload = json.load(handle)
            return payload if isinstance(payload, dict) else None
        except Exception:
            return None

    if os.environ.get("CLAUDE_USAGE_API_DISABLE") == "1":
        return None

    try:
        with open(os.path.join(claude_home, ".credentials.json"), encoding="utf-8") as handle:
            credentials = json.load(handle)
        oauth = credentials.get("claudeAiOauth") or {}
        access_token = str(oauth.get("accessToken") or "")
        expires_at = float(oauth.get("expiresAt") or 0) / 1000
        if not access_token or (expires_at and expires_at <= now.timestamp()):
            return None

        request = urllib.request.Request(
            "https://api.anthropic.com/api/oauth/usage",
            headers={
                "Authorization": "Bearer " + access_token,
                "anthropic-version": "2023-06-01",
                "User-Agent": "lacuna-claude-usage",
            },
        )
        with urllib.request.urlopen(request, timeout=5) as response:
            payload = json.load(response)
        return payload if isinstance(payload, dict) else None
    except Exception:
        return None


def utilization_percent(window):
    try:
        value = float(window.get("utilization"))
    except (AttributeError, TypeError, ValueError):
        return 0
    if value <= 1:
        value *= 100
    return max(0, min(100, round(value)))


session_cost = 0.0
session_end = None
week_cost = 0.0
for block in blocks:
    if block.get("isGap"):
        continue
    cost = float(block.get("costUSD") or 0)
    if block.get("isActive"):
        session_cost = cost
        session_end = parse(block.get("endTime"))
    end = parse(block.get("endTime"))
    if end and end >= now - dt.timedelta(days=7):
        week_cost += cost


def pct(cost, budget):
    return max(0, min(100, round(cost / budget * 100)))


def class_for(used):
    if used >= 100:
        return "over"
    if used >= 90:
        return "alert"
    if used >= 80:
        return "low"
    return "normal"


def next_weekly_reset():
    local_now = now.astimezone()
    target = local_now.replace(hour=week_hour, minute=0, second=0, microsecond=0)
    ahead = (week_dow - local_now.weekday()) % 7
    target += dt.timedelta(days=ahead)
    if target <= local_now:
        target += dt.timedelta(days=7)
    return target


def active_pid(pid):
    text = str(pid or "")
    return text.isdigit() and os.path.isdir(os.path.join("/proc", text))


def live_session_count():
    session_dir = os.path.join(claude_home, "sessions")
    if not os.path.isdir(session_dir):
        return 0
    count = 0
    for path in glob.glob(os.path.join(session_dir, "*.json")):
        try:
            with open(path, encoding="utf-8") as handle:
                payload = json.load(handle)
        except Exception:
            continue
        if active_pid(payload.get("pid")):
            count += 1
    return count


session_used = pct(session_cost, session_budget)
week_used = pct(week_cost, week_budget)
session_active = session_end is not None
session_available = True
week_available = True
availability_known = False
session_reset = local_time(session_end)
week_reset = next_weekly_reset().strftime("%a %-I %p")
source = "ccusage (calibrated)"

api_payload = usage_api_payload()
if api_payload is not None:
    availability_known = True
    session_window = api_payload.get("five_hour")
    week_window = api_payload.get("seven_day")
    session_available = isinstance(session_window, dict)
    week_available = isinstance(week_window, dict)
    session_used = utilization_percent(session_window) if session_available else 0
    week_used = utilization_percent(week_window) if week_available else 0
    session_end = parse(session_window.get("resets_at")) if session_available else None
    week_end = parse(week_window.get("resets_at")) if week_available else None
    session_reset = local_time(session_end)
    week_reset = local_time(week_end, "%a %-I %p")
    session_active = session_available
    source = "Claude usage API"

session_left = max(0, 100 - session_used)
week_left = max(0, 100 - week_used)
active_used = session_used if session_available else week_used
active_class = class_for(active_used)
session_count = live_session_count()

payload = {
    "text": f"{active_used}% used",
    "shortText": f"{active_used}%",
    "tooltip": "",
    "class": active_class if session_available else class_for(week_used),
    "leftPercent": session_left,
    "usedPercent": session_used,
    "active": session_active,
    "sessionAvailable": session_available,
    "sessionAvailabilityKnown": availability_known,
    "resetText": session_reset,
    "sessionCount": session_count,
    "source": source,
    "weekActive": week_available,
    "weekLeftPercent": week_left,
    "weekUsedPercent": week_used,
    "weekClass": class_for(week_used),
    "weekText": f"{week_used}% wk",
    "weekShortText": f"{week_used}%",
    "weekResetText": week_reset,
}

su = html.escape(str(session_used))
wu = html.escape(str(week_used))
lines = ["<b>Claude Code Usage</b>"]
if session_available:
    lines.append(f"<b>{su}% used</b> · 5h block")
    if session_reset:
        lines.append(f"Resets: {html.escape(session_reset)}")
elif availability_known:
    lines.append("5h block: suppressed")
if week_available:
    lines.append(f"<b>{wu}% used</b> · 7-day")
    if week_reset:
        lines.append(f"Resets: {html.escape(week_reset)}")
lines.append(f"Sessions: {session_count}")
lines.append("Source: " + html.escape(source))
payload["tooltip"] = "<br/>".join(lines)
emit(payload)
PYEOF
)"

if [[ -n "$payload" ]] && ! printf '%s' "$payload" | grep -q '"class":"hidden"'; then
  printf '%s\n' "$payload" | tee "$cache_file" 2>/dev/null || printf '%s\n' "$payload"
else
  serve_cache_or_hide
fi
