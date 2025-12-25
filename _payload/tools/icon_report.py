#!/usr/bin/env python3
import os, re
from PIL import Image, ImageDraw

ICON_RE = re.compile(r'^\s*ICON:\s*(.+?)\s*$', re.IGNORECASE)
TOOLBAR_EXTS = (".ReaperMenuSet", ".Toolbar.ReaperMenu", ".ReaperMenu")

def iter_toolbar_files(repo_root: str):
    for base in ("Menus","MenuSets","Toolbars"):
        d=os.path.join(repo_root, base)
        if not os.path.isdir(d):
            continue
        for dp,_,fns in os.walk(d):
            for fn in fns:
                if fn.endswith(TOOLBAR_EXTS):
                    yield os.path.join(dp, fn)

def parse_icons(path: str):
    icons=[]
    with open(path,"r",encoding="utf-8",errors="ignore") as f:
        for line in f:
            m=ICON_RE.match(line)
            if m:
                icons.append(m.group(1).strip())
    return icons

def make_placeholder(path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img=Image.new("RGBA",(64,64),(0,0,0,0))
    d=ImageDraw.Draw(img)
    d.rectangle([1,1,62,62], outline=(255,255,255,255))
    d.text((8,24), "ICON", fill=(255,255,255,255))
    img.save(path)

def main():
    repo_root=os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    icon_dir=os.path.join(repo_root,"Data","toolbar_icons")
    os.makedirs(icon_dir, exist_ok=True)

    missing=set()
    refs=[]
    for tb in iter_toolbar_files(repo_root):
        for ic in parse_icons(tb):
            if not ic.lower().endswith((".png",".ico",".bmp",".jpg",".jpeg")):
                continue
            fname=os.path.basename(ic)
            dst=os.path.join(icon_dir,fname)
            if not os.path.exists(dst):
                missing.add(fname)
            refs.append((os.path.relpath(tb,repo_root).replace("\\","/"), fname))

    for fname in sorted(missing):
        make_placeholder(os.path.join(icon_dir,fname))

    reports=os.path.join(repo_root,"Reports")
    os.makedirs(reports, exist_ok=True)
    rpt=os.path.join(reports,"icon_resolution_report.md")
    with open(rpt,"w",encoding="utf-8") as f:
        f.write("# Icon resolution report\n\n")
        f.write(f"Placeholder icons created in `Data/toolbar_icons/`: **{len(missing)}**\n\n")
        for fname in sorted(missing):
            f.write(f"- `{fname}`\n")
        f.write("\n## References (toolbar -> icon)\n\n")
        for tb, fname in refs:
            f.write(f"- `{tb}` -> `{fname}`\n")

    print(f"Placeholders created: {len(missing)}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
