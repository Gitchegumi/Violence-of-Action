# Implementation Plan: Radial Deployment Menu & Unit Info Panel

**Branch**: `002-implement-radial-menu` | **Date**: 2025-09-21 | **Spec**: `specs/002-implement-radial-menu/spec.md`
**Input**: Feature specification from `/specs/002-implement-radial-menu/spec.md`

## Execution Flow (/plan command scope)

```text
1. Load feature spec from Input path
   → Found and parsed successfully
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → No NEEDS CLARIFICATION markers present in spec
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → No violations detected (see details)
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md (created in this run)
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, copilot agent file
7. Re-evaluate Constitution Check section
   → No new violations
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md in /plan)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:

- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

Implement a reusable radial menu UI and companion unit info panel enabling deployment-phase unit placement through contextual, affordable unit selection with multi-input support (mouse + future controller) while enforcing single-instance determinism, clear feedback on placement success/failure, pagination for overflow, and adherence to test-first, modular architecture principles in Godot 4.4.1.

## Technical Context

**Language/Version**: GDScript / Godot Engine 4.4.1
**Primary Dependencies**: Godot Engine UI system, GUT (testing), optional Gemini CLI & Godot MCP (non-hard dependency)
**Storage**: N/A (in-memory runtime state only)
**Testing**: GUT (unit + integration)
**Target Platform**: Desktop (Windows, keyboard + mouse) with future controller parity
**Project Type**: Single game project (Option 1 structure baseline)
**Performance Goals**: Maintain 60 FPS; radial open/close within 1 frame; zero persistent orphaned nodes; no GC spikes on rapid open/close cycles
**Constraints**: Single radial instance; 250 ms placement debounce; signals prefixed `deploy_`; deterministic resource & tile re-validation on selection
**Scale/Scope**: Up to ~24 unit types initially (paginate > ring capacity, initial ring capacity assumption: 10-12 icons before pagination)

## Constitution Check

Principle I (Engine Version Discipline): Aligned — targets 4.4.1; no experimental APIs planned.
Principle II (GUT Test-First): Plan introduces failing tests for signals, UI scenes before implementing scripts.
Principle III (Modular Scene & Script Architecture): Radial menu and info panel implemented as separate scenes with thin controller integration (likely via `tile_map.gd` or a new `deployment_controller.gd` if responsibility grows). No god objects planned.
Principle IV (Observability & Deterministic Debugging): Will route feedback through `logger.gd` (debug logs only); placement logic deterministic with explicit re-validation; no randomness introduced.
Principle V (Versioning, Tooling & Automation): No external schema changes; optional MCP/Gemini integration remains additive; graceful fallback described in quickstart.

Violations: NONE
Justifications Needed: NONE

## Project Structure

### Documentation (this feature)

```text
specs/002-implement-radial-menu/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   └── signals.md       # Signal contracts & semantics
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)

Existing Godot structure retained. New/updated assets (planned):

```text
scenes/ui/
  radial_menu.tscn        # New radial menu scene
  unit_info_panel.tscn    # (May already be placeholder; else created)

scripts/ui/
  radial_menu.gd          # Behavior script for menu (one responsibility)
  unit_info_panel.gd      # Behavior script for info panel
  deployment_controller.gd (optional if tile_map.gd becomes overloaded)
```

**Structure Decision**: Option 1 (single project). No multi-project split warranted by scope.

## Phase 0: Outline & Research

See `research.md` for detailed decisions. Key outcomes:

- Ring capacity chosen (12) before pagination.
- Pagination UI approach (next/prev wedge or overlay buttons) — initial implementation: two small wedge buttons at fixed angles (top-left / top-right) excluded from unit count.
- Input abstraction strategy (central focus index + directional mapping).
- Signal emission ordering + failure precedence (resources > tile state when both invalid simultaneously).
- MCP/Gemini optional integration strategy (attempt—fallback coach mode).

## Phase 1: Design & Contracts

Artifacts produced:

- `data-model.md`: Entities & fields (UnitType, DeploymentTile, RadialMenuSession, InfoPanelState, ResourcePool, PlacementAttempt).
- `contracts/signals.md`: Semantic contract for all `deploy_` signals + failure reasons.
- `quickstart.md`: Step-by-step TDD implementation & MCP fallback instructions.
- Updated agent context file (copilot) planned (created if absent) referencing new components.

Contract Scope Adaptation: Template references REST/GraphQL; this feature is intra-engine event-driven. We substitute signal & public script API contracts — aligning with modular architecture without introducing unnecessary service layers. No constitution violation (simplicity preserved).

## Phase 2: Task Planning Approach

**Task Generation Strategy**:

- Each signal → declare & test presence.
- Each entity in `data-model.md` → script or documented data structure creation task.
- Each user acceptance scenario → integration test skeleton.
- UI assets creation tasks (scenes) precede logic wiring tasks.
- Parallelizable tasks marked [P] (independent scene scaffolds, basic signal declarations, pagination logic after base ring).

**Ordering Strategy**:

1. Data model + signal declarations (tests fail initially)
2. Scene scaffolding (radial, info panel)
3. Focus & navigation logic
4. Placement validation & resource deduction
5. Failure feedback & edge cases (pagination, edge repositioning)
6. Cleanup & leak prevention tests

**Estimated Output**: ~28 tasks in `tasks.md` (created via /tasks command later).

## Phase 3+: Future Implementation

Out of /plan scope. Will follow tasks with strict GUT TDD, ensuring no large monolithic scripts.

## Complexity Tracking

No deviations; table intentionally left blank.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|

## Progress Tracking

**Phase Status**:

- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [x] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:

- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none)

---
*Based on Constitution v2.2.1 - See `.specify/memory/constitution.md`*
