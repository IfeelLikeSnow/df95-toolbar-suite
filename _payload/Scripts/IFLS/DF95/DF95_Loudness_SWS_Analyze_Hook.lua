
-- @description SWS Offline Loudness Analyze (Hook)
-- @version 1.0
-- @about Triggert SWS Loudness-Analyse falls installiert. Schreibt Status in ExtState/Log.
local r = reaper
local function call_any(keys)
  for _,k in ipairs(keys) do
    local id = r.NamedCommandLookup(k)
    if id and id ~= 0 then
      r.Main_OnCommand(id, 0)
      return k
    end
  end
end

local used = call_any({
  "_SWS_ANALYZE_LOUDNESS",      -- SWS common
  "_BR_ANALYZE_LOUDNESS",       -- Breeder ext
  "_SWS_LOUDNESS_ANALYZE"       -- alt
})

local msg = used and ("triggered: "..used) or "SWS Loudness action not found"
r.SetProjExtState(0, "DF95_MEASURE", "SWS_ANALYZE", msg)
local out = reaper.GetResourcePath().."/Data/DF95/LoudnessHook.log"
local f=io.open(out,"a"); if f then f:write(os.date().."  "..msg.."\n"); f:close() end
r.ShowConsoleMsg("[DF95] Offline Loudness Analyze: "..msg.."\n")
