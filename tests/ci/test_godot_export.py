import sys
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts" / "ci"
sys.path.insert(0, str(SCRIPT_DIR))

import godot_export


class GodotExportLogTests(unittest.TestCase):
    def test_suppresses_only_known_godot_45_shutdown_pair(self):
        lines = [
            "Packing complete",
            'ERROR: Can\'t emit non-existing signal "changed".',
            "   at: emit_signalp (core/object/object.cpp:1232)",
        ]

        sanitized, suppressed = godot_export.sanitize_output(lines)

        self.assertEqual(sanitized, ["Packing complete"])
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


if __name__ == "__main__":
    unittest.main()
