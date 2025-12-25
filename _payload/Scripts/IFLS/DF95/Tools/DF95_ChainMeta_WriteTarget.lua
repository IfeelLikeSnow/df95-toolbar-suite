-- @description ChainMeta – write per-chain target into Track ExtState
-- @version 1.0
local r = reaper
local function set_chain_meta_target_on_sel_tracks(target)
  local proj = 0
  local sel = r.CountSelectedTracks(proj)
  for i=0, sel-1 do
    local tr = r.GetSelectedTrack(proj, i)
    r.GetSetMediaTrackInfo_String(tr, "P_EXT:DF95_CHAIN_META_lufs_target", tostring(target), true)
  end
end
local ok, last = r.GetProjExtState(0, "DF95", "LAST_CHAIN_META")
if ok == 1 and tonumber(last) then
  set_chain_meta_target_on_sel_tracks(tonumber(last))
else
  set_chain_meta_target_on_sel_tracks(-14.0)
end
