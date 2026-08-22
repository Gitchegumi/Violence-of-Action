import json
import tempfile
import unittest
from pathlib import Path

from scripts.ci import release_tool


class ReleaseToolTests(unittest.TestCase):
    def test_latest_tag_prefers_stable_release_over_prereleases(self):
        tags = ["v0.4.0-rc.10", "v0.4.0", "v0.4.0-rc.2", "v0.3.0"]

        self.assertEqual(release_tool.latest_tag(tags), "v0.4.0")

    def test_latest_tag_compares_numeric_prerelease_identifiers_numerically(self):
        tags = ["v1.0.0-rc.2", "v1.0.0-rc.10", "v1.0.0-beta.11"]

        self.assertEqual(release_tool.latest_tag(tags), "v1.0.0-rc.10")

    def test_numeric_prerelease_identifier_has_lower_precedence_than_text(self):
        numeric = release_tool.Version.parse("1.0.0-1")
        text = release_tool.Version.parse("1.0.0-alpha")

        self.assertLess(numeric, text)

    def test_invalid_prerelease_identifiers_are_rejected(self):
        for value in ("1.0.0-rc.01", "1.0.0-rc..1", "1.0.0-rc."):
            with self.subTest(value=value):
                with self.assertRaisesRegex(ValueError, "Invalid semantic version"):
                    release_tool.Version.parse(value)

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

    def test_prepare_release_synchronizes_manifest_project_readme_and_changelog(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".release-please-manifest.json").write_text(
                '{".":"0.3.0"}\n', encoding="utf-8"
            )
            (root / "project.godot").write_text(
                'config/version="0.3.0" ; x-release-please-version\n',
                encoding="utf-8",
            )
            (root / "README.md").write_text(
                "![Forgejo release](https://img.shields.io/badge/"
                "Forgejo%20release-v0.3.0-blue) <!-- x-release-please-version -->\n",
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
            self.assertIn(
                "Forgejo%20release-v0.3.1-blue",
                (root / "README.md").read_text(),
            )
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
            (root / "README.md").write_text(
                "![Forgejo release](https://img.shields.io/badge/"
                "Forgejo%20release-v0.4.0-blue) <!-- x-release-please-version -->\n",
                encoding="utf-8",
            )
            (root / "CHANGELOG.md").write_text(
                "# Changelog\n\n## [0.4.0] (2026-08-21)\n", encoding="utf-8"
            )

            with self.assertRaisesRegex(ValueError, "project.godot version"):
                release_tool.validate_release_files(root, "v0.4.0")

    def test_validate_release_rejects_mismatched_readme_badge_version(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".release-please-manifest.json").write_text(
                '{".":"0.4.0"}\n', encoding="utf-8"
            )
            (root / "project.godot").write_text(
                'config/version="0.4.0" ; x-release-please-version\n',
                encoding="utf-8",
            )
            (root / "README.md").write_text(
                "![Forgejo release](https://img.shields.io/badge/"
                "Forgejo%20release-v0.3.0-blue) <!-- x-release-please-version -->\n",
                encoding="utf-8",
            )
            (root / "CHANGELOG.md").write_text(
                "# Changelog\n\n## [0.4.0] (2026-08-21)\n\n* release\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "README.md badge version"):
                release_tool.validate_release_files(root, "v0.4.0")

    def test_prepare_and_validate_prerelease_uses_shields_hyphen_escaping(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".release-please-manifest.json").write_text(
                '{".":"0.9.0"}\n', encoding="utf-8"
            )
            (root / "project.godot").write_text(
                'config/version="0.9.0" ; x-release-please-version\n',
                encoding="utf-8",
            )
            (root / "README.md").write_text(
                "![Forgejo release](https://img.shields.io/badge/"
                "Forgejo%20release-v0.9.0-blue) <!-- x-release-please-version -->\n",
                encoding="utf-8",
            )
            (root / "CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
            commits = [release_tool.Commit("a" * 40, "fix(ui): correct focus", "")]
            version = release_tool.Version.parse("1.0.0-rc.1")

            release_tool.prepare_release(
                root,
                version,
                release_tool.Version.parse("0.9.0"),
                commits,
                "https://git.example/owner/repo",
                "2026-08-22",
            )

            readme = (root / "README.md").read_text(encoding="utf-8")
            self.assertIn("Forgejo%20release-v1.0.0--rc.1-blue", readme)
            self.assertEqual(
                release_tool.validate_release_files(root, "v1.0.0-rc.1"),
                version,
            )

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
