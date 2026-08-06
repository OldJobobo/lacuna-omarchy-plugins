import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOOTSTRAP = ROOT / "install.sh"


class SourceBootstrapTests(unittest.TestCase):
    def test_help_describes_official_source_alternative(self):
        result = subprocess.run(
            [str(BOOTSTRAP), "--help"],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        self.assertIn("Install or refresh Lacuna Shell from the official GitHub source checkout", result.stdout)
        self.assertIn("alternative to the published AUR package", result.stdout)
        self.assertIn("--dir PATH", result.stdout)

    @unittest.skipIf(os.geteuid() == 0, "bootstrap intentionally refuses root")
    def test_bootstrap_prepares_dependencies_and_runs_full_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            temp = Path(tmp)
            source = temp / "source"
            source.mkdir()
            (source / "scripts").mkdir()
            installer = source / "scripts" / "lacuna"
            installer.write_text(
                "#!/usr/bin/env bash\n"
                "printf 'lacuna %s\\n' \"$*\" >>\"$BOOTSTRAP_LOG\"\n",
                encoding="utf-8",
            )
            installer.chmod(0o755)
            subprocess.run(["git", "init", "-q", "-b", "master"], cwd=source, check=True)
            subprocess.run(["git", "add", "."], cwd=source, check=True)
            subprocess.run(
                [
                    "git",
                    "-c",
                    "user.name=Lacuna Test",
                    "-c",
                    "user.email=lacuna@example.invalid",
                    "commit",
                    "-qm",
                    "Create fixture",
                ],
                cwd=source,
                check=True,
            )

            fake_bin = temp / "bin"
            fake_bin.mkdir()
            omarchy = fake_bin / "omarchy"
            omarchy.write_text(
                "#!/usr/bin/env bash\n"
                "printf 'omarchy %s\\n' \"$*\" >>\"$BOOTSTRAP_LOG\"\n",
                encoding="utf-8",
            )
            omarchy.chmod(0o755)

            log = temp / "bootstrap.log"
            checkout = temp / "checkout"
            env = os.environ.copy()
            env.update(
                {
                    "BOOTSTRAP_LOG": str(log),
                    "LACUNA_REPO_URL": str(source),
                    "LACUNA_REPO_REF": "master",
                    "PATH": f"{fake_bin}:{env['PATH']}",
                }
            )
            result = subprocess.run(
                [str(BOOTSTRAP), "--yes", "--dir", str(checkout)],
                check=True,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            actions = log.read_text(encoding="utf-8")
            self.assertIn(
                "omarchy pkg add git python qt6-multimedia mpv yt-dlp imagemagick",
                actions,
            )
            install_action = "lacuna install --profile full --reinstall --yes"
            self.assertIn(install_action, actions)
            self.assertTrue((checkout / ".git").is_dir())
            self.assertIn("Source ref:        master", result.stdout)
            self.assertEqual(
                subprocess.run(
                    ["git", "branch", "--show-current"], cwd=checkout, check=True,
                    text=True, stdout=subprocess.PIPE,
                ).stdout.strip(),
                "master",
            )
            self.assertIn("Lacuna Shell is installed.", result.stdout)

            second_result = subprocess.run(
                [str(BOOTSTRAP), "--yes", "--dir", str(checkout)],
                check=True,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.assertEqual(
                log.read_text(encoding="utf-8").count(install_action),
                2,
            )
            self.assertIn("Lacuna Shell is installed.", second_result.stdout)


if __name__ == "__main__":
    unittest.main()
