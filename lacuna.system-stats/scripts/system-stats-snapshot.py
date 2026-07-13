#!/usr/bin/env python3
"""Emit a bounded, read-only system telemetry snapshot as JSON."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import time


def read_meminfo(path: Path = Path("/proc/meminfo")) -> dict[str, int]:
    values: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        key, _, rest = line.partition(":")
        try:
            values[key] = int(rest.strip().split()[0]) * 1024
        except (IndexError, ValueError):
            continue
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", 0)
    return {
        "total": total,
        "available": available,
        "used": max(0, total - available),
        "cached": values.get("Cached", 0) + values.get("SReclaimable", 0),
        "swapTotal": values.get("SwapTotal", 0),
        "swapUsed": max(0, values.get("SwapTotal", 0) - values.get("SwapFree", 0)),
    }


def load_cpu_info() -> dict[str, object]:
    load = list(os.getloadavg())
    uptime_seconds = 0.0
    try:
        uptime_seconds = float(Path("/proc/uptime").read_text().split()[0])
    except (OSError, ValueError, IndexError):
        pass
    frequencies: list[float] = []
    try:
        for line in Path("/proc/cpuinfo").read_text(encoding="utf-8").splitlines():
            if line.lower().startswith("cpu mhz"):
                frequencies.append(float(line.split(":", 1)[1].strip()))
    except (OSError, ValueError, IndexError):
        pass
    return {
        "load": [round(value, 2) for value in load],
        "uptimeSeconds": round(uptime_seconds),
        "cores": os.cpu_count() or 0,
        "frequencyMhz": round(sum(frequencies) / len(frequencies)) if frequencies else 0,
    }


def process_rows() -> list[dict[str, object]]:
    command = ["ps", "-eo", "pid=,comm=,pcpu=,pmem=,user=,etime=", "--no-headers"]
    try:
        output = subprocess.run(command, text=True, capture_output=True, timeout=2, check=False).stdout
    except (OSError, subprocess.TimeoutExpired):
        return []
    rows = []
    collector_pids = {os.getpid(), os.getppid()}
    for line in output.splitlines():
        parts = line.split(None, 5)
        if len(parts) != 6:
            continue
        try:
            pid = int(parts[0])
            if pid in collector_pids or parts[1] == "ps" or parts[5] == "00:00":
                continue
            rows.append({
                "pid": pid, "name": parts[1], "cpu": float(parts[2]),
                "memory": float(parts[3]), "user": parts[4], "elapsed": parts[5],
            })
        except ValueError:
            continue
    return rows


def filesystem_rows() -> list[dict[str, object]]:
    command = ["df", "-P", "-B1", "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs"]
    try:
        output = subprocess.run(command, text=True, capture_output=True, timeout=2, check=False).stdout
    except (OSError, subprocess.TimeoutExpired):
        return []
    rows = []
    for line in output.splitlines()[1:]:
        parts = line.split()
        if len(parts) < 6 or not parts[0].startswith("/dev/"):
            continue
        try:
            rows.append({
                "device": parts[0], "total": int(parts[1]), "used": int(parts[2]),
                "available": int(parts[3]), "percent": int(parts[4].rstrip("%")),
                "mount": " ".join(parts[5:]),
            })
        except ValueError:
            continue
    rows.sort(key=lambda row: (row["mount"] != "/", row["mount"]))
    return rows[:8]


def snapshot() -> dict[str, object]:
    processes = process_rows()
    filesystems = filesystem_rows()
    return {
        "timestamp": int(time.time()),
        "cpu": load_cpu_info(),
        "memory": read_meminfo(),
        "topCpu": sorted(processes, key=lambda row: (-row["cpu"], row["pid"]))[:5],
        "topMemory": sorted(processes, key=lambda row: (-row["memory"], row["pid"]))[:5],
        "filesystems": filesystems,
        "rootFilesystem": next((row for row in filesystems if row["mount"] == "/"), {}),
    }


if __name__ == "__main__":
    print(json.dumps(snapshot(), separators=(",", ":")))
