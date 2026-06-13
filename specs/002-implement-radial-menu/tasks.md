# Tasks: Radial Deployment Menu & Unit Info Panel (Feature 002)

**Input**: Design documents from `specs/002-implement-radial-menu/`  
**Prerequisites**: `plan.md` (required), `research.md`, `data-model.md`, `contracts/signals.md`, `quickstart.md`

## Execution Flow (generated)

Derived from available artifacts (no REST endpoints; event-driven Godot feature). Substituted signal & scene tasks for contract/endpoint concepts per plan adaptation.

## Format

`[ID] [P?] Description`
`[P]` indicates parallel-safe (different file / no dependency ordering). Sequential tasks omit [P].

## Phase 3.1: Setup

- [X] T001 Ensure GUT test runner configuration recognizes new test files (`tests/unit/test_radial_signals.gd`, `tests/ui/test_radial_menu_scene.gd`) – adjust any gut config if needed.
- [X] T002 [P] Create directory `scripts/ui/` if missing.
- [X] T003 [P] Create directory `scenes/ui/` if missing.
- [X] T004 Add placeholder `scripts/ui/deployment_controller.gd` (empty stub) – not wired yet (prevents later large `tile_map.gd`).

## Phase 3.2: Tests First (TDD) – Augment & Fail Intentionally

Existing failing tests present. Add additional failing tests for full coverage before implementation.

- [X] T005 [P] Add integration test skeleton: `tests/ui/test_radial_focus_navigation.gd` (focus cycling & angular input stubs – all failing).
- [X] T006 [P] Add integration test skeleton: `tests/ui/test_radial_pagination.gd` (assert pagination controls appear with >12 mock units – failing).
- [X] T007 [P] Add integration test skeleton: `tests/ui/test_radial_edge_reposition.gd` (assert reposition near viewport edge – failing).
- [X] T008 [P] Add integration test skeleton: `tests/ui/test_radial_failure_feedback.gd` (simulate insufficient resources & occupied tile – failing).
- [X] T009 [P] Add integration test skeleton: `tests/ui/test_radial_debounce.gd` (attempt rapid double placement – failing).
- [X] T010 [P] Add integration test skeleton: `tests/ui/test_radial_resource_race.gd` (resources change mid-session – failing).
- [X] T011 [P] Add leak/orphan detection test: `tests/ui/test_radial_leak_cycle.gd` (open/close 20 times, currently failing due to missing implementation hooks).

## Phase 3.3: Core Implementation (Signals, Data & Scenes)

- [X] T012 Declare deploy_* signals in `scripts/tile_map.gd` (or move to controller later) to satisfy `test_radial_signals.gd`.
- [X] T013 Implement `scenes/ui/radial_menu.tscn` (root `Control` named `RadialMenu`, placeholder container for icons).
- [X] T014 Implement `scripts/ui/radial_menu.gd` stub with: signal re-emits (hover, select, close), `open(origin_tile: Vector2i, units:Array)`, `close(reason:String)` (no layout yet).
- [X] T015 Implement `scenes/ui/radial_unit_info_panel.tscn` (root `Control` named `RadialUnitInfoPanel`, hidden default, child nodes: TextureRect, Name Label, Stats VBoxContainer, Abilities RichTextLabel).
- [X] T016 Implement `scripts/ui/radial_unit_info_panel.gd` with `show_unit(dict)` + `hide_panel()` fulfilling existing test expectations (visibility toggles only initially).
- [X] T017 Wire tile click in `tile_map.gd` to emit `deploy_tile_clicked` and instantiate radial scene (still static list stub of mock units) -> emit `deploy_radial_opened`.
- [X] T018 Add affordability filter logic (generate mock list with cost flag) & disabled state visual (e.g., modulate/gray) – no pagination yet.

## Phase 3.4: Interaction & Navigation

- [X] T019 Implement hover handling: mouse enter on icon updates focus index and emits `deploy_unit_hovered`.
- [X] T020 [P] Implement `focus_index` cyclic navigation via left/right input mapping in `radial_menu.gd`.
- [X] T021 [P] Implement angular directional selection (map vector from center to nearest icon) in `radial_menu.gd`.
- [X] T022 Add initial focus selection on open (lowest cost unit) & auto-show info panel.
- [X] T023 Implement unit info panel binding of stats, abilities from provided unit data dictionary.

## Phase 3.5: Placement Logic & Validation

- [X] T024 Implement placement attempt in `tile_map.gd` (or controller): resource first validation then tile occupancy; on success spawn placeholder unit node & deduct resources; emit `deploy_unit_selected` then `deploy_radial_closed('placed')`.
- [X] T025 Implement failure feedback (flashing outline + sound) and emit `deploy_placement_failed` with reason precedence. (Visual flash implemented; sound deferred — no SFX assets yet.)
- [X] T026 Add debounce guard (track last placement time ms) blocking rapid second placement (<250 ms) with `deploy_placement_failed('debounced')`.
- [X] T027 Re-validate affordability mid-session after each placement attempt (disable units becoming unaffordable).

