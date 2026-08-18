# Army Codex

This document is the authority for army identity, unit profiles, and upgrade
design. `GAME_RULES.md` owns universal mechanics, `HOW_TO_PLAY.md` owns current
controls, and the live `.tres` files are the executable profile data.

Status vocabulary:

- **Implemented:** represented in live data and functioning in gameplay.
- **Designed, not implemented:** approved design that is not executable yet.
- **TBD:** known design space without an approved decision.
- **Deferred:** intentionally outside the current release scope.

The entry schema used below is intended to support additional armies, tiers,
and upgrade paths without changing the document structure. If this file becomes
unwieldy, each army section may move to its own codex file while retaining the
same fields.

## The Coreborn

### Army overview

- **Identity:** The Coreborn are a mechanical race of beings bent on removing
  biological life forms from the world.
- **Playstyle: TBD.**
- **Mechanical themes: TBD.**
- **Essence and economy:** **Implemented.** Coreborn units use the universal
  per-unit-type income rules except the Battlefield Scavenger. The Scavenger
  instead earns destruction income and uses an on-field-count Fibonacci
  purchase price under the rules in `GAME_RULES.md`.
- **Roster and tiers:** The Coreborn will have three tiers. All seven Tier 1
  profiles are **Implemented**. Tier 2 and Tier 3 rosters and profiles are
  **TBD**.
- **Upgrade philosophy and tree:** The three-tier structure is approved, but
  eligibility, targets, costs, prerequisites, effects, and whether paths branch
  or remain linear are **TBD**. Design decisions are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).
- **Implementation status:** The complete Tier 1 roster and its listed special
  abilities are **Implemented**. Higher-tier profiles and upgrade paths are not
  yet designed or implemented.

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

- **Unit ID:** `battlefield_scavenger`
- **Display name:** Battlefield Scavenger
- **Army:** The Coreborn
- **Role:** Scavenger
- **Tier:** 1
- **Description/lore:** A unit that profits from destruction on the battlefield.
- **Cost model / current cost:** **Implemented.** Fibonacci; base cost 1.
- **Stats:** **Implemented.** 1 HP, 1 Attack, 1 Range, 0 Armor, 3 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 2, Mountain
  impassable, Water impassable.
- **Special abilities:** **Implemented.** This unit's only method of generating
  essence. See GAME_RULES.md for scaling cost. Gains 3 essence for each unit
  (friendly or enemy) destroyed since the beginning of the player's last turn.
  This includes units destroyed during their own turn and during opponent turns
  between turns. Full timing and cost rules are in `GAME_RULES.md`.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(35, 545, 210, 285)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed no; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Fluxsmith

- **Unit ID:** `fluxsmith`
- **Display name:** Fluxsmith
- **Army:** The Coreborn
- **Role:** Engineer / Support
- **Tier:** 1
- **Description/lore:** Support unit with healing and terrain-altering abilities.
- **Cost model / current cost:** **Implemented.** Standard; 4 essence.
- **Stats:** **Implemented.** 2 HP, 1 Attack, 1 Range, 0 Armor, 3 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 2, Mountain
  impassable, Water impassable.
- **Special abilities:** **Implemented.** Heal 1 HP on an adjacent ally instead
  of attacking. Erect an adjacent 1 HP / 2 Armor barrier instead of attacking.
  Full barrier rules are in `GAME_RULES.md`.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(20, 80, 300, 320)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed yes; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Ghostthorn

- **Unit ID:** `ghostthorn`
- **Display name:** Ghostthorn
- **Army:** The Coreborn
- **Role:** Special Forces
- **Tier:** 1
- **Description/lore:** Stealthy infiltrators using teleportation tech.
- **Cost model / current cost:** **Implemented.** Standard; 8 essence.
- **Stats:** **Implemented.** 2 HP, 2 Attack, 1 Range, 0 Armor, 5 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 1, Mountain
  impassable, Water impassable.
- **Special abilities:** **Implemented.** Free once-per-game teleport up to 3
  hexes to an unoccupied non-Water tile. Full teleport rules are in
  `GAME_RULES.md`.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(360, 80, 300, 320)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed yes; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Golemancer Hull

- **Unit ID:** `golemancer_hull`
- **Display name:** Golemancer Hull
- **Army:** The Coreborn
- **Role:** Heavy Armor
- **Tier:** 1
- **Description/lore:** Massive exo-shell driven by arcane tech. Slow, powerful,
  and resilient.
