# Data Model: Unit Selection

This document outlines the key data entities and state required for the 'Develop Unit Selection Logic' feature.

## 1. Selected Unit State

There is one primary piece of state to manage for this feature:

-   **Entity**: `selected_unit`
-   **Type**: A reference to a Godot `Node` (specifically, the instance of the unit scene that has been placed on the map).
-   **Description**: This state represents the unit that the player has currently selected. It can hold a reference to a unit node or be `null` if no unit is selected.
-   **Location**: This state will likely be managed in a central game state manager singleton (e.g., `GameState.gd`) or directly within the main `tile_map.gd` script to be easily accessible by the UI.

### State Transitions

-   **`null` -> `Unit Node`**: Occurs when the player clicks on a tile containing a unit and no other unit is currently selected.
-   **`Unit Node A` -> `Unit Node B`**: Occurs when the player clicks on a tile containing Unit B while Unit A is currently selected.
-   **`Unit Node` -> `null`**: Occurs when the player clicks on an empty tile or a non-interactive UI element while a unit is selected.
