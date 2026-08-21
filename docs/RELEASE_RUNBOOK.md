# Release Runbook

Violence of Action uses one repository-wide Semantic Version and one immutable
`v<version>` tag. The private Forgejo repository is the release control plane.
GitHub is a public, player-facing mirror of the tag and already-tested release
bytes; it does not calculate versions, create authoritative tags, or rebuild the
game.

The initial release targets are Windows x86_64 and Linux x86_64. Mobile
distribution is intentionally deferred.

## Versioning mechanism

The repository-owned `scripts/ci/release_tool.py` replaces the hosted Release
Please action while preserving the existing manifest release model:

- Conventional Commits since the latest root tag determine the next version.
- A breaking change bumps the major version, `feat` bumps minor, and `fix` or
  `perf` bumps patch.
- The helper updates `CHANGELOG.md`, `.release-please-manifest.json`, and the
  marked `config/version` entry in `project.godot` together.
- Forgejo Actions pushes the generated
  `release-please--branches--main--components--violence-of-action` branch and
  creates or updates one release pull request against `main` through Forgejo's
  API.
- After that pull request is merged, the workflow validates the three version
  sources and creates the single root tag at the exact merge commit.

Release Please's CLI accepts alternate REST and GraphQL URLs, but its provider
still expects GitHub API behavior. Forgejo 15.0.7 is not a compatible GitHub API
or GraphQL endpoint for that provider. The local helper keeps version selection
inside the canonical repository and uses only Forgejo's documented pull-request
API for orchestration.

## One-time repository setup

### Runners

The release workflow requires both labels below:

- `docker`: Linux container runner used for orchestration, authenticated Godot
  downloads, imports, both exports, Linux smoke testing, checksums, and
  publication. The runner inventory on 2026-08-21 contained the repository
  runner `media-server-voa` with this label.
- `windows`: native Windows runner used only to download and execute the exact
  Windows archive built by the `docker` job. It must provide PowerShell and the
  Node runtime required by the pinned artifact action.

A release cannot publish while either smoke job is missing or unsuccessful.
Register the Windows runner before attempting a production release; do not map
the `windows` label to a Linux container or Wine environment.

### Secrets and permissions

Configure these repository Actions secrets:

- `FORGEJO_RELEASE_TOKEN`: a repository-scoped Forgejo token able to push the
  release branch/tag, create or update a pull request, and publish a release.
- `GITHUB_MIRROR_TOKEN`: a fine-grained GitHub token restricted to
  `Gitchegumi/Violence-of-Action` with Contents read/write permission.

Default workflow permissions are read-only. The orchestration job alone receives
contents and pull-request write permission, and the final publication job alone
receives contents write permission. Secrets are passed through environment or
action inputs and are never placed in command-line URLs.

Protect `main` normally while allowing the release identity to open its generated
pull request. Do not grant either token organization-wide administration.

## Normal release

1. Merge Conventional Commit work through `dev`, then promote `dev` into `main`
   according to the repository workflow.
2. The Forgejo **Release** workflow evaluates commits since the latest tag. If no
   `feat`, `fix`, `perf`, or breaking commit exists, it exits without a release.
3. The workflow creates or updates the release pull request containing the
   changelog, manifest, and Godot project version.
4. Review the generated notes, matching versions, and normal Forgejo CI result.
5. Merge the release pull request into `main`.
6. The next Release workflow run creates the immutable tag, checks it out by
   exact commit, authenticates Git LFS and Godot downloads, builds both archives,
   and smoke-tests the archives on their native operating systems.
7. Only after both smoke jobs pass, the publication job generates and verifies
   `SHA256SUMS.txt`, publishes the canonical Forgejo release, verifies the same
   commit exists in GitHub, creates the matching GitHub tag, and uploads the same
   bytes:

   - `violence-of-action-v<version>-windows-x86_64.zip`
   - `violence-of-action-v<version>-linux-x86_64.zip`
   - `SHA256SUMS.txt`

Every external action is pinned to an immutable commit. Godot editor and export
template archives are checked against the official SHA-512 values before they
are extracted or executed on a cache miss.

## Verification

Before announcing a release:

1. Confirm both archives and `SHA256SUMS.txt` are attached to the Forgejo release
   and the GitHub mirror release.
2. Run `sha256sum -c SHA256SUMS.txt` on the downloaded files. On Windows, compare
   `Get-FileHash -Algorithm SHA256` output with the file.
3. Confirm the Forgejo and GitHub tags resolve to the commit recorded in the
   release workflow.
4. Confirm the two host downloads have the SHA-256 values recorded by the
   workflow.
5. Review the Windows and Linux smoke-job logs. For a production sign-off, also
   extract each archive, confirm the main menu loads, and complete a short
   deployment and combat smoke test on each platform.

Workflow artifacts are retained for three days for diagnosis. They are not a
distribution surface.

## Recovery

Use recovery only for packaging or publication failures after an immutable tag
has been created:

1. Fix the workflow on a feature branch and promote the fix to `main`.
2. In Forgejo Actions, open **Release**, choose **Run workflow**, enter the
   existing tag, and set **Explicitly replace assets** to `true`.
3. The workflow checks out the existing tag, verifies that its target and all
   version files still agree, rebuilds both archives from that tag, repeats both
   native smoke tests, regenerates the checksums, and explicitly replaces assets
   on Forgejo and GitHub.

The dispatch never moves or recreates the tag. Leaving the replacement input
disabled makes an existing-asset collision fail instead of silently overwriting
a published file. A missing archive, version mismatch, tag mismatch, failed
smoke test, or failed checksum stops publication.

## Rollback and yank

- Never move, delete, or reuse a published version tag to correct game code.
  Revert the faulty change and publish a new patch release.
- To yank a dangerous binary, mark both host releases as drafts or remove their
  assets through the host interfaces, record the reason in the owning issue, and
  immediately prepare a patch. Keep the immutable tags for auditability.
- If only release notes are wrong, edit the notes on both hosts without replacing
  verified artifacts.
- If GitHub mirroring fails after Forgejo publication, leave Forgejo canonical,
  repair the mirror problem, and run recovery for the same tag with replacement
  enabled.

## Credential rotation

Rotate either token immediately after suspected disclosure and on the regular
maintainer schedule:

1. Create the replacement with the same narrow repository scope.
2. Replace the corresponding Forgejo Actions secret.
3. Run a non-destructive release-PR orchestration check or a prerelease recovery
   test.
4. Revoke the old token after the new credential is verified.

Do not paste tokens into workflow inputs, issue comments, command arguments, or
logs.
