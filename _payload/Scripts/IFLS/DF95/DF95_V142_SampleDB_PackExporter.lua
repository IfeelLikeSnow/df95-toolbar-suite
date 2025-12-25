local g_drone_centerfreq_preset = nil
local g_drone_density_preset = nil
local g_drone_form_preset = nil

-- @description DF95_V142 SampleDB – Pack Exporter (UCS-Light & EMF)
-- @version 1.0
-- @author DF95
-- @about
--   Exportiert selektierte Teile der DF95 SampleDB in einen Export-Ordner:
--     * Kopiert die Audiofiles (WAV/AIFF/FLAC)
--     * Schreibt optional eine CSV mit UCS-/DF95-Metadaten
--
--   Filterbar nach:
--     * ucs_category enthält (...)
--     * home_zone enthält (...)
--     * df95_catid enthält (...)
--     * Mindestlänge
--
--   Typische Use Cases:
--     * "Bathroom_Water" Pack
--     * "Basement_Bikes" Pack
--     * "Kids_Playroom" Pack
--     * "EMF_SOMA" / "EMF_Telephone" Pack
--
--   Hinweis:
--     * Die Originaldateien werden NICHT verändert.
--     * Die Exportdateien sind einfache Kopien im Zielordner.
--
--   DB-Pfad:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json

local r = reaper



------------------------------------------------------------
-- Drone Pack Presets (Phase D2 / LUX / Phase X)
------------------------------------------------------------

