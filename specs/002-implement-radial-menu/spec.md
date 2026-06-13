# Feature Specification: Radial Deployment Menu & Unit Info Panel

**Feature Branch**: `002-implement-radial-menu`  
**Created**: 2025-09-18  
**Status**: Planning  
**Input**: User description: "Implement Radial Menu, an interactive deployment-phase unit placement system: when the player is in the deployment phase and clicks an empty tile inside their valid deployment zone (reject clicks on occupied or out-of-zone tiles), a radial menu appears centered on that tile showing icons for all units the player can currently afford to deploy; hovering or focusing a unit icon updates (and if first shown, reveals) a lower-third info panel displaying a larger sprite, core stats (Health, Attack, Defense, Movement), cost, and any special abilities; clicking a unit in the radial menu immediately places it on the originally selected tile (if still valid), deducts its cost from player resources, and closes the radial + panel (with graceful failure/feedback if resources became insufficient or tile state changed); this replaces the prior basic placement flow and should be implemented as new reusable UI scenes (radial menu + info panel) coordinated by logic added to or factored from tile_map.gd, using clear signals (e.g., tile_clicked, unit_selected) and ensuring the feature is easily extensible for future additions like filtering, previews, or cancel/escape behavior."

## User Scenarios & Testing *(mandatory)*

### Primary User Story

As a player in the deployment phase before gameplay starts, I want to click a valid empty deployment tile and immediately see a contextual radial menu of units I can currently afford so that I can efficiently choose and place a unit while reviewing its stats and abilities.

### Acceptance Scenarios

1. Given the game is in the deployment phase and I have sufficient resources for at least one unit, When I left-click an empty tile inside my deployment zone, Then a radial menu appears centered on that tile showing only units I can afford and no other UI obstructs gameplay view.
2. Given the radial menu is open with multiple unit options, When I hover (or navigate with controller/keyboard focus) over a unit icon, Then a lower-third info panel becomes visible (if hidden) or updates to show that unit's large sprite, stats (Health, Attack, Defense, Movement), cost, and special abilities list.
3. Given the radial menu is open and I hover a unit, When I move hover/focus to a different unit, Then the info panel updates instantly without flicker and no stale data remains.
4. Given the radial menu is open and I click a unit I can afford, When the original tile is still empty and valid, Then the unit is placed on that tile, its cost deducted from my resources, and both radial menu and info panel close.
5. Given the radial menu is open and I click a unit, When my resources have dropped (e.g., external action) below that unit's cost before click resolution, Then placement is blocked, a brief feedback flashing outline + sound feedback is shown, costs/resources UI remains consistent, and the radial stays open while removing or disabling any newly unaffordable units.
6. Given the radial menu is open, When I press Escape / right-click / click outside the menu / perform designated cancel input, Then the radial menu and info panel close without placing a unit.
7. Given I open the radial on a tile, When the tile becomes occupied before I select a unit (e.g., simultaneous placement in multiplayer or scripted event), Then attempting to place displays an occupied feedback (flashing outline + sound) and no placement occurs; the radial remains open but indicates the origin tile is now invalid and blocks further placement until user cancels.
8. Given I have no affordable units, When I click a valid deployment tile, Then a radial appears showing all known unit types as disabled (desaturated) with costs displayed, indicating none are currently affordable.
9. Given controller/keyboard input mode, When I open the radial, Then I can navigate using both directional angular selection (stick/D-pad toward sector) and cyclic rotation (e.g., LB/RB or left/right) and confirm selection with the primary action button.
10. Given the deployment phase ends, When I try to click deployment tiles, Then no radial menu appears and prior placement flow is disabled.

### Edge Cases

