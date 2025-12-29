# Root-path compatibility mirror

This repo includes a **compatibility mirror** of some folders at the repository root
(e.g. `Chains/`, `Menus/`, `MenuSets/`, `Toolbars/`, `Icons/`) copied from `_payload/...`.

Purpose: keep older `index.xml` / references working (pre-_payload layout), avoiding 404 downloads.

Long-term recommended approach:
- keep `_payload/...` as the canonical source
- update package `@provides` / regenerate `index.xml` so ReaPack uses `_payload/...`
- once migrated, you may delete the root mirrors.