local drone_pack_presets = {
  -- Basis-/Serien-Presets (Beispiele; können später erweitert werden)

  -- EMF Series
  EMF_MOVEMENT = {
    cat    = "EMF",
    zone   = "",
    catid  = "DRONE_MOVEMENT",
    minlen = 8.0,
    csv    = "YES",
  },
  EMF_MOVEMENT_LONG = {
    cat    = "EMF",
    zone   = "",
    catid  = "DRONE_MOVEMENT",
    minlen = 12.0,
    csv    = "YES",
  },
  EMF_PULSE = {
    cat    = "EMF",
    zone   = "",
    catid  = "DRONE_PULSE",
    minlen = 6.0,
    csv    = "YES",
  },

  -- HOME Series
  HOME_STATIC = {
    cat    = "HOME_ATMOS",
    zone   = "",
    catid  = "DRONE_STATIC",
    minlen = 6.0,
    csv    = "YES",
  },
  HOME_STATIC_LONG = {
    cat    = "HOME_ATMOS",
    zone   = "",
    catid  = "DRONE_STATIC",
    minlen = 10.0,
    csv    = "YES",
  },
  HOME_SWELL = {
    cat    = "HOME_ATMOS",
    zone   = "",
    catid  = "DRONE_SWELL",
    minlen = 6.0,
    csv    = "YES",
  },

  -- IDM Series
  IDM_TEXTURE = {
    cat    = "IDM_TEXTURE",
    zone   = "",
    catid  = "DRONE_TEXTURE",
    minlen = 4.0,
    csv    = "YES",
  },
  IDM_PULSE = {
    cat    = "IDM_TEXTURE",
    zone   = "",
    catid  = "DRONE_PULSE",
    minlen = 4.0,
    csv    = "YES",
  },

  -- Globale Drone-Presets
  DRONE_ALL = {
    cat    = "",
    zone   = "",
    catid  = "DRONE",
    minlen = 4.0,
    csv    = "YES",
  },
  DRONE_STATIC = {
    cat    = "",
    zone   = "",
    catid  = "DRONE_STATIC",
    minlen = 4.0,
    csv    = "YES",
  },
  DRONE_PULSE = {
    cat    = "",
    zone   = "",
    catid  = "DRONE_PULSE",
    minlen = 4.0,
    csv    = "YES",
  },
  DRONE_TEXTURE = {
    cat    = "",
    zone   = "",
    catid  = "DRONE_TEXTURE",
    minlen = 4.0,
    csv    = "YES",
  },
  DRONE_MOVEMENT = {
    cat    = "",
    zone   = "",
    catid  = "DRONE_MOVEMENT",
    minlen = 6.0,
    csv    = "YES",
  },

  -- Tonale Presets (CenterFreq)
  EMF_MOVEMENT_LOW = {
    cat        = "EMF",
    zone       = "",
    catid      = "DRONE_MOVEMENT",
    centerfreq = "LOW",
    minlen     = 8.0,
    csv        = "YES",
  },
  EMF_MOVEMENT_HIGH = {
    cat        = "EMF",
    zone       = "",
    catid      = "DRONE_MOVEMENT",
    centerfreq = "HIGH",
    minlen     = 8.0,
    csv        = "YES",
  },
  HOME_STATIC_LOW = {
    cat        = "HOME_ATMOS",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "LOW",
    minlen     = 6.0,
    csv        = "YES",
  },
  HOME_STATIC_HIGH = {
    cat        = "HOME_ATMOS",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "HIGH",
    minlen     = 6.0,
    csv        = "YES",
  },
  DRONE_STATIC_LOW = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "LOW",
    minlen     = 4.0,
    csv        = "YES",
  },
  DRONE_STATIC_HIGH = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "HIGH",
    minlen     = 4.0,
    csv        = "YES",
  },

  -- Tonale + Form/Density Presets (Sounddesigner-Presets)
  DRONE_LOW_PAD = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "LOW",
    density    = "LOW",
    form       = "PAD",
    minlen     = 4.0,
    csv        = "YES",
  },
  DRONE_HIGH_PAD = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "HIGH",
    density    = "MED",
    form       = "PAD",
    minlen     = 4.0,
    csv        = "YES",
  },
  DRONE_LOW_TEXTURE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "LOW",
    density    = "HIGH",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },
  DRONE_HIGH_TEXTURE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "HIGH",
    density    = "HIGH",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },
  DRONE_LOW_MOVING_PAD = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_MOVEMENT",
    centerfreq = "LOW",
    density    = "MED",
    form       = "MOVING_PAD",
    minlen     = 6.0,
    csv        = "YES",
  },
  DRONE_HIGH_PULSING_PAD = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_PULSE",
    centerfreq = "HIGH",
    density    = "HIGH",
    form       = "PULSING_PAD",
    minlen     = 4.0,
    csv        = "YES",
  },

  -- Stilistische Presets

  DRONE_DARK_GROWL = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_MOVEMENT",
    centerfreq = "LOW",
    density    = "HIGH",
    form       = "GROWL",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_SUB_BED = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "LOW",
    density    = "LOW",
    form       = "PAD",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_DARK_PULSE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_PULSE",
    centerfreq = "LOW",
    density    = "MED",
    form       = "PULSING_PAD",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_AIRY = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "HIGH",
    density    = "LOW",
    form       = "PAD",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_SHIMMER = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "HIGH",
    density    = "MED",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_CRYSTAL_MOVEMENT = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_MOVEMENT",
    centerfreq = "HIGH",
    density    = "LOW",
    form       = "MOVING_PAD",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_ORGANIC = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "MID",
    density    = "MED",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_RITUAL_LOW = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_SWELL",
    centerfreq = "LOW",
    density    = "MED",
    form       = "PAD",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_RITUAL_HIGH = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_SWELL",
    centerfreq = "HIGH",
    density    = "MED",
    form       = "PAD",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_MECHANICAL_RATTLE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "MID",
    density    = "HIGH",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_MECH_PULSE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_PULSE",
    centerfreq = "MID",
    density    = "MED",
    form       = "PULSING_PAD",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_STEAM_PRESSURE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_SWELL",
    centerfreq = "MID",
    density    = "HIGH",
    form       = "SWELL",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_NOISE_WASH = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "HIGH",
    density    = "HIGH",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_GRIT_FIELD = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_TEXTURE",
    centerfreq = "MID",
    density    = "HIGH",
    form       = "TEXTURE",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_STATIC_HISS = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "HIGH",
    density    = "LOW",
    form       = "PAD",
    minlen     = 4.0,
    csv        = "YES",
  },

  DRONE_EMOTIONAL_PAD = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_STATIC",
    centerfreq = "MID",
    density    = "LOW",
    form       = "PAD",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_TENSION_RISE = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_SWELL",
    centerfreq = "HIGH",
    density    = "MED",
    form       = "SWELL",
    minlen     = 6.0,
    csv        = "YES",
  },

  DRONE_TENSION_GRIT = {
    cat        = "",
    zone       = "",
    catid      = "DRONE_MOVEMENT",
    centerfreq = "MID",
    density    = "HIGH",
    form       = "GROWL",
    minlen     = 6.0,
    csv        = "YES",
  },
}

