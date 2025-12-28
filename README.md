# DF95 Toolbar Suite (Generated Repo)

This repository snapshot was generated from the `df95-ifls-full` repo and is focused on **toolbars + all scripts/resources they require**.

## Quick workflow

1. Install via ReaPack using `index.xml` (after you host this repo on GitHub).
2. In REAPER: `Options -> Customize menus/toolbars...` and import the desired `.ReaperMenuSet` from `Menus/` or `Toolbars/`.
3. If a toolbar button doesn't run, check `Reports/unresolved_script_targets.md`.

## Tools

- `tools/generate_shims_from_toolbars.py`: creates `Scripts/IfeelLikeSnow/...` shims so toolbar targets resolve.
- `tools/icon_report.py`: reports toolbar icon references.
- `tools/build_index_from_toolbars.py`: generates `index.xml` (no Ruby/reapack-index needed).
- `tools/resolve_missing_from_github.sh`: tries to fetch unresolved targets from upstream GitHub repos.

