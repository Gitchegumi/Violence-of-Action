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

## Development

This project encourages a Test-Driven Development (TDD) approach for core game logic. For detailed development guidelines, including coding conventions, testing procedures, and contribution workflow, please refer to the [CONTRIBUTIONS.md](CONTRIBUTIONS.md) file.
