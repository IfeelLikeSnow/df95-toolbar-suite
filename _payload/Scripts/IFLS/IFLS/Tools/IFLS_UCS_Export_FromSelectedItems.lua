-- IFLS_UCS_Export_FromSelectedItems.lua
-- Phase 100: Frontend für UCS-Export aus dem bestehenden Slicing-Workflow
--
-- IDEE:
--   Dieses Script dient als generisches "Export"-Frontend:
--     * Du verwendest dein existierendes Slicing-UI (Items/Regions).
--     * Du markierst die fertigen Slices als ausgewählte Media Items.
--     * Dieses Script fragt einen Export-Root-Ordner ab.
--     * Es nutzt IFLS_UCS_ExportEngine, um:
--         - Kategorie zu schätzen (Kick/Snare/Hihat/...)
--         - Unterordner anzulegen/zu verwenden
--         - UCS-Dateinamen mit fortlaufender Nummer zu vergeben.
--
-- WICHTIG:
--   * Es wird NICHT versucht, neu zu rendern oder zu gluen.
--   * Das Script nimmt an, dass jedes ausgewählte Item bereits ein
--     eigenes Slice-File als Take-Quelle besitzt (typischer Slicing-Workflow).
--
--   Falls dein Slicing-UI anders arbeitet, kannst du dieses Frontend
--   als Vorlage nutzen und anpassen (z.B. andere Kategorie-Herleitung).

local r = reaper

------------------------------------------------------------
-- UCS Engine laden
------------------------------------------------------------

local ok, UCS = pcall(require, "IFLS_UCS_ExportEngine")
if not ok or not UCS then
  r.ShowMessageBox(
    "Konnte IFLS_UCS_ExportEngine nicht laden.\n" ..
    "Stelle sicher, dass 'IFLS_UCS_ExportEngine.lua' im selben Ordner\n" ..
    "liegt wie dieses Script (Scripts/IFLS/IFLS/Tools).",
    "IFLS UCS Export",
    0
  )
  return
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function lower(s)
  return (s or ""):lower()
end

local function guess_category_from_names(track_name, item_name)
  local t = lower(track_name)
  local i = lower(item_name or "")

  local s = t .. " " .. i

  if s:find("kick") or s:find("bd") or s:find("kck") then
    return "Kick"
  end
  if s:find("snare") or s:find("sd") then
    return "Snare"
  end
  if s:find("hhc") or s:find("hat") or s:find("hihat") or s:find("hi hat") then
    if s:find("open") or s:find("op") then
      return "HihatOpen"
    else
      return "HihatClosed"
    end
  end
  if s:find("clap") then
    return "Clap"
  end
  if s:find("tom") then
    return "Tom"
  end
  if s:find("shaker") or s:find("shak") then
    return "Shaker"
  end
  if s:find("perc") or s:find("percussion") then
    return "Perc"
  end
  if s:find("fx") or s:find("rise") or s:find("impact") or s:find("whoosh") then
    return "FX"
  end
  if s:find("noise") or s:find("hiss") then
    return "Noise"
  end

  return "Misc"
end

local function guess_descriptors_from_names(track_name, item_name)
  local s = lower(track_name .. " " .. item_name)

  local timbre = "UNK"
  if s:find("bright") then timbre = "Bright"
  elseif s:find("dark") then timbre = "Dark"
  elseif s:find("warm") then timbre = "Warm"
  elseif s:find("thin") then timbre = "Thin"
  end

  local dyn = "UNK"
  if s:find("soft") or s:find("gentle") then dyn = "Soft"
  elseif s:find("hard") or s:find("slam") then dyn = "Hard"
  elseif s:find("med") or s:find("medium") then dyn = "Med"
  end

  local src = "UNK"
  if s:find("field") or s:find("foley") then src = "Field"
  elseif s:find("acoustic") or s:find("acou") then src = "Acoustic"
  elseif s:find("analog") or s:find("analogue") then src = "Analog"
  elseif s:find("synth") or s:find("digital") then src = "Synth"
  end

  return { timbre, dyn, src }
end

local function get_take_source_path(take)
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  if not src then return nil end
  local buf = ""
  local rv, buf = r.GetMediaSourceFileName(src, "")
  if rv == 0 then return nil end
  return buf
end

------------------------------------------------------------
-- Export Root abfragen
------------------------------------------------------------

local function ask_export_root()
  local default_root = r.GetResourcePath() .. "/IFLS_Exports"
  local ret, input = r.GetUserInputs(
    "IFLS UCS Export",
    1,
    "Export Root Folder:",
    default_root
  )
  if not ret or not input or input == "" then
    return nil
  end
  return input
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  local num_sel = r.CountSelectedMediaItems(0)
  if num_sel == 0 then
    r.ShowMessageBox(
      "Keine Media Items ausgewählt.\n" ..
      "Bitte wähle die Slices (Items) aus, die du exportieren möchtest.",
      "IFLS UCS Export",
      0
    )
    return
  end

  local export_root = ask_export_root()
  if not export_root or export_root == "" then
    return
  end

  local samples = {}

  for i = 0, num_sel-1 do
    local item = r.GetSelectedMediaItem(0, i)
    if item then
      local take = r.GetActiveTake(item)
      if take then
        local track = r.GetMediaItem_Track(item)
        local _, track_name = r.GetTrackName(track)
        local _, item_name  = r.GetSetMediaItemTakeInfo_String(
          take, "P_NAME", "", false
        )

        local src_path = get_take_source_path(take)
        if src_path and src_path ~= "" then
          local category    = guess_category_from_names(track_name, item_name)
          local descriptors = guess_descriptors_from_names(track_name, item_name)

          table.insert(samples, {
            src_path    = src_path,
            category    = category,
            descriptors = descriptors,
            ext         = "wav",
          })
        end
      end
    end
  end

  if #samples == 0 then
    r.ShowMessageBox(
      "Keine gültigen Audioquellen für die ausgewählten Items gefunden.\n" ..
      "Stelle sicher, dass deine Slices Audio-Takes haben.",
      "IFLS UCS Export",
      0
    )
    return
  end

  r.Undo_BeginBlock()
  local results = UCS.export_samples(export_root, samples)
  r.Undo_EndBlock("IFLS UCS Export from selected items", -1)

  -- Kurzes Log
  msg("=== IFLS UCS Export – Ergebnisse ===")
  local ok_count, err_count = 0, 0
  for _, res in ipairs(results) do
    if res.ok then
      ok_count = ok_count + 1
      msg(string.format("[OK]  %s -> %s", res.src_path, res.dst_path or "?"))
    else
      err_count = err_count + 1
      msg(string.format("[ERR] %s (%s)", res.src_path or "?", res.error or "unknown error"))
    end
  end
  msg(string.format("Summary: %d OK, %d Fehler", ok_count, err_count))

  r.ShowMessageBox(
    string.format("UCS Export abgeschlossen.\n\nErfolgreich: %d\nFehler: %d\n\nSiehe REAPER-Konsole für Details.",
      ok_count, err_count),
    "IFLS UCS Export",
    0
  )
end

main()
