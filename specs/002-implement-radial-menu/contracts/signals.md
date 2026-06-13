# Signal Contracts: Radial Deployment Menu

Date: 2025-09-21  
Feature: 002-implement-radial-menu

## Overview

All interactions are event-driven via Godot signals prefixed `deploy_`. These signals define the public integration surface for deployment UI extensions (filters, analytics, tutorials).

## Signals

### deploy_tile_clicked(position: Vector2i)

Emitted after a user left-clicks a tile during deployment phase that passes preliminary zone & occupancy validation.

- position: Map coordinate in tile units.

### deploy_radial_opened(origin: Vector2i)

Emitted when radial menu successfully instantiates & attaches to scene tree.

- origin: Tile coordinate center reference.

### deploy_unit_hovered(unit_id: String)

Emitted when focus/hover changes to a unit icon.

- unit_id: Corresponds to UnitType.id.

### deploy_unit_selected(unit_id: String, origin: Vector2i)

Emitted after successful placement (post validation & resource deduction).

- unit_id: UnitType.id placed.
- origin: Tile coordinate where unit was placed.

### deploy_placement_failed(reason: String, origin: Vector2i, unit_id: String?)

Emitted when a placement attempt fails.

- reason: One of:
  - `insufficient_resources`
  - `tile_occupied`
  - `invalid_tile`
  - `phase_inactive`
  - `debounced`
- origin: Original tile coordinate for the session.
- unit_id: Optional attempted unit identifier (null if failure pre-selection)

### deploy_radial_closed(reason: String)

Emitted when radial + info panel close.

- reason: One of:
  - `cancel`
  - `placed`
  - `phase_end`
  - `invalid_origin`

## Emission Ordering

1. `deploy_tile_clicked`
2. `deploy_radial_opened`
3. 0..N × `deploy_unit_hovered`
4. On selection attempt:
   - Failure → `deploy_placement_failed`
   - Success → `deploy_unit_selected` then `deploy_radial_closed`
5. Cancel → `deploy_radial_closed`

## Determinism Rules

- No duplicate `deploy_radial_opened` until a `deploy_radial_closed` emitted.
- Failures never emit `deploy_unit_selected`.
- A successful selection always emits `deploy_unit_selected` before `deploy_radial_closed(reason=placed)`.

## Extension Guidance

Future filters should not introduce new base signals; instead, extend payloads via optional metadata dictionary appended to hover/selected signals if required (backward compatible).
