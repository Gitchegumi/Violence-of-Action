# Violence of Action

Violence of Action is a local hot-seat, turn-based tactical battle game built with
Godot Engine 4.5.

For player controls and a complete match walkthrough, see
[How to Play](docs/HOW_TO_PLAY.md). For authoritative mechanics and design
specifications, see [Game Rules](docs/GAME_RULES.md).
Army-specific profiles and upgrade status are in the
[Army Codex](docs/ARMY_CODEX.md), and runtime ownership is documented in
[Architecture](docs/ARCHITECTURE.md).

## Requirements

- Godot Engine 4.5, standard (non-.NET) build
- Git
- Git LFS when working with editable files under `source-assets/`

## Setup

1. Clone the repository.
2. If you need editable source artwork, run `git lfs install` and
   `git lfs pull`. Runtime game assets do not require this step.
3. Open Godot 4.5 and import `project.godot` from the repository root.
4. Press F5 or use **Run Project** to launch the game.

## Command-line validation

Set the command path for your platform, then import resources, run all GUT tests,
and smoke-test the main scene.

### Windows PowerShell

```powershell
$godot = "C:\path\to\Godot_v4.5-stable_win64_console.exe"
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit
& $godot --headless --path . --quit-after 5
```

### Linux

```bash
godot --headless --path . --import
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit
godot --headless --path . --quit-after 5
```

Pull requests run the same validation with the pinned Godot 4.5 release.

## Local desktop exports

Install the matching Godot 4.5 export templates before exporting.

```powershell
& $godot --headless --path . --export-release "Windows x86_64" "build/windows/ViolenceOfAction.exe"
& $godot --headless --path . --export-release "Linux x86_64" "build/linux/ViolenceOfAction.x86_64"
```

Windows x86_64 and Linux x86_64 are the initial release targets. Mobile exports
are planned separately after the desktop release.

## Repository layout

```text
assets/          Runtime-imported images, audio, and data
source-assets/   Editable source artwork excluded from Godot imports
docs/            Rules, codex, architecture, guidance, and release operations
scenes/          Godot scenes
scripts/         GDScript source
tests/           GUT unit, integration, and UI tests
project.godot    Godot project configuration
```

See [Contributing](CONTRIBUTIONS.md) for branch, test, and commit expectations.
Release maintainers should use the [release runbook](docs/RELEASE_RUNBOOK.md).
