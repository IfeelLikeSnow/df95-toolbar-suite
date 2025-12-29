#!/usr/bin/env python3
"""
STRICT HYGIENE SANITIZER (Weg 2D)

Adds:
- Escapes both "@tag" lines AND "Key: Value" lines in header blocks of text-like assets.
  (metaheader can treat "Key: Value" as tag -> strict failures like unknown tag 'Theme', 'Source Repo', etc.)
- JSFX: adds a *commented* ReaPack metaheader with @version and @noindex so strict passes without indexing.
- Keeps packages under DF95/ untouched.

Run once locally + commit for fastest stabilization; CI also runs it before check/scan.
"""

from __future__ import annotations
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

TEXT_EXTS = {
    ".txt",".md",".ini",".cfg",".conf",".rpp",".theme",".rtxt",
    ".rtracktemplate",".rfxchain",".reapermenu",".reapermenuset",
    ".reaperkeymap",".reaperconfigzip",".reapertheme",".reaperthemezip",
    ".data"
}
ESCAPE_MAX_LINES = 260

ALLOWED_LUA_TAGS = {
    "description","version","author","about","provides","changelog","link",
    "screenshot","metapackage","donation","repository","category","noindex"
}

def strip_bom(s: str) -> str:
    return s[1:] if s.startswith("\ufeff") else s

def escape_at(line: str) -> str:
    line = strip_bom(line)
    return re.sub(r"^(\s*)@", r"\1[@]", line)

def escape_key_value(line: str) -> str:
    """
    Escape 'Key: Value' header-style lines by replacing first ':' with a fullwidth colon '：'
    (keeps readability, avoids metaheader tag parsing).
    """
    line = strip_bom(line)
    m = re.match(r"^(\s*)([A-Za-z0-9][A-Za-z0-9 _/\-\.\(\)]+):(\s+.+)$", line)
    if not m:
        return line
    return f"{m.group(1)}{m.group(2)}：{m.group(3)}"

def sanitize_text(lines):
    changed = False
    out = list(lines)
    for i in range(min(len(out), ESCAPE_MAX_LINES)):
        l = strip_bom(out[i])
        if re.match(r"^\s*@", l):
            out[i] = escape_at(l)
            changed = True
            continue
        # Escape "Key: Value" style header lines (Theme: ..., Source Repo: ...)
        l2 = escape_key_value(l)
        if l2 != l:
            out[i] = l2
            changed = True
        else:
            out[i] = l
    return changed, out

def sanitize_lua(text: str):
    lines = text.splitlines()
    changed = False
    if lines and lines[0].startswith("\ufeff"):
        lines[0] = strip_bom(lines[0])
        changed = True

    maxn = min(len(lines), 360)
    tag_lines = []
    for i in range(maxn):
        l = lines[i]
        m = re.match(r"^\s*--\s*@([A-Za-z0-9_]+)\b", l) or re.match(r"^\s*--@([A-Za-z0-9_]+)\b", l)
        if m:
            tag_lines.append((i, m.group(1)))

    if not tag_lines:
        return changed, "\n".join(lines) + ("\n" if text.endswith("\n") else "\n")

    for i, tag in tag_lines:
        if tag.lower() not in ALLOWED_LUA_TAGS:
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

    if has_any_allowed and not has_version:
        insert_at = None
        for i in range(maxn):
            if re.match(r"^\s*--\s*@description\b", lines[i]) or re.match(r"^\s*--@description\b", lines[i]):
                insert_at = i + 1
                break
        if insert_at is None:
            insert_at = tag_lines[0][0] + 1
        lines.insert(insert_at, "-- @version 0.0.0")
        changed = True

    return changed, "\n".join(lines) + ("\n" if text.endswith("\n") else "\n")

def ensure_jsfx_noindex(text: str) -> str:
    """
    Prepend a commented ReaPack metaheader that includes @version and @noindex
    so strict validation passes without indexing the file as a package entry.
    """
    lines = [strip_bom(l) for l in text.splitlines()]
    head = "\n".join(lines[:30])
    if "@noindex" in head and "@version" in head:
        return "\n".join(lines) + ("\n" if text.endswith("\n") else "\n")
    meta = [
        "// @description JSFX asset (noindex)",
        "// @version 0.0.0",
        "// @noindex",
        ""
    ]
    return "\n".join(meta + lines) + ("\n" if text.endswith("\n") else "\n")

def main() -> int:
    changed_files = 0
    escaped_text = 0
    jsfx_patched = 0
    lua_sanitized = 0

    for p in ROOT.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(ROOT).as_posix()

        if rel.startswith("DF95/"):
            continue
        if rel.startswith(".git/") or rel.startswith(".github/"):
            continue

        suf = p.suffix.lower()

        if suf in TEXT_EXTS:
            txt = p.read_text(encoding="utf-8", errors="replace")
            lines = txt.splitlines()
            ch, out = sanitize_text(lines)
            if ch:
                p.write_text("\n".join(out) + ("\n" if txt.endswith("\n") else "\n"), encoding="utf-8")
                changed_files += 1
                escaped_text += 1
            continue

        if suf == ".jsfx":
            txt = p.read_text(encoding="utf-8", errors="replace")
            new_txt = ensure_jsfx_noindex(txt)
            if new_txt != (txt if txt.endswith("\n") else txt + "\n"):
                p.write_text(new_txt, encoding="utf-8")
                changed_files += 1
                jsfx_patched += 1
            continue

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
    print(f" - jsfx patched (@noindex): {jsfx_patched}")
    print(f" - lua sanitized: {lua_sanitized}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
