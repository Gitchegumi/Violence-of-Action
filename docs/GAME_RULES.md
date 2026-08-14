# Violence of Action - Game Rules

## Game Overview

This is a turn-based strategy game played on a hexagonal map. The game board is randomly generated at the start of each match, creating a unique battlefield every time. Players will command their units to move across the map, engage in combat, and capture the objective.

## Map and Terrain

The battlefield is a 8 tile radius hex grid, composed of 216 randomly placed tiles built around a central Objective tile. The terrain type of each tile affects unit movement. Tiles are placed based on random noise generation to keep maps natural looking, but random.

### Tile Types and Distribution

There are four types of terrain tiles:

*   **Field:** 78 tiles
*   **Forest:** 77 tiles
*   **Water:** 40 tiles
*   **Mountain:** 21 tiles
*   **Objective:** 1 Tile

### Movement Costs

*   **Field:** Costs 1 movement point to enter.
*   **Forest:** Costs 2 movement points to enter.
*   **Water:** Can only be traversed by units with water-crossing capabilities. Cost 1 movement to enter for these units.
*   **Mountain:** Costs 5 movement points to enter.

## Game Setup

*   **Players:** The game supports 2-3 players.
*   **Map Generation:** The map is generated randomly, starting with the Objective tile placed at the center of the hex map. Other terrain tiles are then randomly placed clockwise around the Objective tile, starting at the 12 o'clock position, until all tiles are placed.
*   **Unit Deployment:** Each player starts the game with 12 essence to purchase their initial deployment force.

## Initial Deployment Phase

Before the first round of turns begins, players enter a one-time **Initial Deployment Phase**. During this phase:

- Each player receives **12 essence** to build their starting force.
- Units are purchased using the same costs listed in their unit profiles.
- Units must be placed within that player's **deployment zone**.
- Players may choose not to spend all 12 essence, saving the remainder for future turns.

Once all players have completed their deployments, the first round begins with the normal turn order.

### Deployment Zones

Each player's **deployment zone** consists of the hexes along one outer edge of the board:
- In 2-player games: Players use opposite outer edges.
- In 3-player games: Players use three equally spaced outer edges.

**Important:** No unit may be deployed outside the owning player’s designated deployment zone at **any time** — this applies to both initial deployment and all future deployments during the game.


## Earning Essence

At the start of each turn, players gain essence based on their active units. Each **unit type** contributes **half of its cost** in essence, but **only once per unit type**, regardless of how many units of that type are on the field.

For example:

* If a player controls **6 Shardwalkers** (cost: 2 essence each), they gain **1 essence** (only one Shardwalker counts for generation).
* If they instead have **4 Shardwalkers** and **1 Tideborn** (cost: 4 essence), they gain **3 essence**:

  * **1** from the Shardwalker type (2 ÷ 2 = 1)
  * **2** from the Tideborn (4 ÷ 2 = 2)

This system encourages diversity in unit composition while limiting passive income from spammed unit types.

**Exception:** The **Battlefield Scavenger** does not generate essence in this way. Its only source of essence is its special ability.


## Turn Order

The game proceeds in a player-by-player turn order. The starting player is chosen randomly at the beginning of the game.

Each player's turn consists of the following phases:

1.  **Start Turn:** Reset any persistent effects from the previous turn.
2.  **Marshal Troops:** Spend any earned essence to improve existing units or add new units to the deployment zone.
3.  **Movement:** Move any active units up to their maximum movement allowance.
4.  **Combat:** Declare combat actions against valid enemy targets.
5.  **Resolve:** Resolve all declared combat actions.
6.  **Clean Up:** Resolve any temporary effects that expire at the end of the turn, and establish any persistent effects that will carry over into the next turn. Finally, pass play to the next player.

### Movement and Engagement

