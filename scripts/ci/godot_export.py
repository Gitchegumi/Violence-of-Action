#!/usr/bin/env python3
"""Run a Godot export while validating and sanitizing its combined output."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Sequence


KNOWN_SHUTDOWN_ERROR = 'ERROR: Can\'t emit non-existing signal "changed".'
KNOWN_ENGINE_BANNER = (
    "Godot Engine v4.5.stable.official.876b29033 - https://godotengine.org"
)
KNOWN_SHUTDOWN_CONTEXT = re.compile(
    r"^\s+at: emit_signalp \(core/object/object\.cpp:\d+\)\s*$"
)
GODOT_ERROR_LINE = re.compile(r"^\s*(?:[A-Z][A-Z0-9 _-]*\s+)?ERROR:\s*")


def sanitize_output(lines: Sequence[str]) -> tuple[list[str], int]:
    """Remove the one proven terminal error pair from the pinned Godot build."""
    known_error_indices = [
        index
        for index, line in enumerate(lines)
        if line.strip() == KNOWN_SHUTDOWN_ERROR
    ]
    has_pinned_banner = any(
        line.strip() == KNOWN_ENGINE_BANNER for line in lines
    )
    if (
        has_pinned_banner
        and len(known_error_indices) == 1
        and known_error_indices[0] == len(lines) - 2
        and KNOWN_SHUTDOWN_CONTEXT.match(lines[-1])
    ):
        return list(lines[:-2]), 1
    return list(lines), 0


def error_lines(lines: Sequence[str]) -> list[str]:
    return [line for line in lines if GODOT_ERROR_LINE.match(line)]


def run_export(
    godot: str | Sequence[str], project: Path, preset: str, output: Path
) -> int:
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.is_file():
        output.unlink()
    godot_command = [godot] if isinstance(godot, str) else list(godot)
    command = [
        *godot_command,
        "--headless",
        "--path",
        str(project),
        "--export-release",
        preset,
        str(output),
    ]
    completed = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    lines = completed.stdout.splitlines()
    sanitized, suppressed = sanitize_output(lines)
    if sanitized:
        print("\n".join(sanitized))
    if suppressed:
        print(
            "NOTICE: Suppressed "
            f"{suppressed} known Godot 4.5 scripted-TileMapLayer "
            "shutdown message(s)."
        )

    failures: list[str] = []
    if completed.returncode != 0:
        failures.append(f"Godot export exited with code {completed.returncode}.")
    remaining_errors = error_lines(sanitized)
    if remaining_errors:
        failures.append(
            f"Godot export emitted {len(remaining_errors)} unexpected error(s)."
        )
    if not output.is_file() or output.stat().st_size == 0:
        failures.append(f"Godot export did not create a non-empty artifact: {output}")

    for failure in failures:
        print(f"ERROR: {failure}", file=sys.stderr)
    return 1 if failures else 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", type=Path, default=Path("."))
    parser.add_argument("--preset", required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    return run_export(args.godot, args.project, args.preset, args.output)


if __name__ == "__main__":
    raise SystemExit(main())
