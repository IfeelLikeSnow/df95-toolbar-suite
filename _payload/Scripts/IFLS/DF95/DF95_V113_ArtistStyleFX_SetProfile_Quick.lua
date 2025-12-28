-- @description DF95_V113_ArtistStyleFX_SetProfile_Quick
-- @version 1.0
-- @author DF95
-- @about
--   Setzt einfache Artist/Style/Tempo-Profile über Input-Boxen.
--   (Lightweight-Alternative zum großen ImGui-Panel.)

local r = reaper

local function set_ext(section, key, val)
  r.SetProjExtState(0, section, key, val or "")
end

local function ask(title, prompt, default)
  local ok, ret = r.GetUserInputs(title, 1, prompt, default or "")
  if not ok then return nil end
  return ret
end

local function main()
  local artist = ask("DF95 Artist", "Artist (z.B. Aphex Twin, Autechre, Burial)", "")
  if not artist then return end

  local style  = ask("DF95 Style", "Style (IDM, Glitch, Ambient, Dub, Minimal)", "")
  if not style then return end

  local tempo  = ask("DF95 Tempo-Layer", "Tempo-Layer (slow / medium / fast)", "medium")
  if not tempo then return end

  set_ext("DF95_ARTIST", "NAME", artist)
  set_ext("DF95_ARTIST", "TEMPO", tempo)
  set_ext("DF95_STYLE",  "NAME", style)

  r.ShowMessageBox("DF95 Artist/Style/Tempo gesetzt:\n\nArtist: "..artist.."\nStyle: "..style.."\nTempo: "..tempo, "DF95 ArtistStyleFX", 0)
end

main()
