-- @description Artist Core Manager
-- @version 1.0
-- @author DF95
-- @about
--   Zentraler Manager für DF95-Artist-Kontext:
--     - globaler Artist-Name
--     - normalisierter Artist-Key
--   Schreibt/liest ProjectExtState-Werte und zeigt ein simples Menü.

local r = reaper

local function normalize_key(name)
  if not name or name == "" then return "" end
  local s = name:lower()
  if s:find("µ%-ziq") or s:find("mu%-ziq") then
    return "mu_ziq"
  end
  if s:find("future sound of london") then
    return "fsold"
  end
  s = s:gsub("[^%w]+", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_", ""):gsub("_$", "")
  return s
end

local function get_proj_ext(section, key)
  local rv, val = r.GetProjExtState(0, section, key)
  if rv == 0 then return "" end
  return val or ""
end

local function set_proj_ext(section, key, val)
  r.SetProjExtState(0, section, key, val or "")
end

local function get_current_artist()
  local v = get_proj_ext("DF95", "CurrentArtist")
  if v ~= "" then return v end
  return ""
end

local function main()
  local cur_artist = get_current_artist()
  local cur_key = normalize_key(cur_artist)

  local rv, input = r.GetUserInputs("DF95 Artist Core Manager", 1,
                                    "Artist-Name (leer = unverändert):",
                                    cur_artist or "")
  if not rv then return end

  local new_artist = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if new_artist == "" then
    r.ShowMessageBox("Artist bleibt: "..(cur_artist ~= "" and cur_artist or "<nicht gesetzt>"),
                     "DF95 Artist Core Manager", 0)
    return
  end

  local new_key = normalize_key(new_artist)
  set_proj_ext("DF95", "CurrentArtist", new_artist)
  set_proj_ext("DF95", "CurrentArtistKey", new_key)

  local msg = {}
  msg[#msg+1] = "DF95 Artist Core Manager"
  msg[#msg+1] = ""
  msg[#msg+1] = "Neuer Artist: " .. new_artist
  msg[#msg+1] = "Key: " .. new_key
  msg[#msg+1] = ""
  msg[#msg+1] = "Hinweis:"
  msg[#msg+1] = "  - Sub-Profile (SLICING / HUMANIZE / LOOP / SAMPLER / WARP / GROOVE)"
  msg[#msg+1] = "    werden separat von den jeweiligen Menüs gesetzt."

  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 Artist Core Manager", 0)
end

main()
