# GitchPygame Hex Battle

A turn-based tactical battle game built with Pygame.

## Project Overview

This repository contains the source code for GitchPygame Hex Battle (working title), a turn-based strategy game. This README focuses on setting up the development environment and running the game.

For detailed game rules, mechanics, and design specifications, please refer to the [Game Rules documentation](docs/GAME_RULES.md).

## Setup and Installation

This project uses [Poetry](https://python-poetry.org/) for dependency management. If you don't have Poetry installed, please follow the official installation instructions: [Poetry Installation Guide](https://python-poetry.org/docs/#installation).

Once Poetry is installed, navigate to the project root directory and run the following command to install all dependencies:

```bash
poetry install
```

This will create a virtual environment and install all required packages.

## How to Run the Game

After setting up the project with Poetry (as described in the 'Setup and Installation' section), you can run the game using the following command from the project root directory:

```bash
poetry run python gitchpygame/main.py
```

This command activates the Poetry virtual environment and executes the main game script.

## Project Structure

```
E:/GitHub/GitchPygame/
├───.git/                      # Git version control directory (managed by Git).
├───.venv/                     # Python virtual environment (managed by Poetry).
├───.gitignore                 # Specifies intentionally untracked files to ignore.
├───CONTRIBUTIONS.md           # Guidelines for contributing to the project.
├───poetry.lock                # Locks the exact versions of dependencies used by Poetry.
├───poetry.toml                # Poetry configuration file.
├───pyproject.toml             # Project configuration, including Poetry dependencies and project metadata.
├───README.md                  # This file.
├───docs/                      # Documentation directory.
│   └───GAME_RULES.md          # Detailed game rules and mechanics.
└───gitchpygame/               # Main source code directory for the game.
    ├───__init__.py            # Marks the gitchpygame directory as a Python package.
    ├───main.py                # The main entry point for running the game.
    ├───assets/                # Contains game assets and data.
    │   └───data/              # Data files for game configuration.
    │       ├───config.json    # Game configuration settings.
    │       ├───settings.json  # User settings or game specific settings.
    │       ├───terrain.json   # Defines terrain types and properties.
    │       └───units/         # Directory containing individual unit data files.
    │           └───The_Coreborn/ # Data for The Coreborn army.
    ├───core/                  # Core game logic and components.
    │   ├───__init__.py        # Marks the core directory as a Python package.
    │   ├───board.py           # Handles game board generation and manipulation.
    │   ├───game.py            # Manages overall game state and flow.
    │   ├───tiles.py           # Defines tile properties and interactions.
    │   └───units.py           # Manages unit properties, actions, and interactions.
    └───tests/                 # Unit and integration tests for the game.
        ├───__init__.py        # Marks the tests directory as a Python package.
        └───unit_tests.py      # Python code unit tests.
```

## Development

This project encourages a Test-Driven Development (TDD) approach for core game logic. For detailed development guidelines, including coding conventions, testing procedures, and contribution workflow, please refer to the [CONTRIBUTIONS.md](CONTRIBUTIONS.md) file.
