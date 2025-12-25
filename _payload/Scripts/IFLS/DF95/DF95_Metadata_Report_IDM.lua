-- @description Metadata Report – IDM & Tape Overview
-- @version 1.1
-- @author DF95
-- @about
--   Erstellt einen Textreport über erkannte Plugins (IDM_GLITCH, TAPE_LOFI, MASTERING etc.)
--   und speichert ihn nach Data/DF95/DF95_Metadata_Report.txt

local r = reaper
local sep = package.config:sub(1,1)
local function join(...) local t={...}; return table.concat(t,sep) end

local function msg(s) r.ShowConsoleMsg(tostring(s).."\n") end

local function load_meta()
  local respath = r.GetResourcePath()
  local meta_path = join(respath,"Scripts","IfeelLikeSnow","DF95","DF95_Metadata_Core.lua")
  local f, err = loadfile(meta_path)
  if not f then
    r.ShowMessageBox("DF95_Metadata_Core.lua nicht gefunden:\n"..tostring(err),
      "DF95 Metadata Report",0)
    return nil
  end
  local ok,mod = pcall(f)
  if not ok then
    r.ShowMessageBox("Fehler beim Laden von Metadata-Core:\n"..tostring(mod),
      "DF95 Metadata Report",0)
    return nil
  end
  mod.load()
  return mod
end

local function has_tag(pl, tag)
  for _,t in ipairs(pl.tags or {}) do
    if t==tag then return true end
  end
  return false
end

local function main()
  local meta = load_meta()
  if not meta or not meta.db then return end
  local respath = r.GetResourcePath()
  local outdir = join(respath,"Data","DF95")
  reaper.RecursiveCreateDirectory(outdir,0)
  local outfile = join(outdir,"DF95_Metadata_Report.txt")
  local f, err = io.open(outfile,"w")
  if not f then
    r.ShowMessageBox("Kann Report-Datei nicht schreiben:\n"..tostring(err),
      "DF95 Metadata Report",0)
    return
  end

  local db = meta.db
  f:write("DF95 Metadata Report – Übersicht\n\n")
  f:write(string.format("Gesamtzahl Plugins im Cache: %d\n\n", #db.plugins))

  local function section(title, filter_fn)
    f:write("==== "..title.." ====\n")
    local count = 0
    for _,pl in ipairs(db.plugins) do
      if filter_fn(pl) then
        count = count + 1
        f:write(string.format("- %s (%s) | role=%s | tags=%s\n",
          pl.name or "?", pl.developer or "?", pl.role or "-",
          table.concat(pl.tags or {}, ",")))
      end
    end
    f:write(string.format("  -> %d Treffer\n\n", count))
  end

  section("IDM / Glitch Plugins", function(pl) return has_tag(pl,"IDM_GLITCH") end)
  section("Tape / LoFi / BoC Plugins", function(pl)
    return has_tag(pl,"TAPE_LOFI") or has_tag(pl,"BOC_TAPE")
  end)
  section("Granular / Texture Plugins", function(pl)
    return has_tag(pl,"IDM_GRANULAR") or has_tag(pl,"TEXTURE")
  end)
  section("Mastering / Limiter Plugins", function(pl)
    return has_tag(pl,"MASTERING") or pl.role=="Limiter"
  end)
  section("Analyzer / Metering Plugins", function(pl)
    return has_tag(pl,"METERING") or pl.role=="Analyzer/Meter"
  end)

  f:close()
  msg("DF95 Metadata Report geschrieben: "..outfile)

  if r.CF_ShellExecute then
    r.CF_ShellExecute(outfile)
  end
  r.ShowMessageBox("DF95 Metadata Report erstellt.\nDatei:\n"..outfile,
    "DF95 Metadata Report",0)
end

main()
