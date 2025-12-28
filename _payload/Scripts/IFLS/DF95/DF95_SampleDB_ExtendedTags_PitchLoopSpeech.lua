-- @description DF95_SampleDB_ExtendedTags_PitchLoopSpeech
-- @version 1.0
-- @author DF95
-- @about
--   Erweiterung der DF95-SampleDB-Analyse um:
--     - Tonhöhen-Metadaten (pitch_hz, pitch_note, pitch_confidence)
--     - Loop-Erkennung (is_loop, loop_confidence)
--     - Sprach/Speech-Erkennung (is_speech, speech_confidence)
--
--   Dieses Script arbeitet primär über Dateinamen-Heuristiken
--   (z.B. "Kick_C2_120bpm_loop.wav", "vox_talk_01.wav") und ergänzt
--   eine bestehende DF95_SampleDB.json um neue Felder.
--
--   Integration:
--     - erwartet eine bestehende DF95_SampleDB.json (oder konfigurierbarer Pfad)
--     - liest sie ein, reichert jeden Eintrag mit neuen Feldern an,
--       und schreibt die JSON-Datei zurück.

local r = reaper

local CFG = {
  sampledb_relpath = "Data/DF95/DF95_SampleDB.json",
}

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 SampleDB Extended Tags", 0)
end

local function get_resource_based_path(relpath)
  local sep = package.config:sub(1,1)
  local base = r.GetResourcePath()
  local full = base .. sep .. relpath
  return full:gsub("\\","/")
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function decode_json(str)
  local ok, res = pcall(function() return assert(load("return " .. str))() end)
  if ok and type(res) == "table" then
    return res
  end
  return nil, "JSON parse failed"
end

local function encode_json_lua(tbl, indent)
  indent = indent or 0
  local function esc(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\"", "\\\"")
    s = s:gsub("\n", "\\n")
    return s
  end
  local function encode_val(v, level)
    level = level or 0
    local pad = string.rep("  ", level)
    if type(v) == "table" then
      local is_array = true
      local idx = 1
      for k,_ in pairs(v) do
        if k ~= idx then
          is_array = false
          break
        end
        idx = idx+1
      end
      local parts = {}
      if is_array then
        for _,vv in ipairs(v) do
          table.insert(parts, encode_val(vv, level+1))
        end
        return "[ " .. table.concat(parts, ", ") .. " ]"
      else
        for k,vv in pairs(v) do
          local key = '"' .. esc(tostring(k)) .. '"'
          table.insert(parts, "\n" .. pad .. "  " .. key .. ": " .. encode_val(vv, level+1))
        end
        return "{" .. table.concat(parts, ",") .. "\n" .. pad .. "}"
      end
    elseif type(v) == "string" then
      return '"' .. esc(v) .. '"'
    elseif type(v) == "number" then
      return tostring(v)
    elseif type(v) == "boolean" then
      return v and "true" or "false"
    else
      return "null"
    end
  end
  return encode_val(tbl, indent)
end

-- Pitch aus Dateinamen
local NOTE_MAP = {
  C = 0, ["C#"] = 1, Db = 1,
  D = 2, ["D#"] = 3, Eb = 3,
  E = 4,
  F = 5, ["F#"] = 6, Gb = 6,
  G = 7, ["G#"] = 8, Ab = 8,
  A = 9, ["A#"] = 10, Bb = 10,
  B = 11,
}

local function midi_to_hz(m)
  return 440.0 * (2 ^ ((m - 69) / 12))
end

local function parse_note_from_filename(name)
  local patterns = {
    "([A-G][b#]?)(%d)",
    "_([A-G][b#]?)(%d)_",
    "[- ]([A-G][b#]?)(%d)",
  }
  name = name or ""
  for _,pat in ipairs(patterns) do
    local note, oct = name:match(pat)
    if note and oct then
      local base = NOTE_MAP[note]
      if base then
        local octave = tonumber(oct) or 3
        local midi = base + (octave + 1) * 12
        local hz = midi_to_hz(midi)
        local note_str = note .. oct
        return {
          midi = midi,
          note = note_str,
          hz   = hz,
          confidence = 0.7,
          source = "filename",
        }
      end
    end
  end
  return nil
end

local function parse_loop_from_filename(name)
  name = (name or ""):lower()
  local is_loop = false
  if name:match("loop") or name:match("_lp") or name:match("looped") then
    is_loop = true
  end
  local conf = is_loop and 0.7 or 0.0
  return is_loop, conf, "filename"
end

local function parse_speech_from_filename(name)
  name = (name or ""):lower()
  local is_speech = false
  if name:match("vox") or name:match("vocal") or name:match("voice") or name:match("speech") or name:match("talk") or name:match("dialog") then
    is_speech = true
  end
  local conf = is_speech and 0.7 or 0.0
  return is_speech, conf, "filename"
end

local function extend_sampledb()
  local path = get_resource_based_path(CFG.sampledb_relpath)
  if not file_exists(path) then
    msg("SampleDB JSON nicht gefunden:\n" .. path)
    return
  end

  local f = io.open(path, "r")
  if not f then
    msg("Konnte SampleDB nicht öffnen:\n" .. path)
    return
  end
  local content = f:read("*a")
  f:close()

  local db, err = decode_json(content)
  if not db or type(db) ~= "table" then
    msg("Konnte SampleDB nicht parsen:\n" .. (err or "unknown error"))
    return
  end

  local changed = 0

  for _, entry in ipairs(db) do
    if type(entry) == "table" then
      local path = entry.path or entry.file or ""
      local fname = path:match("([^/\\]+)$") or path

      local pitch = parse_note_from_filename(fname)
      if pitch then
        entry.pitch_hz         = pitch.hz
        entry.pitch_note       = pitch.note
        entry.pitch_midi       = pitch.midi
        entry.pitch_confidence = pitch.confidence
        entry.pitch_source     = pitch.source
      else
        entry.pitch_hz         = entry.pitch_hz         or nil
        entry.pitch_note       = entry.pitch_note       or nil
        entry.pitch_midi       = entry.pitch_midi       or nil
        entry.pitch_confidence = entry.pitch_confidence or 0.0
        entry.pitch_source     = entry.pitch_source     or "unknown"
      end

      local is_loop, loop_conf, loop_src = parse_loop_from_filename(fname)
      if is_loop or entry.is_loop == nil then
        entry.is_loop         = is_loop
        entry.loop_confidence = loop_conf
        entry.loop_source     = loop_src
      end

      local is_speech, speech_conf, speech_src = parse_speech_from_filename(fname)
      if is_speech or entry.is_speech == nil then
        entry.is_speech          = is_speech
        entry.speech_confidence  = speech_conf
        entry.speech_source      = speech_src
      end

      changed = changed + 1
    end
  end

  local out = encode_json_lua(db, 0)
  local wf = io.open(path, "w")
  if not wf then
    msg("Konnte SampleDB nicht zum Schreiben öffnen:\n" .. path)
    return
  end
  wf:write(out)
  wf:close()

  msg("SampleDB erweitert.\nEinträge bearbeitet: " .. tostring(changed))
end

local function main()
  local ok, ans = r.GetUserInputs("DF95 SampleDB Extended Tags", 1,
                                  "SampleDB Relativpfad (von REAPER-ResourcePath),extrawidth=200",
                                  CFG.sampledb_relpath)
  if not ok then return end
  if ans and ans ~= "" then
    CFG.sampledb_relpath = ans
  end
  extend_sampledb()
end

main()