- A unit may split its Speed across multiple movement actions during its turn. Unspent movement remains available later in the turn, including after combat if the combat action destroys the adjacent enemy.
- Movement automatically follows the cheapest valid path by movement-point cost.
- Units may move through hexes occupied by friendly units, but may not end movement on an occupied hex.
- Enemy-occupied hexes block movement and may not be entered or crossed.
- A unit adjacent to one enemy is **decisively engaged**. It may attack, or it may move as a **disengagement action**, but it cannot both disengage and take another action that turn.
- If an engaged unit attacks and destroys the enemy so that it is no longer adjacent to an enemy, it may spend any remaining movement normally.
- A unit adjacent to enemies from more than one direction is **pinned** and cannot move, including by disengagement.

### Combat Resolution

- Each unit may attack once per turn during the Combat/Resolve flow.
- A target must be an enemy within the attacker's Range and line of sight.
- An intervening Mountain hex blocks line of sight. Units, Field, Forest, Objective, and Water hexes do not block line of sight.
- Roll **2d6 + the attacker's Attack** against **8 + the defender's Armor**.
- A defender occupying a Forest hex adds **+1** to its Defense Target.
- A natural 2 automatically misses. A natural 12 automatically hits. Otherwise, the attack hits when the Attack Total equals or exceeds the Defense Target.
- A hit deals exactly **1 persistent HP damage**. HP does not automatically recover during Cleanup.
- Armor raises the Defense Target; it is not a health pool and does not deplete or replenish.
- A unit at 0 HP is destroyed and removed from the battlefield.
- The initial combat implementation does not add critical damage, variable damage, counterattacks, friendly fire, cover, flanking, armor penetration, or status effects.

### 1. Deploying New Units

- New units may be purchased at their listed cost.
- Units must be deployed into the player’s **deployment zone**.
- No unit may be deployed outside its owner’s designated deployment zone at any time.

### 2. Upgrading Existing Units

- Units already on the board may be upgraded to improve their stats or gain new abilities (exact upgrade paths TBD).
- A unit may be upgraded **only once per turn**.
- Upgrades can only be applied to units that are **not engaged in combat** and **are not adjacent to enemy units**.
- Upgrades are purchased by paying an **upgrade cost** (mechanics and values to be defined once combat rules are finalized).

Players must choose between expanding their force or enhancing the strength of the units they already control. This creates a flexible but finite economy where strategic decisions shape the battlefield over time.

## Win Conditions

Players can achieve victory through one of the following conditions:

*   **Elimination:** Eliminate all enemy units belonging to opposing players.
*   **Objective Control:** Retain the central Objective tile's occupation token through 3 of your own completed turns after capturing it. The token persists even if the occupying unit moves off the tile, until an opposing unit occupies it or upkeep cannot be paid.

### Objective Control (Occupation Token Rules)

The Objective tile represents a critical point of interest on the battlefield. Control of this tile is tracked using an **occupation token** and is governed by the following rules:

- **Gaining Control:**  
  A player gains control of the Objective tile at the **end of their turn** if they occupy it with a unit and no opposing unit also occupies it. If multiple players contest the tile during a round, **combat resolves control**.

- **Token Persistence:**  
  Once gained, the **occupation token remains** with the controlling player, even if they no longer have a unit on the Objective tile. The token only changes hands if:
  - An **opposing player ends their turn** with a unit on the Objective tile.
  - The **current controller cannot afford the upkeep cost** (see below).

- **Essence Bonus:**  
  When a player **gains control** of the Objective tile, they immediately gain **6 essence**.

- **Upkeep Cost:**  
  Capturing the Objective establishes control at **0 control turns** and does not charge upkeep on the capture turn. At the end of each later turn of their own while holding the Objective token, a player must pay **3 essence** to maintain control. Opponents' completed turns do not charge upkeep or advance the counter.
  - After successful upkeep, increase the controller's control-turn counter by 1.
  - The controller wins immediately when that counter reaches 3.
  - If they **cannot pay**, the **local populace rebels**, and the occupation token is **removed** from play. The tile becomes uncontrolled until another player captures it again.

## Armies

This game features different armies, each with their own unique units and playstyles. The first army available is **The Coreborn**.

