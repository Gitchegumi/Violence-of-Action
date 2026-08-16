import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts" / "ci"
sys.path.insert(0, str(SCRIPT_DIR))

import godot_export


class GodotExportLogTests(unittest.TestCase):
    def test_suppresses_only_known_godot_45_shutdown_pair(self):
        lines = [
            godot_export.KNOWN_ENGINE_BANNER,
            "Packing complete",
            'ERROR: Can\'t emit non-existing signal "changed".',
            "   at: emit_signalp (core/object/object.cpp:1232)",
        ]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(
            sanitized,
            [godot_export.KNOWN_ENGINE_BANNER, "Packing complete"],
        )
        self.assertEqual(suppressed, 1)
        self.assertEqual(godot_export.error_lines(sanitized), [])

    def test_preserves_unrelated_export_errors(self):
        lines = [
            "ERROR: Project export failed.",
            "   at: export_project (editor/export/editor_export.cpp:999)",
        ]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(sanitized, lines)
        self.assertEqual(suppressed, 0)
        self.assertEqual(
            godot_export.error_lines(sanitized),
            ["ERROR: Project export failed."],
        )

    def test_changed_error_without_matching_engine_context_is_not_suppressed(self):
        lines = [
            godot_export.KNOWN_ENGINE_BANNER,
            'ERROR: Can\'t emit non-existing signal "changed".',
            "   at: project_script (res://scripts/example.gd:12)",
        ]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(sanitized, lines)
        self.assertEqual(suppressed, 0)
        self.assertEqual(
            godot_export.error_lines(sanitized),
            ['ERROR: Can\'t emit non-existing signal "changed".'],
        )

    def test_changed_error_without_pinned_engine_banner_is_not_suppressed(self):
        lines = [
            "Godot Engine v4.6.stable.official.other - https://godotengine.org",
            'ERROR: Can\'t emit non-existing signal "changed".',
            "   at: emit_signalp (core/object/object.cpp:1232)",
        ]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(sanitized, lines)
        self.assertEqual(suppressed, 0)

    def test_changed_error_pair_with_trailing_output_is_not_suppressed(self):
        lines = [
            godot_export.KNOWN_ENGINE_BANNER,
            'ERROR: Can\'t emit non-existing signal "changed".',
            "   at: emit_signalp (core/object/object.cpp:1232)",
            "GDScript backtrace (most recent call first):",
            "    res://scripts/broken_tool.gd:7",
        ]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(sanitized, lines)
        self.assertEqual(suppressed, 0)

    def test_multiple_changed_error_pairs_are_not_suppressed(self):
        pair = [
            'ERROR: Can\'t emit non-existing signal "changed".',
            "   at: emit_signalp (core/object/object.cpp:1232)",
        ]
        lines = [godot_export.KNOWN_ENGINE_BANNER, *pair, *pair]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(sanitized, lines)
        self.assertEqual(suppressed, 0)

    def test_detects_categorized_godot_errors(self):
        lines = [
            "SCRIPT ERROR: Parse Error: Unexpected token.",
            "SHADER ERROR: Invalid fragment expression.",
            "ERROR: Export failed.",
        ]

        self.assertEqual(godot_export.error_lines(lines), lines)


class GodotExportProcessTests(unittest.TestCase):
    def _run_fake_export(self, lines: list[str]) -> int:
        with tempfile.TemporaryDirectory(
            dir=Path(__file__).resolve().parent,
            prefix="tmp_export_",
        ) as directory:
            root = Path(directory)
            fake_exporter = root / "fake_exporter.py"
            fake_exporter.write_text(
                "import pathlib\n"
                "import sys\n"
                "output = pathlib.Path(sys.argv[-1])\n"
                "output.parent.mkdir(parents=True, exist_ok=True)\n"
                "output.write_bytes(b'fake export artifact')\n"
                f"print({chr(10).join(lines)!r})\n",
                encoding="utf-8",
            )
            return godot_export.run_export(
                [sys.executable, str(fake_exporter)],
                root,
                "Fake preset",
                root / "build" / "game.bin",
            )

    def test_run_export_accepts_single_terminal_pinned_shutdown_pair(self):
        result = self._run_fake_export(
            [
                godot_export.KNOWN_ENGINE_BANNER,
                "Packing complete",
                godot_export.KNOWN_SHUTDOWN_ERROR,
                "   at: emit_signalp (core/object/object.cpp:1232)",
            ]
        )

        self.assertEqual(result, 0)

    def test_run_export_rejects_script_error_with_artifact_and_zero_exit(self):
        result = self._run_fake_export(
            [
                godot_export.KNOWN_ENGINE_BANNER,
                "SCRIPT ERROR: Parse Error: Unexpected token.",
            ]
        )

        self.assertEqual(result, 1)

    def test_run_export_rejects_shutdown_pair_followed_by_backtrace(self):
        result = self._run_fake_export(
            [
                godot_export.KNOWN_ENGINE_BANNER,
                godot_export.KNOWN_SHUTDOWN_ERROR,
                "   at: emit_signalp (core/object/object.cpp:1232)",
                "GDScript backtrace (most recent call first):",
                "    res://scripts/broken_tool.gd:7",
            ]
        )

        self.assertEqual(result, 1)


if __name__ == "__main__":
    unittest.main()
