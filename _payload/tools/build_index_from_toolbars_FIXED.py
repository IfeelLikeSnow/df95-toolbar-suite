#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DF95 Toolbar Suite - Standalone ReaPack index builder (fixed)

Goals:
- Core package owns ALL scripts/resources (single ownership).
- Toolbar/MenuSet packages own ONLY toolbar/menu files.
- Toolbar/menu files are installed into REAPER's MenuSets/ (not under Scripts/),
  so users can import them easily in REAPER.
- All source URLs are URL-encoded (spaces/special chars) to avoid libcurl errors.

Usage (from repo root):
  python tools/build_index_from_toolbars.py

It writes: index.xml (in repo root)
Optional report: Reports/toolbar_menuset_map.md
"""
from __future__ import annotations

import os
import sys
import re
import xml.etree.ElementTree as ET
from datetime import datetime
from urllib.parse import quote
from pathlib import Path
from typing import Iterable, List, Tuple, Union, Optional, Dict

# -------------------------
# Config (edit if needed)
# -------------------------
REPO_NAME = "DF95 Toolbar Suite"
AUTHOR = "IfeelLikeSnow"
VERSION = "1.0.0"

RAW_BASE_DEFAULT = "https://raw.githubusercontent.com/IfeelLikeSnow/df95-toolbar-suite/main/"

# Core content roots (relative to repo root) that should be owned by Core package.
CORE_ROOTS = [
    "Scripts",
    "Data",
    "Effects",
    "FXChains",
    "Support",
    "TrackTemplates",
    "Projects",
    "Theme",
    "ThemeMod",
    "_selectors",
    "MenuSets",   # if you have this at root
    "Menus",      # if you have this at root
    "Toolbars",   # if you have this at root
    "Icons",      # if you have this at root
]

# Toolbar/MenuSet file extensions
MENUS_EXTS = (".ReaperMenuSet", ".Toolbar.ReaperMenu")

# Exclude patterns (relative posix paths)
EXCLUDE_RE = [
    re.compile(r"^\.git/"),
    re.compile(r"^\.github/"),
    re.compile(r"^Reports/"),
    re.compile(r"^tools?/"),  # keep tools out of install
    re.compile(r"^Tools/"),   # optional tooling
]

# -------------------------
# Helpers
# -------------------------
def repo_root_from_this_file() -> Path:
    # tools/build_index_from_toolbars.py -> repo root is parent of tools/
    p = Path(__file__).resolve()
    # if it's in tools/, go up one
    if p.parent.name.lower() in ("tools", "tool", "scripts", "util"):
        return p.parent.parent
    return p.parent

def to_posix_rel(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()

def is_excluded(rel_posix: str) -> bool:
    for rx in EXCLUDE_RE:
        if rx.search(rel_posix):
            return True
    return False

def iter_files_under(root: Path) -> Iterable[Path]:
    if not root.exists():
        return
    for p in root.rglob("*"):
        if p.is_file():
            yield p

def pretty_xml(elem: ET.Element) -> None:
    # Python 3.9+: ET.indent
    try:
        ET.indent(elem, space="  ")
    except Exception:
        pass

FileItem = Union[str, Tuple[str, str]]  # (target_install_path, repo_rel_path) or plain rel path

def add_pkg(category_el: ET.Element,
            name: str,
            desc: str,
            file_list: List[FileItem],
            raw_base: str,
            author: str = AUTHOR,
            version: str = VERSION) -> None:
    reapack_el = ET.SubElement(category_el, "reapack", attrib={"name": name, "type": "script"})
    ET.SubElement(reapack_el, "metadata").extend([
        ET.Element("version", text=version)  # placeholder; we set correctly below
    ])
    # metadata in proper form
    meta = reapack_el.find("metadata")
    meta.clear()
    ET.SubElement(meta, "description").text = desc
    ET.SubElement(meta, "author").text = author

    ver_el = ET.SubElement(reapack_el, "version", attrib={"name": version})
    ET.SubElement(ver_el, "time").text = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    for item in file_list:
        if isinstance(item, (tuple, list)) and len(item) == 2:
            target_path, repo_rel = item[0], item[1]
        else:
            target_path, repo_rel = item, item  # install where it is in repo (not recommended for menusets)

        src = ET.SubElement(ver_el, "source", attrib={"file": target_path})
        # URL-encode but keep slashes
        src.text = raw_base + quote(str(repo_rel), safe="/")

def classify_toolbar(rel_posix: str) -> str:
    # determine DF95 vs IFLS
    up = rel_posix.upper()
    if "/IFLS/" in up or up.startswith("IFLS_") or "/IFLS_" in up:
        return "IFLS"
    if "/DF95/" in up or up.startswith("DF95_") or "/DF95_" in up:
        return "DF95"
    # fallback: filename prefix
    fn = os.path.basename(rel_posix).upper()
    if fn.startswith("IFLS_"):
        return "IFLS"
    return "DF95"

def toolbar_pkg_name(rel_posix: str) -> str:
    # Use base filename without extension for unique package names
    base = os.path.basename(rel_posix)
    for ext in MENUS_EXTS:
        if base.endswith(ext):
            base = base[: -len(ext)]
            break
    return base

def build() -> Path:
    repo_root = repo_root_from_this_file()
    out_index = repo_root / "index.xml"
    raw_base = os.environ.get("REAPACK_RAW_BASE", RAW_BASE_DEFAULT).rstrip("/") + "/"

    # Collect all files for core (excluding MenuSets/toolbar files which will be owned by toolbar packages)
    core_files: List[str] = []
    menu_files: List[str] = []

    for root_rel in CORE_ROOTS:
        root = repo_root / root_rel
        for p in iter_files_under(root):
            rel = to_posix_rel(p, repo_root)
            if is_excluded(rel):
                continue
            if rel.endswith(MENUS_EXTS):
                menu_files.append(rel)
                continue
            core_files.append(rel)

    # If menu files live somewhere else, also find them globally
    for p in repo_root.rglob("*"):
        if not p.is_file():
            continue
        rel = to_posix_rel(p, repo_root)
        if is_excluded(rel):
            continue
        if rel.endswith(MENUS_EXTS) and rel not in menu_files:
            menu_files.append(rel)

    core_files = sorted(set(core_files))
    menu_files = sorted(set(menu_files))

    # Build XML
    idx = ET.Element("index", attrib={"version": "1"})
    # Root category
    root_cat = ET.SubElement(idx, "category", attrib={"name": REPO_NAME})

    cat_core = ET.SubElement(root_cat, "category", attrib={"name": "DF95/00 Core"})
    cat_df95 = ET.SubElement(root_cat, "category", attrib={"name": "DF95/10 Toolbars"})
    cat_ifls = ET.SubElement(root_cat, "category", attrib={"name": "IFLS/10 Toolbars"})

    add_pkg(
        cat_core,
        "Core scripts/resources used by toolbars",
        "Standalone Core: scripts, framework, data, effects. Install this FIRST.",
        core_files,
        raw_base,
    )

    # MenuSet install target: put into MenuSets/DF95 Toolbar Suite/<DF95|IFLS>/filename
    # This makes import in REAPER easy.
    report_lines = ["# DF95 Toolbar Suite – MenuSet install map", ""]
    for rel in menu_files:
        kind = classify_toolbar(rel)
        pkg = toolbar_pkg_name(rel)
        cat = cat_ifls if kind == "IFLS" else cat_df95

        fname = os.path.basename(rel)
        target = f"MenuSets/{REPO_NAME}/{kind}/{fname}"

        add_pkg(
            cat,
            f"{kind} – {pkg}",
            "Toolbar/MenuSet (requires Core). Import via Options → Customize menus/toolbars… → Import.",
            [(target, rel)],
            raw_base,
        )

        report_lines.append(f"- **{kind} – {pkg}**")
        report_lines.append(f"  - repo: `{rel}`")
        report_lines.append(f"  - install: `{target}`")
        report_lines.append("")

    pretty_xml(idx)
    ET.ElementTree(idx).write(out_index, encoding="utf-8", xml_declaration=True)

    # Write report
    reports_dir = repo_root / "Reports"
    reports_dir.mkdir(exist_ok=True)
    (reports_dir / "toolbar_menuset_map.md").write_text("\n".join(report_lines), encoding="utf-8")

    return out_index

def main() -> None:
    try:
        out = build()
        print(f"Wrote: {out}")
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        raise

if __name__ == "__main__":
    main()
