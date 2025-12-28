
-- DF95_AutoMic_Inserter.lua
-- Auto Mic Inserter for V67g

local r = reaper
package.path = package.path .. ";../?.lua"

local tagger = dofile("DF95_Auto_MicTagger.lua")

local function insert_for_selected()
  local track = r.GetSelectedTrack(0,0)
  if not track then return end
  local _, name = r.GetTrackName(track)
  local rec = tagger.detect_recorder(name)
  local model, pattern, ch = tagger.detect_model(name)
  local chain = tagger.build_name(rec, model, pattern, ch)

  r.TrackFX_AddByName(track, chain, false, -1)
end

insert_for_selected()
