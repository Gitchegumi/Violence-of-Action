# Source assets

Editable production files live here so Godot does not import them as runtime
resources. Export only the game-ready images needed by scenes into `assets/`.
The Affinity and Illustrator sources are Git LFS objects. Before working with
them, install Git LFS and retrieve the objects:

```text
git lfs install
git lfs pull
```

Future high-fidelity audio sources use Git LFS. The existing title-theme WAV is
an explicit exception because it predates LFS and already exists as a regular
Git blob in repository history. It is retained under `source-assets/audio/`,
ignored by Godot, and deferred to GitHub issue #104.

Do not add new visual assets or change their creative direction without an owned
issue and creative-director approval.
