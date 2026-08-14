# How to Play Violence of Action

This guide covers the controls and complete match flow available in the current MVP build. For exact mechanic definitions and unit profiles, see [Game Rules](GAME_RULES.md).

## Start a Match

1. Select **Start Game** from the main menu.
2. Choose **2 Players** or **3 Players**.
3. Enter a name and choose a unique color for each player. The game will not start with a missing name, missing color, or duplicate color.
4. Optionally enter an integer map seed. Reusing a seed generates the same battlefield; leaving it blank generates a random seed.
5. Select **Start**. Each player's chosen color tints every unit they control, and their chosen name appears in turn information.

The game is local hotseat: players take turns using the same screen.

## Controls

| Input | Action |
| --- | --- |
| Left-click a hex | Select the hex, open deployment on an eligible empty hex, or open actions for an occupied hex |
| Left-click a destination | Confirm a pending Move, Attack, or special-ability target |
| Right-click while choosing a target | Cancel the pending action |
| **Cancel Action** button | Cancel the pending action |
| Right mouse drag | Pan the battlefield |
| Mouse wheel | Zoom in or out |
| Arrow keys or WASD | Pan the battlefield |
| Move the pointer to a screen edge | Pan the battlefield |
| F | Center the camera on the selected hex |
| P | Open deployment on the selected hex when deployment is allowed there |
| Escape | Cancel a pending action first; otherwise pause or resume the match |

## Initial Deployment

Each player begins with **12 essence** and deploys within their highlighted deployment zone.

1. Left-click an empty hex in the active player's deployment zone.
2. Hover a unit in the radial menu to inspect its cost and stats.
3. Select an affordable unit to purchase and place it.
4. Repeat as desired. Unspent essence is saved.
5. Select **Ready Player N** when finished.

Every player must place at least one unit before declaring Ready. After all players are ready, round one begins. The MVP deployment menu offers all seven Coreborn profiles: Battlefield Scavenger, Fluxsmith, Ghostthorn, Golemancer Hull, Shardwalker, Skyrender, and Tideborn.

## Take a Turn

The top status line shows the round, active player, and current phase. Select **Complete Phase** to advance through the turn.

1. **Start Turn:** The game resets per-turn unit actions and awards essence automatically.
2. **Marshal Troops:** Purchase units by left-clicking an empty hex in your deployment zone. New units cannot be placed outside that zone.
3. **Movement:** Left-click one of your units and choose **Move**. Every legal destination is shaded light blue. Select one to move there; the game automatically uses the cheapest valid path and deducts its terrain cost. A unit may move more than once while it has movement remaining. The selected unit's information panel shows its live movement as current points over maximum Speed.
4. **Combat:** Left-click one of your units and choose **Attack**. Every legal enemy target is shaded red. Select an enemy in Range and line of sight to resolve the attack. Each unit may attack once per turn.
5. **Resolve:** Any unit that has not attacked yet may still attack here.
6. **Clean Up:** End-of-turn Objective control and upkeep resolve, then play passes to the next player.

A player with no units remains in the turn rotation and gains 1 essence at Start Turn, allowing them to save toward or immediately purchase a new unit during Marshal Troops.

An invalid destination or target leaves the action active so you can choose another. Use right-click, Escape, or the visible Cancel button to abandon it.

## Coreborn Special Actions

- **Fluxsmith:** In Combat or Resolve, choose **Heal** to restore 1 HP to an adjacent ally or **Barrier** to erect a barrier on a highlighted adjacent hex. Either choice consumes the Fluxsmith's combat action. Barriers cannot be placed on occupied, Water, or Mountain hexes. Entering a barrier hex costs 3 movement, and barriers block line of sight. Select a friendly barrier to dismantle it for free. An enemy unit must enter its hex before selecting **Attack Barrier**.
- **Ghostthorn:** Choose **Teleport** during any phase to move up to 3 hexes to a highlighted unoccupied, non-Water destination. This is a free action usable once per Ghostthorn per game, including after that Ghostthorn attacks.
- **Golemancer Hull:** A successful primary attack automatically checks the same attack roll against each enemy adjacent to the primary target. Each target still applies its own Armor and terrain defense.
- **Skyrender:** After attacking, an optional once-per-game **Post Move** action becomes available later that turn at full speed, whether the attack hit or missed. Normal engagement rules apply, and the move cannot be split. During Movement or Resolve, choose **Load** beside a friendly Shardwalker, Ghostthorn, or Fluxsmith, then **Unload** beside a valid destination. Each action costs 3 movement. If the carrier is destroyed, the passenger survives only on a 2d6 result above 8 and is placed on the carrier's former hex; a passenger that cannot cross Water is destroyed automatically when the carrier is destroyed over Water.

## Movement and Engagement

- Terrain movement depends on the unit profile. The current Shardwalker pays 1 for Field and 2 for Forest, and cannot enter Mountain or Water.
- Friendly units may be crossed but cannot share a destination. Enemy units cannot be crossed or entered.
- Movement ends when a unit first becomes adjacent to a new enemy.
- A unit that starts adjacent to one enemy may attack or disengage by moving, but cannot do both.
- A unit adjacent to enemies from more than one direction is pinned and cannot move.
- If an engaged unit destroys its only adjacent enemy, it may spend its remaining movement during Combat.

## Combat

Attacks resolve immediately when a valid target is selected:

1. Roll **2d6 + Attack** against **8 + Armor**.
2. Add **+1** to the Defense Target when the defender occupies a Forest.
3. A natural 2 always misses; a natural 12 always hits. Otherwise, meeting or exceeding the Defense Target hits.
4. A hit deals 1 persistent HP damage. Armor does not deplete.
5. A unit at 0 HP is removed from the battlefield.

An intervening Mountain blocks line of sight. Other terrain and units do not. The combat result display shows the dice, Attack value, Defense Target, hit or miss, and remaining HP.

## Objective and Victory

The central Objective changes control when a player ends their turn occupying it. Capturing it grants **6 essence** and starts its control counter at 0. The token remains with that player after their unit leaves unless an opponent captures it, upkeep fails, or their last unit is destroyed while occupying the Objective. In that last case, the Objective immediately becomes uncontrolled.

On each later turn of the controller:

- Pay **3 essence** at the end of the turn.
- Successful upkeep advances the control counter by 1.
- Reaching 3 control turns wins the match.
- If upkeep cannot be paid, control is lost and the Objective becomes uncontrolled.

A player also wins immediately when every opposing army has been eliminated.

After either victory condition, select **Return to Main Menu** to leave the completed match and start a fresh setup.
