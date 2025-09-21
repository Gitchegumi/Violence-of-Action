# Violence of Action (Godot Game)

This file expands the global GEMINI.md to provide additional context for the _Violence of Action_ project – a 2D/3D turn-based tactical game developed in Godot.

## 🎓 Project Overview

- **Engine**: Godot 4.x
- **Language**: GDScript
- **Structure**: Scene-based architecture with modular logic
- **Focus**: Tactical gameplay, terrain interaction, unit management

## ⚡ Gemini Tasks Allowed

- Suggest refactors or break up large GDScript files
- Auto-generate tooltips, HUD elements, or input signal hooks
- Explain scene tree behaviors or node signal connections
- Help structure reusable scripts for units, terrain, and combat
- Give suggestions for nodes to add the the scene tree
- Give suggestions for signals to connect when appropriate
- Only directly edit `.gd` files

## ⛔ Gemini Must Not:

- Modify `project.godot` or `.import/` directories
- Do not modify `.tscn` files directly
- Do not modify `.tres` files directly
- Do not modify any file that is not a `.gd` file without being asked to
- Overwrite user-authored shader code unless explicitly asked
- Suggest monetization or distribution plans

## 📓 Key Structure

- `scenes/`: Main gameplay scenes (battlefield, HUD, units)
- `scripts/`: All GDScript files for logic
- `assets/`: Sprites, tilesets, audio, data
- `docs/`: Design notes and gameplay rules
