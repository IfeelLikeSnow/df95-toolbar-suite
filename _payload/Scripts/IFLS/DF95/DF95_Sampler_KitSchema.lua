\
-- @description DF95_Sampler_KitSchema
-- @version 1.0
-- @author DF95
-- @about
--   Gemeinsames Kit-Datenmodell fuer DF95-Sampler-Engines (Sitala, RS5k, TX16Wx, ...).
--   Ein Kit besteht aus Slots (je ein Sample) und Meta-Daten (Artist, BPM, Quelle).
--
--   Beispiel:
--     local KitSchema = dofile("DF95_Sampler_KitSchema.lua")
--     local kit = KitSchema.new("Autechre IDM Kit", "Autechre", "SampleDB_V2", 120)
--     KitSchema.add_slot(kit, {
--       id   = "KICK1",
--       file = "C:/Samples/Kick01.wav",
--       root = 36,
--       tags = {"kick","idm"},
--     })
--
--   Ebenso gibt es einen Helper, um aus SampleDB V2-Eintraegen ein Kit zu bauen.

local M = {}

----------------------------------------------------------------
-- Kit-Erzeugung
----------------------------------------------------------------

function M.new(name, artist, source, bpm)
  local kit = {
    meta = {
      name   = name   or "DF95 Kit",
      artist = artist or "",
      source = source or "",
      bpm    = bpm    or 0,
      created_at = os.date("%Y-%m-%d %H:%M:%S"),
    },
    slots = {}
  }
  return kit
end

function M.add_slot(kit, slot)
  if not kit or type(kit) ~= "table" then return end
  if not slot or type(slot) ~= "table" then return end
  if not slot.file or slot.file == "" then return end
  slot.id   = slot.id   or ("SLOT_" .. tostring(#kit.slots+1))
  slot.root = slot.root or 60
  slot.vel_layer = slot.vel_layer or 1
  kit.slots[#kit.slots+1] = slot
end

----------------------------------------------------------------
-- Helper fuer SampleDB V2
----------------------------------------------------------------

local function guess_slot_id_from_entry(e, idx)
  if e.tags and type(e.tags) == "table" then
    for _, t in ipairs(e.tags) do
      local tl = tostring(t):lower()
      if tl:find("kick") then return "KICK" .. idx end
      if tl:find("snare") or tl:find("clap") then return "SNARE" .. idx end
      if tl:find("hat") or tl:find("hihat") then return "HAT" .. idx end
      if tl:find("tom") then return "TOM" .. idx end
    end
  end
  if e.material == "drum" then
    return "DRUM" .. idx
  end
  if e.material == "tonal" then
    return "TONAL" .. idx
  end
  if e.material == "noise" then
    return "FX" .. idx
  end
  return "SLOT" .. idx
end

local function guess_root_from_entry(e, base_note, idx)
  base_note = base_note or 36
  return base_note + (idx - 1)
end

-- entries: Liste von SampleDB V2-Eintraegen (z.B. gefiltert nach Artist)
-- opts: { name, artist, source, bpm, base_note }
function M.build_from_sampledb_entries(entries, opts)
  opts = opts or {}
  local name   = opts.name   or "DF95 Kit from SampleDB V2"
  local artist = opts.artist or ""
  local source = opts.source or "SampleDB_V2"
  local bpm    = opts.bpm    or 0
  local base_note = opts.base_note or 36

  local kit = M.new(name, artist, source, bpm)

  if type(entries) ~= "table" then
    return kit
  end

  local idx = 1
  for _, e in ipairs(entries) do
    if e.file and e.file ~= "" then
      local slot_id = guess_slot_id_from_entry(e, idx)
      local root = guess_root_from_entry(e, base_note, idx)
      local tags = {}
      if e.material then table.insert(tags, e.material) end
      if e.tags and type(e.tags) == "table" then
        for _, t in ipairs(e.tags) do table.insert(tags, t) end
      end
      M.add_slot(kit, {
        id   = slot_id,
        file = e.file,
        root = root,
        tags = tags,
      })
      idx = idx + 1
    end
  end

  return kit
end

return M
