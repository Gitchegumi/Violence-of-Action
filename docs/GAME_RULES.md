# GitchPygame Hex Battle - Game Rules

## Game Overview

This is a turn-based strategy game played on a 15x15 hexagonal grid. The game board is randomly generated at the start of each match, creating a unique battlefield every time. Players will command their units to move across the map, engage in combat, and complete objectives.

## Map and Terrain

The battlefield is a 15x15 hex grid, composed of 225 randomly placed tiles built around a central Objective tile. The terrain type of each tile affects unit movement.

### Tile Types and Distribution

There are four types of terrain tiles:

*   **Grass:** 57 tiles
*   **Tall Grass:** 56 tiles
*   **Water:** 56 tiles
*   **Mountain:** 55 tiles
*   **Objective:** 1 Tile

### Movement Costs

*   **Grass:** Costs 1 movement point to enter.
*   **Tall Grass:** Costs 2 movement points to enter.
*   **Water:** Can only be traversed by units with water-crossing capabilities. Cost 1 movement to enter for these units.
*   **Mountain:** Costs 5 movement points to enter.

## Game Setup

*   **Players:** The game supports 2-3 players.
*   **Map Generation:** The map is generated randomly, starting with the Objective tile placed at the center of the 15x15 hex grid. Other terrain tiles are then randomly placed clockwise around the Objective tile, starting at the 12 o'clock position, until all tiles are placed.
*   **Unit Deployment:** (Details on initial unit placement will be added here once unit types are defined.)

## Turn Order

The game proceeds in a player-by-player turn order. The starting player is chosen randomly at the beginning of the game.

Each player's turn consists of the following phases:

1.  **Start Turn:** Reset any persistent effects from the previous turn.
2.  **Marshal Troops:** Spend earned currency (details on currency to be defined) to improve existing units or add new units to the deployment zone.
3.  **Movement:** Move any active units up to their maximum movement allowance.
4.  **Combat:** Declare combat actions. (Detailed combat mechanics will be addressed in a separate section/issue.)
5.  **Resolve:** Resolve all declared combat actions.
6.  **Clean Up:** Resolve any temporary effects that expire at the end of the turn, and establish any persistent effects that will carry over into the next turn. Finally, pass play to the next player.

## Win Conditions

Players can achieve victory through one of the following conditions:

*   **Elimination:** Eliminate all enemy units belonging to opposing players.
*   **Objective Control:** Occupy the central Objective tile for 3 consecutive turns. An 'occupation token' will be used to signify control of the Objective tile, persisting even if the occupying unit moves off the tile, until an opposing unit occupies it.

## Units and Stats

(This section is under development.)

Details about the different units, their stats, abilities, and combat mechanics will be added here.

## How to Play

(Instructions on how to play will be added once the core mechanics are implemented.)
