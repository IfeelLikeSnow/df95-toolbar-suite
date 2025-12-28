-- @description Export – UCS Guess From Filename
-- @version 1.0
-- @author DF95

-- Liest Dateinamen (z.B. aktive Takes selektierter Items) und versucht,
-- daraus sinnvolle UCS-Felder (CatID, FXName) abzuleiten.
-- Ergebnis wird in DF95_EXPORT/wizard_tags eingetragen, so dass
-- der DF95 Export Wizard / DF95_Export_UCS_ImGui die Werte übernehmen.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function get_export_core()
  local ok, mod_or_err = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  if not ok then return nil end
  if type(mod_or_err) ~= "table" then return nil end
  return mod_or_err
end

local function basename(path)
  if not path then return "" end
  local name = path:match("([^/\\]+)$") or path
  return name:gsub("%.%w+$","")
end

local function humanize_fxname(name)
  name = name or ""
  name = name:gsub("_"," ")
  name = name:gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
  -- Capitalize first letters
  name = name:gsub("(%a)([%w']*)", function(a,b) return a:upper()..b:lower() end)
  -- Remove too-long names
  if #name > 30 then
    name = name:sub(1,30)
  end
  -- Convert spaces to no-space or underscore for filename block
  name = name:gsub("%s+","")
  return name
end

local function guess_catid_from_words(words)
  -- Heuristik auf Basis von Schlüsselwörtern.
  -- Diese CatIDs sind UCS-inspiriert, aber für DF95 vereinfacht.
  local s = (" "..(words or ""):lower().." ")

  local function has(w) return s:find(" "..w.." ", 1, true) ~= nil end


  -- Feinere Interior/Foley/Impact-Heuristiken vor den generischen Regeln

  -- Kitchen / Bathroom Interior (Roomtone / Ambience)
  if (has("kitchen") or has("bathroom") or has("restroom") or has("toilet"))
     and (has("roomtone") or has("room") or has("amb") or has("ambience") or has("interior")) then
    return "AMBIntKit"
  end

  -- Office Interior
  if (has("office") or has("workspace") or has("desk") or has("cubicle"))
     and (has("roomtone") or has("room") or has("amb") or has("ambience") or has("interior")) then
    return "AMBIntOffc"
  end

  -- Car / Vehicle Cabin Interior
  if (has("car") or has("taxi") or has("van") or has("bus") or has("truck"))
     and (has("interior") or has("inside") or has("cabin") or has("cockpit")) then
    return "AMBIntCar"
  end

  -- Forest Floor / Schritte / Foliage
  if (has("forest") or has("woods") or has("jungle"))
     and (has("floor") or has("ground") or has("foliage") or has("leaves")
          or has("steps") or has("footsteps") or has("trail")) then
    return "AMBExtFrst"
  end

  -- Clothes / Fabric Foley
  if (has("cloth") or has("clothes") or has("jacket") or has("coat")
      or has("fabric") or has("shirt") or has("jeans"))
     and (has("rustle") or has("movement") or has("grab") or has("handle")
          or has("fold") or has("touch")) then
    return "FOLEYClth"
  end

  -- Metal Impacts
  if (has("metal") or has("steel") or has("iron"))
     and (has("impact") or has("impacts") or has("hit") or has("hits")
          or has("drop") or has("clang") or has("bang") or has("slam")) then
    return "HITMetal"
  end

  -- Wasser / Flüssigkeiten
  if has("shower") or has("bathroom") or has("tap") or has("faucet") then
    return "WATRFlow"
  elseif has("rain") or has("drizzle") or has("downpour") then
    return "WATRRain"
  elseif has("ocean") or has("sea") or has("waves") or has("surf") then
    return "WATROcn"
  elseif has("river") or has("stream") then
    return "WATRStrm"
  -- Türen / Möbel / Haushalt
  elseif has("door") or has("cupboard") or has("cabinet") or has("drawer") or has("fridge") or has("kitchen") then
    return "OBJHsehld"
  -- Schritte / Bewegung
  elseif has("step") or has("footstep") or has("walk") or has("run") or has("stairs") then
    return "FOOTStep"
  -- Ambience / Umwelt
  elseif has("street") or has("traffic") or has("city") or has("road") or has("intersection") then
    return "AMBStrt"
  elseif has("forest") or has("woods") or has("jungle") or has("birds") or has("crickets") then
    return "AMBNatur"
  elseif has("roomtone") or has("room tone") or has("room") then
    return "AMBRoom"
  -- Luft / Wind
  elseif has("wind") or has("storm") or has("gust") or has("whoosh") then
    return "AIRWind"
  -- Technik / Geräte
  elseif has("typing") or has("keyboard") or has("mouse") or has("click") then
    return "TECHComp"
  elseif has("printer") or has("scanner") then
    return "TECHOffc"
  elseif has("machine") or has("motor") or has("engine") or has("fan") then
    return "MECHMach"
  elseif has("car") or has("truck") or has("bus") or has("train") then
    return "VEHCar"
  end

  return nil
