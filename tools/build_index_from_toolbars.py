#!/usr/bin/env python3
import os, re, time
import xml.etree.ElementTree as ET

TOOLBAR_EXTS = (".ReaperMenuSet", ".Toolbar.ReaperMenu", ".ReaperMenu")
SCRIPT_RE = re.compile(r'^\s*SCRIPT:\s*(.+?)\s*$', re.IGNORECASE)

def iter_toolbar_files(repo_root: str):
    for base in ("Menus","MenuSets","Toolbars"):
        d=os.path.join(repo_root, base)
        if not os.path.isdir(d):
            continue
        for dp,_,fns in os.walk(d):
            for fn in fns:
                if fn.endswith(TOOLBAR_EXTS):
                    yield os.path.relpath(os.path.join(dp, fn), repo_root).replace("\\","/")

def parse_script_targets(abs_path: str):
    out=[]
    with open(abs_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m=SCRIPT_RE.match(line)
            if m:
                out.append(m.group(1).strip().replace("\\","/"))
    return out

def normalize_target(t: str):
    if t.lower().startswith("scripts/"):
        return t
    if os.path.basename(t).lower().startswith("ifls_"):
        return f"Scripts/IfeelLikeSnow/IFLS/{os.path.basename(t)}"
    return f"Scripts/IfeelLikeSnow/DF95/{os.path.basename(t)}"

def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        for e in elem:
            indent(e, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def add_pkg(cat, name, desc, files, raw_base, version="1.0.0", author="IfeelLikeSnow"):
    rp=ET.SubElement(cat,"reapack",attrib={"name":name,"type":"script","desc":desc})
    md=ET.SubElement(rp,"metadata")
    ET.SubElement(md,"description").text=desc
    ver=ET.SubElement(rp,"version",attrib={"name":version,"author":author,"time":str(int(time.time()))})
    for f in files:
        src=ET.SubElement(ver,"source",attrib={"file":f})
        src.text = raw_base + f
    return rp

def main():
    repo_root=os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    raw_base=os.environ.get("RAW_BASE","https://raw.githubusercontent.com/IfeelLikeSnow/df95-toolbar-suite/main/")

    idx=ET.Element("index",attrib={"version":"1","name":"DF95 Toolbar Suite","desc":"Toolbars + required scripts/resources"})

    # Core package (everything except .git / tools build outputs)
    cat_core=ET.SubElement(idx,"category",attrib={"name":"DF95/00 Core"})
    core_dirs=["Scripts","_selectors","Data","Effects","FXChains","Support","TrackTemplates","Projects","Theme","ThemeMod","Icons","DF95_MetaCore","Config","Chains","RenderPresets"]
    core_files=[]
    for d in core_dirs:
        p=os.path.join(repo_root,d)
        if not os.path.exists(p):
            continue
        for dp,_,fns in os.walk(p):
            for fn in fns:
                if fn.startswith("."):
                    continue
                rel=os.path.relpath(os.path.join(dp,fn),repo_root).replace("\\","/")
                core_files.append(rel)
    core_files=sorted(set(core_files))
    add_pkg(cat_core,"DF95 Toolbar Suite – Core","Core scripts/resources used by toolbars",core_files,raw_base)

    # Per-toolbar packages
    for tb_rel in sorted(iter_toolbar_files(repo_root)):
        cat_name="IFLS/10 Toolbars" if "IFLS" in tb_rel or "ifls" in tb_rel.lower() else "DF95/10 Toolbars"
        cat=None
        for c in idx.findall("category"):
            if c.get("name")==cat_name:
                cat=c; break
        if cat is None:
            cat=ET.SubElement(idx,"category",attrib={"name":cat_name})

        abs_tb=os.path.join(repo_root,tb_rel)
        targets=[normalize_target(t) for t in parse_script_targets(abs_tb)]
        files=[tb_rel] + [t for t in targets if os.path.exists(os.path.join(repo_root,t))]
        files=sorted(set(files))
        pkg_name=os.path.splitext(os.path.basename(tb_rel))[0]
        add_pkg(cat,pkg_name,"Toolbar/MenuSet + referenced scripts (shims included)",files,raw_base)

    indent(idx)
    ET.ElementTree(idx).write(os.path.join(repo_root,"index.xml"),encoding="utf-8",xml_declaration=True)
    print("Wrote index.xml")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
