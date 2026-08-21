#!/usr/bin/env python3
"""Forgejo-native release planning, validation, and API helpers."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from functools import total_ordering
from pathlib import Path
from typing import Iterable


SEMVER_RE = re.compile(
    r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\."
    r"(?P<patch>0|[1-9]\d*)(?P<suffix>-[0-9A-Za-z.-]+)?$"
)
CONVENTIONAL_RE = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?: "
    r"(?P<description>.+)$"
)


@total_ordering
@dataclass(frozen=True)
class Version:
    major: int
    minor: int
    patch: int
    suffix: str = ""

    @classmethod
    def parse(cls, value: str) -> "Version":
        match = SEMVER_RE.fullmatch(value)
        if not match:
            raise ValueError(f"Invalid semantic version: {value}")
        return cls(
            int(match.group("major")),
            int(match.group("minor")),
            int(match.group("patch")),
            match.group("suffix") or "",
        )

    def __str__(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}{self.suffix}"

    def _precedence(self) -> tuple[int, int, int, int, str]:
        return (
            self.major,
            self.minor,
            self.patch,
            1 if not self.suffix else 0,
            self.suffix,
        )

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        return self._precedence() < other._precedence()

    def bump(self, level: str) -> "Version":
        if level == "major":
            return Version(self.major + 1, 0, 0)
        if level == "minor":
            return Version(self.major, self.minor + 1, 0)
        if level == "patch":
            return Version(self.major, self.minor, self.patch + 1)
        raise ValueError(f"Unknown version bump: {level}")


@dataclass(frozen=True)
class Commit:
    sha: str
    subject: str
    body: str

    def conventional(self) -> re.Match[str] | None:
        match = CONVENTIONAL_RE.fullmatch(self.subject.strip())
        if match:
            return match
        if self.subject.startswith("Merge "):
            for line in self.body.splitlines():
                match = CONVENTIONAL_RE.fullmatch(line.strip())
                if match:
                    return match
        return None

    def is_breaking(self) -> bool:
        match = self.conventional()
        return bool(
            match
            and (
                match.group("breaking")
                or re.search(r"^BREAKING(?: CHANGE|-CHANGE):", self.body, re.MULTILINE)
            )
        )


def next_version(current: Version, commits: Iterable[Commit]) -> Version | None:
    level = 0
    for commit in commits:
        match = commit.conventional()
        if not match:
            continue
        if commit.is_breaking():
            level = max(level, 3)
        elif match.group("type") == "feat":
            level = max(level, 2)
        elif match.group("type") in {"fix", "perf"}:
            level = max(level, 1)
    return current.bump({1: "patch", 2: "minor", 3: "major"}[level]) if level else None


def _manifest_version(root: Path) -> Version:
    manifest = json.loads(
        (root / ".release-please-manifest.json").read_text(encoding="utf-8")
    )
    if set(manifest) != {"."}:
        raise ValueError("Release manifest must contain exactly one root package")
    return Version.parse(manifest["."])


def _project_version(root: Path) -> Version:
    project = (root / "project.godot").read_text(encoding="utf-8")
    matches = re.findall(r'^config/version="([^"]+)"', project, re.MULTILINE)
    if len(matches) != 1:
        raise ValueError("project.godot must contain exactly one config/version")
    return Version.parse(matches[0])


def validate_release_files(root: Path, tag: str) -> Version:
    if not tag.startswith("v"):
        raise ValueError("Release tag must use v<semver>")
    tag_version = Version.parse(tag[1:])
    manifest_version = _manifest_version(root)
    project_version = _project_version(root)
    if manifest_version != tag_version:
        raise ValueError(
            f"manifest version {manifest_version} does not match tag {tag_version}"
        )
    if project_version != tag_version:
        raise ValueError(
            f"project.godot version {project_version} does not match tag {tag_version}"
        )
    release_notes((root / "CHANGELOG.md").read_text(encoding="utf-8"), tag_version)
    return tag_version


def release_notes(changelog: str, version: Version) -> str:
    heading = re.compile(rf"^## \[{re.escape(str(version))}\].*$", re.MULTILINE)
    match = heading.search(changelog)
    if not match:
        raise ValueError(f"CHANGELOG.md has no section for {version}")
    start = match.end()
    next_heading = re.search(r"^## ", changelog[start:], re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(changelog)
    notes = changelog[start:end].strip()
    if not notes:
        raise ValueError(f"CHANGELOG.md section for {version} is empty")
    return notes


def _release_entries(commits: Iterable[Commit], repository_url: str) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {
        "Breaking Changes": [],
        "Features": [],
        "Bug Fixes": [],
        "Performance Improvements": [],
    }
    seen: set[tuple[str, str, str]] = set()
    for commit in commits:
        match = commit.conventional()
        if not match:
            continue
        commit_type = match.group("type")
        if commit.is_breaking():
            group = "Breaking Changes"
        elif commit_type == "feat":
            group = "Features"
        elif commit_type == "fix":
            group = "Bug Fixes"
        elif commit_type == "perf":
            group = "Performance Improvements"
        else:
            continue
        scope = match.group("scope") or ""
        description = match.group("description")
        key = (group, scope, description)
        if key in seen:
            continue
        seen.add(key)
        prefix = f"**{scope}:** " if scope else ""
        short_sha = commit.sha[:7]
        groups[group].append(
            f"* {prefix}{description} "
            f"([{short_sha}]({repository_url}/commit/{commit.sha}))"
        )
    return groups


def prepare_release(
    root: Path,
    version: Version,
    previous: Version,
    commits: Iterable[Commit],
    repository_url: str,
    release_date: str,
) -> None:
    if version <= previous:
        raise ValueError("New release version must be greater than the current version")
    manifest_path = root / ".release-please-manifest.json"
    manifest_path.write_text(json.dumps({".": str(version)}, separators=(",", ":")) + "\n")

    project_path = root / "project.godot"
    project = project_path.read_text(encoding="utf-8")
    updated, count = re.subn(
        r'^(config/version=")[^"]+("\s*;\s*x-release-please-version\s*)$',
        rf"\g<1>{version}\g<2>",
        project,
        flags=re.MULTILINE,
    )
    if count != 1:
        raise ValueError("Could not update the single release version in project.godot")
    project_path.write_text(updated, encoding="utf-8")

    groups = _release_entries(commits, repository_url)
    sections = []
    for title, entries in groups.items():
        if entries:
            sections.append(f"### {title}\n\n" + "\n".join(entries))
    if not sections:
        raise ValueError("No releasable Conventional Commits were found")
    heading = (
        f"## [{version}]({repository_url}/compare/v{previous}...v{version}) "
        f"({release_date})"
    )
    block = heading + "\n\n\n" + "\n\n\n".join(sections) + "\n\n"
    changelog_path = root / "CHANGELOG.md"
    changelog = changelog_path.read_text(encoding="utf-8")
    if not changelog.startswith("# Changelog\n"):
        raise ValueError("CHANGELOG.md must start with '# Changelog'")
    changelog_path.write_text(
        "# Changelog\n\n" + block + changelog[len("# Changelog\n") :].lstrip("\n"),
        encoding="utf-8",
    )


def git_commits(root: Path, base_ref: str) -> list[Commit]:
    result = subprocess.run(
        [
            "git",
            "log",
            "-z",
            "--format=%H%x1f%s%x1f%b",
            f"{base_ref}..HEAD",
        ],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    commits = []
    for record in result.stdout.split("\0"):
        if not record:
            continue
        sha, subject, body = record.split("\x1f", 2)
        commits.append(Commit(sha, subject, body.strip()))
    return commits


def _write_outputs(path: Path | None, values: dict[str, str]) -> None:
    rendered = "".join(f"{key}={value}\n" for key, value in values.items())
    if path:
        with path.open("a", encoding="utf-8") as stream:
            stream.write(rendered)
    else:
        sys.stdout.write(rendered)


def _api_request(
    url: str,
    token: str,
    *,
    method: str = "GET",
    payload: object | None = None,
    github: bool = False,
    content_type: str = "application/json",
) -> object | None:
    data = None
    if payload is not None:
        data = payload if isinstance(payload, bytes) else json.dumps(payload).encode()
    headers = {
        "Accept": "application/vnd.github+json" if github else "application/json",
        "Authorization": f"Bearer {token}" if github else f"token {token}",
        "Content-Type": content_type,
        "User-Agent": "violence-of-action-release-workflow",
    }
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            content = response.read()
    except urllib.error.HTTPError as error:
        message = error.read().decode(errors="replace")
        raise RuntimeError(f"API request failed ({error.code}) for {url}: {message}") from error
    return json.loads(content) if content else None


def sync_forgejo_pr(args: argparse.Namespace) -> None:
    token = os.environ.get("FORGEJO_RELEASE_TOKEN")
    if not token:
        raise ValueError("FORGEJO_RELEASE_TOKEN is required")
    api = args.api_url.rstrip("/")
    pulls = _api_request(
        f"{api}/repos/{args.repository}/pulls?state=open&limit=50", token
    )
    existing = next(
        (
            pull
            for pull in pulls or []
            if pull["head"]["ref"] == args.head and pull["base"]["ref"] == args.base
        ),
        None,
    )
    payload = {"title": args.title, "body": args.body}
    if existing:
        pull = _api_request(
            f"{api}/repos/{args.repository}/pulls/{existing['number']}",
            token,
            method="PATCH",
            payload=payload,
        )
    else:
        payload.update({"head": args.head, "base": args.base})
        pull = _api_request(
            f"{api}/repos/{args.repository}/pulls",
            token,
            method="POST",
            payload=payload,
        )
    print(pull["html_url"])


def mirror_github_release(args: argparse.Namespace) -> None:
    token = os.environ.get("GITHUB_MIRROR_TOKEN")
    if not token:
        raise ValueError("GITHUB_MIRROR_TOKEN is required")
    api = "https://api.github.com"
    repo_api = f"{api}/repos/{args.repository}"
    _api_request(f"{repo_api}/commits/{args.sha}", token, github=True)

    try:
        ref = _api_request(f"{repo_api}/git/ref/tags/{args.tag}", token, github=True)
    except RuntimeError as error:
        if "(404)" not in str(error):
            raise
        ref = _api_request(
            f"{repo_api}/git/refs",
            token,
            method="POST",
            payload={"ref": f"refs/tags/{args.tag}", "sha": args.sha},
            github=True,
        )
    if ref["object"]["sha"] != args.sha:
        raise ValueError("GitHub mirror tag does not resolve to the Forgejo tag commit")

    notes = Path(args.notes_file).read_text(encoding="utf-8")
    release_payload = {
        "tag_name": args.tag,
        "target_commitish": args.sha,
        "name": f"Violence of Action {args.tag}",
        "body": notes,
        "draft": False,
        "prerelease": "-" in args.tag,
    }
    try:
        release = _api_request(f"{repo_api}/releases/tags/{args.tag}", token, github=True)
        release = _api_request(
            f"{repo_api}/releases/{release['id']}",
            token,
            method="PATCH",
            payload=release_payload,
            github=True,
        )
    except RuntimeError as error:
        if "(404)" not in str(error):
            raise
        release = _api_request(
            f"{repo_api}/releases",
            token,
            method="POST",
            payload=release_payload,
            github=True,
        )

    assets_dir = Path(args.assets_dir)
    expected = {
        f"violence-of-action-{args.tag}-windows-x86_64.zip",
        f"violence-of-action-{args.tag}-linux-x86_64.zip",
        "SHA256SUMS.txt",
    }
    actual = {path.name for path in assets_dir.iterdir() if path.is_file()}
    if actual != expected:
        raise ValueError(f"Mirror assets mismatch: expected {sorted(expected)}, got {sorted(actual)}")
    existing_assets = {asset["name"]: asset for asset in release.get("assets", [])}
    upload_base = release["upload_url"].split("{", 1)[0]
    for name in sorted(expected):
        if name in existing_assets:
            if not args.replace:
                raise ValueError(f"GitHub asset {name} already exists; recovery requires --replace")
            _api_request(
                f"{repo_api}/releases/assets/{existing_assets[name]['id']}",
                token,
                method="DELETE",
                github=True,
            )
        path = assets_dir / name
        _api_request(
            f"{upload_base}?{urllib.parse.urlencode({'name': name})}",
            token,
            method="POST",
            payload=path.read_bytes(),
            github=True,
            content_type="application/octet-stream",
        )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    plan = subparsers.add_parser("plan")
    plan.add_argument("--root", type=Path, default=Path.cwd())
    plan.add_argument("--base-tag", required=True)
    plan.add_argument("--repository-url", required=True)
    plan.add_argument("--date", default=dt.date.today().isoformat())
    plan.add_argument("--output", type=Path)

    validate = subparsers.add_parser("validate")
    validate.add_argument("--root", type=Path, default=Path.cwd())
    validate.add_argument("--tag", required=True)
    validate.add_argument("--notes-file", type=Path)

    current_version = subparsers.add_parser("current-version")
    current_version.add_argument("--root", type=Path, default=Path.cwd())

    assert_newer = subparsers.add_parser("assert-newer")
    assert_newer.add_argument("--previous", required=True)
    assert_newer.add_argument("--current", required=True)

    sync_pr = subparsers.add_parser("sync-pr")
    sync_pr.add_argument("--api-url", required=True)
    sync_pr.add_argument("--repository", required=True)
    sync_pr.add_argument("--head", required=True)
    sync_pr.add_argument("--base", default="main")
    sync_pr.add_argument("--title", required=True)
    sync_pr.add_argument("--body", required=True)

    mirror = subparsers.add_parser("mirror-github")
    mirror.add_argument("--repository", required=True)
    mirror.add_argument("--tag", required=True)
    mirror.add_argument("--sha", required=True)
    mirror.add_argument("--assets-dir", required=True)
    mirror.add_argument("--notes-file", required=True)
    mirror.add_argument("--replace", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.command == "plan":
        current = _manifest_version(args.root)
        base = Version.parse(args.base_tag.removeprefix("v"))
        if current != base:
            raise ValueError(
                f"manifest version {current} must match latest tag version {base} before planning"
            )
        commits = git_commits(args.root, args.base_tag)
        version = next_version(current, commits)
        if version is None:
            _write_outputs(args.output, {"action": "noop"})
            return 0
        prepare_release(
            args.root, version, current, commits, args.repository_url, args.date
        )
        _write_outputs(
            args.output,
            {
                "action": "prepare",
                "version": str(version),
                "tag": f"v{version}",
                "branch": "release-please--branches--main--components--violence-of-action",
            },
        )
    elif args.command == "validate":
        version = validate_release_files(args.root, args.tag)
        if args.notes_file:
            notes = release_notes(
                (args.root / "CHANGELOG.md").read_text(encoding="utf-8"), version
            )
            args.notes_file.write_text(notes + "\n", encoding="utf-8")
        print(version)
    elif args.command == "current-version":
        print(_manifest_version(args.root))
    elif args.command == "assert-newer":
        previous = Version.parse(args.previous)
        current = Version.parse(args.current)
        if current <= previous:
            raise ValueError(f"version {current} must be newer than {previous}")
    elif args.command == "sync-pr":
        sync_forgejo_pr(args)
    elif args.command == "mirror-github":
        mirror_github_release(args)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, RuntimeError) as error:
        print(f"release error: {error}", file=sys.stderr)
        raise SystemExit(1)
