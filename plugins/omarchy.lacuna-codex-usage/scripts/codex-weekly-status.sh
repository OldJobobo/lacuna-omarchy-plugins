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
import sys

left = float(sys.argv[1])
tooltip = sys.argv[2].strip()
rich_tooltip = "<b>Codex Weekly Limit</b><br/>" + tooltip.replace("\n", "<br/>")

if left <= 10:
    klass = "alert"
elif left <= 25:
    klass = "low"
else:
    klass = "normal"

print(json.dumps({
    "text": f"{left:g}% left",
    "tooltip": rich_tooltip,
    "class": klass,
}, separators=(",", ":")))
PYEOF
