-- @description DF95 AutoIngest Master V4 – Confidence + Drone-Intelligence SampleDB Curator
-- @version 1.1
-- @author DF95
-- @about
--   Liest die DF95 SampleDB (Multi-UCS JSON), wertet df95_ai_confidence aus
--   und übernimmt bei Bedarf *_suggested Felder (HomeZone, SubZone, UCS, df95_catid)
--   in die "echten" Felder. Arbeitet in drei Modi:
--
--     * ANALYZE:
--         - Nimmt keine Änderungen an den Items vor (DB wird nicht geschrieben)
--         - Setzt df95_ai_review_flag auf OK_HIGH/REVIEW_MED/REVIEW_LOW
--
--     * SAFE:
--         - Wendet *_suggested nur für HIGH-Confidence-Items an
--         - Nur, wenn Ziel-Felder leer oder generisch sind (z.B. UCS=MISC/FIELDREC)
--
--     * AGGRESSIVE:
--         - Wie SAFE, plus:
--             - MED-Confidence-Items dürfen leere Felder füllen
--             - HIGH-Confidence-Items können generische UCS überschreiben
--
--   Default-DB: <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json

local r = reaper

------------------------------------------------------------
-- JSON Helper (minimal, wie in Inspector V4)
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

local function encode_json_table(t, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)
  local parts = {}

  if type(t) ~= "table" then
    if type(t) == "string" then
      return string.format("%q", t)
    elseif type(t) == "number" then
      return tostring(t)
    elseif type(t) == "boolean" then
      return t and "true" or "false"
    else
      return "null"
    end
  end

  local is_array = true
  local max_index = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then
      is_array = false
      break
    else
      if k > max_index then max_index = k end
    end
  end

  if is_array then
    table.insert(parts, "[\n")
    for i = 1, max_index do
      local v = t[i]
      table.insert(parts, pad .. "  " .. encode_json_table(v, indent+1))
      if i < max_index then table.insert(parts, ",") end
      table.insert(parts, "\n")
    end
    table.insert(parts, pad .. "]")
  else
    table.insert(parts, "{\n")
    local first = true
    for k, v in pairs(t) do
      if not first then
        table.insert(parts, ",\n")
      end
      first = false
      table.insert(parts, pad .. "  " .. string.format("%q", tostring(k)) .. ": " .. encode_json_table(v, indent+1))
    end
    table.insert(parts, "\n" .. pad .. "}")
  end

  return table.concat(parts)
end

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function get_default_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")

local function get_subset_filter_path()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local dir = res
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    dir = dir .. sep
  end
  dir = dir .. "Support" .. sep .. "DF95_SampleDB"
  return dir .. sep .. "DF95_AutoIngest_Subset.json"
end

local function load_subset_map()
  local path = get_subset_filter_path()
  local f = io.open(path, "r")
  if not f then
    return nil, "Subset-Datei nicht gefunden (" .. tostring(path) .. ")"
  end
  local text = f:read("*all")
  f:close()

  local data, err = decode_json(text)
  if not data then
    return nil, "Fehler beim Dekodieren der Subset-Datei: " .. tostring(err or "unbekannt")
  end

  local paths_tbl = nil

  if type(data) == "table" then
    if #data > 0 and type(data[1]) == "string" then
      paths_tbl = data
    elseif type(data.paths) == "table" then
      paths_tbl = data.paths
    end
  end

  if not paths_tbl then
    return nil, "Subset-Datei hat kein gültiges Format (erwartet: Array von Filepaths oder {paths=[...]})"
  end

  local map = {}
  local count = 0
  for _, p in ipairs(paths_tbl) do
    if type(p) == "string" and p ~= "" then
      map[p] = true
      count = count + 1
    end
  end

  if count == 0 then
    return nil, "Subset-Liste ist leer."
  end

  return map, nil
end


local function get_changelog_path()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local dir = res
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    dir = dir .. sep
  end
  dir = dir .. "Support" .. sep .. "DF95_SampleDB"
  return dir .. sep .. "DF95_AutoIngest_ChangeLog.jsonl"
end

local function snapshot_item_state(it)
  return {
    filepath            = tostring(it.filepath or ""),
    df95_ai_review_flag = it.df95_ai_review_flag,
    ai_status           = it.ai_status,
    df95_ai_confidence  = it.df95_ai_confidence,
    home_zone           = it.home_zone,
    home_zone_sub       = it.home_zone_sub,
    ucs_category        = it.ucs_category,
    df95_catid          = it.df95_catid,
  }
end

