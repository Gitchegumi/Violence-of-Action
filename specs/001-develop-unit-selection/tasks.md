# Tasks: Develop Unit Selection Logic

**Input**: Design documents from `specs/001-develop-unit-selection/`

This file outlines the dependency-ordered tasks to implement the feature. Tasks marked with `[P]` can be worked on in parallel.

## Phase 3.1: Setup
- [x] **T001**: Install the GUT (Godot Unit Test) plugin from the Godot Asset Library and configure it for the project (see `research.md`).
- [x] **T002**: Create a new script `scripts/logger.gd`, and configure it as an Autoload singleton named `Logger`. Implement basic `info(message)` and `error(message)` methods that print to the console.

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [x] **T003** [P]: Create a new GUT test script `tests/unit/test_tile_map_signals.gd`. Write a test that checks if the `unit_selected` signal is emitted from `scripts/tile_map.gd` when a simulated click occurs. This test must fail as the signal does not yet exist.
- [x] **T004** [P]: Create a new GUT test script `tests/ui/test_unit_info_panel.gd`. Write a test that instances a placeholder `unit_info_panel.tscn` and checks that `show_unit()` and `hide_panel()` functions correctly manage the panel's visibility. This test must fail as the scene and functions do not yet exist.

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [x] **T005**: In `scripts/tile_map.gd`, add the `signal unit_selected(unit: Node)`. 
- [x] **T006**: Create a new scene `scenes/ui/unit_info_panel.tscn`. Design a functional placeholder UI with `Label` nodes for stats (e.g., Name, Health, Attack) and a `TextureRect` for the unit image.
- [x] **T007**: Create a new script `scripts/ui/unit_info_panel.gd` and attach it to the `unit_info_panel.tscn` scene. Implement the `show_unit(unit: Node)` and `hide_panel()` functions. The `show_unit` function should populate the labels with data from the passed-in `unit` node.
- [x] **T008**: In `scripts/tile_map.gd`, implement the input handling logic (e.g., in `_unhandled_input`) to detect clicks on tiles. If a clicked tile contains a unit, emit the `unit_selected` signal with the unit node as the payload. If an empty tile is clicked, emit `unit_selected` with `null`.

## Phase 3.4: Integration
- [x] **T009**: In the main game scene (`scenes/main.tscn`), instance the `unit_info_panel.tscn`.
- [x] **T010**: In the main game script (`scripts/main.gd`), connect the `unit_selected` signal from the `tile_map` node to the `show_unit` function on the `unit_info_panel` node.

## Phase 3.5: Polish
- [x] **T011**: Run all GUT tests. Refactor the implementation in `tile_map.gd` and `unit_info_panel.gd` until all tests created in T003 and T004 pass.
- [x] **T012** [P]: Perform the manual end-to-end test as described in `specs/001-develop-unit-selection/quickstart.md` to ensure all acceptance criteria are met.
- [x] **T013** [P]: Add GDScript documentation (docstrings) to the new `unit_selected` signal in `tile_map.gd` and the public functions in `unit_info_panel.gd`.

## Dependencies
- `T001`, `T002` must be done before all other tasks.
- `T003`, `T004` must be done before `T005`-`T010`.
- `T005` must be done before `T008`.
- `T006`, `T007` must be done before `T009`.
- `T011` depends on all preceding implementation tasks.

## Parallel Example
Tasks T003 and T004 can be run in parallel as they relate to different test files:
```
# In parallel, execute:
Task: "Create a new GUT test script tests/unit/test_tile_map_signals.gd..."
Task: "Create a new GUT test script tests/ui/test_unit_info_panel.gd..."
```
