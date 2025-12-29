#!/usr/bin/env python3
import os, re
from collections import defaultdict

TOOLBAR_EXTS = (".ReaperMenuSet", ".Toolbar.ReaperMenu", ".ReaperMenu")
SCRIPT_RE = re.compile(r'^\s*SCRIPT:\s*(.+?)\s*$', re.IGNORECASE)

def iter_toolbar_files(repo_root: str):
    for base in ("Menus", "MenuSets", "Toolbars"):
        d = os.path.join(repo_root, base)
        if not os.path.isdir(d):
            continue
        for dp, _, fns in os.walk(d):
            for fn in fns:
                if fn.endswith(TOOLBAR_EXTS):
                    yield os.path.join(dp, fn)

def parse_script_targets(toolbar_path: str):
    out = []
    with open(toolbar_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = SCRIPT_RE.match(line)
            if m:
                out.append(m.group(1).strip())
    return out

def normalize_target(t: str):
    t = t.replace("\\", "/")
    if t.lower().startswith("scripts/"):
        return t
    if os.path.basename(t).lower().startswith("ifls_"):
        return f"Scripts/IfeelLikeSnow/IFLS/{os.path.basename(t)}"
    return f"Scripts/IfeelLikeSnow/DF95/{os.path.basename(t)}"

def find_candidate_by_basename(repo_root: str, basename: str):
    scripts_root = os.path.join(repo_root, "Scripts")
    hits = []
    for dp, _, fns in os.walk(scripts_root):
        for fn in fns:
            if fn == basename:
                rel = os.path.relpath(os.path.join(dp, fn), repo_root).replace("\\", "/")
                if rel.startswith("Scripts/IfeelLikeSnow/"):
                    continue
                hits.append(rel)
    return hits

def write_shim(path_abs: str, target_rel: str, candidates: list):
    os.makedirs(os.path.dirname(path_abs), exist_ok=True)
    if len(candidates) == 1:
        real = candidates[0]
        code = f'''-- Auto-generated shim for toolbar compatibility
-- Toolbar target: "{target_rel}"
local real = reaper.GetResourcePath() .. "/Scripts/{real}"
dofile(real)
'''
    else:
        cand_lines = "\n".join([f"  - {c}" for c in candidates]) if candidates else "  (no candidates found)"
        code = f'''-- Auto-generated shim for toolbar compatibility
-- Toolbar target: "{target_rel}"
-- Could not uniquely resolve to a real script in this repo.
-- Candidates:
--{cand_lines}
reaper.ShowMessageBox("DF95 Toolbar Suite: Missing or ambiguous script target:\n{target_rel}\n\nSee Reports/unresolved_script_targets.md", "DF95 Toolbar Suite", 0)
'''
    with open(path_abs, "w", encoding="utf-8") as f:
        f.write(code)

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    unresolved = []
    created = 0
    seen = set()

    for tb in iter_toolbar_files(repo_root):
        for raw in parse_script_targets(tb):
            norm = normalize_target(raw)
            if norm in seen:
                continue
            seen.add(norm)

            abs_path = os.path.join(repo_root, norm)
            if os.path.exists(abs_path):
                continue

            basename = os.path.basename(norm)
            candidates = find_candidate_by_basename(repo_root, basename)
            write_shim(abs_path, norm, candidates)
            created += 1
            if len(candidates) != 1:
                unresolved.append((norm, tb, candidates))

    reports_dir = os.path.join(repo_root, "Reports")
    os.makedirs(reports_dir, exist_ok=True)
    rpt = os.path.join(reports_dir, "unresolved_script_targets.md")
    with open(rpt, "w", encoding="utf-8") as f:
        f.write("# Unresolved script targets referenced by toolbars\n\n")
        f.write(f"Total unresolved: **{len(unresolved)}**\n\n")
        for target, tb, cands in unresolved:
            f.write(f"## {target}\n")
            tb_rel = os.path.relpath(tb, repo_root).replace('\\\\','/')
            f.write(f"- Referenced in: `{tb_rel}`\n")
            f.write(f"- Candidates found: {len(cands)}\n")
            for c in cands[:30]:
                f.write(f"  - `{c}`\n")
            if len(cands) > 30:
                f.write(f"  - ... ({len(cands)-30} more)\n")
            f.write("\n")

    print(f"Shims created: {created}")
    print(f"Unresolved targets: {len(unresolved)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
