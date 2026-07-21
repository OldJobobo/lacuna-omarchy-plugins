import json
import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PKGBUILD = ROOT / "packaging" / "aur" / "PKGBUILD"
SRCINFO = ROOT / "packaging" / "aur" / ".SRCINFO"


class AurPackagingTests(unittest.TestCase):
    def test_package_version_matches_project_version(self):
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        pkgbuild = PKGBUILD.read_text(encoding="utf-8")
        match = re.search(r"^_upstream_version=(.+)$", pkgbuild, re.MULTILINE)
        self.assertIsNotNone(match)
        self.assertEqual(version, match.group(1).strip())
        arch_version = version.replace("-", "")
        self.assertIn(f"\tpkgver = {arch_version}", SRCINFO.read_text(encoding="utf-8"))

    def test_package_uses_release_archive_and_publish_checksum_gate(self):
        pkgbuild = PKGBUILD.read_text(encoding="utf-8")
        self.assertIn("_source_sha256=SKIP", pkgbuild)
        self.assertIn('pkgver=${_upstream_version//-/}', pkgbuild)
        self.assertIn('/releases/download/v${_upstream_version}/', pkgbuild)
        self.assertIn('sha256sums=("${_source_sha256}")', pkgbuild)
        checker = (ROOT / "scripts" / "check-aur-package").read_text(encoding="utf-8")
        self.assertIn("--publish-check", checker)
        self.assertIn("release archive SHA-256 is still SKIP", checker)

    def test_arch_versions_sort_beta_rc_stable(self):
        if not (Path("/usr/bin/vercmp").exists() or subprocess.run(["sh", "-c", "command -v vercmp"], stdout=subprocess.DEVNULL).returncode == 0):
            self.skipTest("vercmp is unavailable")
        versions = ["0.1.0beta.1", "0.1.0beta.2", "0.1.0rc.1", "0.1.0"]
        for older, newer in zip(versions, versions[1:]):
            result = subprocess.run(["vercmp", older, newer], text=True, stdout=subprocess.PIPE, check=True)
            self.assertLess(int(result.stdout.strip()), 0, f"{older} must sort before {newer}")

    def test_package_requires_host_and_installs_only_system_payload(self):
        pkgbuild = PKGBUILD.read_text(encoding="utf-8")
        srcinfo = SRCINFO.read_text(encoding="utf-8")
        self.assertIn("depends=('omarchy' 'python' 'qt6-multimedia')", pkgbuild)
        self.assertIn("\tdepends = omarchy", srcinfo)
        self.assertIn("\tdepends = python", srcinfo)
        self.assertIn("\tdepends = qt6-multimedia", srcinfo)
        self.assertIn('/usr/share/$pkgname', pkgbuild)
        self.assertIn('cp -a lacuna.* shared config "$appdir/"', pkgbuild)
        self.assertIn('/usr/bin/lacuna-omarchy', pkgbuild)
        self.assertNotIn("$HOME", pkgbuild)
        self.assertNotIn(".config/omarchy", pkgbuild)

    def test_ci_and_release_rehearse_packaging(self):
        check_script = (ROOT / "scripts" / "check.sh").read_text(encoding="utf-8")
        check_workflow = (ROOT / ".github" / "workflows" / "check.yml").read_text(encoding="utf-8")
        release_workflow = (ROOT / ".github" / "workflows" / "release.yml").read_text(encoding="utf-8")
        self.assertIn("scripts/check-aur-package", check_script)
        self.assertIn("scripts/rehearse-aur-package", check_workflow)
        self.assertIn("namcap", check_workflow)
        self.assertIn("scripts/build-release-archive", release_workflow)
        self.assertIn("prerelease:", release_workflow)
        compatibility = json.loads((ROOT / "config/quattro-compatibility.json").read_text(encoding="utf-8"))
        revision = compatibility["reviewedOmarchyVersion"].rsplit(".g", 1)[-1].split("-", 1)[0]
        self.assertIn(f"ref: {revision}", check_workflow)
        self.assertIn(f"ref: {revision}", release_workflow)


if __name__ == "__main__":
    unittest.main()
