# Contributing to Violence of Action

Thank you for your interest in contributing to Violence of Action. The game is built with GDScript and Godot Engine 4.5.

Development takes place in the private [**GitcheGit**](https://git.gitchegumi.com/) repository hosted on Forgejo. The public GitHub repository is a downstream mirror and is not an accepted contribution channel.

Pull requests opened on GitHub will not be reviewed or merged.

## Contributor access

Violence of Action does not accept anonymous or unsolicited code contributions.

Contributors must request and receive access to the private GitcheGit repository before beginning work. Access is granted at the discretion of the project owner and may be limited or revoked at any time.

Before access is granted, contributors must read and explicitly agree to the Contributor Terms below.

Access to the repository does not guarantee that a proposed or completed contribution will be accepted.

### Private development materials

Access to unreleased source code, assets, builds, design documents, issues, discussions, and other non-public project material is provided solely for the purpose of contributing to Violence of Action.

Unless specifically authorized by the project owner, contributors may not publish, distribute, share, or use unreleased project material outside their work on Violence of Action.

These restrictions do not limit rights a contributor independently holds in material that has already been publicly released under the GPL or another applicable license.

## Contributor Terms

These terms apply to code, documentation, artwork, audio, designs, data, and other material intentionally submitted for inclusion in Violence of Action.

By receiving contributor access and submitting a contribution, you agree to the following:

1. **You retain ownership of your original contributions.**

2. **You grant Mathew Lindholm a perpetual, worldwide, non-exclusive, royalty-free, irrevocable, transferable, and sublicensable license to use, reproduce, modify, prepare derivative works from, distribute, publicly display, publicly perform, sublicense, and relicense your contributions.**

3. This license specifically includes the right to incorporate your contributions into:
   - GPL-licensed or otherwise open-source releases;
   - free or paid releases;
   - proprietary or commercially licensed versions of Violence of Action; and
   - future versions, expansions, ports, or derivative works of the project.

4. You understand that accepted contributions may therefore appear in a future proprietary or commercial version of Violence of Action without additional permission or compensation being required.

5. You represent that you have the legal right to submit your contribution and grant these rights. If an employer, client, or other party may own rights to your work, you are responsible for obtaining any necessary authorization before contributing.

6. Do not submit third-party code, assets, or other material unless its licensing terms have been disclosed and approved. In particular, do not introduce material whose license would prevent the project owner from exercising the relicensing rights described above.

7. Nothing in these terms prevents you from using your own original contribution elsewhere.

Contributor access will not be granted until these terms have been explicitly acknowledged in writing.

A contributor acknowledgement should identify the version of these terms being accepted, such as by repository commit hash or date.

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
6. Push the feature branch to GitcheGit and open a pull request targeting `dev`.
7. Link the relevant issue, describe the change and validation, and keep the issue checklist current for every completed item.

For example:

```bash
git switch dev
git pull --ff-only origin dev
git switch -c fix/short-description

# Conduct and validate the work, then commit it.

git push -u origin fix/short-description
```

After pushing, open the pull request in GitcheGit and target the `dev` branch.

The creative director batches `dev` into `main`; contributors do not open feature pull requests directly against `main` or merge `dev` into `main`.

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

Pull requests run a clean import, a cold-cache Windows release export, the complete GUT suite, and a headless main-scene smoke test on Godot 4.5. The export validator also has focused Python unit coverage.

Keep the scope focused and describe player-visible changes and known risks in the pull request.

## AI-assisted development

AI tools may be used, but contributors remain responsible for reviewing generated code, testing it, and confirming that it follows the game rules and project standards.

Contributors are also responsible for ensuring that AI-assisted work does not introduce copyrighted, proprietary, or otherwise restricted third-party material that they do not have the right to contribute under the Contributor Terms above.

## Releases

The Forgejo release workflow derives versions and release notes from Conventional Commits and maintains the root release pull request. Maintainers should follow the [release runbook](docs/RELEASE_RUNBOOK.md).

## Code of conduct

Treat contributors and reviewers with respect and professionalism.
