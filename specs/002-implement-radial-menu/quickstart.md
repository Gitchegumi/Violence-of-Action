# Quickstart: Radial Deployment Menu Implementation

Feature: 002-implement-radial-menu  
Date: 2025-09-21

## Purpose

Step-by-step sequence to implement the radial deployment menu & unit info panel following GUT test-first and constitutional principles. Use this as the minimal path to green tests and functional feature.

## Preconditions

- Godot 4.4.1 project loaded.
- GUT plugin installed (already in `addons/gut`).
- Feature branch `002-implement-radial-menu` checked out.

## Sequence

1. Run GUT to view failing new tests (added by planning phase):
   - `tests/unit/test_radial_signals.gd`
   - `tests/ui/test_radial_menu_scene.gd`
2. Create `scenes/ui/radial_menu.tscn`:
   - Root: `Control` (name: `RadialMenu`)
   - Add container node for icons (e.g., `Node2D` or `Control` with custom drawing) placeholder.
3. Create `scripts/ui/radial_menu.gd` and attach to root:
   - Declare required signals (`deploy_*`).
   - Expose method `open(origin_tile: Vector2i, units: Array)`.
   - Expose method `close(reason: String)`.
4. Implement icon layout stub:
   - Accept list of units; store; draw placeholder circles (ColorRect or TextureButton) arranged around center.
5. Create `scenes/ui/unit_info_panel.tscn`:
   - Root: `Control` (name: `UnitInfoPanel`) hidden by default.
   - Children: Icon TextureRect, Name Label, Stats VBox, Abilities RichTextLabel.
6. Create `scripts/ui/unit_info_panel.gd` with methods:
   - `show_unit(unit_data: Dictionary)` binds and shows
   - `hide_panel()` hides
7. Update `tile_map.gd` (or introduce `deployment_controller.gd`) to:
   - Detect deployment-phase tile clicks
   - Instantiate radial menu (autoload or scene) and populate with available units
   - Wire signals to placement logic & info panel updating
8. Placement logic:
   - On `deploy_unit_selected` validate tile & resources; if success spawn unit scene; update resources; close radial.
   - On failure, emit `deploy_placement_failed`.
9. Hover logic:
   - On `deploy_unit_hovered` call `unit_info_panel.show_unit(...)`.
10. Cancel logic: Right-click, Escape, outside click -> call `close('cancel')`.
11. Pagination (if >12 units): Add next/prev buttons to cycle page_index, rebuild icon ring.
12. Edge reposition: Before showing, clamp position inward so ring fully visible.
13. Debounce: Track last placement timestamp; ignore attempts <250 ms.
14. Cleanup: Ensure menu freed on close; ensure info panel hidden.
15. Logging: Replace any `print()` with calls to central `logger.gd` if needed.
16. Run GUT; make tests pass incrementally.

## MCP / Gemini Optional Tooling

Attempt automation via Godot MCP for scene creation. If MCP not available:

- Manually create scenes as described above.
- Confirm asset presence by listing them in a commit diff or directory view.

## Testing Guidance

- Add integration test verifying:
  - Opening on valid tile emits `deploy_radial_opened`.
  - Selecting unaffordable unit triggers `deploy_placement_failed('insufficient_resources')`.
  - Successful placement closes radial (`deploy_radial_closed('placed')`).
- Add leak test: Open/close radial N times (e.g., 25) and assert orphan count stable.

## Extension Hooks

Future: Add filter bar node; emit additional metadata dictionary in hover/selected without breaking existing parameter order.

## Completion Criteria

- All new tests green.
- No orphan nodes after repeated open/close.
- Radial + info panel operate within 1 frame open latency.
- No raw `print()` statements.