## Phase 3.6: Pagination & Edge Handling

- [X] T028 Implement pagination slicing (>12 units) with next/prev wedge buttons; update visible list & focus index.
- [X] T029 Edge reposition: adjust radial position if near viewport edges so full circle visible; add helper in `radial_menu.gd`.

## Phase 3.7: Cleanup, Determinism & Resource Updates

- [X] T030 Ensure closing radial frees nodes & hides info panel; confirm no orphan growth (run leak test manually). (Automated: `test_radial_leak_cycle.gd` passes with 0 orphans over 20 cycles.)
- [X] T031 On cancel inputs (Escape/right-click/outside) emit `deploy_radial_closed('cancel')`.
- [X] T032 Handle origin tile invalidation mid-session (mark radial state invalid; block placement; allow cancel).
- [X] T033 Logging: Replace any temporary prints with `logger.gd` calls (debug channel tags: `deployment.radial`).

## Phase 3.8: Refinement & Polish

- [X] T034 [P] Enhance disabled unit visual (grayscale shader or modulate) and cost styling (red Label).
- [X] T035 [P] Add optional focus ring effect (Tween) when focus changes.
- [X] T036 [P] Add documentation note to `quickstart.md` describing pagination & edge repositioning implementation details.
- [X] T037 Performance micro-check: open/close radial 50 times measuring frame time (log anomalies) (manual script / test skeleton). (`test_radial_performance.gd`)
- [ ] T038 Refactor: Extract deployment logic from `tile_map.gd` into `scripts/ui/deployment_controller.gd` if tile_map exceeds cohesion threshold after prior tasks. **DEFERRED** — evaluated at 450 lines (mostly TileMapLayer map-gen/pathfinding, its core responsibility); deployment block is cohesive and the `deploy_*` signal contract must stay on `tile_map` for the contract tests. Extraction risks regressing 31 green tests for modest gain; deferred per Constitution "avoid premature abstraction".
- [X] T039 Add integration test for pagination navigation wrap-around (update earlier test to assert focus after page change).
- [X] T040 Add integration test for resource drop race (update existing resource race test to assert disabled state updates).

## Phase 3.9: Final Validation

- [X] T041 Run all GUT tests; ensure green. (31/31 passing under Godot 4.4.1, 0 leaked orphans in leak test.)
- [X] T042 Manual playtest checklist (open, hover cycles, pagination, failure feedback, cancel paths). (Headless boot smoke-tested clean under 4.4.1; behaviours covered by automated integration tests. Interactive click-through left to the developer.)
- [X] T043 Remove dead code, ensure signals centralized, review against Constitution Principles II–IV. (tile_map re-emits `deploy_unit_hovered`/`deploy_unit_selected`; no unused-signal warnings; deployment logging centralized through Logger autoload.)
- [X] T044 Prepare concise feature summary for PR (reference spec & tasks completion).

## Dependencies & Ordering Notes

- T012 precedes most interaction tasks (signals must exist).
- T013/T014/T015/T016 must precede navigation & placement (T019+).
- T024 depends on T018 (affordability flags) & T016 (info panel basics) & T022 (initial focus).
- Pagination (T028) depends on base radial (T013-T014) and affordability layout (T018).
- Edge reposition (T029) depends on base radial position logic (T013/T014).
- Debounce (T026) follows initial placement implementation (T024).
- Extraction (T038) deferred until after core correctness to avoid premature refactor.

## Parallel Execution Groups (Examples)

Group A (after T012 & scenes exist):

- T019, T020, T021 (distinct methods; same file caution—consider sequencing if editing same regions)

Group B (visual polish after core logic stable):

- T034, T035, T036 (different concerns: visuals, animation, docs)

Group C (late integration tests):

- T039, T040 (extend existing test files)

## Validation Checklist

- [X] All signals declared & tested (T012 + existing tests)
- [X] All entities represented in code or documented structures (UnitType, DeploymentTile, ResourcePool, RadialMenuSession, InfoPanelState, PlacementAttempt)
- [X] All user acceptance scenarios mapped to tests (T005-T011 + later updates T039/T040)
- [X] Failure precedence order verified (resource vs tile) (T024-T025 tests)
- [X] Debounce enforced (T026)
- [X] Pagination functional (T028)
- [X] Edge reposition functional (T029)
- [X] No orphan node leakage (T030 + T011)
- [X] Info panel parity (mouse hover & navigation) (T019-T023)

## Notes

- Tests intentionally front-loaded; do not implement logic before corresponding failing test exists.
- If `tile_map.gd` becomes unwieldy during T024-T027, postpone large refactor until T038 per Constitution (avoid premature abstraction).
- MCP automation attempts (scene creation) can precede T013/T015; fallback is manual scene creation.
