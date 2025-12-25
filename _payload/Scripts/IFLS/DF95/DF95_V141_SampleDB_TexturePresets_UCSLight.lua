-- @description DF95_V141 SampleDB – Texture Presets (UCS-Light Home & EMF)
-- @version 1.0
-- @author DF95
-- @about
--   Baut Soundscapes/Atmosphären aus der DF95 SampleDB Multi-UCS JSON anhand
--   von vordefinierten Presets (Bathroom Drone, Basement Machines, Kids Playroom,
--   Kitchen Ambience, EMF Sizzle etc.).
--
--   Nutzt die gleichen Felder wie der AI Soundscape Generator:
--     * home_zone
--     * material
--     * object_class
--     * ucs_category / ucs_subcategory (z.B. ELECTRIC/EMF_*)
--     * ai_primary (optional)
--
--   DB-Pfad:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Hinweis:
--     * Dieses Script erzeugt Tracks + Items im aktuellen Projekt.
--     * Die Files selbst werden nicht verändert.

local r = reaper

------------------------------------------------------------
-- JSON Decoder
------------------------------------------------------------

local function decode_json(text)
  if type(text) ~= "string" then return nil, "no text" end

  local lua_text = text
  lua_text = lua_text:gsub('"(.-)"%s*:', '["%1"] =')
  lua_text = lua_text:gsub("%[", "{")
  lua_text = lua_text:gsub("%]", "}")
  lua_text = lua_text:gsub("null", "nil")

  lua_text = "return " .. lua_text

  local f, err = load(lua_text)
  if not f then return nil, err end

  local ok, res = pcall(f)
  if not ok then return nil, res end
  return res
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function basename(path)
  return (path or ""):match("([^"..sep.."]+)$") or path
end

local function lower(s) return (s or ""):lower() end
local function upper(s) return (s or ""):upper() end

local function grade_to_rank(g)
  if not g then return 0 end
  g = g:upper()
  if g == "A" then return 4
  elseif g == "B" then return 3
  elseif g == "C" then return 2
  elseif g == "D" then return 1
  end
  return 0
end