local function write_changelog_entry(run)
  local path = get_changelog_path()
  local f, err = io.open(path, "a")
  if not f then
    r.ShowMessageBox("Konnte AutoIngest ChangeLog nicht schreiben:\\n" .. tostring(err or "unbekannt"), "DF95 AutoIngest V3", 0)
    return
  end
  local line = encode_json_value(run, 0)
  f:write(line)
  f:write("\n")
  f:close()
end

end

------------------------------------------------------------
-- Confidence & Heuristik
------------------------------------------------------------

local function is_nonempty(v)
  return v ~= nil and v ~= ""
end

local function is_generic_ucs(ucs)
  if not ucs or ucs == "" then return true end
  local u = tostring(ucs):upper()
  return (u == "FIELDREC" or u == "MISC" or u == "UNKNOWN" or u == "OTHER")
end

local function get_confidence(it)
  local c = tonumber(it.df95_ai_confidence or 0.0) or 0.0
  if c < 0.0 then c = 0.0 end
  if c > 1.0 then c = 1.0 end
  return c
end

local function classify_confidence(it, high_thr, med_thr)
  local c = get_confidence(it)
  if c >= high_thr then
    return "HIGH", c
  elseif c >= med_thr then
    return "MED", c
  else
    return "LOW", c
  end
end



------------------------------------------------------------
-- Phase V4: Drone-Intelligence (D2 + LUX + Hooks für Phase X)
------------------------------------------------------------

-- Phase D2: Drone-Autotagging (heuristische Zuordnung über vorhandene Metadaten)
local function classify_drone_item(it)
  -- Versucht, Items als Drone/Atmos zu erkennen (basierend auf Kategorie, df95_catid, role, source, fxflavor, Name).
  if not it then return nil end

  local function up(v) return tostring(v or ""):upper() end

  local ucs    = up(it.ucs_category)
  local dfcat  = up(it.df95_catid)
  local role   = up(it.role)
  local source = up(it.source or it.rec_source)
  local flavor = up(it.fxflavor)
  local name   = tostring(it.name or it.filepath or ""):lower()

  local is_drone = false
  local kind = nil

  -- 1) Explizites role-Feld
  if role == "DRONE" then
    is_drone = true
  end

  -- 2) Kategorie-Flags
  if ucs:find("DRONE", 1, true) or dfcat:find("DRONE", 1, true) then
    is_drone = true
  end

  -- 3) Export-Preset-Kategorien (Home/EMF/IDM)
  if ucs:find("HOME_ATMOS", 1, true) or dfcat:find("HOME_ATMOS", 1, true) then
    if name:find("drone", 1, true) or role == "DRONE" then
      is_drone = true
      kind = kind or "HOME_DRONE"
    end
  end

  if ucs:find("EMF", 1, true) or dfcat:find("EMF", 1, true) then
    if role == "DRONE" or ucs:find("DRONE", 1, true) or dfcat:find("DRONE", 1, true) then
      is_drone = true
      kind = kind or "EMF_DRONE"
    end
  end

  if ucs:find("IDM_TEXTURE", 1, true) or dfcat:find("IDM_TEXTURE", 1, true) then
    if role == "DRONE" or ucs:find("DRONE", 1, true) or dfcat:find("DRONE", 1, true) then
      is_drone = true
      kind = kind or "IDM_DRONE"
    end
  end

  -- 4) fxflavor-Hint aus Export-Presets
  if flavor:find("DRONEFXV1", 1, true) then
    is_drone = true
    if not kind then
      if ucs:find("IDM", 1, true) or dfcat:find("IDM", 1, true) then
        kind = "IDM_DRONE"
      elseif ucs:find("EMF", 1, true) or dfcat:find("EMF", 1, true) then
        kind = "EMF_DRONE"
      elseif ucs:find("HOME_ATMOS", 1, true) or dfcat:find("HOME_ATMOS", 1, true) then
        kind = "HOME_DRONE"
      end
    end
  end

  -- 5) Name-Heuristik (Fallback)
  if (not is_drone) and name:find("drone", 1, true) then
    is_drone = true
  end

  if not is_drone then
    return nil
  end

  return kind or "GENERIC_DRONE"
end

local function apply_drone_autotag(it)
  local kind = classify_drone_item(it)
  if not kind then return false end

  local changed = false

  -- Rolle setzen, falls leer
  if not is_nonempty(it.role) then
    it.role = "Drone"
    changed = true
  end

  -- df95_catid nur setzen, wenn leer
  if not is_nonempty(it.df95_catid) then
    if kind == "HOME_DRONE" then
      it.df95_catid = "DRONE_HOME_ATMOS"
    elseif kind == "EMF_DRONE" then
      it.df95_catid = "DRONE_EMF_LONG"
    elseif kind == "IDM_DRONE" then
      it.df95_catid = "DRONE_IDM_TEXTURE"
    else
      it.df95_catid = "DRONE_GENERIC"
    end
    changed = true
  end

  -- Drone-Flag / Status markieren
  if not is_nonempty(it.df95_drone_flag) then
    it.df95_drone_flag = kind
    changed = true
  end

  if not is_nonempty(it.ai_status) then
    it.ai_status = "auto_drone_tagged"
    changed = true
  end

  return changed
