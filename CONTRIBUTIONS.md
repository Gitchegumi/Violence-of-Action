# Contributing to Violence of Action

Thank you for your interest in contributing to Violence of Action! This document outlines the guidelines and best practices for contributing to this project.

## Technology Stack

Violence of Action is developed using the Godot Engine (primarily GDScript). All previous Python-based code has been or will be removed. Future development will focus solely on Godot for game logic, rendering, and UI/UX.

## Getting Started

Refer to the [README.md](README.md) for basic project setup.

## Development Workflow

We follow a feature branch workflow. All new features and bug fixes should be developed on a dedicated branch and submitted via a Pull Request to the `master` branch.

1.  **Branching:** To start working on an issue, use the `gh issue develop` command. This command will create a new branch and link it to the issue. You can also use the `--checkout` flag to automatically switch to the new branch after creation.
    ```bash
    gh issue develop <issue-number> [--checkout]
    ```
    By default, `gh` will generate a branch name like `your-username/issue-123-issue-title`. If you wish to specify a custom branch name (e.g., `<function-label>/<issue-title-slug>`), you can use the `--name` flag:
    ```bash
    gh issue develop <issue-number> --name "<function-label>/<issue-title-slug>" [--checkout]
    ```
    For example, to work on issue #17 "Define game rules" and name the branch `docs/define-game-rules`, you would run:
    ```bash
    gh issue develop 17 --name "docs/define-game-rules" --checkout
    ```
    This branch is automatically associated with the issue, which helps with linking Pull Requests and closing issues upon merge.

2.  **Code Style:** Please adhere to the existing code style and conventions found within the project. We aim for consistency and readability.

3.  **Test-Driven Development (TDD):** For core game logic and mechanics, we encourage a Test-Driven Development (TDD) approach. Write your tests before writing the code they are meant to test.

    Instructions on how to run tests will be provided once a testing framework is integrated.

4.  **Commit Messages:** Write clear, concise, and descriptive commit messages. A good commit message explains *why* the change was made, not just *what* was changed.

5.  **Pull Requests:** Submit your changes via a Pull Request (PR) to the `master` branch. Ensure your PR description clearly explains the changes and links to the relevant issue(s) using keywords like `Closes #IssueNumber` or `Fixes #IssueNumber` so that the issue automatically closes when the PR is merged.

## Code of Conduct

We aim to foster an open and welcoming environment. Please treat all contributors with respect and professionalism.
