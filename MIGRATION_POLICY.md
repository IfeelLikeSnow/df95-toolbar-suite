# DF95 ReaPack Repository – Migration Policy (No-Uninstall, No-Breakage)

This policy is designed to prevent the two classic ReaPack disasters:
1) **Uninstall-on-sync** after a refactor/rename, and
2) Toolbars/menus breaking because actions disappear.

## The invariants (never break these)

### 1) Package IDs are immutable
In ReaPack, a package is identified by the **path of the package file inside the repo**.
Once published, these paths must never change:
- `DF95/00 Core/DF95 Toolbar Suite - Core.lua`
- `DF95/10 UI/DF95 Toolbar Suite - UI+Toolbars.data`
- (optional) `DF95/90 Legacy/DF95 Toolbar Suite - Legacy Compatibility.lua`

### 2) Target install paths are immutable
In `@provides` mappings, the right-hand side `> Target/Path` must never change once released.
Refactors happen only on the left side (inside `_payload/`).

### 3) One owner per target file
A given installed file must be provided by exactly one package.
If you split packages, give the new package its own **non-overlapping target root**.

## Allowed refactors (safe)

### A) Move/rename anything inside `_payload/`
As long as the **target side** stays stable (right side of `>`), you can reorganize `_payload/` freely.

### B) Add new files/targets (additive changes)
Adding new resources is safe. Prefer placing new content under existing stable target roots.

### C) Deprecate instead of delete
If an action/script was previously installed, avoid removing it.
Use a **tombstone** stub that displays a warning and forwards to the new action.

## Breaking changes (do only with a migration plan)

### A) Changing a target path
If you must change a target path:
1) Keep the old target file for at least 2 release cycles (stub/tombstone).
2) Introduce the new target in parallel.
3) Only then consider removing the old one (prefer never removing if toolbars depend on it).

### B) Splitting ownership
If files move from package A to package B, ReaPack may remove them during sync due to ownership changes.
Prefer:
- keeping legacy files owned by the original package, or
- moving only to a new unique target root that never existed before.

## Release checklist

- Run `reapack-index --check` locally (or rely on CI).
- Confirm:
  - no overlaps between packages' target paths,
  - no removed legacy entry points without a tombstone,
  - package files stayed in the same repo path.

## Recovery playbook (if someone already broke it)

- Recreate the missing targets (even as stubs) so toolbars/actions resolve.
- Restore the old package file paths if they moved.
- Publish a follow-up release that stabilizes targets and documents the change.
