"""Live load-smoke: compile every self-contained plugin entry point in a real
Quickshell instance and fail on any QML load error.

Unlike the static load-smoke, this resolves the full QML type/import tree
(Quickshell types, custom components, bindings) the way the running shell does.
It uses Qt.createComponent (compile only, never createObject), so no windows or
layer-shell surfaces are mapped onto the live desktop.

Skips when there is no Quickshell binary or Wayland session (e.g. CI). Entry
points that import Omarchy host modules (``qs.*``) are host-dependent: they only
resolve with the Omarchy shell as the config root, so they are exercised
separately by the running shell rather than here.
"""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QUICKSHELL = shutil.which("quickshell")
HAVE_SESSION = bool(QUICKSHELL and os.environ.get("WAYLAND_DISPLAY"))


def entry_points() -> tuple[list[Path], list[Path]]:
    """Return (self_contained, host_dependent) entry-point QML files."""
    self_contained: list[Path] = []
    host_dependent: list[Path] = []
    for manifest_path in sorted(ROOT.glob("lacuna.*/manifest.json")):
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        for target in (data.get("entryPoints") or {}).values():
            qml = manifest_path.parent / target
            text = qml.read_text(encoding="utf-8")
            (host_dependent if "import qs." in text else self_contained).append(qml)
    return self_contained, host_dependent


def build_harness(urls: list[Path]) -> str:
    array = ",\n      ".join(f'"file://{path}"' for path in urls)
    return (
        "import Quickshell\n"
        "import QtQuick\n\n"
        "ShellRoot {\n"
        "  Component.onCompleted: {\n"
        f"    var urls = [\n      {array}\n    ]\n"
        "    var failures = 0\n"
        "    for (var i = 0; i < urls.length; i++) {\n"
        "      var c = Qt.createComponent(urls[i])\n"
        "      if (c.status === Component.Error) {\n"
        "        failures += 1\n"
        '        console.log("LOADFAIL " + urls[i] + " :: " + c.errorString().replace(/\\n/g, " | "))\n'
        "      }\n"
        "      c.destroy()\n"
        "    }\n"
        '    console.log("SMOKE_SUMMARY failures=" + failures + " total=" + urls.length)\n'
        "    Qt.callLater(Qt.quit)\n"
        "  }\n"
        "}\n"
    )


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class LiveLoadSmokeTests(unittest.TestCase):
    def test_self_contained_entry_points_compile_in_quickshell(self):
        self_contained, _host = entry_points()
        self.assertTrue(self_contained, "no self-contained entry points found")

        with tempfile.TemporaryDirectory() as tmp:
            shell = Path(tmp) / "shell.qml"
            shell.write_text(build_harness(self_contained), encoding="utf-8")
            env = dict(os.environ)
            env["QT_QPA_PLATFORM"] = "wayland"
            proc = subprocess.run(
                [QUICKSHELL, "-p", str(shell)],
                env=env,
                capture_output=True,
                text=True,
                timeout=120,
            )

        output = proc.stdout + proc.stderr
        self.assertIn("SMOKE_SUMMARY", output, output[-2000:])
        failures = [line.split("DEBUG", 1)[-1] for line in output.splitlines() if "LOADFAIL" in line]
        self.assertEqual(failures, [], "QML entry points failed to load:\n" + "\n".join(failures))


if __name__ == "__main__":
    unittest.main()
