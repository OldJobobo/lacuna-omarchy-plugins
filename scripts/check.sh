#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 -m json.tool config/settings.example.json >/dev/null

while IFS= read -r manifest; do
  python3 -m json.tool "$manifest" >/dev/null
done < <(find . -maxdepth 2 -path './lacuna.*/manifest.json' -print | sort)

if command -v qmllint >/dev/null 2>&1; then
  qmllint $(find . -path './lacuna.*/*.qml' -print | sort)
else
  echo "warning: qmllint not found; skipping QML lint" >&2
fi

if python3 -c 'import pytest' >/dev/null 2>&1; then
  python3 -m pytest
else
  python3 -m unittest discover -s tests
fi