## Units and Stats

Here are the details about the different units, their stats, abilities, and terrain movement costs:

### The Coreborn

#### Battlefield Scavenger
*   **Role:** Scavenger  
*   **Tier:** 1  
*   **Description:** A unit that profits from destruction on the battlefield.  
*   **Cost:** Variable (see below)  
*   **Stats:** HP: 1, Attack: 1, Range: 1, Armor: 0, Speed: 3  
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: N/A  
*   **Special:** This unit's only method of generating essence.

At the **start of its controller's turn**, the Battlefield Scavenger grants **3 essence for each unit** (friendly or enemy) destroyed **since the beginning of that player's previous turn**.

- This includes units destroyed during the player's previous turn, any opponent’s turns, and any effects in between.
- The bonus is awarded during the **Start Turn** phase.
- Each destroyed unit can only trigger one Scavenger per turn — you can't double-dip on the same kill.

##### Scaling Cost
Each Battlefield Scavenger a player controls increases the cost of the next one, using the Fibonacci sequence:

- 1st Scavenger: **1 essence**
- 2nd Scavenger: **2 essence**
- 3rd Scavenger: **3 essence**
- 4th Scavenger: **5 essence**
- 5th Scavenger: **8 essence**
- 6th and beyond: Continue the Fibonacci progression (13, 21, etc.)

This cost scaling represents increasing resistance from the battlefield population and logistical strain in deploying additional scavengers.

#### Fluxsmith
*   **Role:** Engineer / Support
*   **Tier:** 1
*   **Description:** Support unit with healing and terrain-altering abilities.
*   **Cost:** 4
*   **Stats:** HP: 2, Attack: 1, Range: 1, Armor: 0, Speed: 3
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: N/A
*   **Special:** Heals adjacent allies; can construct temporary barriers

#### Ghostthorn
*   **Role:** Special Forces
*   **Tier:** 1
*   **Description:** Stealthy infiltrators using teleportation tech.
*   **Cost:** 8
*   **Stats:** HP: 2, Attack: 2, Range: 1, Armor: 0, Speed: 5
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 1, Water: N/A, Mountain: N/A
*   **Special:** Can teleport up to 3 hexes once per game

#### Golemancer Hull
*   **Role:** Heavy Armor
*   **Tier:** 1
*   **Description:** Massive exo-shell driven by arcane tech. Slow, powerful, and resilient.
*   **Cost:** 8
*   **Stats:** HP: 5, Attack: 3, Range: 1, Armor: 2, Speed: 2
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: 10
*   **Special:** Splash damage in adjacent hexes

#### Shardwalker
*   **Role:** Core Infantry
*   **Tier:** 1
*   **Description:** Light troops augmented with crystal tech for standard mobility.
*   **Cost:** 2
*   **Stats:** HP: 3, Attack: 1, Range: 1, Armor: 0, Speed: 4
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: N/A, Mountain: N/A
*   **Special:** None

#### Skyrender
*   **Role:** All-Terrain Flanker
*   **Tier:** 1
*   **Description:** Hovering drone-rider capable of crossing all terrain types.
*   **Cost:** 12
*   **Stats:** HP: 3, Attack: 2, Range: 2, Armor: 1, Speed: 6
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 1, Water: 1, Mountain: 1
*   **Special:** Ignores terrain penalties; may move again after combat once per game

#### Tideborn
*   **Role:** Amphibious Unit
*   **Tier:** 1
*   **Description:** Bio-engineered aquatic troopers with amphibious mobility.
*   **Cost:** 4
*   **Stats:** HP: 2, Attack: 2, Range: 1, Armor: 0, Speed: 3
*   **Terrain Movement Costs:** Grass: 1, Tall Grass: 2, Water: 1, Mountain: N/A
*   **Special:** None

## How to Play

See [How to Play](HOW_TO_PLAY.md) for current controls, initial deployment, turn-by-turn interactions, combat targeting, and victory instructions.
