#!/usr/bin/env python3
"""
sanitize_metaheaders.py

Goal (Weg 2 / strict mode):
- Keep reapack-index --strict enabled
- Prevent non-package asset files from being interpreted as ReaPack package files
  by removing/escaping metaheader-like tags.

What it does:
1) For .txt/.md/.ini/.cfg/.conf files: escape any line starting with '@' in the first N lines.
2) For .jsfx: ensure the first non-empty line is NOT starting with '@' by prepending comment lines.
3) For .lua: if a file contains a metaheader with @description but missing @version, inject "@version 0.0.0"
   right after @description. (Strict mode requires version.)

It never touches package files under DF95/ (your actual ReaPack packages).
"""

from __future__ import annotations
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

TEXT_EXTS = {".txt",".md",".ini",".cfg",".conf",".rpp",".reapack-index.conf"}
ESCAPE_MAX_LINES = 120

def first_nonempty_idx(lines):
    for i,l in enumerate(lines):
        if l.strip():
            return i
    return None

def escape_at_lines(lines, max_lines=ESCAPE_MAX_LINES):
    changed = False
    for i in range(min(len(lines), max_lines)):
        if re.match(r"^\s*@", lines[i]):
            lines[i] = re.sub(r"^(\s*)@", r"\1[@]", lines[i])
            changed = True
    return changed, lines

def main() -> int:
    changed_files = 0
    injected_versions = 0
    escaped_text = 0
    jsfx_patched = 0

    for p in ROOT.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(ROOT).as_posix()

        # Never touch package files
        if rel.startswith("DF95/"):
            continue

        suf = p.suffix.lower()

        if suf in TEXT_EXTS or p.name.lower() in {"readme","readme.txt"}:
            txt = p.read_text(encoding="utf-8", errors="replace")
            lines = txt.splitlines()
            ch, new_lines = escape_at_lines(lines)
            if ch:
                p.write_text("\n".join(new_lines) + ("\n" if txt.endswith("\n") else "\n"), encoding="utf-8")
                changed_files += 1
                escaped_text += 1

        elif suf == ".jsfx":
            txt = p.read_text(encoding="utf-8", errors="replace")
            lines = txt.splitlines()
            idx = first_nonempty_idx(lines)
            if idx is not None and re.match(r"^\s*@", lines[idx]):
                header = [
                    "// JSFX asset (DF95/IFLS)",
                    "// Prefixed comment prevents reapack-index/metaheader strict validation from mis-parsing JSFX sections.",
                    ""
                ]
                p.write_text("\n".join(header + lines) + ("\n" if txt.endswith("\n") else "\n"), encoding="utf-8")
                changed_files += 1
                jsfx_patched += 1

        elif suf == ".lua":
            txt = p.read_text(encoding="utf-8", errors="replace")
            lines = txt.splitlines()
            head = "\n".join(lines[:200])

            has_desc = re.search(r"^\s*--\s*@description\b", head, flags=re.M)
            has_ver = re.search(r"^\s*--\s*@version\b", head, flags=re.M)

            if has_desc and not has_ver:
                for i in range(min(len(lines), 200)):
                    if re.match(r"^\s*--\s*@description\b", lines[i]):
                        lines.insert(i+1, "-- @version 0.0.0")
                        p.write_text("\n".join(lines) + ("\n" if txt.endswith("\n") else "\n"), encoding="utf-8")
                        changed_files += 1
                        injected_versions += 1
                        break

    print(f"Sanitizer done. Changed files: {changed_files}")
    print(f" - escaped text metaheaders: {escaped_text}")
    print(f" - jsfx patched: {jsfx_patched}")
    print(f" - lua versions injected: {injected_versions}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
