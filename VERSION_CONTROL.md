# History, backup and recovery

Keep this project in Git; commit code, briefs, catalog, Blender sources, exports and QA evidence together. Use `feature/<purpose>` branches, small reviewed commits, and pull requests for collaboration. Never commit credentials, node_modules, generated build places, temporary QA edits, machine-specific auth or production player data. Large evolving binary assets use Git LFS; verify remote LFS support before pushing.

Before major changes: cleanly identify existing changes; create a Git checkpoint; save a full Studio place to a versioned local file under `assets/scenes/<date>-<purpose>.rbxl` and save to the owner's Roblox place; run `tools/production/snapshot.ps1` for a Git bundle plus an archive of asset sources. Generated WorldBuilder geometry can be rebuilt, but imported/manual scenery and template bindings must also be saved/exported. A Rojo scripts build is not an authoritative Studio scene backup.

Private GitHub destination: WDMika/pooping-birds requested; creation/push is pending browser sign-in. Never report a cloud backup until the remote commit and asset objects are verified. After creation, configure `origin`, push main and LFS objects, then compare local HEAD with `git ls-remote origin refs/heads/main`. Keep the repository private and do not add collaborators or tokens without a specific request.

Rollback through `git revert <commit>` on a shared branch, or create a recovery branch at a known commit. Do not reset/discard user work. On a separate directory: clone/bundle clone → restore LFS or archived binary assets → restore the matching saved Studio scene → reconnect Rojo to the intended place → regenerate missing blockout → import versioned FBXs if needed → run static/Studio smoke checks. Record restored commit and scene version. Public release rollback also needs Roblox place-version selection and a compatible data schema; reverting code must not erase newer user data.

When Git identity is not configured, automation uses an explicit local `POOPING BIRDS Development` / `pooping-birds@local.invalid` attribution for the checkpoint, not an invented human identity. Set your preferred identity before personal commits. Local bundles are recovery copies, not off-machine backups.

Run `tools/production/verify-backup.ps1 -Snapshot <snapshot-directory>` to clone a bundle into a separate directory, restore materialized assets from the archive, compare every asset hash and run the development workflow check. This verifies local file recovery; the full Studio scene and live behavior still need the separate restore gate.
