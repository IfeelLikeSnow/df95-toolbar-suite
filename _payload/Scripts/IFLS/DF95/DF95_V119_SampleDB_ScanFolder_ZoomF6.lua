-- @description DF95_V119 SampleDB – Scan Folder (ZoomF6 / Fieldrec) and build JSON DB
-- @version 1.0
-- @author DF95
-- @about
--   Scannt einen Ordner mit WAV-Dateien (z.B. Zoom F6 Fieldrec-Ordner),
--   analysiert Grundparameter (Länge, Kanäle, Dateiname) und erstellt eine
--   einfache DF95 Sample-Datenbank mit groben Typen (KICK/SNARE/HAT/PERC/FX/DRONE/NOISE).
--
--   Die Datenbank wird als JSON in
--     Support/DF95_SampleDB/DF95_SampleDB_ZoomF6.json
--   im REAPER-ResourcePath gespeichert.
--
--   Hinweis:
--   * Dies ist ein heuristisches System ohne KI – es nutzt Dateinamen und Dauer.
--   * Die Typen sind bewusst grob (KICK/SNARE/HAT/PERC/FX/DRONE/NOISE/TEXTURE).
--   * Diese DB kann später von der BeatEngine/ArtistEngine genutzt werden.

local r = reaper

local sep = package.config:sub(1,1)

local function msg(s)
  r.ShowConsoleMsg(tostring(s).."\n")
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

------------------------------------------------------------
-- Simple JSON encoder (minimal)
------------------------------------------------------------

local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  return str
end

local function json_encode_table(t, indent)
  indent = indent or ""
  local next_indent = indent .. "  "
  local is_array = (#t > 0)
  local parts = {}
  if is_array then
    table.insert(parts, "[\n")
    for i, v in ipairs(t) do
      if type(v) == "table" then
        table.insert(parts, next_indent .. json_encode_table(v, next_indent))
      elseif type(v) == "string" then
        table.insert(parts, next_indent .. "\"" .. json_escape(v) .. "\"")
      elseif type(v) == "number" then
        table.insert(parts, next_indent .. tostring(v))
      elseif type(v) == "boolean" then
        table.insert(parts, next_indent .. (v and "true" or "false"))
      else
        table.insert(parts, next_indent .. "null")
      end
      if i < #t then table.insert(parts, ",") end
      table.insert(parts, "\n")
    end
    table.insert(parts, indent .. "]")
  else
    table.insert(parts, "{\n")
    local first = true
    for k, v in pairs(t) do
      if not first then table.insert(parts, ",\n") end
      first = false
      local key = "\"" .. json_escape(k) .. "\""
      if type(v) == "table" then
        table.insert(parts, next_indent .. key .. ": " .. json_encode_table(v, next_indent))
      elseif type(v) == "string" then
        table.insert(parts, next_indent .. key .. ": \"" .. json_escape(v) .. "\"")
      elseif type(v) == "number" then
        table.insert(parts, next_indent .. key .. ": " .. tostring(v))
      elseif type(v) == "boolean" then
        table.insert(parts, next_indent .. key .. ": " .. (v and "true" or "false"))
      else
        table.insert(parts, next_indent .. key .. ": null")
      end
    end
    table.insert(parts, "\n" .. indent .. "}")
  end
  return table.concat(parts)
end

------------------------------------------------------------
-- Folder enumeration helpers
------------------------------------------------------------

local function enum_files_recursive(base_dir, out_list)
  out_list = out_list or {}
  local idx = 0
  while true do
    local fname = r.EnumerateFiles(base_dir, idx)
    if not fname then break end
    local full = join_path(base_dir, fname)
    table.insert(out_list, full)
    idx = idx + 1
  end
  local didx = 0
  while true do
    local sub = r.EnumerateSubdirectories(base_dir, didx)
    if not sub then break end
    local fullsub = join_path(base_dir, sub)
    enum_files_recursive(fullsub, out_list)
    didx = didx + 1
  end
  return out_list
end

------------------------------------------------------------
-- Classification heuristics
------------------------------------------------------------

local function classify_file(path, duration, channels)
  local name = path:match("([^" .. sep .. "]+)$") or path
  local lower = name:lower()

  -- 1) Name-basierte Hinweise
  if lower:find("kick") or lower:find("bd") or lower:find("bassdrum") then
    return "KICK", {"DRUM","LOW","TRANSIENT"}
  end
  if lower:find("snare") or lower:find("sn") then
    return "SNARE", {"DRUM","MID","TRANSIENT"}
  end
  if lower:find("hat") or lower:find("hihat") or lower:find("hh") then
    return "HAT", {"DRUM","HIGH","TRANSIENT"}
  end
  if lower:find("tom") then
    return "PERC", {"DRUM","TOM","MID"}
  end
  if lower:find("fx") or lower:find("sfx") then
    return "FX", {"FX","MIXED"}
  end
  if lower:find("drone") or lower:find("pad") then
    return "DRONE", {"SUSTAIN","TEXTURE"}
  end
  if lower:find("noise") or lower:find("hiss") then
    return "NOISE", {"NOISE","TEXTURE"}
  end

  -- 2) Dauer-basierte Heuristik
  if duration and duration < 0.18 then
    -- sehr kurz -> eher Hat/Click/OneShot
    return "HAT", {"DRUM","SHORT","TRANSIENT"}
  elseif duration and duration < 0.5 then
    -- One-Shot Perc/Drum
    return "PERC", {"DRUM","ONE_SHOT"}
  else
    -- länger -> Drone/Texture/FX
    return "TEXTURE", {"SUSTAIN","TEXTURE"}
  end
