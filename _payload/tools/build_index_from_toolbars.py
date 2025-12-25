#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DF95 Toolbar Suite - ReaPack index builder (stand-alone layout)

Goals:
- Stand-alone: Core package owns ALL executable resources (Scripts/Data/FX/Selectors/etc.)
- Toolbar packages own ONLY MenuSet/Toolbar export files (no scripts) to avoid ReaPack ownership conflicts
- All <source> URLs are URL-encoded (spaces -> %20) to prevent libcurl "Malformed input" errors
- Optional report: list script targets referenced by toolbars (for auditing), but NOT packaged per-toolbar

Usage:
  python tools/build_index_from_toolbars.py
or:
  python build_index_from_toolbars.py   (if you keep it at repo root)

It writes ./index.xml by default.
"""

from __future__ import annotations

import os
import re
import sys
from datetime import datetime, timezone
from urllib.parse import quote
import xml.etree.ElementTree as ET
from pathlib import Path

# ----------------------------
# Config (edit to match repo)
# ----------------------------

REPO_NAME = "DF95 Toolbar Suite"
INDEX_NAME = "DF95 Toolbar Suite"
AUTHOR = "IfeelLikeSnow"

# IMPORTANT: must match your GitHub repo + branch
RAW_BASE = "https://raw.githubusercontent.com/IfeelLikeSnow/df95-toolbar-suite/main/"

# Package version (ReaPack uses this as the displayed version)
VERSION = "1.0.0"

# What goes into Core (stand-alone)
CORE_INCLUDE_DIRS = [
    "Scripts",
    "_selectors",
    "Data",
    "Effects",
    "FXChains",
    "Support",
    "TrackTemplates",
    "Projects",
    "Theme",
    "ThemeMod",
    "DF95_MetaCore",
    "Icons",
]

# Toolbars / Menu exports (these become their own small packages)
TOOLBAR_DIRS = [
    "Menus",
    "MenuSets",
    "Toolbars",
]

# Only these extensions belong in toolbar packages
TOOLBAR_EXTS = {".reapermenu", ".reapermenusets", ".reapermenuset"}  # handled case-insensitively
# Common actual extensions
# - .ReaperMenuSet
# - .Toolbar.ReaperMenu

# Optional: icons package paths (if you want separate icons package)
ICONS_INCLUDE_DIRS = [
    "Icons",
    "DF95_MetaCore/UI/Icons",
    "Data/toolbar_icons",
]

# Output paths
OUT_INDEX = "index.xml"
OUT_REPORT_DIR = "Reports"
OUT_TOOLBAR_TARGETS_REPORT = "Reports/toolbar_script_targets.md"

# ----------------------------
# Helpers
# ----------------------------

def to_posix_rel(p: Path, repo_root: Path) -> str:
    return p.relative_to(repo_root).as_posix()

def now_rfc3339_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

def is_toolbar_file(p: Path) -> bool:
    ext = p.suffix.lower()
    if ext in (".reapermenusets", ".reapermenuset", ".reapermenu"):
        return True
    # Handle weird double extensions like ".Toolbar.ReaperMenu"
    name_lower = p.name.lower()
    if name_lower.endswith(".toolbar.reapermenu"):
        return True
    if name_lower.endswith(".reapermenuset"):
        return True
    return False

SCRIPT_TARGET_RE = re.compile(r"^\s*SCRIPT:\s*(.+?)\s*$", re.IGNORECASE)

def parse_script_targets_from_toolbar(toolbar_path: Path) -> list[str]:
    """Extract 'SCRIPT: ...' lines (best effort)."""
    targets: list[str] = []
    try:
        txt = toolbar_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return targets
    for line in txt.splitlines():
        m = SCRIPT_TARGET_RE.match(line)
        if not m:
            continue
        target = m.group(1).strip()
        if target:
            targets.append(target)
    return targets

def url_for_source(raw_base: str, rel_posix_path: str) -> str:
    # Encode spaces/special chars but keep slashes
    return raw_base + quote(rel_posix_path, safe="/")

def add_pkg(category_el: ET.Element, name: str, desc: str, rel_files: list[str], raw_base: str) -> None:
    reapack = ET.SubElement(category_el, "reapack", attrib={"name": name, "type": "script"})
    ET.SubElement(reapack, "metadata").append(ET.Element("author", text=AUTHOR))  # placeholder; we will fix below

    # xml.etree doesn't support setting element text via constructor above, so fix it:
    md = reapack.find("metadata")
    # clear any children created oddly
    for child in list(md):
        md.remove(child)
    a = ET.SubElement(md, "author")
    a.text = AUTHOR

    v_el = ET.SubElement(reapack, "version", attrib={"name": VERSION, "time": now_rfc3339_utc()})

    d = ET.SubElement(v_el, "desc")
    d.text = desc

    # Ensure deterministic ordering
    for rel in sorted(set(rel_files)):
        s = ET.SubElement(v_el, "source", attrib={"file": rel})
        s.text = url_for_source(raw_base, rel)

def collect_files_under(repo_root: Path, rel_dir: str) -> list[str]:
    base = repo_root / rel_dir
    if not base.exists():
        return []
    rels: list[str] = []
    for p in base.rglob("*"):
        if p.is_file():
            rels.append(to_posix_rel(p, repo_root))
    return rels

def collect_toolbar_files(repo_root: Path) -> list[str]:
    rels: list[str] = []
    for d in TOOLBAR_DIRS:
        base = repo_root / d
        if not base.exists():
            continue
        for p in base.rglob("*"):
            if p.is_file() and is_toolbar_file(p):
                rels.append(to_posix_rel(p, repo_root))
    return sorted(set(rels))

def write_toolbar_targets_report(repo_root: Path, toolbar_rel_paths: list[str]) -> None:
    report_dir = repo_root / OUT_REPORT_DIR
    report_dir.mkdir(parents=True, exist_ok=True)
    out = repo_root / OUT_TOOLBAR_TARGETS_REPORT

    lines = []
    lines.append(f"# Toolbar script targets report ({INDEX_NAME})")
    lines.append("")
    lines.append(f"Generated: {now_rfc3339_utc()}")
    lines.append("")
    lines.append("This report lists `SCRIPT:` targets found in toolbar/menu export files. These targets are **not** packaged per-toolbar (to avoid ReaPack ownership conflicts). They are expected to be provided by the **Core** package.")
    lines.append("")

    total = 0
    for rel in toolbar_rel_paths:
        abs_p = repo_root / rel
        targets = parse_script_targets_from_toolbar(abs_p)
        if not targets:
            continue
        total += len(targets)
        lines.append(f"## {rel}")
        lines.append("")
        for t in targets:
            lines.append(f"- `{t}`")
        lines.append("")
    lines.append(f"Total targets found: **{total}**")
    out.write_text("\n".join(lines), encoding="utf-8")

def indent(elem: ET.Element, level: int = 0) -> None:
    # Pretty-print helper for xml.etree
    i = "\n" + level * "  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        for e in elem:
            indent(e, level + 1)
        if not e.tail or not e.tail.strip():
            e.tail = i
    if level and (not elem.tail or not elem.tail.strip()):
        elem.tail = i

def main() -> int:
    repo_root = Path(__file__).resolve().parent
    # If this file is stored in tools/, repo root is parent
    if (repo_root / ".git").exists() is False and (repo_root.parent / ".git").exists():
        repo_root = repo_root.parent

    # Build index
    idx = ET.Element("index", attrib={"name": INDEX_NAME})

    # Core category/package
    cat_core = ET.SubElement(idx, "category", attrib={"name": "DF95/00 Core"})
    core_files: list[str] = []
    for d in CORE_INCLUDE_DIRS:
        core_files.extend(collect_files_under(repo_root, d))
    add_pkg(
        cat_core,
        f"{REPO_NAME} – Core (Standalone)",
        "Standalone core: Scripts + framework + resources (install this first).",
        core_files,
        RAW_BASE,
    )

    # Icons package (optional but useful) – keep it separate if paths exist
    icon_files: list[str] = []
    for d in ICONS_INCLUDE_DIRS:
        icon_files.extend(collect_files_under(repo_root, d))
    # Only create if there are any icon files not already in core (avoid duplicates)
    icon_only = sorted(set(icon_files) - set(core_files))
    if icon_only:
        cat_icons = ET.SubElement(idx, "category", attrib={"name": "DF95/90 Icons"})
        add_pkg(
            cat_icons,
            f"{REPO_NAME} – Icons",
            "Optional: toolbar/icon assets.",
            icon_only,
            RAW_BASE,
        )

    # Toolbar packages: menu files only
    toolbar_rel_paths = collect_toolbar_files(repo_root)

    cat_tb_df95 = ET.SubElement(idx, "category", attrib={"name": "DF95/10 Toolbars"})
    cat_tb_ifls = ET.SubElement(idx, "category", attrib={"name": "IFLS/10 Toolbars"})

    for rel in toolbar_rel_paths:
        base = Path(rel).name
        pkg_name = os.path.splitext(base)[0]
        # crude routing: IFLS if folder or name hints it
        upper = rel.upper()
        cat = cat_tb_ifls if ("IFLS" in upper) else cat_tb_df95

        add_pkg(
            cat,
            pkg_name,
            "Toolbar/MenuSet only (requires Core installed first). Import via REAPER: Options → Customize menus/toolbars → Import.",
            [rel],
            RAW_BASE,
        )

    # Write audit report of script targets in toolbars (optional)
    try:
        write_toolbar_targets_report(repo_root, toolbar_rel_paths)
    except Exception as e:
        print(f"warning: failed to write toolbar targets report: {e}", file=sys.stderr)

    # Write index.xml
    indent(idx)
    out_path = repo_root / OUT_INDEX
    ET.ElementTree(idx).write(out_path, encoding="utf-8", xml_declaration=True)
    print(f"Wrote {out_path}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
