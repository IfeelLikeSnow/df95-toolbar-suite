
-- @description Slicing FadeShape – Auto from Preset/Category
-- @version 1.0
local r = reaper
local function read_json(path)
  local f=io.open(path,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
  return nil
end
local cfg = read_json(reaper.GetResourcePath().."/Data/DF95/Slicing_FadePreset_Overrides.json") or {{}};
local cat = ({r.GetProjExtState(0,"DF95_SLICING","CATEGORY")})[2] or ""
local pre = ({r.GetProjExtState(0,"DF95_SLICING","PRESET")})[2] or ""

local sel = cfg.presets and cfg.presets[pre] or nil
local csel = cfg.categories and cfg.categories[cat] or nil
local def = cfg.default or {{shape="linear", len_in_ms=5, len_out_ms=8}}

local shape = (sel and sel.shape) or (csel and csel.shape) or def.shape or "linear"
local fin   = (sel and sel.len_in_ms) or (csel and csel.len_in_ms) or def.len_in_ms or 5
local fout  = (sel and sel.len_out_ms) or (csel and csel.len_out_ms) or def.len_out_ms or 8

local set = dofile((reaper.GetResourcePath().."/Scripts/IFLS/DF95/_DF95_Slicing_FadeCommon.lua"))
set(shape, fin, fout)
