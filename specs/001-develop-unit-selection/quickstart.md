# Quickstart: Testing Unit Selection

This document provides a manual end-to-end test script to verify the functionality of the 'Develop Unit Selection Logic' feature, based on the acceptance criteria in the feature specification.

### Prerequisites
- The game is running.
- A match has been started.
- At least one unit has been placed on the map during the deployment phase.

### Test Steps

1.  **Select a Unit**
    -   **Action**: Use the mouse to click on a tile that contains a friendly unit.
    -   **Verification**: 
        -   ✅ The tile under the unit becomes visually highlighted, using the game's standard tile selection highlight.
        -   ✅ A UI panel appears in the lower third of the screen.
        -   ✅ The panel displays the correct name, stats, and image for the unit that was clicked.

2.  **Deselect by Clicking Empty Tile**
    -   **Action**: Click on any empty tile on the map.
    -   **Verification**:
        -   ✅ The highlight on the previously selected unit's tile disappears.
        -   ✅ The lower-third information panel is hidden or cleared.

3.  **Switch Selection to Another Unit**
    -   **Prerequisite**: At least two units are on the map.
    -   **Action**: Click on the first unit to select it. Then, click on the second unit.
    -   **Verification**:
        -   ✅ The highlight moves from the first unit's tile to the second unit's tile.
        -   ✅ The information panel immediately updates to show the details of the second unit.

### Test-Driven Development (TDD) Approach

Based on the research in `research.md`, the **GUT (Godot Unit Test)** framework will be used. The following tests should be created *before* implementation begins:

1.  **`test_unit_selection_signal.gd`**
    -   A test that checks if the `unit_selected` signal is emitted from the `tile_map` when a simulated click occurs on a tile with a mock unit.
    -   This test should initially fail because the signal does not exist.

2.  **`test_unit_info_panel_visibility.gd`**
    -   A test for the `unit_info_panel` UI scene.
    -   It should test the `show_unit()` and `hide_panel()` functions, asserting that the panel's visibility property is correctly updated.
    -   This test should initially fail because the functions do not exist.
