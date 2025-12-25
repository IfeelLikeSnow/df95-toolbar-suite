-- IFLS_PolyRhythmHub_ImGui.lua
-- UI-Hub für polymetrische Euclid-Lanes (IFLS_PolyRhythmDomain)

local r = reaper

package.path = package.path .. ";" .. r.GetResourcePath() .. "/Scripts/?.lua"
package.path = package.path .. ";" .. r.GetResourcePath() .. "/Scripts/?/init.lua"

local ok_imgui, imgui = pcall(require, "imgui")
if not ok_imgui then
  r.ShowMessageBox("ReaImGui nicht gefunden. Bitte über ReaPack installieren.", "IFLS PolyRhythm Hub", 0)
  return
end
local ig = imgui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
  }
end

local function safe_load_domain(name)
  local ok, mod = pcall(dofile, domain_path .. name .. ".lua")
  if ok and type(mod) == "table" then
    return mod
  end
  return nil
end

local polydom   = safe_load_domain("IFLS_PolyRhythmDomain")
local beatdom   = safe_load_domain("IFLS_BeatDomain")
local artistdom = safe_load_domain("IFLS_ArtistDomain")

local function read_cfg()
  if polydom and polydom.load_cfg_from_extstate then
    return polydom.load_cfg_from_extstate()
  else
    return {
      enabled = false,
      bars    = 4,
      lanes = {
        { enabled=true, steps=16, hits=5, rotation=0, pitch=36, div=1 },
        { enabled=true, steps=10, hits=4, rotation=0, pitch=38, div=1 },
        { enabled=true, steps=7,  hits=3, rotation=0, pitch=42, div=1 },
      },
    }
  end
end

local function write_cfg(cfg)
  if polydom and polydom.save_cfg_to_extstate then
    polydom.save_cfg_to_extstate(cfg)
  end
end

local function main()
  local ctx = ig.CreateContext("IFLS PolyRhythm Hub")
  local cfg = read_cfg()
  local visible, open = true, true

  local function loop()
    ig.SetNextWindowSize(ctx, 540, 420, ig.Cond_FirstUseEver)
    visible, open = ig.Begin(ctx, "IFLS PolyRhythm Hub", true)

    if visible then
      ig.Text(ctx, "Polymetric Euclid Lanes (PolyRhythmDomain)")
      ig.Separator(ctx)

      if artistdom and artistdom.get_artist_state then
        local a = artistdom.get_artist_state()
        ig.Text(ctx, ("Artist: %s (%s)"):format(a.name or "<unnamed>", a.style_preset or "<none>"))
      end
      if beatdom and beatdom.get_state then
        local bs = beatdom.get_state()
        ig.Text(ctx, ("Beat: %.1f BPM, %d/%d, Bars=%d"):format(bs.bpm or 0, bs.ts_num or 4, bs.ts_den or 4, bs.bars or 4))
      end

      ig.Separator(ctx)

      local ch_en, en_val = ig.Checkbox(ctx, "Enable Polyrhythm Pattern (EUCLIDPOLY)", cfg.enabled or false)
      if ch_en then cfg.enabled = en_val end

      ig.SameLine(ctx)
      ig.PushItemWidth(ctx, 80)
      local ch_bars, bars_val = ig.InputInt(ctx, "Bars", cfg.bars or 4)
      if ch_bars then cfg.bars = math.max(1, bars_val) end
      ig.PopItemWidth(ctx)

      ig.Separator(ctx)
      ig.Text(ctx, "Lanes")
      ig.Separator(ctx)

      local labels = { "Lane 1", "Lane 2", "Lane 3" }
      for i=1,3 do
        local lane = cfg.lanes[i] or { enabled=false, steps=16, hits=4, rotation=0, pitch=36+2*i, div=1 }
        cfg.lanes[i] = lane
        ig.Text(ctx, labels[i])
        ig.SameLine(ctx)
        local ch_l_en, l_en = ig.Checkbox(ctx, "On##" .. i, lane.enabled or false)
        if ch_l_en then lane.enabled = l_en end

        ig.PushItemWidth(ctx, 70)
        local c_steps, steps_val = ig.InputInt(ctx, "Steps##" .. i, lane.steps or 16)
        if c_steps then lane.steps = math.max(1, steps_val) end
        ig.SameLine(ctx)
        local c_hits, hits_val = ig.InputInt(ctx, "Hits##" .. i, lane.hits or 4)
        if c_hits then lane.hits = math.max(0, hits_val) end
        ig.SameLine(ctx)
        local c_rot, rot_val = ig.InputInt(ctx, "Rot##" .. i, lane.rotation or 0)
        if c_rot then lane.rotation = rot_val end
        ig.SameLine(ctx)
        local c_pitch, pitch_val = ig.InputInt(ctx, "Pitch##" .. i, lane.pitch or (35+2*i))
        if c_pitch then lane.pitch = pitch_val end
        ig.SameLine(ctx)
        local c_div, div_val = ig.InputInt(ctx, "Div##" .. i, lane.div or 1)
        if c_div then lane.div = math.max(1, div_val) end
        ig.PopItemWidth(ctx)

        ig.Separator(ctx)
      end

      if ig.Button(ctx, "Save Polyrhythm Config") then
        write_cfg(cfg)
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, "Reload") then
        cfg = read_cfg()
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, "Generate Polyrhythm Pattern") then
        write_cfg(cfg)
        if polydom and polydom.generate_from_extstate then
          local bs = beatdom and beatdom.get_state and beatdom.get_state() or nil
          polydom.generate_from_extstate(bs, nil)
        else
          r.ShowMessageBox("IFLS_PolyRhythmDomain.lua nicht gefunden oder ungültig.", "IFLS PolyRhythm Hub", 0)
        end
      end

      ig.Separator(ctx)
      ig.Text(ctx, "Hinweis: Mode 'EUCLIDPOLY' in IFLS_PatternDomain triggert diese Engine.")
    end

    ig.End(ctx)

    if open then
      r.defer(loop)
    else
      ig.DestroyContext(ctx)
    end
  end

  r.defer(loop)
end

main()