local function apply_drone_pack_preset_shortcuts(s_root, s_cat, s_zone, s_catid, s_minlen, s_csv)
  -- Erkennt Presets anhand des df95_catid-Eingabefelds.
  -- Key ist case-insensitive, Whitespace wird entfernt.
  local key = (s_catid or ""):upper():gsub("%s+", "")
  local preset = drone_pack_presets[key]
  if not preset then
    g_drone_centerfreq_preset = nil
    g_drone_density_preset    = nil
    g_drone_form_preset       = nil
    return s_root, s_cat, s_zone, s_catid, s_minlen, s_csv
  end

  if preset.cat then   s_cat    = preset.cat   end
  if preset.zone then  s_zone   = preset.zone  end
  if preset.catid then s_catid  = preset.catid end
  if preset.minlen then s_minlen = tostring(preset.minlen) end
  if preset.csv then   s_csv    = preset.csv   end

  if preset.centerfreq then
    g_drone_centerfreq_preset = tostring(preset.centerfreq):upper()
  else
    g_drone_centerfreq_preset = nil
  end

  if preset.density then
    g_drone_density_preset = tostring(preset.density):upper()
  else
    g_drone_density_preset = nil
  end

  if preset.form then
    g_drone_form_preset = tostring(preset.form):upper()
  else
    g_drone_form_preset = nil
  end

  return s_root, s_cat, s_zone, s_catid, s_minlen, s_csv
end

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

local function get_default_export_root()
  local res = r.GetResourcePath()
  return join_path(res, "DF95_Exports")
end

local function ensure_dir(path)
  if not path or path == "" then return end
  local attr = r.GetFileAttributes and r.GetFileAttributes(path)
  if attr then return end
  if sep == "\\" then
    os.execute(string.format('mkdir "%s"', path))
  else
    os.execute(string.format('mkdir -p "%s"', path))
  end
end

local function lower(s) return (s or ""):lower() end

local function file_copy(src, dst)
  local f_in = io.open(src, "rb")
  if not f_in then return false, "cannot open source" end
  local f_out = io.open(dst, "wb")
  if not f_out then
    f_in:close()
    return false, "cannot open dest"
  end

  while true do
    local chunk = f_in:read(64*1024)
    if not chunk then break end
    f_out:write(chunk)
  end

  f_in:close()
  f_out:close()
  return true
