
-- DF95_Auto_MicTagger.lua
-- Automatic Mic Tagging Engine for DF95

local r = reaper

local recorders = {
  ZF6 = "ZF6",
  F6  = "ZF6",
  H5  = "H5",
  H5N = "H5",
}

local models = {
  ["MD400"] = {model="MD400", pattern="Cardioid",  ch="Mono"},
  ["NTG4+"] = {model="NTG4Plus", pattern="Supercardioid", ch="Mono"},
  ["NTG4"]  = {model="NTG4Plus", pattern="Supercardioid", ch="Mono"},
  ["CM300"] = {model="CM300", pattern="Omni", ch="Mono"},
  ["XYH5"]  = {model="XYH5", pattern="XY", ch="Stereo"},
  ["SGH6"]  = {model="SGH6", pattern="Supercardioid", ch="Mono"}
}

local function detect_recorder(name)
  name = name:upper()
  for key, rec in pairs(recorders) do
    if name:match(key) then return rec end
  end
  if name:match("ANDROID") then return "Android" end
  return "UnknownRecorder"
end

local function detect_model(name)
  for key, info in pairs(models) do
    if name:upper():match(key) then return info.model, info.pattern, info.ch end
  end
  return "Generic", "Wide", "Mono"
end

local function build_name(rec, model, pattern, ch)
  return string.format("Mic_%s_%s_%s_%s.RfxChain", rec, model, pattern, ch)
end

return {
  detect_recorder = detect_recorder,
  detect_model = detect_model,
  build_name = build_name
}