local function choice(list)
  if not list or #list == 0 then return nil end
  local idx = math.random(#list)
  return list[idx]
end

local function filter_best_quality(list, min_rank)
  local best = {}
  local best_rank = min_rank or 0
  for _, it in ipairs(list or {}) do
    local rnk = grade_to_rank(it.quality_grade)
    if rnk >= best_rank then
      if rnk > best_rank then
        best_rank = rnk
        best = { it }
      else
        best[#best+1] = it
      end
    end
  end
  return best
end

local function add_item_with_source(track, path, pos)
  local proj = 0
  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemPosition(item, pos, false)

  local take = r.AddTakeToMediaItem(item)
  local src = r.PCM_Source_CreateFromFile(path)
  if not src then
    r.DeleteTrackMediaItem(track, item)
    return nil, nil, nil
  end
  r.SetMediaItemTake_Source(take, src)

  local length = r.GetMediaSourceLength(src)
  r.SetMediaItemLength(item, length, false)

  return item, take, length
end

------------------------------------------------------------
-- is_texture Heuristik (wie im AI Soundscape Generator)
------------------------------------------------------------

local function is_texture(it)
  local name = lower(basename(it.path or ""))
  local cat  = lower(it.ucs_category or "")
  local ai   = lower(it.ai_primary or "")

  if name:find("water") or name:find("rain") or name:find("river") or name:find("sea") then
    return true
  end
  if name:find("wind") or name:find("whoosh") or name:find("swoosh") or name:find("air") then
    return true
  end
  if name:find("amb") or name:find("atmo") or name:find("ambience") then
    return true
  end

  if ai:find("water") or ai:find("rain") or ai:find("ocean") or ai:find("sea") then
    return true
  end
  if ai:find("wind") or ai:find("whoosh") or ai:find("swoosh") then
    return true
  end
  if ai:find("ambience") or ai:find("room") or ai:find("hall") or ai:find("forest") or ai:find("city") then
    return true
  end

  if cat:find("water") or cat:find("ambience") or cat:find("amb") or cat:find("whoosh") then
    return true
  end
  -- EMF / ELECTRIC can also be textural
  if cat:find("electric") then
    return true
  end

  return false
end

------------------------------------------------------------
-- Preset-Definitionen
------------------------------------------------------------

local presets = {
  {
    name = "Bathroom – Water Drone",
    desc = "Dusch-/Badezimmer-Wasseratmosphäre (Shower/Sink, WATER).",
    zone = "BATHROOM",
    material = "WATER",
    object_class = nil,
    ai_contains = "water",
  },
  {
    name = "Kitchen – Busy Ambience",
    desc = "Küchen-Atmo mit Geschirr/Besteck/Wasser.",
    zone = "KITCHEN",
    material = nil,
    object_class = "FOLEY",
    ai_contains = "",
  },
  {
    name = "Childroom – Playroom",
    desc = "Kinderzimmer-Spielatmo (Toys, Lego, Movement).",
    zone = "CHILDROOM",
    material = nil,
    object_class = "TOY",
    ai_contains = "",
  },
  {
    name = "Basement – Machines",
    desc = "Kellermaschinen (Waschmaschine, Trockner, Geräuschkulisse).",
    zone = "BASEMENT",
    material = nil,
    object_class = "APPLIANCE",
    ai_contains = "",
  },
  {
    name = "Hallway – Distant Rooms",
    desc = "Flur mit Türen, entfernten Räumen, Roomtone.",
    zone = "HALLWAY",
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  -- EMF / ELECTRIC Presets
  {
    name = "EMF – SOMA Sweep",
    desc = "Breite SOMA Ether Scans (ELECTRIC/EMF_SOMA).",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_SOMA",
  },
  {
    name = "EMF – Telephone Lines",
    desc = "Telephone Pick-Up Coil: Leitungen, Telefone, Basisstationen.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Telephone",
  },
  {
    name = "EMF – Devices & Chargers",
    desc = "Router, Laptop, Ladegeräte, Monitore (ELECTRIC/EMF_Devices).",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – Mixed Noise Bed",
    desc = "Gemischtes EMF-Bett aus allen EMF-Kategorien.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
  },
  -- Bedroom / Kids
  {
    name = "Bedroom – Night Quiet",
    desc = "Leise Nachtgeräusche: Bett, Decke, Zimmerbewegungen.",
    zone = "BEDROOM",
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  {
    name = "Kids – Asleep",
    desc = "Schlafende Kinder, ruhiges Rascheln, Raumton.",
    zone = "CHILDROOM",
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  -- Computer / Office EMF
  {
    name = "Computer Room – EMF",
    desc = "EMF von PC, Monitor, GPU, Router.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – Smartphone Idle",
    desc = "Smartphone im Standby: subtile EMF-/Polling-/Signalgeräusche.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "phone",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – WiFi Router Burst",
    desc = "Stärkere EMF-Spitzen von Router/WiFi/LAN-Geräten.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "router",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – Laptop Coil Whine",
    desc = "Hohe, feine EMF-/Elektronik-Fiepgeräusche (Laptops, GPUs, Netzteile).",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "computer",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  -- Themes / Whole Apartment
  {
    name = "Whole Apartment – Night",
    desc = "Gesamte Wohnung nachts: leise Ambiences aus Schlafzimmer, Kinderzimmer, Flur, Wohnzimmer.",
    zones = {"BEDROOM","CHILDROOM","HALLWAY","LIVINGROOM"},
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  {
    name = "Basement – Heavy Machines",
    desc = "Keller mit lauten Maschinen/Appliances (Waschmaschine, Trockner, etc.).",
    zone = "BASEMENT",
    material = nil,
    object_class = "APPLIANCE",
    ai_contains = "",
  },
  {
    name = "Urban – EMF Map",
    desc = "Städtische EMF-Karte: verschiedene EMF-Quellen gemischt.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
  },
  -- Generic
  {
    name = "Generic – Soft Ambience",
    desc = "Weiche Ambiences (Roomtone, leise Bewegungen).",
    zone = nil,
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
}

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local db_path = get_db_path()
  local f = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "SampleDB JSON nicht gefunden:\n"..db_path..
      "\n\nBitte zuerst den DF95 UCS-Light Scanner ausführen.",
      "DF95 Texture Presets",
      0
    )
    return
  end

  local text = f:read("*all")
  f:close()

  local db, err = decode_json(text)
  if not db then
    r.ShowMessageBox(
      "Fehler beim Lesen der SampleDB:\n"..tostring(err),
      "DF95 Texture Presets",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die SampleDB enthält keine Items.\n"..db_path,
      "DF95 Texture Presets",
      0
    )
    return
  end

  -- Preset-Auswahl-String
  local preset_labels = {}
  for i, p in ipairs(presets) do
    preset_labels[#preset_labels+1] = string.format("%d: %s", i, p.name)
  end

  local ok, vals = r.GetUserInputs(
    "DF95 Texture Presets",
    4,
    "Preset-Nummer ("..table.concat(preset_labels, " | ").."),Dauer in Sekunden,Layer,Min Quality Grade (A/B/C/D, leer=keine)",
    "1,60,4,"
  )
  if not ok then return end

  local s_idx, s_dur, s_layers, s_grade = vals:match("([^,]*),([^,]*),([^,]*),([^,]*)")
  local idx = tonumber(s_idx or "1") or 1
  if idx < 1 then idx = 1 end
  if idx > #presets then idx = #presets end

  local preset = presets[idx]

  local duration = tonumber(s_dur or "60") or 60
  if duration < 10 then duration = 10 end
  if duration > 1200 then duration = 1200 end

  local layers = tonumber(s_layers or "4") or 4
  if layers < 1 then layers = 1 end
  if layers > 16 then layers = 16 end

  local min_rank = grade_to_rank(s_grade)

  -- Filter Items gemäß Preset
  local cand = {}
  local required_cat = preset.require_cat and upper(preset.require_cat)
  local required_sub = preset.require_sub and upper(preset.require_sub)

  for _, it in ipairs(items) do
    if it.path then
      if is_texture(it) then
        local rank = grade_to_rank(it.quality_grade)
        if rank >= min_rank then
          local ok_zone = true
          local ok_mat  = true
          local ok_obj  = true
          local ok_ai   = true
          local ok_cat  = true
          local ok_sub  = true

          if preset.zone then
            local hz = upper(it.home_zone or "")
            ok_zone = (hz:find(upper(preset.zone), 1, true) ~= nil)
          end
          if preset.zones then
            local hz = upper(it.home_zone or "")
            ok_zone = false
            for _, z in ipairs(preset.zones) do
              if hz:find(upper(z), 1, true) then
                ok_zone = true
                break
              end
            end
          end
          if preset.material then
            local mt = upper(it.material or "")
            ok_mat = (mt:find(upper(preset.material), 1, true) ~= nil)
          end
          if preset.object_class then
            local oc = upper(it.object_class or "")
            ok_obj = (oc:find(upper(preset.object_class), 1, true) ~= nil)
          end
          if preset.ai_contains and preset.ai_contains ~= "" then
            local ai = lower(it.ai_primary or "")
            ok_ai = (ai:find(lower(preset.ai_contains), 1, true) ~= nil)
          end
          if required_cat then
            local cat = upper(it.ucs_category or "")
            ok_cat = (cat:find(required_cat, 1, true) ~= nil)
          end
          if required_sub then
            local sub = upper(it.ucs_subcategory or "")
            ok_sub = (sub:find(required_sub, 1, true) ~= nil)
          end

          if ok_zone and ok_mat and ok_obj and ok_ai and ok_cat and ok_sub then
            cand[#cand+1] = it
          end
        end
      end
    end
  end

  if #cand == 0 then
    r.ShowMessageBox(
      "Keine geeigneten Textur-Samples für das gewählte Preset gefunden.\n"..
      "Preset: "..preset.name,
      "DF95 Texture Presets",
      0
    )
    return
  end

  local proj = 0
  r.Undo_BeginBlock()

  local start_track_idx = r.CountTracks(proj)

  local function create_track(name)
    r.InsertTrackAtIndex(start_track_idx, true)
    local tr = r.GetTrack(proj, start_track_idx)
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
    start_track_idx = start_track_idx + 1
    return tr
  end

  for i = 1, layers do
    local it = choice(filter_best_quality(cand, min_rank)) or choice(cand)
    if it then
      local label = basename(it.path or "")
      if it.home_zone and it.home_zone ~= "" and it.home_zone ~= "(none)" then
        label = "["..it.home_zone.."] "..label
      end
      local tr = create_track("DF95 TexturePreset "..i.." – "..label)
      local pos = 0.0
      while pos < duration do
        local item, take, len = add_item_with_source(tr, it.path, pos)
        if not len or len <= 0 then
          break
        end
        local overlap = math.random() * 0.5
        local step = len * (1.0 - overlap)
        if step <= 0.01 then step = len end
        pos = pos + step
        if pos > duration then break end
      end
    end
  end

  r.Undo_EndBlock("DF95 Texture Presets – "..preset.name, -1)
end

main()
