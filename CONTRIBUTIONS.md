# Contributing to Violence of Action

Thank you for contributing to Violence of Action. The game is built with GDScript
and Godot Engine 4.5.

## Development environment

- Install the standard (non-.NET) Godot 4.5 editor.
- Import `project.godot` from the repository root.
- Use tabs with a width of four for GDScript and LF line endings.
- Keep generated `.godot`, build, log, and editor temp files out of commits.

## Workflow

1. Update your local `dev` branch from `origin/dev`.
2. Create a focused feature or fix branch from `dev`, never from `main`.
3. Add or update GUT tests for behavior changes.
4. Run the import, test, and smoke checks below.
5. Use a Conventional Commit message such as `fix(combat): prevent a second attack`.
6. Push the feature branch and open a pull request targeting `dev`.
7. Link the relevant issue, describe the change and validation, and keep the
   issue checklist current for every completed item.

For example:

```bash
git switch dev
git pull --ff-only origin dev
git switch -c fix/short-description
# Conduct and validate the work, then commit it.
git push -u origin fix/short-description
gh pr create --base dev
```

The creative director batches `dev` into `main`; contributors do not open
feature pull requests directly against `main` or merge `dev` into `main`.

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
