# Violence of Action

A turn-based tactical battle game.

## Project Overview

This repository contains the source code for Violence of Action, a turn-based strategy game. This README focuses on setting up the development environment and running the game.

### From Pygame to Godot

Initially, Violence of Action was envisioned and prototyped using Pygame. However, due to the inherent challenges in developing complex UI/UX elements and managing intricate game states within Pygame, a strategic decision was made to transition the project to the Godot Engine. This shift occurred early in development, prior to any significant game logic or asset creation, to leverage Godot's robust tools for game development, particularly its scene-based architecture and integrated editor. Another key factor in choosing Godot was the Pythonic nature of GDScript, which provides a familiar and efficient scripting environment. All Python code will be removed as development progresses in Godot.

For detailed game rules, mechanics, and design specifications, please refer to the [Game Rules documentation](docs/GAME_RULES.md).

## Setup and Installation

1. Download and install the [Godot Engine](https://godotengine.org/download/) (version 4.x is recommended).
2. Clone this repository to your local machine.
3. Open the Godot Engine, click the "Import" button, and select the `project.godot` file from this repository's root directory.

## How to Run the Game

1. Open the project in the Godot Engine.
2. Press the "Play" button (or F5) in the top-right corner of the editor.

## Project Structure

```
/
├───.godot/              # Godot's internal project data.
├───assets/              # Game assets (images, sounds, data, etc.).
├───docs/                # Project documentation.
├───scenes/              # Godot scenes (.tscn files).
├───scripts/             # GDScript files (.gd files).
├───.gitignore           # Files and directories ignored by Git.
├───CONTRIBUTIONS.md     # Contribution guidelines.
├───project.godot        # The main Godot project file.
└───README.md            # This file.
```

## Development

This project encourages a Test-Driven Development (TDD) approach for core game logic. For detailed development guidelines, including coding conventions, testing procedures, and contribution workflow, please refer to the [CONTRIBUTIONS.md](CONTRIBUTIONS.md) file.