end

local function get_wav_info(path)
  local src = r.PCM_Source_CreateFromFile(path)
  if not src then return nil end
  local len, _ = r.GetMediaSourceLength(src)
  local sr = r.GetMediaSourceSampleRate(src)
  local num_ch = r.GetMediaSourceNumChannels(src)
  r.PCM_Source_Destroy(src)
  return {
    length = len or 0,
    samplerate = sr or 48000,
    channels = num_ch or 1,
  }
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local ok, folder = r.GetUserInputs("DF95 SampleDB Scan", 1,
    "Ordnerpfad (z.B. E:/ZoomF6/Session01)", "")
  if not ok or not folder or folder == "" then return end

  -- Normalisieren
  folder = folder:gsub("\"","")
  if folder:sub(-1) == "/" or folder:sub(-1) == "\\" then
    folder = folder:sub(1, -2)
  end

  local all_files = enum_files_recursive(folder, {})
  local wav_files = {}
  for _, p in ipairs(all_files) do
    if p:lower():match("%.wav$") then
      table.insert(wav_files, p)
    end
  end

  if #wav_files == 0 then
    r.ShowMessageBox("Keine WAV-Dateien gefunden im Ordner:\n"..folder, "DF95 SampleDB Scan", 0)
    return
  end

  local res = get_resource_path()
  local out_dir = join_path(res, "Support" .. sep .. "DF95_SampleDB")
  r.RecursiveCreateDirectory(out_dir, 0)

  local db = {}
  for i, p in ipairs(wav_files) do
    r.ShowConsoleMsg(string.format("Scanne (%d/%d): %s\n", i, #wav_files, p))
    local info = get_wav_info(p)
    local typ, tags = classify_file(p, info and info.length, info and info.channels)
    db[#db+1] = {
      path = p,
      type = typ or "UNKNOWN",
      tags = tags or {},
      length_sec = info and info.length or 0,
      samplerate = info and info.samplerate or 0,
      channels = info and info.channels or 0,
    }
  end

  local out_path = join_path(out_dir, "DF95_SampleDB_ZoomF6.json")
  local f = io.open(out_path, "w")
  if not f then
    r.ShowMessageBox("Konnte DB-Datei nicht schreiben:\n"..out_path, "DF95 SampleDB Scan", 0)
    return
  end
  f:write(json_encode_table(db, ""))
  f:close()

  r.ShowMessageBox("Scan abgeschlossen.\nEinträge: "..#db.."\nDB-Datei:\n"..out_path, "DF95 SampleDB Scan", 0)
end

main()
