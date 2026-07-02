"""Shared helpers for runtime QML behavior probes.

The default harness only creates non-window QML objects. Tests that touch the
real desktop or layer-shell surfaces must be opt-in and live in
``test_live_visual.py``.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
QUICKSHELL = shutil.which("quickshell")
HAVE_SESSION = bool(QUICKSHELL and os.environ.get("WAYLAND_DISPLAY"))


def qml_url(path: str | Path) -> str:
    qml = Path(path)
    if not qml.is_absolute():
        qml = ROOT / qml
    return f"file://{qml}"


def run_quickshell(qml: str, *, timeout: int = 60, config_home: Path | None = None) -> str:
    if QUICKSHELL is None:
        raise RuntimeError("quickshell is not available")

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        shell = tmp_path / "shell.qml"
        shell.write_text(qml, encoding="utf-8")
        env = dict(os.environ)
        env["QT_QPA_PLATFORM"] = "wayland"
        if config_home is not None:
            env["XDG_CONFIG_HOME"] = str(config_home)
        proc = subprocess.run(
            [QUICKSHELL, "-p", str(shell)],
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    return proc.stdout + proc.stderr


def parse_behave(output: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line in output.splitlines():
        marker = line.find("BEHAVE ")
        if marker < 0:
            continue
        payload = line[marker + len("BEHAVE ") :].strip()
        rows.append(json.loads(payload))
    return rows


def require_no_qml_errors(output: str) -> None:
    failures = [
        line
        for line in output.splitlines()
        if "BEHAVE_ERR" in line or "ReferenceError:" in line or "TypeError:" in line
    ]
    if failures:
        raise AssertionError("QML harness errors:\n" + "\n".join(failures[-20:]) + "\n\n" + output[-2000:])
