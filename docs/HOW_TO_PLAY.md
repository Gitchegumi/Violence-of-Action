# How to Play Violence of Action

This guide covers the controls and complete match flow available in the current MVP build. For exact mechanic definitions and unit profiles, see [Game Rules](GAME_RULES.md).

## Start a Match

1. Select **Start Game** from the main menu.
2. Choose **2 Players** or **3 Players**.
3. Optionally enter an integer map seed. Reusing a seed generates the same battlefield; leaving it blank generates a random seed.
4. Select **Start**.

The game is local hotseat: players take turns using the same screen.

## Controls

| Input | Action |
| --- | --- |
| Left-click a hex | Select the hex, open deployment on an eligible empty hex, or open actions for an occupied hex |
| Left-click a destination | Confirm a pending Move or Attack target |
| Right-click while choosing a target | Cancel the pending Move or Attack |
| **Cancel Move/Attack** button | Cancel the pending action |
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

Every player must place at least one unit before declaring Ready. After all players are ready, round one begins. The MVP deployment menu offers all seven Coreborn profiles: Battlefield Scavenger, Fluxsmith, Ghostthorn, Golemancer Hull, Shardwalker, Skyrender, and Tideborn. Their listed special abilities are reserved for later feature updates unless the mechanic is already active in the game.

## Take a Turn

The top status line shows the round, active player, and current phase. Select **Complete Phase** to advance through the turn.

1. **Start Turn:** The game resets per-turn unit actions and awards essence automatically.
2. **Marshal Troops:** Purchase units by left-clicking an empty hex in your deployment zone. New units cannot be placed outside that zone.
3. **Movement:** Left-click one of your units, choose **Move**, then select a destination. The game automatically uses the cheapest valid path and deducts its terrain cost. A unit may move more than once while it has movement remaining.
4. **Combat:** Left-click one of your units, choose **Attack**, then select an enemy in Range and line of sight. Each unit may attack once per turn.
5. **Resolve:** Any unit that has not attacked yet may still attack here.
6. **Clean Up:** End-of-turn Objective control and upkeep resolve, then play passes to the next player.

A player with no units remains in the turn rotation and gains 1 essence at Start Turn, allowing them to save toward or immediately purchase a new unit during Marshal Troops.

An invalid destination or target leaves the action active so you can choose another. Use right-click, Escape, or the visible Cancel button to abandon it.

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

The central Objective changes control when a player ends their turn occupying it. Capturing it grants **6 essence** and starts its control counter at 0. The token remains with that player after their unit leaves unless an opponent captures it or upkeep fails.

On each later turn of the controller:

- Pay **3 essence** at the end of the turn.
- Successful upkeep advances the control counter by 1.
- Reaching 3 control turns wins the match.
- If upkeep cannot be paid, control is lost and the Objective becomes uncontrolled.

A player also wins immediately when every opposing army has been eliminated.

After either victory condition, select **Return to Main Menu** to leave the completed match and start a fresh setup.
