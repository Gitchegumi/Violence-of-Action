import json
import tempfile
import unittest
from pathlib import Path

from scripts.ci import release_tool


class ReleaseToolTests(unittest.TestCase):
    def test_conventional_commits_choose_highest_required_bump(self):
        commits = [
            release_tool.Commit("a" * 40, "fix(ui): correct focus", ""),
            release_tool.Commit("b" * 40, "feat(input): add controller", ""),
            release_tool.Commit("c" * 40, "docs: update help", ""),
        ]

        self.assertEqual(
            release_tool.next_version(release_tool.Version.parse("0.3.0"), commits),
            release_tool.Version.parse("0.4.0"),
        )

    def test_breaking_change_requires_major_bump(self):
        commits = [
            release_tool.Commit(
                "a" * 40,
                "feat(config): rename release token",
                "BREAKING CHANGE: RELEASE_TOKEN is replaced.",
            )
        ]

        self.assertEqual(
            release_tool.next_version(release_tool.Version.parse("0.3.0"), commits),
            release_tool.Version.parse("1.0.0"),
        )

    def test_non_releasable_commits_do_not_create_a_version(self):
        commits = [release_tool.Commit("a" * 40, "chore(ci): update runner", "")]

        self.assertIsNone(
            release_tool.next_version(release_tool.Version.parse("0.3.0"), commits)
        )

    def test_prepare_release_synchronizes_manifest_project_and_changelog(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".release-please-manifest.json").write_text(
                '{".":"0.3.0"}\n', encoding="utf-8"
            )
            (root / "project.godot").write_text(
                'config/version="0.3.0" ; x-release-please-version\n',
                encoding="utf-8",
            )
            (root / "CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
            commits = [release_tool.Commit("a" * 40, "fix(ui): correct focus", "")]

            release_tool.prepare_release(
                root,
                release_tool.Version.parse("0.3.1"),
                release_tool.Version.parse("0.3.0"),
                commits,
                "https://git.example/owner/repo",
                "2026-08-21",
            )

            manifest = json.loads(
                (root / ".release-please-manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(manifest["."], "0.3.1")
            self.assertIn('config/version="0.3.1"', (root / "project.godot").read_text())
            changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")
            self.assertIn("## [0.3.1]", changelog)
            self.assertIn("### Bug Fixes", changelog)
            self.assertIn("**ui:** correct focus", changelog)

    def test_validate_release_rejects_mismatched_versions(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".release-please-manifest.json").write_text(
                '{".":"0.4.0"}\n', encoding="utf-8"
            )
            (root / "project.godot").write_text(
                'config/version="0.3.0" ; x-release-please-version\n',
                encoding="utf-8",
            )
            (root / "CHANGELOG.md").write_text(
                "# Changelog\n\n## [0.4.0] (2026-08-21)\n", encoding="utf-8"
            )

            with self.assertRaisesRegex(ValueError, "project.godot version"):
                release_tool.validate_release_files(root, "v0.4.0")

    def test_release_notes_are_limited_to_requested_version(self):
        changelog = """# Changelog

## [0.4.0] (2026-08-21)

### Features

* add a thing

## [0.3.0] (2026-08-18)

* older
"""

        self.assertEqual(
            release_tool.release_notes(changelog, release_tool.Version.parse("0.4.0")),
            "### Features\n\n* add a thing",
        )


if __name__ == "__main__":
    unittest.main()