end

-- Phase LUX: heuristische Drone-Motion/Density/CenterFreq/Form (ohne Audioscan)
local function classify_drone_motion(it)
  if not it then return nil end

  local function up(v) return tostring(v or ""):upper() end
  local function low(v) return tostring(v or ""):lower() end

  local ucs    = up(it.ucs_category)
  local dfcat  = up(it.df95_catid)
  local role   = up(it.role)
  local flavor = up(it.fxflavor)
  local name   = low(it.name or it.filepath or "")

  local motion = nil
  local density = nil
  local center = nil
  local form = nil

  -- Motion
  if name:find("pulse", 1, true) or name:find("rhythm", 1, true) then
    motion = "PULSE"
  elseif name:find("swell", 1, true) or name:find("rise", 1, true) or name:find("fall", 1, true) then
    motion = "SWELL"
  elseif name:find("texture", 1, true) or name:find("grain", 1, true) or name:find("noise", 1, true) then
    motion = "TEXTURE"
  elseif ucs:find("TEXTURE", 1, true) or dfcat:find("TEXTURE", 1, true) then
    motion = "TEXTURE"
  elseif ucs:find("PULSE", 1, true) or dfcat:find("PULSE", 1, true) then
    motion = "PULSE"
  elseif ucs:find("SWELL", 1, true) or dfcat:find("SWELL", 1, true) then
    motion = "SWELL"
  elseif flavor:find("DRONEFXV1", 1, true) then
    -- Presets liefern meistens Bewegung
    motion = "MOVEMENT"
  end

  if not motion then
    if role == "DRONE" then
      motion = "STATIC"
    else
      motion = nil
    end
  end

  -- Density (nur heuristisch aus Namen)
  if name:find("thin", 1, true) or name:find("sparse", 1, true) or name:find("light", 1, true) then
    density = "LOW"
  elseif name:find("wall", 1, true) or name:find("full", 1, true) or name:find("dense", 1, true) or name:find("heavy", 1, true) then
    density = "HIGH"
  elseif name:find("texture", 1, true) or name:find("grain", 1, true) or name:find("noise", 1, true) then
    density = "HIGH"
  end

  -- Center-Frequency (aus Namen)
  if name:find("sub", 1, true) or name:find("low", 1, true) or name:find("bass", 1, true) or name:find("dark", 1, true) then
    center = "LOW"
  elseif name:find("air", 1, true) or name:find("high", 1, true) or name:find("bright", 1, true) or name:find("shimmer", 1, true) then
    center = "HIGH"
  end

  -- Form (stilistische Zuordnung)
  if name:find("pad", 1, true) then
    if motion == "PULSE" then
      form = "PULSING_PAD"
    elseif motion == "MOVEMENT" or motion == "SWELL" then
      form = "MOVING_PAD"
    else
      form = "PAD"
    end
  elseif name:find("growl", 1, true) or name:find("grit", 1, true) or name:find("grind", 1, true) then
    form = "GROWL"
  elseif name:find("texture", 1, true) or name:find("grain", 1, true) or name:find("noise", 1, true) then
    form = "TEXTURE"
  elseif motion == "TEXTURE" then
    form = "TEXTURE"
  end

  -- Wenn gar kein Drone-Bezug erkennbar ist, abbrechen
  local flag = tostring(it.df95_drone_flag or ""):upper()
  if not motion and flag == "" and role ~= "DRONE" then
    return nil
  end

  return {
    motion     = motion,
    density    = density,
    centerfreq = center,
    form       = form,
  }
end

local function apply_drone_lux(it)
  local dx = classify_drone_motion(it)
  if not dx then return false end

  local changed = false

  if dx.motion and not is_nonempty(it.df95_drone_motion) then
    it.df95_drone_motion = dx.motion
    changed = true
  end
  if dx.density and not is_nonempty(it.df95_drone_density) then
    it.df95_drone_density = dx.density
    changed = true
  end
  if dx.centerfreq and not is_nonempty(it.df95_drone_centerfreq) then
    it.df95_drone_centerfreq = dx.centerfreq
    changed = true
  end
  if dx.form and not is_nonempty(it.df95_drone_form) then
    it.df95_drone_form = dx.form
    changed = true
  end

  if changed and not is_nonempty(it.ai_status) then
    it.ai_status = "auto_drone_lux"
  end

  return changed
