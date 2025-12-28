-- @description DF95_V83_SessionStateEngine
-- @version 1.0
-- @author DF95
local r = reaper
local M = {}
local EXT_NS = "DF95_SESSION"
local function set_state(key, value, persist)
  if value == nil then value = "" end
  r.SetExtState(EXT_NS, tostring(key), tostring(value), persist and true or false)
end
local function get_state(key)
  local v = r.GetExtState(EXT_NS, tostring(key))
  if v == "" then return nil end
  return v
end
function M.set(key, value, persist) set_state(key, value, persist) end
function M.get(key) return get_state(key) end
function M.clear(key) r.SetExtState(EXT_NS, tostring(key), "", true) end
function M.set_bool(key, b, persist) if b then set_state(key,"1",persist) else set_state(key,"0",persist) end end
function M.get_bool(key)
  local v = get_state(key)
  if v == nil then return nil end
  if v=="1" then return true end
  if v=="0" then return false end
  return nil
end
function M.set_number(key,n,persist) if n==nil then set_state(key,"",persist) return end set_state(key,tostring(n),persist) end
function M.get_number(key) local v=get_state(key) if not v then return nil end return tonumber(v) end
function M.set_active_profile(key) set_state("ACTIVE_PROFILE_KEY",key or "",true) end
function M.get_active_profile() return get_state("ACTIVE_PROFILE_KEY") end
function M.set_profile_ready(f) M.set_bool("PROFILE_READY",f,false) end
function M.set_offset_ready(f) M.set_bool("OFFSET_READY",f,false) end
function M.set_autogain_ready(f) M.set_bool("AUTOGAIN_READY",f,false) end
function M.set_pedalchain_ready(f) M.set_bool("PEDALCHAIN_READY",f,false) end
function M.get_profile_ready() return M.get_bool("PROFILE_READY") end
function M.get_offset_ready() return M.get_bool("OFFSET_READY") end
function M.get_autogain_ready() return M.get_bool("AUTOGAIN_READY") end
function M.get_pedalchain_ready() return M.get_bool("PEDALCHAIN_READY") end
function M.set_last_reamp_take(path_or_name)
  set_state("LAST_REAMP_TAKE", path_or_name or "", false)
  set_state("LAST_REAMP_TIME", tostring(os.time()), false)
end
function M.get_last_reamp_take()
  return get_state("LAST_REAMP_TAKE"), tonumber(get_state("LAST_REAMP_TIME") or "")
end
function M.get_health_summary()
  local profile_key     = M.get_active_profile()
  local profile_ready   = M.get_profile_ready()
  local offset_ready    = M.get_offset_ready()
  local autogain_ready  = M.get_autogain_ready()
  local pedalchain_ready= M.get_pedalchain_ready()
  local problems = {}
  if not profile_key or profile_key=="" or profile_ready==false then
    problems[#problems+1]="kein aktives Profil (ACTIVE_PROFILE_KEY/PROFILE_READY)"
  end
  if profile_key and offset_ready==false then
    problems[#problems+1]="Offset nicht komplett (OFFSET_READY=false)"
  end
  if profile_key and autogain_ready==false then
    problems[#problems+1]="AutoGain nicht komplett (AUTOGAIN_READY=false)"
  end
  if pedalchain_ready==false then
    problems[#problems+1]="keine gültige PedalChain (PEDALCHAIN_READY=false)"
  end
  local ok = (#problems==0)
  return {ok=ok, problems=problems, profile_key=profile_key}
end
return M
