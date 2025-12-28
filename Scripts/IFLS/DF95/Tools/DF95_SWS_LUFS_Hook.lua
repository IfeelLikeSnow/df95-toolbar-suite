-- @description SWS LUFS Hook (analyze & write console report)
-- @version 1.0
-- @about Versucht SWS-Loudness-Analyse zu triggern. Voraussetzung: SWS installiert.
local r = reaper
local function find(cmds) for _,c in ipairs(cmds) do local id = r.NamedCommandLookup(c); if id ~= 0 then return id end end return 0 end
-- Bekannte Kandidaten (kann je Version variieren)
local candidates = { "_BR_ANALYZE_LOUDNESS", "_SWS_ANALYZE_LOUDNESS", "_BR_NORMALIZE_LOUDNESS" }
local id = find(candidates)
if id == 0 then r.ShowMessageBox("SWS Loudness Analyse nicht gefunden. Bitte SWS installieren/aktivieren.","DF95",0) return end
-- Optional: Items/Tracks selektiert lassen, dann Aktion ausführen
r.Main_OnCommand(id, 0)
r.ShowConsoleMsg("[DF95] SWS Loudness Analyse angestoßen (prüfe Results/Notes/CSV je nach SWS-Einstellung).\n")