- Clicking rapidly on multiple tiles should only show one radial at a time; previous instance closes cleanly.
- Opening the radial at map edge must not clip visuals; layout repositions/rotates to stay fully visible.
- Very large number of unit types (exceeding ring capacity) must paginate using explicit next/previous page controls.
- Unit with zero movement or special unusual stats still displays appropriately (no assumptions about min values).
- Resource count exactly equals unit cost: placement succeeds and resources become zero without negative values.
- Simultaneous close inputs (Escape + outside click) cause only one close event; no errors.
- Performance: opening/closing repeatedly should not leak nodes or leave orphaned UI.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect left-clicks (and designated selection input) on tiles only during the deployment phase.
- **FR-002**: System MUST validate clicked tile belongs to the player's deployment zone and is currently unoccupied before showing any placement UI.
- **FR-003**: System MUST compute the set of deployable unit types the player can currently afford at the moment of menu invocation.
- **FR-004**: System MUST display a radial menu centered on the selected tile containing an icon for each currently affordable unit type.
- **FR-005**: System MUST show unaffordable units as disabled (desaturated, cost styled in red) rather than omitting them.
- **FR-006**: System MUST, upon hover/focus of a radial icon, display/update a lower-third info panel with: large sprite, Health, Attack, Defense, Movement, cost, special abilities list (may be empty), and unit name.
- **FR-007**: System MUST ensure the info panel first becomes visible on first hover/focus event if it was hidden at radial opening.
- **FR-008**: System MUST place (instantiate) the selected unit on the originally clicked tile if still valid, deduct cost, update resources display, then close radial and info panel.
- **FR-009**: System MUST re-validate tile emptiness and zone validity plus affordability at selection confirmation time to prevent race conditions.
- **FR-010**: System MUST provide user feedback (visual and/or textual) when placement fails due to insufficient resources, occupied tile, or invalid tile state change.
- **FR-011**: System MUST close both radial menu and info panel when user cancels via: Escape, right-click, clicking outside, or other defined cancel action.
- **FR-012**: System MUST emit signals/events (prefixed with `deploy_`): `deploy_tile_clicked(valid_tile_pos)`, `deploy_radial_opened(tile_pos)`, `deploy_unit_hovered(unit_type)`, `deploy_unit_selected(unit_type, tile_pos)`, `deploy_placement_failed(reason, tile_pos, unit_type?)`, `deploy_radial_closed(reason)` for integration/extensibility.
- **FR-013**: System MUST ignore input that would open radial while one is already open (or close the prior first). Behavior must be deterministic.
- **FR-014**: System MUST support both angular directional selection (stick/D-pad direction) and cyclic focus rotation (e.g., LB/RB or left/right) of unit options in addition to mouse hover.
- **FR-015**: System SHOULD maintain a full circular layout by shifting the radial center inward to keep icons within viewport bounds when near edges.
- **FR-016**: System SHOULD be extensible to future filters (e.g., category tabs) without changing core signals (open/hover/select).
- **FR-017**: System MUST prevent interaction with underlying map tiles while radial is open except for allowed cancel/outside click logic.
- **FR-018**: System MUST not allow placement outside deployment phase; attempts are silently ignored.
- **FR-019**: System MUST ensure only one unit is placed per selection action (debounce multi-clicks / rapid fire input; 250 ms window).
- **FR-020**: System MUST cleanly free/destroy UI nodes on close to avoid leaks/orphans.
- **FR-021**: System MUST support desktop mouse pointer interaction: hover highlights icon and updates info panel; left-click selects unit; right-click (or Escape) cancels and closes radial without placement.

### Decisions & Assumptions

#### Decisions (Q1–Q20)

- Failed placement (insufficient resources): radial stays open; newly unaffordable units disabled/removed (disabled preference applied).
- Tile becomes occupied: radial stays open; origin marked invalid; placement blocked until cancel.
- Empty affordable list: show radial with all units disabled.
- Navigation: both angular and cyclic schemes supported.
- Excess units: pagination via next/previous buttons.
- Unaﬀordable units: always displayed disabled (desaturate + red cost).
- Signal naming: `deploy_` prefix across all emitted events.
- Edge layout: shift center inward (preserve circle).
- Invalid phase input: ignore silently.
- Cancellation inputs: Escape, right-click, outside click only.
- Race condition priority: insufficient resources feedback takes precedence over tile invalidity if both fail.
- Failure feedback modality: flashing outline + sound only (no text toast).
- Resource deduction timing: after successful re-validation (conservative).
- Debounce window: 250 ms between accepted placements.
- Post-placement: radial closes unless modifier future extension; note future optional chain mode (Shift) not in this scope.
- Info panel initial visibility: shows first unit pre-selected on open.
- Camera panning: allowed while radial open; tile interactions blocked.
- Unit ordering: grouped by type category then ascending cost within each category.
- Special abilities overflow: scroll area inside panel.
- Accessibility focus default: lowest cost unit initially focused / highlighted.
- Desktop pointer parity: Mouse hover/click is a first-class input path equal to controller/keyboard navigation (no reduced functionality).

#### Additional Assumptions

- Single-player context baseline; multiplayer race conditions limited to speculative tile occupation changes.
- Categories for grouping are predefined in unit metadata; if absent, fallback to cost ascending.
- Pagination controls appear only when more units than capacity of one ring (capacity defined during implementation; documented in planning phase).
- Disabled units are non-interactive but still hoverable for info viewing (cost and stats visible) unless future constraints arise.
- Sound feedback uses existing UI feedback channel; no new audio asset scope defined here.
- Maximum radial open instances: exactly one globally.
- Performance expectation: open/close within a single frame under typical roster size (< 24 units).

### Key Entities

- **Deployment Tile**: Represents a map coordinate eligible for initial unit placement; attributes: position, zone owner, occupancy state.
- **Unit Type**: Abstract definition with attributes: name, cost, stats (Health, Attack, Defense, Movement), special abilities (list), icon, large sprite.
- **Player Resources**: Current numeric pool used to determine affordability; updated after successful placement.
- **Radial Menu Session**: Ephemeral UI context referencing: originating tile position, generated list of affordable unit types, open timestamp/state.
- **Info Panel View Model**: Current focused unit data bundle used to bind to UI elements.

---

## Review & Acceptance Checklist

GATE: Automated checks run during main() execution

### Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status

Updated by main() during processing

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed
