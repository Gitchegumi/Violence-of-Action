# Runtime Architecture

## Sources of truth

- `GAME_RULES.md`: universal mechanics and victory rules.
- `HOW_TO_PLAY.md`: controls and current player-facing flow.
- `ARMY_CODEX.md`: army identity, unit profiles, and upgrade design.
- `assets/data/armies/**/.tres`: executable unit profile data.
- GitHub issues: unresolved or deferred product requirements.

## Runtime ownership

- `GameSession` owns match setup and player names/colors.
- `GameState` owns the turn, active player, phase, and victory state.
- `TileMapLayer` owns board input, map presentation, action highlights, and the
  signal boundary between board interactions and UI.
- `TroopManager` owns the unit catalog, placement, occupancy, movement, combat,
  barriers, teleportation, and transport state.
- `CombatResolver` owns deterministic 2d6 resolution calculations.
- `ResourceManager` owns player Essence balances and economy changes.
- Radial menus/controllers own menu focus and translate choices into board
  requests; they do not own gameplay truth.
- `UnitInfoPanel` presents selected-unit state and does not mutate it.

Gameplay changes should flow through the owning system and its signals rather
than reach across the tree or duplicate state. Random behavior accepts an
injected seed. Gameplay diagnostics go through `GameLog`.

## Shared unit runtime

Every current profile uses `scenes/units/unit.tscn` and
`scripts/units/unit.gd`. `TroopManager` instantiates that scene and injects, in
this order before adding it to the scene tree: the `UnitType` profile, stable
unit ID, map coordinate, controlling player ID, player color, display position,
and display scale. It then resets turn state and calls `add_child`. This preserves
correct `_ready()` initialization, artwork region, tint, HP, selection, movement,
combat, and previews for every profile.

A distinct scene is justified only when a unit needs a materially different node
hierarchy, rig, collision model, or runtime behavior. Different stats, names, or
artwork regions use the shared scene plus a `UnitType` resource.

## Deferred product work recovered during cleanup

- #100: analog gamepad navigation for radial menus.
- #101: audio feedback for failed deployment actions.
- #102: deployment roster filtering for expanded armies.
- #103: active status effects in selected-unit information.
- #104: integration of the provided title-theme audio.

Networked multiplayer architecture remains owned by its existing issue and is
not part of the local hot-seat MVP runtime.
