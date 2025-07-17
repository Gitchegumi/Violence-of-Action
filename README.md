# Violence of Action

A turn-based tactical battle game.

## Project Overview

This repository contains the source code for Violence of Action, a turn-based strategy game. This README focuses on setting up the development environment and running the game.

### From Pygame to Godot

Initially, Violence of Action was envisioned and prototyped using Pygame. However, due to the inherent challenges in developing complex UI/UX elements and managing intricate game states within Pygame, a strategic decision was made to transition the project to the Godot Engine. This shift occurred early in development, prior to any significant game logic or asset creation, to leverage Godot's robust tools for game development, particularly its scene-based architecture and integrated editor. Another key factor in choosing Godot was the Pythonic nature of GDScript, which provides a familiar and efficient scripting environment. All Python code will be removed as development progresses in Godot.

For detailed game rules, mechanics, and design specifications, please refer to the [Game Rules documentation](docs/GAME_RULES.md).

## Setup and Installation

(Instructions for setting up the Godot project will go here.)

## How to Run the Game

(Instructions for running the Godot game will go here.)

## Project Structure

```
E:/GitHub/ViolenceOfAction/
├───.git/                      # Git version control directory (managed by Git).
├───docs/                      # Documentation directory.
│   └───GAME_RULES.md          # Detailed game rules and mechanics.
├───assets/                    # Game assets (images, sounds, etc.)
├───scenes/                    # Godot scenes
├───scripts/                   # Godot scripts (GDScript or C#)
└───project.godot              # Godot project file
```

## Development

This project encourages a Test-Driven Development (TDD) approach for core game logic. For detailed development guidelines, including coding conventions, testing procedures, and contribution workflow, please refer to the [CONTRIBUTIONS.md](CONTRIBUTIONS.md) file.