end

-- Phase X: Echte Audioanalyse für Drone/Atmos-Files (Luxus-Variante)
-- Nutzt PCM_Source_GetPeaks, um grobe Amplituden- und Spektral-Merkmale zu bestimmen.
-- Liefert ein kleines Diskret-Merkmalsset zurück:
--   dx.motion      = "STATIC" | "MOVEMENT" | "PULSE" | "SWELL"
--   dx.density     = "LOW" | "MED" | "HIGH"
--   dx.centerfreq  = "LOW" | "MID" | "HIGH"
--   dx.form        = "PAD" | "TEXTURE" | "PULSING_PAD" | "SWELL" | "GROWL"
--
-- Alle Ausgaben sind bewusst grob, aber stabil genug, um mit den Drone-Pack-Presets
-- (DRONE_HIGH_PAD, DRONE_LOW_TEXTURE, DRONE_TENSION_GRIT, ...) zu harmonieren.
--
-- WICHTIG:
--   * Robust gegen fehlende Files / fehlende API-Funktionen
--   * CPU-Limitierung über resampled Peaks (kein Full-FFT über die komplette Datei)

local function analyze_drone_audio(it)
  local path = tostring(it.filepath or "")
  if path == "" then return nil end

  -- Nur Drones/Atmos wirklich anfassen (alles andere früh raus)
  local role   = tostring(it.role or ""):upper()
  local dflag  = tostring(it.df95_drone_flag or ""):upper()
  local dfcat  = tostring(it.df95_catid or ""):upper()
  local ucs    = tostring(it.ucs_category or ""):upper()

  if role ~= "DRONE"
     and not dflag:find("DRONE", 1, true)
     and not dfcat:find("DRONE", 1, true)
     and not ucs:find("DRONE", 1, true)
  then
    return nil
  end

  if not r or not r.PCM_Source_CreateFromFile or not r.PCM_Source_GetPeaks then
    -- Alte REAPER-Version oder exotische Umgebung: lieber nichts tun.
    return nil
  end

  -- Helper für sichere Bit-Operationen (Lua 5.3+)
  local function b_and(a, b) return a & b end
  local function b_rshift(a, bits) return a >> bits end

  local src = r.PCM_Source_CreateFromFile(path)
  if not src then
    return nil
  end

  local ok, dx = pcall(function()
    ----------------------------------------------------------
    -- PCM-Source Basisdaten
    ----------------------------------------------------------
    local length, is_qn = r.GetMediaSourceLength(src)
    if not length or length <= 0 then
      return nil
    end
    local sr = r.GetMediaSourceSampleRate(src) or 44100
    if sr <= 0 then sr = 44100 end

    local nch = r.GetMediaSourceNumChannels(src) or 2
    if nch < 1 then nch = 1 end
    if nch > 2 then nch = 2 end -- wir behandeln nur 1–2 Kanäle explizit

    -- MIDI / Nicht-Audio früh raus
    local stype = ""
    if r.GetMediaSourceType then
      stype = (r.GetMediaSourceType(src) or ""):upper()
      if stype == "MIDI" then
        return nil
      end
    end

    ----------------------------------------------------------
    -- Peaks holen (ein resampled Block über die gesamte Datei)
    ----------------------------------------------------------
    local MAX_PEAK_SLOTS = 1024             -- max. „Zeit-Slots“ über die gesamte Länge
    local peak_slots = MAX_PEAK_SLOTS
    -- Wir verwenden eine mittlere Peakrate, die die Datei in etwa in MAX_PEAK_SLOTS Segmente teilt.
    -- PCM_Source_GetPeaks arbeitet intern mit Peakrate = Samples pro Sekunde / gewünschten Peaks pro Sekunde.
    local peakrate = 0
    if length > 0 then
      -- simple Heuristik: Peaks ~ max 1024 Slots über die gesamte Länge
      peakrate = (MAX_PEAK_SLOTS / length)
    end
    if peakrate <= 0 then
      peakrate = 1.0
    end

    local numsamplesperchannel = MAX_PEAK_SLOTS
    local want_extra_type = 115 -- 's' => Spektral-Info (Frequency+Tonality)
    local buf = r.new_array(nch * numsamplesperchannel * 3)

    local ret = r.PCM_Source_GetPeaks(src, peakrate, 0.0, nch, numsamplesperchannel, want_extra_type, buf)
    if not ret or ret == 0 then
      return nil
    end

    -- ret: untere 20 Bit = Samplecount, Bit24 = extra_type_available
    local sample_count = b_and(ret, 0xFFFFF)
    if sample_count <= 0 then
      return nil
    end
    if sample_count > numsamplesperchannel then
      sample_count = numsamplesperchannel
    end

    local has_extra = (b_and(ret, 0x100000) ~= 0) or (b_and(ret, 0x1000000) ~= 0)

    local block_stride = sample_count * nch
    local amp_values = {}
    local freq_values = {}
    local tonality_values = {}

    ----------------------------------------------------------
    -- Amplituden-Feature (STATIC / MOVEMENT / PULSE / SWELL)
    -- und spektrale Zusatzwerte aus dem extra-Block
    ----------------------------------------------------------
    for i = 0, sample_count - 1 do
      local max_sum = 0.0
      local min_sum = 0.0

      for ch = 0, nch - 1 do
        local idx_max = (i * nch) + ch + 1
        local idx_min = block_stride + (i * nch) + ch + 1

        local v_max = buf[idx_max] or 0.0
        local v_min = buf[idx_min] or 0.0

        max_sum = max_sum + math.abs(v_max)
        min_sum = min_sum + math.abs(v_min)
      end

      local amp = (max_sum + min_sum) / (2.0 * nch)
      amp_values[#amp_values + 1] = amp

      if has_extra then
        -- Extra-Block: spektrale Kodierung (Frequency & Tonality in einem Int)
        local idx_extra = (2 * block_stride) + (i * nch) + 1
        local v_extra = buf[idx_extra]
        if v_extra and v_extra ~= 0 then
          local iv = math.floor(v_extra + 0.5)
          if iv < 0 then iv = 0 end

          local freq_index = b_and(iv, 0x7FFF)          -- 15 Bit
          local tonal_index = b_and(b_rshift(iv, 15), 0x3FFF) -- nächste 14 Bit

          freq_values[#freq_values + 1] = freq_index
          tonality_values[#tonality_values + 1] = tonal_index
        end
      end
    end

    if #amp_values < 4 then
      -- zu wenig Information, um eine sinnvolle Klassifikation zu bauen
      return nil
    end

    ----------------------------------------------------------
    -- Amplituden-Metriken
    ----------------------------------------------------------
    local amp_min, amp_max = 1e9, -1e9
    local diff_sum_sq = 0.0
    local diff_count = 0

    for i = 1, #amp_values do
      local a = amp_values[i]
      if a < amp_min then amp_min = a end
      if a > amp_max then amp_max = a end
      if i > 1 then
        local d = a - amp_values[i-1]
        diff_sum_sq = diff_sum_sq + d*d
        diff_count = diff_count + 1
      end
    end

    local dyn_range = amp_max - amp_min
    local motion_index = 0.0
    if diff_count > 0 then
      motion_index = math.sqrt(diff_sum_sq / diff_count)
    end

    -- grobe Segment-Mittelwerte (Anfang / Mitte / Ende) zur Erkennung von Swells
    local function segment_avg(from_norm, to_norm)
      local n = #amp_values
      local i1 = math.floor(1 + from_norm * (n-1))
      local i2 = math.floor(1 + to_norm   * (n-1))
      if i1 < 1 then i1 = 1 end
      if i2 < i1 then i2 = i1 end
      if i2 > n then i2 = n end
      local sum = 0.0
      local cnt = 0
      for i = i1, i2 do
        sum = sum + amp_values[i]
        cnt = cnt + 1
      end
      if cnt == 0 then return 0.0 end
      return sum / cnt
    end

    local seg_start = segment_avg(0.0, 0.2)
    local seg_mid   = segment_avg(0.4, 0.6)
    local seg_end   = segment_avg(0.8, 1.0)

    ----------------------------------------------------------
    -- Spektrale Metriken (Center-Frequency & Tonality)
    ----------------------------------------------------------
    local avg_freq_index = nil
    local avg_tonality_index = nil

    if #freq_values > 0 then
      local sf, st = 0.0, 0.0
      for i = 1, #freq_values do
        sf = sf + freq_values[i]
      end
      for i = 1, #tonality_values do
        st = st + tonality_values[i]
      end
      avg_freq_index = sf / #freq_values
      if #tonality_values > 0 then
        avg_tonality_index = st / #tonality_values
      end
    end

    -- Normierung: 15 Bit => 0..32767, 14 Bit => 0..16383
    local freq_norm = nil
    if avg_freq_index then
      freq_norm = math.max(0.0, math.min(1.0, avg_freq_index / 32767.0))
    end

    local tonal_norm = nil
    if avg_tonality_index then
      tonal_norm = math.max(0.0, math.min(1.0, avg_tonality_index / 16383.0))
    end

    ----------------------------------------------------------
    -- Diskrete Klassen ableiten
    ----------------------------------------------------------

    -- 1) Center-Frequency
    local center_band = nil
    if freq_norm then
      if freq_norm < 0.33 then
        center_band = "LOW"
      elseif freq_norm < 0.67 then
        center_band = "MID"
      else
        center_band = "HIGH"
      end
    end

    -- 2) Dichte (LOW/MED/HIGH) über Tonalität + Amplituden-Schwankungen
    local density = nil
    if tonal_norm then
      -- hoher Tonalitätswert => eher "clean/pure" => niedrigere Dichte
      if tonal_norm >= 0.7 then
        density = "LOW"
      elseif tonal_norm >= 0.4 then
        density = "MED"
      else
        density = "HIGH"
      end
    else
      -- Fallback nur über Dynamik
      if dyn_range < 0.04 then
        density = "LOW"
      elseif dyn_range < 0.12 then
        density = "MED"
      else
        density = "HIGH"
      end
    end

    -- 3) Bewegungs-Typ (motion)
    local motion = "STATIC"
    if dyn_range < 0.03 and motion_index < 0.01 then
      motion = "STATIC"
    else
      -- Pulsende Dinge: hohe Frame-to-Frame-Änderung, aber eher moderater Gesamtbereich
      if motion_index > 0.06 and dyn_range > 0.05 then
        -- Swell-Erkennung vor PULSE
        local swell_up   = (seg_mid > seg_start + 0.04) and (seg_mid >= seg_end)
        local swell_down = (seg_mid > seg_end   + 0.04) and (seg_mid >= seg_start)
        if swell_up or swell_down then
          motion = "SWELL"
        else
          motion = "PULSE"
        end
      elseif dyn_range > 0.08 or motion_index > 0.03 then
        motion = "MOVEMENT"
      else
        motion = "STATIC"
      end
    end

    -- 4) Form-Heuristik (PAD/TEXTURE/PULSING_PAD/SWELL/GROWL)
    local form = nil

    if motion == "SWELL" then
      form = "SWELL"
    elseif center_band == "LOW" and density == "HIGH" and dyn_range > 0.08 then
      form = "GROWL"
    elseif motion == "PULSE" then
      if density == "HIGH" then
        form = "PULSING_PAD"
      else
        form = "PULSING_PAD"
      end
    elseif density == "HIGH" then
      form = "TEXTURE"
    else
      form = "PAD"
    end

    local dx = {
      motion     = motion,
      density    = density,
      centerfreq = center_band,
      form       = form,
    }

    -- nur zurückgeben, wenn mindestens eine sinnvolle Info vorliegt
    if not dx.motion and not dx.density and not dx.centerfreq and not dx.form then
      return nil
    end

    return dx
  end)

  r.PCM_Source_Destroy(src)

  if not ok then
    -- Bei Analyse-Fehlern lieber nichts setzen, als das Skript zu killen.
    return nil
  end

  return dx