end


end

local function parse_wizard(last)
  if not last or last == "" then return nil end

  local mode, target, category, role, source, fxflavor, dest_root,
        ucs_catid, ucs_fxname, ucs_creatorid, ucs_sourceid =
    last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")

  local eleven = true
  if not mode then
    eleven = false
    mode, target, category, role, source, fxflavor, dest_root =
      last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")
  end

  if not mode then return nil end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  return {
    eleven        = eleven,
    mode          = trim(mode),
    target        = trim(target),
    category      = trim(category),
    role          = trim(role),
    source        = trim(source),
    fxflavor      = trim(fxflavor),
    dest_root     = trim(dest_root or ""),
    ucs_catid     = trim(ucs_catid or ""),
    ucs_fxname    = trim(ucs_fxname or ""),
    ucs_creatorid = trim(ucs_creatorid or ""),
    ucs_sourceid  = trim(ucs_sourceid or ""),
  }
end

local function save_wizard(cfg)
  local function nz(s) return s or "" end
  local val = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",
    nz(cfg.mode), nz(cfg.target), nz(cfg.category), nz(cfg.role), nz(cfg.source),
    nz(cfg.fxflavor), nz(cfg.dest_root),
    nz(cfg.ucs_catid), nz(cfg.ucs_fxname), nz(cfg.ucs_creatorid), nz(cfg.ucs_sourceid))
  r.SetExtState("DF95_EXPORT", "wizard_tags", val, true)
end

local function main()
  local proj = 0
  local num_items = r.CountSelectedMediaItems(proj)
  if num_items == 0 then
    r.ShowMessageBox("Bitte ein oder mehrere Items selektieren, deren Dateinamen als UCS-Basis dienen sollen.", "DF95 UCS From Filename", 0)
    return
  end

  local first_name
  for i = 0, num_items-1 do
    local item = r.GetSelectedMediaItem(proj, i)
    local take = item and r.GetActiveTake(item)
    if take then
      local src = r.GetMediaItemTake_Source(take)
      local buf = ""
      local rv, buf = r.GetMediaSourceFileName(src, "")
      if rv and buf ~= "" then
        first_name = basename(buf)
        break
      end
    end
  end

  if not first_name or first_name == "" then
    r.ShowMessageBox("Konnte keinen Dateinamen aus den selektierten Items ermitteln.", "DF95 UCS From Filename", 0)
    return
  end

  local cfg = parse_wizard(r.GetExtState("DF95_EXPORT", "wizard_tags") or "")
  if not cfg then
    cfg = {
      mode          = "SELECTED_SLICES_SUM",
      target        = "ORIGINAL",
      category      = "Slices_Master",
      role          = "Any",
      source        = "Any",
      fxflavor      = "Generic",
      dest_root     = "",
      ucs_catid     = "",
      ucs_fxname    = "",
      ucs_creatorid = "",
      ucs_sourceid  = "",
    }
  end

  local desc = first_name:gsub("_"," "):gsub("%d+"," "):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
  local catid = guess_catid_from_words(desc) or cfg.ucs_catid
  local fxname = humanize_fxname(desc)

  -- optional: Dialog zur Bestätigung/Anpassung
  local cap = "UCS_CatID(auto-guess),UCS_FXName(Description)"
  local def = string.format("%s,%s", catid or "", fxname or "")
  local ok, ret = r.GetUserInputs("DF95 UCS Guess From Filename", 2, cap..",extrawidth=200", def)
  if not ok or not ret or ret == "" then return end

  local new_catid, new_fxname = ret:match("^(.-),(.-)$")
  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  cfg.ucs_catid  = trim(new_catid or catid or "")
  cfg.ucs_fxname = trim(new_fxname or fxname or "")

  save_wizard(cfg)

  r.ShowMessageBox(
    string.format("UCS aus Dateiname abgeleitet:\nCatID: %s\nFXName: %s\nDiese Werte werden beim nächsten Export verwendet.",
      cfg.ucs_catid or "(leer)", cfg.ucs_fxname or "(leer)"),
    "DF95 UCS From Filename", 0)
end

main()
