#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

while IFS= read -r config; do
  python3 -m json.tool "$config" >/dev/null
done < <(find config -maxdepth 1 -name '*.json' -print | sort)

while IFS= read -r manifest; do
  python3 -m json.tool "$manifest" >/dev/null
done < <(find . -maxdepth 2 -path './lacuna.*/manifest.json' -print | sort)

if command -v qmllint >/dev/null 2>&1; then
  mapfile -t qml_files < <(find . -path './lacuna.*/*.qml' -print | sort)
  qmllint "${qml_files[@]}"
else
  echo "warning: qmllint not found; skipping QML lint" >&2
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/check.sh \
    lacuna.theme-preloader/scripts/*.sh \
    lacuna.claude-usage/scripts/claude-code-status.sh \
    lacuna.codex-usage/scripts/*.sh
else
  echo "warning: shellcheck not found; skipping shell script lint" >&2
fi

qsb_bin=""
if command -v qsb >/dev/null 2>&1; then
  qsb_bin="$(command -v qsb)"
elif [ -x /usr/lib/qt6/bin/qsb ]; then
  qsb_bin="/usr/lib/qt6/bin/qsb"
fi

if [ -n "$qsb_bin" ]; then
  while IFS= read -r shader; do
    baked="${shader}.qsb"
    if [ ! -f "$baked" ]; then
      echo "missing baked shader: $baked" >&2
      exit 1
    fi
    tmp="$(mktemp)"
    "$qsb_bin" --qt6 -O -o "$tmp" "$shader"
    if ! cmp -s "$tmp" "$baked"; then
      echo "stale baked shader: $baked" >&2
      rm -f "$tmp"
      exit 1
    fi
    rm -f "$tmp"
  done < <(find . -maxdepth 3 -path './lacuna.*/shaders/*.frag' -print | sort)
else
  echo "warning: qsb not found; skipping shader bake validation" >&2
fi

scripts/sync-vendored --check

if python3 -c 'import pytest' >/dev/null 2>&1; then
  python3 -m pytest
else
  python3 -m unittest discover -s tests
fi