end

local function apply_drone_phase_x(it)
  local dx = analyze_drone_audio(it)
  if not dx then return false end

  local changed = false

  if dx.motion and not is_nonempty(it.df95_drone_motion) then
    it.df95_drone_motion = dx.motion
    changed = true
  end
  if dx.density and not is_nonempty(it.df95_drone_density) then
    it.df95_drone_density = dx.density
    changed = true
  end
  if dx.centerfreq and not is_nonempty(it.df95_drone_centerfreq) then
    it.df95_drone_centerfreq = dx.centerfreq
    changed = true
  end
  if dx.form and not is_nonempty(it.df95_drone_form) then
    it.df95_drone_form = dx.form
    changed = true
  end

  if changed and not is_nonempty(it.ai_status) then
    it.ai_status = "auto_drone_x"
  end

  return changed
end

------------------------------------------------------------
-- Apply-Logiken
------------------------------------------------------------

local function apply_suggestions_safe(it, level)
  -- Nur HIGH-Confidence, nur leere/generische Felder
  if level ~= "HIGH" then
    return false
  end

  local changed = false

  if is_nonempty(it.home_zone_suggested) and not is_nonempty(it.home_zone) then
    it.home_zone = it.home_zone_suggested
    changed = true
  end
  if is_nonempty(it.home_zone_sub_suggested) and not is_nonempty(it.home_zone_sub) then
    it.home_zone_sub = it.home_zone_sub_suggested
    changed = true
  end
  if is_nonempty(it.ucs_category_suggested) then
    if (not it.ucs_category) or it.ucs_category == "" or is_generic_ucs(it.ucs_category) then
      it.ucs_category = it.ucs_category_suggested
      changed = true
    end
  end
  if is_nonempty(it.df95_catid_suggested) and not is_nonempty(it.df95_catid) then
    it.df95_catid = it.df95_catid_suggested
    changed = true
  end

  if changed then
    it.ai_status = "auto_safe"
  end

  return changed
