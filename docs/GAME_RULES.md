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

Here are the details about the different units, their stats, abilities, and terrain movement costs:

### Fluxsmith
*   **Role:** Engineer / Support
*   **Tier:** 1
*   **Description:** Support unit with healing and terrain-altering abilities.
*   **Cost:** 2
*   **Stats:** HP: 2, Attack: 1, Range: 1, Armor: 0, Speed: 3
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: N/A
*   **Special:** Heals adjacent allies; can construct temporary barriers

### Ghostthorn
*   **Role:** Special Forces
*   **Tier:** 1
*   **Description:** Stealthy infiltrators using teleportation tech.
*   **Cost:** 3
*   **Stats:** HP: 2, Attack: 2, Range: 1, Armor: 0, Speed: 5
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 1, Water: N/A, Mountain: N/A
*   **Special:** Can teleport up to 3 hexes once per game

### Golemancer Hull
*   **Role:** Heavy Armor
*   **Tier:** 1
*   **Description:** Massive exo-shell driven by arcane tech. Slow, powerful, and resilient.
*   **Cost:** 3
*   **Stats:** HP: 5, Attack: 3, Range: 1, Armor: 2, Speed: 2
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: 10
*   **Special:** Splash damage in adjacent hexes

### Shardwalker
*   **Role:** Core Infantry
*   **Tier:** 1
*   **Description:** Light troops augmented with crystal tech for standard mobility.
*   **Cost:** 1
*   **Stats:** HP: 3, Attack: 1, Range: 1, Armor: 0, Speed: 4
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: N/A
*   **Special:** None

### Skyrender
*   **Role:** All-Terrain Flanker
*   **Tier:** 1
*   **Description:** Hovering drone-rider capable of crossing all terrain types.
*   **Cost:** 4
*   **Stats:** HP: 3, Attack: 2, Range: 2, Armor: 1, Speed: 6
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 1, Water: 1, Mountain: 1
*   **Special:** Ignores terrain penalties; may move again after combat once per game

### Tideborn
*   **Role:** Amphibious Unit
*   **Tier:** 1
*   **Description:** Bio-engineered aquatic troopers with amphibious mobility.
*   **Cost:** 2
*   **Stats:** HP: 2, Attack: 2, Range: 1, Armor: 0, Speed: 3
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: 1, Mountain: N/A
*   **Special:** None

## How to Play

(Instructions on how to play will be added once the core mechanics are implemented.)
