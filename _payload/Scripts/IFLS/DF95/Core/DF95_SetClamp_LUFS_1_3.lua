-- @description Set Humanize LUFS clamp to ±1.3
-- @version 0.0.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local cfg = res..sep.."Data"..sep.."DF95"..sep.."DF95_Humanize_Config.json"
local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function writeall(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s); f:close(); return true end
local raw = readall(cfg) or "{}"
local t = reaper.JSON_Decode and reaper.JSON_Decode(raw) or {}
t = t or {}; t.clamp_lufs = 1.3
local out = reaper.JSON_Encode and reaper.JSON_Encode(t) or raw
writeall(cfg, out)
reaper.ShowMessageBox("Humanize Clamp gesetzt auf ±1.3 LUFS", "DF95", 0)
