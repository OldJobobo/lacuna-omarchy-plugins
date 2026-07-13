#!/usr/bin/env python3
"""Read hwmon temperature sensors and emit a classified JSON snapshot."""

from __future__ import annotations

import json
from pathlib import Path
import time


GROUPS = {
    "k10temp": "CPU", "coretemp": "CPU", "zenpower": "CPU",
    "amdgpu": "GPU", "nouveau": "GPU", "nvidia": "GPU",
    "nvme": "NVME", "acpitz": "ACPI",
}


def sensor_group(device: str) -> str:
    return GROUPS.get(device.lower(), "BOARD")


def primary_score(sensor: dict[str, object]) -> tuple[int, float]:
    group = sensor["group"]
    label = str(sensor["label"]).lower()
    device = str(sensor["device"]).lower()
    score = 0
    if group == "CPU": score += 100
    if device in {"k10temp", "coretemp"}: score += 40
    if any(word in label for word in ("tctl", "package", "tdie")): score += 30
    if "core" in label: score += 10
    return score, float(sensor["celsius"])


def read_sensors(root: Path = Path("/sys/class/hwmon")) -> list[dict[str, object]]:
    sensors = []
    for hwmon in sorted(root.glob("hwmon*")):
        try:
            device = (hwmon / "name").read_text(encoding="utf-8").strip()
        except OSError:
            device = hwmon.name
        for value_path in sorted(hwmon.glob("temp*_input")):
            try:
                value = float(value_path.read_text(encoding="utf-8").strip()) / 1000.0
            except (OSError, ValueError):
                continue
            if value <= 0 or value >= 150:
                continue
            stem = value_path.name.removesuffix("_input")
            try:
                label = (hwmon / f"{stem}_label").read_text(encoding="utf-8").strip()
            except OSError:
                label = stem.upper()
            sensors.append({
                "id": f"{device}:{stem}", "device": device, "label": label,
                "group": sensor_group(device), "celsius": round(value, 1),
                "fahrenheit": round(value * 9 / 5 + 32),
            })
    return sensors


def snapshot(root: Path = Path("/sys/class/hwmon")) -> dict[str, object]:
    sensors = read_sensors(root)
    primary = max(sensors, key=primary_score) if sensors else {}
    hottest = max(sensors, key=lambda sensor: sensor["celsius"]) if sensors else {}
    return {"timestamp": int(time.time()), "primary": primary, "hottest": hottest, "sensors": sensors}


if __name__ == "__main__":
    print(json.dumps(snapshot(), separators=(",", ":")))
