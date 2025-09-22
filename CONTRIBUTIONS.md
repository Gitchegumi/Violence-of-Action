# Contributing to Violence of Action

Thank you for your interest in contributing to Violence of Action! This document outlines the guidelines and best practices for contributing to this project.

## Technology Stack

Violence of Action is developed using the Godot Engine (primarily GDScript). All previous Python-based code has been or will be removed. Future development will focus solely on Godot for game logic, rendering, and UI/UX.

## Development Tools and AI Assistance

This project utilizes modern development tools and methodologies to enhance productivity and maintain quality:

### GitHub Spec Kit

We use [GitHub Spec Kit](https://github.com/gitchegumi/github-spec-kit) for structured project planning, specification management, and implementation workflows. This includes:

- Structured feature specifications and task breakdowns
- Constitution-based development principles
- Template-driven planning and implementation processes

### AI-Assisted Development

AI agents (including GitHub Copilot, Claude, Gemini, and others) are actively used throughout this project to assist with:

- Code generation and refactoring
- Documentation and specification writing  
- Test-driven development workflows
- Architecture planning and problem-solving

**Important for Contributors**: If you choose to use AI tools in your contributions, you are **required** to:

1. **Verify all generated code** thoroughly before submission
2. **Test your changes** to ensure they compile and function correctly
3. **Review AI-generated logic** for correctness and adherence to project standards
4. **Take full responsibility** for any code you submit, regardless of its origin

AI assistance is encouraged as a productivity tool, but human oversight and validation remain essential.

## Getting Started

Refer to the [README.md](README.md) for basic project setup.

### Developer Environment Setup

To ensure consistency across the project, please configure your development environment as follows:

- **Godot Version:** This project is developed using **Godot Engine version 4.4.1**. Please use this specific version to avoid compatibility issues. You can download it from the [Godot Engine website](https://godotengine.org/download/).

- **Editor Settings:** To maintain a consistent code style, please configure your Godot editor settings:
  1. Open the Godot Editor.
  2. Go to `Editor -> Editor Settings -> Text Editor`.
  3. **Indentation:**
     - Set `Indent With` to `Tabs`.
     - Set `Indent Size` to `4`.
  4. **Whitespace:**
     - Enable `Trim Trailing Whitespace On Save`.
  5. **Line Endings:**
     - Under `Files`, set `Line Endings` to `LF (Unix/macOS)`.

- **Editor Plugins:** (No required plugins at this time.)

## Development Workflow

We follow a feature branch workflow. All new features and bug fixes should be developed on a dedicated branch and submitted via a Pull Request to the `master` branch.

1. **Branching:** To start working on an issue, use the `gh issue develop` command. This command will create a new branch and link it to the issue. You can also use the `--checkout` flag to automatically switch to the new branch after creation.

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

2. **Code Style:** Please adhere to the existing code style and conventions found within the project. We aim for consistency and readability.

3. **Test-Driven Development (TDD):** For core game logic and mechanics, we encourage a Test-Driven Development (TDD) approach. Write your tests before writing the code they are meant to test.

   Instructions on how to run tests will be provided once a testing framework is integrated.

4. **Commit Messages:** Write clear, concise, and descriptive commit messages. A good commit message explains *why* the change was made, not just *what* was changed.

5. **Pull Requests:** Submit your changes via a Pull Request (PR) to the `master` branch. Ensure your PR description clearly explains the changes and links to the relevant issue(s) using keywords like `Closes #IssueNumber` or `Fixes #IssueNumber` so that the issue automatically closes when the PR is merged.

## Code of Conduct

We aim to foster an open and welcoming environment. Please treat all contributors with respect and professionalism.
