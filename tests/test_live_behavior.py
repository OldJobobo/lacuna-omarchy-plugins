"""Live behavioral tests: instantiate real plugin services in a Quickshell
instance and exercise runtime behavior that static/string tests cannot reach.

These createObject the lacuna.state settings service (a non-visual Item, so no
windows are mapped onto the live desktop) against a temp XDG_CONFIG_HOME and
assert the Tier 0 fixes actually work at runtime: the loaded() signal fires
(it was shadowed and threw before the fix), and a corrupt settings.json is
backed up before defaults are restored.

Skips without a quickshell binary and Wayland session (e.g. CI).
"""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QUICKSHELL = shutil.which("quickshell")
HAVE_SESSION = bool(QUICKSHELL and os.environ.get("WAYLAND_DISPLAY"))
SERVICE_URL = f"file://{ROOT / 'lacuna.state' / 'Service.qml'}"


def harness(body: str) -> str:
    return (
        "import Quickshell\n"
        "import QtQuick\n\n"
        "ShellRoot {\n"
        "  property var svc: null\n"
        "  property bool loadedFired: false\n"
        "  Component.onCompleted: {\n"
        f'    var c = Qt.createComponent("{SERVICE_URL}")\n'
        "    if (c.status === Component.Error) { console.log(\"BEHAVE_ERR \" + c.errorString()); Qt.quit(); return }\n"
        "    svc = c.createObject(root)\n"
        "    svc.loaded.connect(function() { root.loadedFired = true })\n"
        "  }\n"
        "  Timer {\n"
        "    interval: 800; running: true; repeat: false\n"
        f"    onTriggered: {{ {body} Qt.callLater(Qt.quit) }}\n"
        "  }\n"
        "  id: root\n"
        "}\n"
    )


def run_quickshell(config_home: Path, qml: str) -> str:
    with tempfile.TemporaryDirectory() as tmp:
        shell = Path(tmp) / "shell.qml"
        shell.write_text(qml, encoding="utf-8")
        env = dict(os.environ)
        env["QT_QPA_PLATFORM"] = "wayland"
        env["XDG_CONFIG_HOME"] = str(config_home)
        proc = subprocess.run(
            [QUICKSHELL, "-p", str(shell)],
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
        )
    return proc.stdout + proc.stderr


@unittest.skipUnless(HAVE_SESSION, "needs a quickshell binary and a Wayland session")
class LiveBehaviorTests(unittest.TestCase):
    def _settings_dir(self, cfg: Path) -> Path:
        d = cfg / "omarchy" / "lacuna"
        d.mkdir(parents=True)
        return d

    def test_loaded_signal_fires_and_data_is_applied(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp)
            (self._settings_dir(cfg) / "settings.json").write_text(
                '{"colorProfile":"colorful","designStyle":"omarchy"}\n', encoding="utf-8"
            )
            out = run_quickshell(
                cfg,
                harness(
                    'console.log("BEHAVE loadedFired=" + root.loadedFired);'
                    ' console.log("BEHAVE colorProfile=" + (root.svc && root.svc.data ? root.svc.data.colorProfile : "NULL"));'
                ),
            )
        self.assertIn("BEHAVE loadedFired=true", out, out[-1500:])
        self.assertIn("BEHAVE colorProfile=colorful", out, out[-1500:])

    def test_corrupt_settings_are_backed_up_before_defaults(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp)
            settings_dir = self._settings_dir(cfg)
            corrupt = "{ this is not valid json ]["
            (settings_dir / "settings.json").write_text(corrupt, encoding="utf-8")
            out = run_quickshell(
                cfg,
                harness(
                    'console.log("BEHAVE recovered=" + (root.svc ? root.svc.recoveredFromCorruptSettings : "NULL"));'
                    ' console.log("BEHAVE colorProfile=" + (root.svc && root.svc.data ? root.svc.data.colorProfile : "NULL"));'
                ),
            )
            backup = settings_dir / "settings.json.bak"
            self.assertIn("BEHAVE recovered=true", out, out[-1500:])
            self.assertIn("BEHAVE colorProfile=semantic", out, out[-1500:])
            self.assertTrue(backup.exists(), "corrupt settings were not backed up")
            self.assertEqual(backup.read_text(encoding="utf-8"), corrupt)


if __name__ == "__main__":
    unittest.main()
