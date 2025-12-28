-- @description FlowBus (ExtState sync)
-- @version 1.0
-- @author DF95
local FB = {}
local r = reaper
local NS = "DF95_FLOW"

function FB.set(k, v) r.SetExtState(NS, k, tostring(v or ""), false) end
function FB.get(k, d)
  local v = r.GetExtState(NS, k); if v == "" then return d end; return v
end
function FB.clear() r.DeleteExtState(NS, "", true) end
return FB