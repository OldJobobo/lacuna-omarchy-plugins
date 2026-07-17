import re
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

    def test_package_uses_matching_immutable_tag(self):
        pkgbuild = PKGBUILD.read_text(encoding="utf-8")
        self.assertIn('pkgver=${_upstream_version//-/}', pkgbuild)
        self.assertIn('source=("git+${url}.git#tag=v${_upstream_version}")', pkgbuild)
        self.assertIn("makedepends=('git')", pkgbuild)

    def test_package_installs_system_payload_without_touching_user_state(self):
        pkgbuild = PKGBUILD.read_text(encoding="utf-8")
        self.assertIn('/usr/share/$pkgname', pkgbuild)
        self.assertIn('cp -a lacuna.* shared config "$appdir/"', pkgbuild)
        self.assertIn('/usr/bin/lacuna-omarchy', pkgbuild)
        self.assertNotIn("$HOME", pkgbuild)
        self.assertNotIn(".config/omarchy", pkgbuild)

    def test_ci_and_release_validate_aur_metadata(self):
        check_script = (ROOT / "scripts" / "check.sh").read_text(encoding="utf-8")
        check_workflow = (ROOT / ".github" / "workflows" / "check.yml").read_text(encoding="utf-8")
        release_workflow = (ROOT / ".github" / "workflows" / "release.yml").read_text(encoding="utf-8")
        self.assertIn("scripts/check-aur-package", check_script)
        self.assertIn("base-devel", check_workflow)
        self.assertIn("Run release checks", release_workflow)
        self.assertIn("packaging", release_workflow)


if __name__ == "__main__":
    unittest.main()
