# Feature Contracts: Unit Selection Signals

This document defines the signal-based contracts for communication between different components of the 'Develop Unit Selection Logic' feature.

## 1. `tile_map.gd`

This script is the central hub for detecting user input on the map.

### Signal: `unit_selected`

-   **Signature**: `unit_selected(unit: Node)`
-   **Description**: Emitted when a player successfully clicks on a tile containing a unit.
-   **Payload**:
    -   `unit`: A reference to the specific `Node` of the unit that was selected. If no unit is selected (e.g., an empty tile is clicked), this can be `null`.
-   **Connected To**: This signal will be connected to the main UI control script that manages the lower-third information panel.

## 2. `unit_info_panel.gd` (or equivalent UI script)

This script manages the display of the lower-third information panel.

### Public Function: `show_unit(unit: Node)`

-   **Description**: This function is called to display or update the panel with a specific unit's information. It is the primary entry point for the UI panel.
-   **Parameters**:
    -   `unit`: A reference to the unit node whose data needs to be displayed. The function will then read the properties (stats, name, texture, etc.) from this node to populate the UI fields.

### Public Function: `hide_panel()`

-   **Description**: Hides the information panel.
-   **Parameters**: None.
