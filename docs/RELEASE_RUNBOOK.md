# Release Runbook

Violence of Action uses Release Please and Semantic Versioning for its `0.x` MVP
releases. The initial automated release targets are Windows x86_64 and Linux
x86_64. Mobile distribution is intentionally deferred.

## One-time repository setup

1. Keep GitHub Actions enabled with read/write workflow permissions.
2. Create a fine-grained personal access token or GitHub App token that can write
   repository contents and pull requests.
3. Save it as the repository Actions secret `RELEASE_PLEASE_TOKEN`.
4. If `main` is protected, allow the release automation identity to open release
   pull requests while retaining required CI and review rules.

The release workflow falls back to `GITHUB_TOKEN`, but pull requests created with
that token do not trigger other GitHub Actions workflows. Configure
`RELEASE_PLEASE_TOKEN` so the release pull request receives the normal Godot CI
checks.

## Creating a release

1. Merge Conventional Commit pull requests into `main`.
2. Release Please opens or updates a release pull request containing the version,
   manifest, and changelog changes.
3. Review the generated notes and confirm the Godot CI check passes.
4. Merge the release pull request.
5. The release workflow creates the tag and GitHub release, exports both desktop
   builds with Godot 4.5, smoke-tests each executable on its target operating
   system, and uploads:
   - `violence-of-action-v<version>-windows-x86_64.zip`
   - `violence-of-action-v<version>-linux-x86_64.zip`
   - `SHA256SUMS.txt`

The workflow uses official Godot editor and export-template archives and pins all
third-party GitHub Actions to immutable commits.

## Verification

Before announcing a release:

1. Confirm both archives and `SHA256SUMS.txt` are attached to the GitHub release.
2. Verify the checksums with `sha256sum -c SHA256SUMS.txt` on Linux or compare
   `Get-FileHash -Algorithm SHA256` output on Windows.
3. Extract and launch the Windows build on Windows and the Linux build on Linux.
4. Confirm the main menu loads and complete a short deployment and combat smoke
   test on each platform.

## Recovery

- If a release build, smoke test, or upload fails because of the workflow, fix the
  workflow on a feature branch and merge that fix into `main`.
- In GitHub Actions, open the **Release** workflow, choose **Run workflow**, select
  `main`, and enter the existing immutable release tag (for example `v0.1.0`).
- The recovery run verifies that the GitHub release exists, checks out the game
  source at that tag, rebuilds both archives, smoke-tests them on Windows and
  Linux, regenerates `SHA256SUMS.txt`, and replaces the release assets with
  `gh release upload --clobber`.
- A recovery run changes artifacts only. It does not move the tag or rebuild from
  the newer `main` source.
- Do not reuse or move a published version tag. Publish a patch release for code
  changes.
- If release notes alone are wrong, edit the GitHub release text without replacing
  verified build artifacts.