end

local function apply_suggestions_aggressive(it, level)
  -- HIGH: darf generische UCS überschreiben, leere Felder füllen
  -- MED : darf nur leere Felder füllen
  local changed = false

  local function can_apply_home(current, lvl)
    if not is_nonempty(current) then return true end
    -- Vorläufig konservativ: existierende HomeZone/Sub werden nicht überschrieben.
    return false
  end

  local lvl = level or "LOW"

  if is_nonempty(it.home_zone_suggested) and can_apply_home(it.home_zone, lvl) then
    it.home_zone = it.home_zone_suggested
    changed = true
  end
  if is_nonempty(it.home_zone_sub_suggested) and can_apply_home(it.home_zone_sub, lvl) then
    it.home_zone_sub = it.home_zone_sub_suggested
    changed = true
  end

  if is_nonempty(it.ucs_category_suggested) then
    if lvl == "HIGH" then
      if (not it.ucs_category) or it.ucs_category == "" or is_generic_ucs(it.ucs_category) then
        it.ucs_category = it.ucs_category_suggested
        changed = true
      end
    elseif lvl == "MED" then
      if (not it.ucs_category) or it.ucs_category == "" then
        it.ucs_category = it.ucs_category_suggested
        changed = true
      end
    end
  end

  if is_nonempty(it.df95_catid_suggested) then
    if not is_nonempty(it.df95_catid) then
      it.df95_catid = it.df95_catid_suggested
      changed = true
    end
  end

  if changed then
    if lvl == "HIGH" then
      it.ai_status = "auto_high"
    elseif lvl == "MED" then
      it.ai_status = "auto_med"
    else
      it.ai_status = "auto"
    end
  end

  return changed
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local default_db = get_default_db_path()
  local ok, csv = r.GetUserInputs(
    "DF95 AutoIngest V3 – Modus wählen",
    4,
    "Mode (ANALYZE/SAFE/AGGR),High-Threshold (0-1),Med-Threshold (0-1),Subset-Only? (0=alle,1=Subset)",
    "SAFE,0.85,0.65,0"
  )
  if not ok then return end

  local mode_str, high_str, med_str, subset_str = csv:match("([^,]*),([^,]*),([^,]*),([^,]*)")
  mode_str = (mode_str or ""):upper()
  local high_thr = tonumber(high_str) or 0.85
  local med_thr  = tonumber(med_str)  or 0.65

  if high_thr < 0.0 then high_thr = 0.0 end
  if high_thr > 1.0 then high_thr = 1.0 end
  if med_thr < 0.0 then med_thr = 0.0 end
  if med_thr > 1.0 then med_thr = 1.0 end
  if med_thr > high_thr then
    med_thr = high_thr
  end
  local subset_only = tonumber(subset_str or "0") == 1
  local subset_map = nil
  if subset_only then
    subset_map, err = load_subset_map()
    if not subset_map then
      r.ShowMessageBox("Subset-Mode angefordert, aber Subset-Datei konnte nicht geladen werden:\n" .. tostring(err or "unbekannt") .. "\nEs wird auf ALLE Items zurückgefallen.", "DF95 AutoIngest V3", 0)
      subset_only = false
    end
  end


  if mode_str ~= "ANALYZE" and mode_str ~= "SAFE" and mode_str ~= "AGGR" then
    r.ShowMessageBox("Ungültiger Modus: " .. tostring(mode_str) .. "\nErlaubt: ANALYZE, SAFE, AGGR", "DF95 AutoIngest V3", 0)
    return
  end

  local db_path = default_db
  local f, err = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox("JSON-Datenbank nicht gefunden:\n" .. tostring(db_path) .. "\n\nBitte zuerst den DF95 SampleDB Scanner / Exporter ausführen.", "DF95 AutoIngest V3", 0)
    return
  end

  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    r.ShowMessageBox("Fehler beim Lesen der JSON-Datenbank:\n" .. tostring(derr), "DF95 AutoIngest V3", 0)
    return
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    r.ShowMessageBox("SampleDB enthält keine Items oder hat ein unbekanntes Format.", "DF95 AutoIngest V3", 0)
    return
  end

  local total = #items
  local cnt_high, cnt_med, cnt_low = 0, 0, 0
  local applied_safe, applied_aggr = 0, 0
  local subset_count = 0

  local changes = {}
  local run_meta = {
    ts           = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    mode         = mode_str,
    high_thr     = high_thr,
    med_thr      = med_thr,
    subset_only  = subset_only,
    subset_size  = 0, -- wird später mit subset_count befüllt
    db_path      = db_path,
  }

  for _, it in ipairs(items) do
    local do_process = true
    if subset_only and subset_map then
      local fp = tostring(it.filepath or "")
      if not subset_map[fp] then
        do_process = false
      end
    end

    if not do_process then
      goto continue_item
    end

    subset_count = subset_count + 1

    local level, conf = classify_confidence(it, high_thr, med_thr)

    if level == "HIGH" then
      cnt_high = cnt_high + 1
    elseif level == "MED" then
      cnt_med = cnt_med + 1
    else
      cnt_low = cnt_low + 1
    end

    if mode_str == "ANALYZE" then
      if level == "MED" then
        it.df95_ai_review_flag = "REVIEW_MED"
      elseif level == "LOW" then
        it.df95_ai_review_flag = "REVIEW_LOW"
      else
        it.df95_ai_review_flag = "OK_HIGH"
      end
    elseif mode_str == "SAFE" then
      local before_state = snapshot_item_state(it)
      local changed = apply_suggestions_safe(it, level)
      if changed then
        applied_safe = applied_safe + 1
        local after_state = snapshot_item_state(it)
        changes[#changes+1] = {
          filepath = tostring(it.filepath or ""),
          before   = before_state,
          after    = after_state,
        }
      end
    elseif mode_str == "AGGR" then
      local before_state = snapshot_item_state(it)
      local changed = apply_suggestions_aggressive(it, level)
      if changed then
        applied_aggr = applied_aggr + 1
        local after_state = snapshot_item_state(it)
        changes[#changes+1] = {
          filepath = tostring(it.filepath or ""),
          before   = before_state,
          after    = after_state,
        }
      end
    end


    -- Phase V4: Drone-Intelligence läuft unabhängig vom Modus (ANALYZE/SAFE/AGGR)
    -- 1) Phase D2: Drone-Autotagging (role/df95_catid/df95_drone_flag/ai_status, nur wenn Felder leer sind)
    apply_drone_autotag(it)

    -- 2) Phase LUX: heuristische Motion/Density/CenterFreq/Form (nur leere Drone-Felder werden befüllt)
    apply_drone_lux(it)

    -- 3) Phase X (Stub): vorbereitet für zukünftige Audioanalyse
    apply_drone_phase_x(it)


