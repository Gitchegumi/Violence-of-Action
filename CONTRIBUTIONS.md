# Contributing to Violence of Action

Thank you for contributing to Violence of Action. The game is built with GDScript
and Godot Engine 4.5.

## Development environment

- Install the standard (non-.NET) Godot 4.5 editor.
- Import `project.godot` from the repository root.
- Use tabs with a width of four for GDScript and LF line endings.
- Keep generated `.godot`, build, log, and editor temp files out of commits.

## Workflow

1. Create a focused feature or fix branch from `main`.
2. Add or update GUT tests for behavior changes.
3. Run the import, test, and smoke checks below.
4. Use a Conventional Commit message such as `fix(combat): prevent a second attack`.
5. Open a pull request targeting `dev` and link the relevant issue.

The creative director batches `dev` into `main`; contributors do not open
feature pull requests directly against `main`.

### Required validation

On Windows PowerShell, set `$godot` to the Godot 4.5 console executable:

```powershell
& $godot --headless --path . --import
& $godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit
& $godot --headless --path . --quit-after 5
```

On Linux:

```bash
godot --headless --path . --import
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit
godot --headless --path . --quit-after 5
```

Pull requests run the complete GUT suite and a headless main-scene smoke test on
Godot 4.5. Keep the scope focused and describe player-visible changes and known
risks in the pull request.

## AI-assisted development

AI tools may be used, but contributors remain responsible for reviewing generated
code, testing it, and confirming that it follows the game rules and project
standards.

## Releases

Release Please derives versions and release notes from Conventional Commits.
Maintainers should follow the [release runbook](docs/RELEASE_RUNBOOK.md).

## Code of conduct

Treat contributors and reviewers with respect and professionalism.
