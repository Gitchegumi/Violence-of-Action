# Copilot Context: Radial Deployment Menu (Feature 002)

## Overview
Implement radial deployment menu + unit info panel for deployment phase in Godot 4.4.1 with GUT test-first approach.

## New Components
- scenes/ui/radial_menu.tscn
- scenes/ui/unit_info_panel.tscn
- scripts/ui/radial_menu.gd
- scripts/ui/unit_info_panel.gd
- (optional) scripts/ui/deployment_controller.gd (extract logic if tile_map.gd grows too large)

## Signals (contract)
- deploy_tile_clicked(position: Vector2i)
- deploy_radial_opened(origin: Vector2i)
- deploy_unit_hovered(unit_id: String)
- deploy_unit_selected(unit_id: String, origin: Vector2i)
- deploy_placement_failed(reason: String, origin: Vector2i, unit_id: String?)
- deploy_radial_closed(reason: String)

## Key Rules
- Single radial instance at a time.
- Ring capacity 12 icons/page; paginate >12.
- Affordability check then tile validity (failure precedence: insufficient_resources > tile issues).
- Debounce placement 250 ms.
- Edge reposition to keep ring fully visible.
- Disabled units shown (desaturated) but hoverable for info.

## Testing
New failing tests added:
- tests/unit/test_radial_signals.gd
- tests/ui/test_radial_menu_scene.gd

Implement until they pass; add integration tests for scenarios after base signals and scenes exist.

## Logging & Determinism
Use logger.gd (no raw print). Re-validate tile + resources at selection.

## MCP Fallback
Attempt Godot MCP for scene creation; otherwise manual creation guided by quickstart.

## Recent Changes
- Added plan, research, data model, signal contracts, quickstart docs.
- Added failing tests for signals & scene presence.

