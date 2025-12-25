-- DF95_ArtistIntensity.lua
-- Zentrale Mapping-Logik: Artist-Name -> Slicing/Humanize-Intensity + Drum-Bus-Intensity.

local M = {}

-- Normalisiert freie Artist-Eingaben auf Kanon-Namen
function M.normalize_artist(name)
  if not name then return nil end
  local n = name:lower()
  n = n:gsub("%s+", "")
  if n == "" then return nil end

  -- Mapping gängiger Eingaben
  if n:find("autechre") or n == "ae" then
    return "autechre"
  elseif n:find("squarepusher") or n == "sq" then
    return "squarepusher"
  elseif n:find("aphex") or n:find("afx") then
    return "aphextwin"
  elseif n:find("boardsofcanada") or n:find("boc") then
    return "boc"
  elseif n:find("bogdan") then
    return "bogdanraczynski"
  elseif n:find("flyinglotus") or n:find("flylo") then
    return "flyinglotus"
  elseif n:find("mouseonmars") then
    return "mouseonmars"
  elseif n:find("plaid") then
    return "plaid"
  elseif n:find("arovane") then
    return "arovane"
  elseif n:find("monoceros") then
    return "monoceros"
  elseif n:find("apparat") then
    return "apparat"
  elseif n:find("styrofoam") then
    return "styrofoam"
  elseif n:find("jelinek") then
    return "janjelinek"
  elseif n:find("telefontelaviv") or n:find("telefon") then
    return "telefontelaviv"
  elseif n:find("proem") then
    return "proem"
  elseif n:find("thomyorke") or n:find("thom") then
    return "thomyorke"
  elseif n:find("jega") then
    return "jega"
  else
    -- fallback: unknown artist, aber trotzdem String zurückgeben
    return n
  end
end

-- Basis-Intensity fürs Slicing/Humanize (soft/medium/extreme)
-- user_choice: "auto"/"soft"/"medium"/"extreme"
function M.slicing_intensity_for(artist_raw, user_choice)
  local choice = (user_choice or "auto"):lower()
  if choice == "soft" or choice == "medium" or choice == "extreme" then
    return choice
  end

  local a = M.normalize_artist(artist_raw) or ""

  -- Default-Mapping orientiert an tonal/ritmischer „Aggressivität“
  if a == "autechre" or a == "squarepusher" or a == "bogdanraczynski" or a == "jega" then
    return "extreme"
  elseif a == "aphextwin" or a == "flyinglotus" or a == "mouseonmars" then
    return "medium"
  elseif a == "boc" or a == "arovane" or a == "monoceros" or a == "janjelinek"
      or a == "telefontelaviv" or a == "proem" or a == "styrofoam" then
    return "soft"
  elseif a == "plaid" or a == "apparat" or a == "thomyorke" then
    return "medium"
  else
    -- Unbekannte Artists -> neutral
    return "medium"
  end
end

-- Drum-Bus-Intensity (safe/medium/extreme) basierend auf Artist + Slicing-Intensity
function M.drum_bus_intensity_for(artist_raw, slicing_intensity)
  local a = M.normalize_artist(artist_raw) or ""
  local si = (slicing_intensity or "medium"):lower()
  if si ~= "soft" and si ~= "medium" and si ~= "extreme" then
    si = "medium"
  end

  -- sehr edgy Artists -> Drums eher eine Stufe aggressiver
  if a == "autechre" or a == "squarepusher" or a == "bogdanraczynski" or a == "jega" then
    if si == "soft" then
      return "medium"
    elseif si == "medium" then
      return "extreme"
    else
      return "extreme"
    end
  -- sehr warme/organische Artists -> Drums eher safe/medium
  elseif a == "boc" or a == "janjelinek" or a == "telefontelaviv" or a == "proem"
      or a == "arovane" or a == "monoceros" then
    if si == "soft" then
      return "safe"
    elseif si == "medium" then
      return "medium"
    else
      return "medium"
    end
  -- Mittel- bis hybrid-aggressiv
  elseif a == "aphextwin" or a == "flyinglotus" or a == "mouseonmars"
      or a == "plaid" or a == "apparat" or a == "styrofoam" or a == "thomyorke" then
    if si == "soft" then
      return "medium"
    elseif si == "medium" then
      return "medium"
    else
      return "extreme"
    end
  else
    -- Fallback
    if si == "soft" then
      return "safe"
    elseif si == "medium" then
      return "medium"
    else
      return "extreme"
    end
  end
end

return M
