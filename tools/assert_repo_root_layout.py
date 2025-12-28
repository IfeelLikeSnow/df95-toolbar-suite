#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
needed = ["DF95", "Scripts", "Toolbars", "Menus", "MenuSets"]
missing = [n for n in needed if not (root/n).exists()]

# Common "nested repo" symptom: a single subfolder containing everything
nested_candidates = [p for p in root.iterdir() if p.is_dir() and (p/"DF95").exists() and (p/"Scripts").exists()]
if missing and nested_candidates:
    msg = [
        "Repository layout looks NESTED (one folder too deep).",
        "GitHub Actions runs from repo root; @provides paths must exist at root.",
        "",
        "Found candidate nested folder(s):",
        *[f" - {p.name}/" for p in nested_candidates],
        "",
        "Fix: move contents of that folder up to the repo root (where .git is), then delete the wrapper folder.",
    ]
    print("\n".join(msg))
    sys.exit(2)

if missing:
    print("Missing expected root folders: " + ", ".join(missing))
    sys.exit(2)

print("Repo root layout OK.")
sys.exit(0)
