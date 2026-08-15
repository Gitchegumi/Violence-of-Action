# Repository Instructions

Violence of Action is a Godot 4.5, GDScript, local hot-seat tactics game. Treat
`docs/GAME_RULES.md` as the authority for universal mechanics,
`docs/HOW_TO_PLAY.md` as the authority for current controls, and
`docs/ARMY_CODEX.md` as the authority for army and unit design. Escalate any
creative choice those documents do not answer; do not invent rules, lore, art,
audio, names, balance values, or UX behavior.

## Workflow

1. Create a focused feature branch from the current `main` branch.
2. Conduct the work and validate it on that branch.
3. Open the pull request against `dev`, never directly against `main`.
4. The creative director handles batching and merging `dev` into `main`.

Use Conventional Commits. Link the owning issue and keep its checklist current,
checking only work that is complete and verified.

## Engineering standards

- Add or update GUT tests first for behavior changes. Run the complete import,
  GUT, and smoke commands in `README.md`; contribution details are in
  `CONTRIBUTIONS.md`.
- Keep scene responsibilities modular, signal ownership explicit, and state in
  its documented owner. Do not create monolith scripts or hidden global state.
- Use `GameLog` for gameplay diagnostics. Do not add raw gameplay `print()`
  calls. Inject random seeds so tests and reported matches are reproducible.
- Directly edit `.gd` source. Create or modify `.tscn` and `.tres` resources
  only through Godot-aware tooling, then validate imports and UID references.
- Godot MCP and other local tools are optional development aids, not runtime
  dependencies. The game must open and run in a standard Godot 4.5 install.
- A separate unit scene is justified only by a material node hierarchy, rig,
  collision, or behavior difference. Stats and artwork alone belong in a
  `UnitType` resource and use the shared `Unit` scene.

See `docs/ARCHITECTURE.md` for runtime ownership and data flow.
