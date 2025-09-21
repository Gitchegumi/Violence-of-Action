# Data Model: Radial Deployment Menu & Unit Info Panel

Date: 2025-09-21  
Feature: 002-implement-radial-menu

## Overview

Logical (in-memory) entities supporting deployment radial flow. No persistent storage implied.

## Entities

### UnitType

Represents a deployable unit archetype.

- id: String (unique key or resource path)
- name: String
- category: String (may be empty; ordering groups)
- cost: int
- stats: Dictionary { health:int, attack:int, defense:int, movement:int }
- abilities: Array[String]
- icon_texture: Texture2D (reference)
- large_sprite: Texture2D (reference)

### DeploymentTile

Represents a tile eligible for placement.

- position: Vector2i
- zone_owner_id: String
- occupied: bool

### ResourcePool

Represents player resources for affordability.

- current: int
- last_updated_frame: int

### RadialMenuSession

Ephemeral session state while radial is open.

- origin_tile: DeploymentTile
- page_index: int
- page_size: int (constant = 12)
- visible_units: Array[UnitType] (current page slice)
- all_units: Array[UnitType] (full ordered list)
- focus_index: int (0-based within visible_units)
- opened_at_ms: int
- last_selection_time_ms: int
- active: bool

### InfoPanelState

Data bound to info panel.

- focused_unit: UnitType | null
- visible: bool

### PlacementAttempt

Transient validation context.

- unit: UnitType
- tile: DeploymentTile
- resources_before: int
- resources_after: int (expected if success)
- valid: bool
- failure_reason: String? ("insufficient_resources" | "tile_occupied" | "invalid_tile" | "phase_inactive")

## Relationships

- RadialMenuSession.references → DeploymentTile (origin)
- RadialMenuSession.visible_units derived from RadialMenuSession.all_units filtered by affordability & paginated.
- InfoPanelState.focused_unit drawn from RadialMenuSession.visible_units[focus_index].
- PlacementAttempt composed during selection confirm using UnitType + DeploymentTile + ResourcePool.

## Ordering Rules

1. Order by category (ascending lexical) then cost (ascending) then name (ascending) to produce all_units.
2. Disabled units (unaffordable) remain in ordering but flagged when rendering.

## Validation Rules

- Affordability: ResourcePool.current >= UnitType.cost.
- Tile Validity: !DeploymentTile.occupied && zone ownership matches player.
- Debounce: now_ms - RadialMenuSession.last_selection_time_ms >= 250.

## State Transitions

RadialMenuSession.active: false → true (open).  
active true → false (close or cancel).

On selection:

1. Build PlacementAttempt
2. Validate affordability first; if fail assign failure_reason and emit failure signal.
3. Validate tile occupancy/zone; if fail and no prior failure assign failure_reason.
4. If success: deduct cost, place unit, update last_selection_time_ms, close session.

## Notes

- No inheritance introduced; composition + simple dictionaries maintain flexibility.
- Future filters can insert pre-order grouping without breaking contract (append filter state field).
