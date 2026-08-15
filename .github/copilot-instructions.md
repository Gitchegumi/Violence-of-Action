# Violence of Action contributor context

Violence of Action is a local hot-seat tactical game built with GDScript and the
standard Godot Engine 4.5 release.

## Sources of truth

- Treat `docs/GAME_RULES.md` as authoritative for mechanics and design intent.
- Use `docs/HOW_TO_PLAY.md` for the player-facing match flow.
- Do not invent or revise creative rules when those documents are silent; request
  creative direction in the related issue or pull request.

## Implementation expectations

- Work on a focused branch from `main` and link changes to an issue.
- Preserve deterministic behavior where tests provide a fixed match or dice seed.
- Use `logger.gd` instead of raw debug prints in gameplay code.
- Keep scenes thin when logic can live in a focused GDScript class.
- Revalidate game state when an action is confirmed; never trust stale UI state.
- Add or update GUT tests for behavior changes.

## Validation

Run the Godot 4.5 import, complete GUT suite, and main-scene smoke commands in the
README before opening a pull request. Pull requests run the same checks in GitHub
Actions.

Use Conventional Commits so Release Please can derive versions and release notes.