::continue_item::
  end

  run_meta.subset_size = subset_count

  if (mode_str == "SAFE" or mode_str == "AGGR") and #changes > 0 then
    run_meta.items = changes
    write_changelog_entry(run_meta)
  end

  -- Nur schreiben, wenn Modus nicht ANALYZE ist? 
  -- Wir entscheiden: ANALYZE schreibt auch die review_flags, weil diese zur manuellen Arbeit dienen.
  local out_text = encode_json_table(db, 0)
  local wf, werr = io.open(db_path, "w")
  if not wf then
    r.ShowMessageBox("Fehler beim Schreiben der JSON-Datenbank:\n" .. tostring(werr), "DF95 AutoIngest V3", 0)
    return
  end
  wf:write(out_text)
  wf:close()

  local msg = {}
  msg[#msg+1] = "DF95 AutoIngest V3 abgeschlossen."
  msg[#msg+1] = ""
  msg[#msg+1] = "DB: " .. tostring(db_path)
  msg[#msg+1] = string.format("Items gesamt: %d", total)
  msg[#msg+1] = string.format("HIGH (>= %.2f): %d", high_thr, cnt_high)
  msg[#msg+1] = string.format("MED  (>= %.2f): %d", med_thr, cnt_med)
  msg[#msg+1] = string.format("LOW           : %d", cnt_low)
  if subset_only and subset_map then
    msg[#msg+1] = ""
    msg[#msg+1] = string.format("Subset-Mode aktiv: %d Items im Subset verarbeitet.", subset_count)
  end

  if mode_str == "ANALYZE" then
    msg[#msg+1] = ""
    msg[#msg+1] = "Modus: ANALYZE (nur df95_ai_review_flag aktualisiert, keine Field-Applies)."
  elseif mode_str == "SAFE" then
    msg[#msg+1] = ""
    msg[#msg+1] = "Modus: SAFE"
    msg[#msg+1] = string.format("Angewendete Suggestions (SAFE): %d", applied_safe)
  elseif mode_str == "AGGR" then
    msg[#msg+1] = ""
    msg[#msg+1] = "Modus: AGGRESSIVE"
    msg[#msg+1] = string.format("Angewendete Suggestions (AGGR): %d", applied_aggr)
  end

  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 AutoIngest V3", 0)
end

main()