end

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
      "DF95 SampleDB – Pack Exporter",
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
      "DF95 SampleDB – Pack Exporter",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die SampleDB enthält keine Items.\n"..db_path,
      "DF95 SampleDB – Pack Exporter",
      0
    )
    return
  end

  local def_root = get_default_export_root()
  ensure_dir(def_root)

  local ok, vals = r.GetUserInputs(
    "DF95 Pack Exporter – Optionen",
    6,
    "Export-Ordner (wird erstellt falls nötig),Filter: ucs_categ...95_catid enthält,Min. Length (Sekunden),Metadata CSV? (YES/NO)",
    def_root..sep.."MyPack,EMF,,EMF_,0.0,YES"
  )
  if not ok then return end

  local s_root, s_cat, s_zone, s_catid, s_minlen, s_csv =
    vals:match("([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")

  -- Preset-Shortcuts (Drone-Packs, tonal, stilistisch)
  s_root, s_cat, s_zone, s_catid, s_minlen, s_csv =
    apply_drone_pack_preset_shortcuts(s_root, s_cat, s_zone, s_catid, s_minlen, s_csv)

  local export_root = s_root or def_root
  export_root = export_root:gsub("%s+$","")
  if export_root == "" then
    export_root = def_root
  end
  ensure_dir(export_root)

  local cat_filter   = lower(s_cat or "")
  local zone_filter  = lower(s_zone or "")
  local catid_filter = lower(s_catid or "")
  if cat_filter == "" then cat_filter = nil end
  if zone_filter == "" then zone_filter = nil end
  if catid_filter == "" then catid_filter = nil end

  local min_len = tonumber(s_minlen or "0.0") or 0.0
  if min_len < 0 then min_len = 0 end

  local want_csv = ((s_csv or ""):upper() == "YES")

  -- Drone-Pack-Modus (Phase D2 / LUX / Phase X / tonale & stilistische Presets)
  local drone_only = false
  local drone_motion_filter     = nil
  local drone_centerfreq_filter = g_drone_centerfreq_preset
  local drone_density_filter    = g_drone_density_preset
  local drone_form_filter       = g_drone_form_preset

  do
    local raw = (s_catid or ""):upper()
    if raw:find("DRONE", 1, true) == 1 then
      drone_only = true
      if raw:find("STATIC", 1, true) then
        drone_motion_filter = "STATIC"
      elseif raw:find("PULSE", 1, true) then
        drone_motion_filter = "PULSE"
      elseif raw:find("SWELL", 1, true) then
        drone_motion_filter = "SWELL"
      elseif raw:find("FALL", 1, true) then
        drone_motion_filter = "FALL"
      elseif raw:find("TEXTURE", 1, true) then
        drone_motion_filter = "TEXTURE"
      elseif raw:find("MOVE", 1, true) then
        drone_motion_filter = "MOVEMENT"
      end
      -- df95_catid-Textfilter deaktivieren, wenn wir im Drone-Modus sind
      catid_filter = nil
    end
  end

  local selected = {}

  for _, it in ipairs(items) do
    local len = tonumber(it.length_sec or it.length or 0) or 0
    if len >= min_len then
      local ok_cat  = true
      local ok_zone = true
      local ok_cid  = true

      local cat  = lower(it.ucs_category or "")
      local zone = lower(it.home_zone or "")
      local cid  = lower(it.df95_catid or "")

      if cat_filter then
        ok_cat = (cat:find(cat_filter, 1, true) ~= nil)
      end
      if zone_filter then
        ok_zone = (zone:find(zone_filter, 1, true) ~= nil)
      end
      if catid_filter then
        ok_cid = (cid:find(catid_filter, 1, true) ~= nil)
      end

      local ok_drone = true
      if drone_only then
        local role  = lower(it.role or "")
        local dflag = lower(it.df95_drone_flag or "")
        if dflag == "" and role ~= "drone" then
          ok_drone = false
        end

        if ok_drone and drone_motion_filter then
          local motion = (it.df95_drone_motion or ""):upper()
          if motion == "" or motion ~= drone_motion_filter then
            ok_drone = false
          end
        end

        if ok_drone and drone_centerfreq_filter then
          local cf = (it.df95_drone_centerfreq or ""):upper()
          if cf == "" or cf ~= drone_centerfreq_filter then
            ok_drone = false
          end
        end

        if ok_drone and drone_density_filter then
          local dens = (it.df95_drone_density or ""):upper()
          if dens == "" or dens ~= drone_density_filter then
            ok_drone = false
          end
        end

        if ok_drone and drone_form_filter then
          local form = (it.df95_drone_form or ""):upper()
          if form == "" or form ~= drone_form_filter then
            ok_drone = false
          end
        end
      end

      if ok_cat and ok_zone and ok_cid and ok_drone then
        selected[#selected+1] = it
      end
    end
  end

  if #selected == 0 then
    r.ShowMessageBox(
      "Keine Items entsprechen den Filterkriterien.",
      "DF95 SampleDB – Pack Exporter",
      0
    )
    return
  end

  local exported = 0
  local failed = 0
  local failures = {}

  local csv_path = nil
  local fcsv = nil

  if want_csv then
    csv_path = join_path(export_root, "DF95_Pack_Metadata.csv")
    local err2
    fcsv, err2 = io.open(csv_path, "w")
    if not fcsv then
      r.ShowMessageBox(
        "Fehler beim Anlegen der CSV-Datei:\n"..tostring(err2 or csv_path),
        "DF95 SampleDB – Pack Exporter",
        0
      )
      return
    end
    fcsv:write("filename,src_path,ucs_category,ucs_subcategory,df95_catid,home_zone,material,object_class,action,length_sec,samplerate,channels,ai_primary,quality_grade\n")
  end

  local function csv_escape(s)
    s = tostring(s or "")
    if s:find("[,;\n\"]") then
      s = "\"" .. s:gsub("\"", "\"\"") .. "\""
    end
    return s
  end

  for _, it in ipairs(selected) do
    local src_path = it.path
    local base = src_path:match("([^"..sep.."]+)$") or src_path
    local dst_path = join_path(export_root, base)

    local ok_copy, errc = file_copy(src_path, dst_path)
    if ok_copy then
      exported = exported + 1
      if fcsv then
        local row = {
          csv_escape(base),
          csv_escape(src_path),
          csv_escape(it.ucs_category),
          csv_escape(it.ucs_subcategory),
          csv_escape(it.df95_catid),
          csv_escape(it.home_zone),
          csv_escape(it.material),
          csv_escape(it.object_class),
          csv_escape(it.action),
          tostring(it.length_sec or it.length or ""),
          tostring(it.samplerate or ""),
          tostring(it.channels or ""),
          csv_escape(it.ai_primary),
          csv_escape(it.quality_grade),
        }
        fcsv:write(table.concat(row, ",") .. "\n")
      end
    else
      failed = failed + 1
      failures[#failures+1] = string.format("%s -> %s (%s)", src_path, dst_path, tostring(errc))
    end
  end

  if fcsv then
    fcsv:close()
  end

  local msg = string.format("Export abgeschlossen.\n\nExport-Ordner:\n%s\n\nErfolgreich kopiert: %d\nFehlgeschlagen: %d",
    export_root, exported, failed)
  if csv_path then
    msg = msg .. "\n\nMetadata CSV:\n" .. csv_path
  end
  if failed > 0 then
    msg = msg .. "\n\nFehler (Auszug):\n"
    for i = 1, math.min(10, #failures) do
      msg = msg .. failures[i] .. "\n"
    end
  end

  r.ShowMessageBox(msg, "DF95 SampleDB – Pack Exporter", 0)
end

main()
