-- @description Seed Save (per Project ExtState)
-- @version 1.0
local u = dofile((debug.getinfo(1,"S").source:match("(.+[\\/])") or "").."DF95_SeedUtil.lua")
u.save_seed()