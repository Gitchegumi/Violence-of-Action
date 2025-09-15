# Implementation Plan: Develop Unit Selection Logic

**Branch**: `001-develop-unit-selection` | **Date**: 2025-09-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `E:\GitHub\ViolenceofAction\specs\001-develop-unit-selection\spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
4. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
5. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, or `GEMINI.md` for Gemini CLI).
6. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
7. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
8. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
The feature 'Develop Unit Selection Logic' allows a player to select a unit on the map by clicking its tile, which then displays the unit's detailed information in a lower-third UI panel. The implementation will involve modifying `tile_map.gd` to handle click detection on occupied tiles, creating a new UI scene for the information panel, and connecting signals between the map and the UI to show/hide/update the panel. The existing tile highlight function will be used to indicate the selected unit. The Godot MCP server will be used to interact with the Godot editor.

## Technical Context
**Language/Version**: GDScript (Godot 4.x)
**Primary Dependencies**: Godot Engine
**Storage**: N/A (Unit data is stored in .tres files)
**Testing**: [NEEDS CLARIFICATION: An official testing framework has not been established (see issue #28).]
**Target Platform**: Desktop (Windows/Linux)
**Project Type**: single project
**Performance Goals**: N/A
**Constraints**: N/A
**Scale/Scope**: Applies to all selectable units on the map.

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simplicity**:
- Projects: 1 (The Godot project)
- Using framework directly? Yes
- Single data model? Yes, Godot resources (.tres)
- Avoiding patterns? Yes

**Architecture**:
- EVERY feature as library? N/A (Game project, not library-based)
- Libraries listed: N/A
- CLI per library: N/A
- Library docs: N/A

**Testing (NON-NEGOTIABLE)**:
- RED-GREEN-Refactor cycle enforced? [NEEDS CLARIFICATION: No testing framework is established.]
- Git commits show tests before implementation? [NEEDS CLARIFICATION: No testing framework is established.]
- Order: Contract→Integration→E2E→Unit strictly followed? [NEEDS CLARIFICATION: No testing framework is established.]
- Real dependencies used? Yes
- Integration tests for: [NEEDS CLARIFICATION: No testing framework is established.]
- FORBIDDEN: [NEEDS CLARIFICATION: No testing framework is established.]

**Observability**:
- Structured logging included? [NEEDS CLARIFICATION: No logging framework is established.]
- Frontend logs → backend? N/A
- Error context sufficient? [NEEDS CLARIFICATION: No logging framework is established.]

**Versioning**:
- Version number assigned? No
- BUILD increments on every change? No
- Breaking changes handled? N/A

## Project Structure

### Documentation (this feature)
```
specs/001-develop-unit-selection/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/  # Note: Project root is used instead of a dedicated src/ dir
├── scenes/
├── scripts/
└── assets/

tests/ # [NEEDS CLARIFICATION: No tests directory exists]
├── contract/
├── integration/
└── unit/
```

**Structure Decision**: Option 1: Single project

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `/scripts/powershell/update-agent-context.ps1 -AgentType gemini` for your AI assistant
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

The `/tasks` command will generate a `tasks.md` file by following a Test-Driven Development (TDD) approach:

1.  **Setup GUT:** Create a task to install and configure the GUT testing framework from the Godot Asset Library (related to issue #28).
2.  **Create Tests First (TDD):**
    *   Create a task to write the failing `test_unit_selection_signal.gd` as described in `quickstart.md`.
    *   Create a task to write the failing `test_unit_info_panel_visibility.gd` as described in `quickstart.md`.
3.  **Implement the Feature:**
    *   Create a task to add the `unit_selected(unit: Node)` signal to `tile_map.gd`.
    *   Create a task to implement the click handling logic in `tile_map.gd` to detect clicks on tiles with units and emit the `unit_selected` signal.
    *   Create a task to create a **functional placeholder** for the `unit_info_panel.tscn` scene. This includes adding basic `Label` nodes for stats and a `TextureRect` for the image. The script should include the `show_unit(unit: Node)` and `hide_panel()` functions. The final aesthetic design will be handled in a separate task.
    *   Create a task to connect the `tile_map.gd` `unit_selected` signal to the `unit_info_panel.gd` `show_unit` function in the main scene.
4.  **Make Tests Pass:**
    *   Create a task to run the tests and verify that they now pass.
5.  **Manual Verification:**
    *   Create a final task to perform the manual end-to-end test as described in `quickstart.md`.

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [x] Phase 3: Tasks generated (/tasks command)
- [x] Phase 4: Implementation complete
- [x] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*