- **Cost model / current cost:** **Implemented.** Standard; 8 essence.
- **Stats:** **Implemented.** 5 HP, 3 Attack, 1 Range, 2 Armor, 2 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 2, Mountain 10, Water
  impassable.
- **Special abilities:** **Implemented.** A primary hit checks the same attack
  roll against adjacent enemies. Full splash-damage rules are in
  `GAME_RULES.md`.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(690, 80, 300, 320)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed yes; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Shardwalker

- **Unit ID:** `shard_walker`
- **Display name:** Shardwalker
- **Army:** The Coreborn
- **Role:** Core Infantry
- **Tier:** 1
- **Description/lore:** Light troops augmented with crystal tech for standard
  mobility.
- **Cost model / current cost:** **Implemented.** Standard; 2 essence.
- **Stats:** **Implemented.** 3 HP, 1 Attack, 1 Range, 0 Armor, 4 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 2, Mountain
  impassable, Water impassable.
- **Special abilities:** None in the live profile.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(258, 548, 236, 301)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed yes; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Skyrender

- **Unit ID:** `sky_render`
- **Display name:** Skyrender
- **Army:** The Coreborn
- **Role:** All-Terrain Flanker
- **Tier:** 1
- **Description/lore:** Hovering drone-rider capable of crossing all terrain types.
- **Cost model / current cost:** **Implemented.** Standard; 12 essence.
- **Stats:** **Implemented.** 3 HP, 2 Attack, 2 Range, 1 Armor, 6 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 1, Mountain 1, Water 1.
- **Special abilities:** **Implemented.** Ignores terrain penalties. Once per
  game, may take one unsplittable full-speed move after attacking. Carries one
  Shardwalker, Ghostthorn, or Fluxsmith; load and unload each cost 3 movement.
  Full post-combat-move and transport rules are in `GAME_RULES.md`.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(500, 520, 300, 320)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed yes; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Tideborn

- **Unit ID:** `tide_born`
- **Display name:** Tideborn
- **Army:** The Coreborn
- **Role:** Amphibious Unit
- **Tier:** 1
- **Description/lore:** Bio-engineered aquatic troopers with amphibious mobility.
- **Cost model / current cost:** **Implemented.** Standard; 4 essence.
- **Stats:** **Implemented.** 2 HP, 2 Attack, 1 Range, 0 Armor, 3 Speed.
- **Terrain movement:** **Implemented.** Field 1, Forest 2, Mountain
  impassable, Water 1.
- **Special abilities:** None in the live profile.
- **Artwork/source status:** Placeholder runtime sprite-sheet artwork at region
  `(790, 570, 205, 260)`; replacement army assets are tracked in
  [issue #30](https://github.com/Gitchegumi/Violence-of-Action/issues/30).
- **Implementation status:** **Implemented.**
- **Upgrade eligibility:** **TBD.** Legacy planning proposed yes; this is not an
  approved eligibility decision.
- **Planned upgrade target(s):** **TBD.**
- **Planned upgrade cost / requirements:** **TBD.**
- **Planned upgrade effects / deltas:** **TBD.**
- **Open design questions:** Eligibility and all upgrade fields are tracked in
  [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

### Upgrade implementation boundary

The universal upgrade system is **Designed, not implemented**: an eligible,
safe unit may eventually purchase an upgrade no more than once per turn. The
Coreborn will have three tiers, but every per-unit eligibility decision and all
Tier 2 and Tier 3 names, profiles, paths, costs, prerequisites, and effects are
**TBD** pending [issue #118](https://github.com/Gitchegumi/Violence-of-Action/issues/118).

Legacy planning data proposed that Fluxsmith, Ghostthorn, Golemancer Hull,
Shardwalker, Skyrender, and Tideborn could upgrade, while Battlefield Scavenger
could not. These flags are retained only as historical proposals, not approved
design. The live Tier 1 resources correctly fail closed with
`can_upgrade = false`, `upgrade_cost = -1`, and no target until the creative
director approves complete paths and implementation work is delivered.

## Volka'ana

- **Identity:** The Volka'ana will be wardens of nature: an elvine race of
  beings who desire to defend the natural order of the universe. “Elvine” is
  the intentional in-world term corresponding to “elven.”
- **Playstyle:** **TBD.**
- **Mechanical themes:** **TBD.**
- **Essence and economy:** **TBD.**
- **Roster and tiers:** **TBD.**
- **Upgrade philosophy and tree:** **TBD.**
- **Unit profiles:** **TBD.**
- **Artwork/source status:** **TBD.**
- **Implementation status:** **Designed, not implemented — Coming soon.**
