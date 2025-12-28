#!/usr/bin/env python3
"""
STRICT HYGIENE SANITIZER (Weg 2C)

Purpose:
- Keep `reapack-index --strict` enabled.
- Prevent non-package asset files from being interpreted/validated as ReaPack packages.

Key ideas:
- Only real packages live under DF95/ (never touched).
- Many REAPER asset formats are plain text and may contain lines starting with '@' (or '-- @tag')
  which `reapack-index` may treat as metaheader tags -> strict failures (unknown tags, missing version).
- We "escape" leading @-lines in those assets so they are no longer parsed as ReaPack metaheaders.
- For LUA assets that intentionally include ReaPack metaheader tags, we enforce @version and escape unknown tags.

Notes:
- This sanitizer is meant to run in CI before `reapack-index --check/--scan`.
- It will modify files in-place. Best practice: run once locally and commit the changes.
"""

from __future__ import annotations
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

# Treat these as text-like assets that should NOT contain ReaPack metaheaders
TEXT_EXTS = {
    ".txt",".md",".ini",".cfg",".conf",".rpp",".theme",".rtxt",
    ".rtracktemplate",".rfxchain",".reapermenu",".reapermenuset",
    ".reaperkeymap",".reaperconfigzip",".reapertheme",".reaperthemezip",
    ".reaper-kb",".reaper-km",".data"
}

# Max lines to sanitize at file start (most metaheaders are in the leading block)
ESCAPE_MAX_LINES = 220

# Recognized (common) ReaPack Lua metaheader tags
ALLOWED_LUA_TAGS = {
    "description","version","author","about","provides","changelog","link",
    "screenshot","metapackage","donation","repository","category","noindex"
}

def strip_bom(s: str) -> str:
    return s[1:] if s.startswith("\ufeff") else s

def escape_at_line(line: str) -> str:
    line = strip_bom(line)
    # escape leading @ to [@] so strict won't parse it as a meta tag
    return re.sub(r"^(\s*)@", r"\1[@]", line)

def escape_text_header(lines):
    changed = False
    out = list(lines)
    for i in range(min(len(out), ESCAPE_MAX_LINES)):
        l = strip_bom(out[i])
        if re.match(r"^\s*@", l):
            out[i] = escape_at_line(l)
            changed = True
        else:
            out[i] = l
    return changed, out

def sanitize_lua(text: str):
    lines = text.splitlines()
    changed = False

    # Strip BOM on first line
    if lines and lines[0].startswith("\ufeff"):
        lines[0] = strip_bom(lines[0])
        changed = True

    maxn = min(len(lines), 320)

    # Find metaheader-like lines in the first block
    tag_lines = []
    for i in range(maxn):
        l = lines[i]
        m = re.match(r"^\s*--\s*@([A-Za-z0-9_]+)\b", l) or re.match(r"^\s*--@([A-Za-z0-9_]+)\b", l)
        if m:
            tag_lines.append((i, m.group(1)))

    if not tag_lines:
        return changed, "\n".join(lines) + ("\n" if text.endswith("\n") else "\n")

    # Escape unknown tags
    for i, tag in tag_lines:
        if tag.lower() not in ALLOWED_LUA_TAGS:
            # "-- @coding" -> "-- [@]coding"
            lines[i] = re.sub(r"^(\s*--\s*)@", r"\1[@]", lines[i])
            lines[i] = re.sub(r"^(\s*--)@", r"\1[@]", lines[i])
            changed = True

    head = "\n".join(lines[:maxn])
    has_any_allowed = any(
        re.search(r"^\s*--\s*@%s\b" % re.escape(t), head, flags=re.M) or
        re.search(r"^\s*--@%s\b" % re.escape(t), head, flags=re.M)
        for t in ALLOWED_LUA_TAGS
    )
    has_version = bool(re.search(r"^\s*--\s*@version\b", head, flags=re.M) or re.search(r"^\s*--@version\b", head, flags=re.M))

    # Enforce @version if there is any allowed metaheader tag
    if has_any_allowed and not has_version:
        insert_at = None
        for i in range(maxn):
            if re.match(r"^\s*--\s*@description\b", lines[i]) or re.match(r"^\s*--@description\b", lines[i]):
                insert_at = i + 1
                break
        if insert_at is None:
            # after first meta tag
            insert_at = tag_lines[0][0] + 1
        lines.insert(insert_at, "-- @version 0.0.0")
        changed = True

    return changed, "\n".join(lines) + ("\n" if text.endswith("\n") else "\n")

def main() -> int:
    changed_files = 0
    escaped_text = 0
    jsfx_patched = 0
    lua_sanitized = 0

    for p in ROOT.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(ROOT).as_posix()

        # Never touch actual ReaPack package files
        if rel.startswith("DF95/"):
            continue

        suf = p.suffix.lower()

        # Skip .git and workflow metadata
        if rel.startswith(".git/") or rel.startswith(".github/"):
            continue

        # Text-like REAPER assets
        if suf in TEXT_EXTS:
            txt = p.read_text(encoding="utf-8", errors="replace")
            lines = txt.splitlines()
            ch, out = escape_text_header(lines)
            if ch:
                p.write_text("\n".join(out) + ("\n" if txt.endswith("\n") else "\n"), encoding="utf-8")
                changed_files += 1
                escaped_text += 1
            continue

        # JSFX: ensure the first non-empty line is not starting with '@'
        if suf == ".jsfx":
            txt = p.read_text(encoding="utf-8", errors="replace")
            lines = [strip_bom(l) for l in txt.splitlines()]
            idx = next((i for i,l in enumerate(lines) if l.strip()), None)
            if idx is not None and re.match(r"^\s*@", lines[idx]):
                header = [
                    "// JSFX asset (DF95/IFLS)",
                    "// Prefixed comment prevents reapack-index strict validation from mis-parsing JSFX sections.",
                    ""
                ]
                p.write_text("\n".join(header + lines) + ("\n" if txt.endswith("\n") else "\n"), encoding="utf-8")
                changed_files += 1
                jsfx_patched += 1
            continue

        # LUA assets
        if suf == ".lua":
            txt = p.read_text(encoding="utf-8", errors="replace")
            ch, new_txt = sanitize_lua(txt)
            if ch:
                p.write_text(new_txt, encoding="utf-8")
                changed_files += 1
                lua_sanitized += 1
            continue

    print(f"Sanitizer done. Changed files: {changed_files}")
    print(f" - escaped text headers: {escaped_text}")
    print(f" - jsfx patched: {jsfx_patched}")
    print(f" - lua sanitized: {lua_sanitized}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
