# Army Codex

This document is the authority for army identity, unit profiles, and upgrade
design. `GAME_RULES.md` owns universal mechanics, `HOW_TO_PLAY.md` owns current
controls, and the live `.tres` files are the executable profile data.

Status vocabulary:

- **Implemented:** available in the current build.
- **Designed, not implemented:** approved design that is not executable yet.
- **TBD:** requires a creative-director decision.
- **Deferred:** intentionally outside the current release scope.

## The Coreborn

**Roster status: Implemented.** All seven Tier 1 profiles are deployable. Their
roles, costs, stats, terrain movement, descriptions, abilities, and placeholder
sprite-sheet regions are encoded in
`assets/data/armies/TheCoreborn/tier-1/*.tres`.

`-1` means the terrain is impassable. The Battlefield Scavenger's displayed base
cost is 1; its actual purchase price uses the on-field Fibonacci rule in
`GAME_RULES.md`.

<!-- CODEX_PROFILE_TABLE_START -->
| Unit ID | Display name | Role | Tier | Cost type | Cost | HP | Attack | Range | Armor | Speed | Field | Forest | Mountain | Water |
| --- | --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| battlefield_scavenger | Battlefield Scavenger | Scavenger | 1 | fibonacci | 1 | 1 | 1 | 1 | 0 | 3 | 1 | 2 | -1 | -1 |
| fluxsmith | Fluxsmith | Engineer / Support | 1 | standard | 4 | 2 | 1 | 1 | 0 | 3 | 1 | 2 | -1 | -1 |
| ghostthorn | Ghostthorn | Special Forces | 1 | standard | 8 | 2 | 2 | 1 | 0 | 5 | 1 | 1 | -1 | -1 |
| golemancer_hull | Golemancer Hull | Heavy Armor | 1 | standard | 8 | 5 | 3 | 1 | 2 | 2 | 1 | 2 | 10 | -1 |
| shard_walker | Shardwalker | Core Infantry | 1 | standard | 2 | 3 | 1 | 1 | 0 | 4 | 1 | 2 | -1 | -1 |
| sky_render | Skyrender | All-Terrain Flanker | 1 | standard | 12 | 3 | 2 | 2 | 1 | 6 | 1 | 1 | 1 | 1 |
| tide_born | Tideborn | Amphibious Unit | 1 | standard | 4 | 2 | 2 | 1 | 0 | 3 | 1 | 2 | -1 | 1 |
<!-- CODEX_PROFILE_TABLE_END -->

### Battlefield Scavenger

**Implemented.** A unit that profits from destruction on the battlefield. Its
destruction income and on-field-count Fibonacci purchase price are defined in
`GAME_RULES.md`. Artwork uses placeholder sheet region `(35, 545, 210, 285)`.

### Fluxsmith

**Implemented.** Support unit with healing and terrain-altering abilities. It
may heal 1 HP on an adjacent ally or erect an adjacent 1 HP / 2 Armor barrier;
either action replaces its attack. Barrier placement, duration, movement, line
of sight, attack, and dismantling rules are defined in `GAME_RULES.md`. Artwork
uses placeholder sheet region `(20, 80, 300, 320)`.

### Ghostthorn

**Implemented.** Stealthy infiltrators using teleportation tech. Each may make a
free, once-per-game teleport up to 3 hexes to an unoccupied non-Water tile under
the rules in `GAME_RULES.md`. Artwork uses placeholder sheet region
`(360, 80, 300, 320)`.

### Golemancer Hull

**Implemented.** Massive exo-shell driven by arcane tech. Slow, powerful, and
resilient. A primary hit checks the same roll against adjacent enemy units,
applying their Armor and terrain separately. Artwork uses placeholder sheet
region `(690, 80, 300, 320)`.

### Shardwalker

**Implemented.** Light troops augmented with crystal tech for standard
mobility. It has no special ability. Artwork uses placeholder sheet region
`(258, 548, 236, 301)`.

### Skyrender

**Implemented.** Hovering drone-rider capable of crossing all terrain types. It
has the once-per-game unsplittable post-attack move and one-infantry transport
rules defined in `GAME_RULES.md`. Artwork uses placeholder sheet region
`(500, 520, 300, 320)`.

### Tideborn

**Implemented.** Bio-engineered aquatic troopers with amphibious mobility. It
has no special ability. Artwork uses placeholder sheet region
`(790, 570, 205, 260)`.

## Upgrades

The army-level upgrade system is **Designed, not implemented**: an eligible,
safe unit may eventually purchase an upgrade no more than once per turn. Exact
paths remain **TBD**.

Legacy planning data proposed that Fluxsmith, Ghostthorn, Golemancer Hull,
Shardwalker, Skyrender, and Tideborn could upgrade, while Battlefield Scavenger
could not. That proposal did not define targets, costs, prerequisites, effects,
Tier 2 profiles, or Tier 3 profiles, so every per-unit eligibility decision and
all of those fields remain **TBD**, not approved facts. The live Tier 1 resources
correctly fail closed with `can_upgrade = false`, `upgrade_cost = -1`, and no
target until the creative director approves complete paths.

Special abilities beyond the implemented Tier 1 roster are **Deferred**. Audio
and replacement visual assets are **Deferred** until the creative director
supplies them under an owned issue.

| Unit | Eligibility | Target | Cost | Prerequisites | Effects | Open questions |
| --- | --- | --- | --- | --- | --- | --- |
| Battlefield Scavenger | TBD (legacy proposal: no) | TBD | TBD | TBD | TBD | All fields require approval. |
| Fluxsmith | TBD (legacy proposal: yes) | TBD | TBD | TBD | TBD | All fields require approval. |
| Ghostthorn | TBD (legacy proposal: yes) | TBD | TBD | TBD | TBD | All fields require approval. |
| Golemancer Hull | TBD (legacy proposal: yes) | TBD | TBD | TBD | TBD | All fields require approval. |
| Shardwalker | TBD (legacy proposal: yes) | TBD | TBD | TBD | TBD | All fields require approval. |
| Skyrender | TBD (legacy proposal: yes) | TBD | TBD | TBD | TBD | All fields require approval. |
| Tideborn | TBD (legacy proposal: yes) | TBD | TBD | TBD | TBD | All fields require approval. |
