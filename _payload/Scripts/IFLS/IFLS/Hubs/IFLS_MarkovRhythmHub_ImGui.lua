-- IFLS_MarkovRhythmHub_ImGui.lua
-- ImGui-Hub für Markov-basierte Rhythmen (IFLS_MarkovRhythmDomain)

local r = reaper

package.path = package.path .. ";" .. r.GetResourcePath() .. "/Scripts/?.lua"
package.path = package.path .. ";" .. r.GetResourcePath() .. "/Scripts/?/init.lua"

local ok_imgui, imgui = pcall(require, "imgui")
if not ok_imgui then
  r.ShowMessageBox("ReaImGui nicht gefunden. Bitte über ReaPack installieren.", "IFLS MarkovRhythm Hub", 0)
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

local markovdom = safe_load_domain("IFLS_MarkovRhythmDomain")
local beatdom   = safe_load_domain("IFLS_BeatDomain")
local artistdom = safe_load_domain("IFLS_ArtistDomain")

local function ep_num(ns, key, def)
  local s = ext.get_proj(ns, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local NS_MARKOV = "IFLS_MARKOVRHYTHM"

local function read_cfg()
  if markovdom and markovdom.load_cfg_from_extstate then
    return markovdom.load_cfg_from_extstate()
  else
    return {
      enabled = false,
      bars    = 4,
      steps   = 16,
      start_hit_prob = 0.5,
      p_hh = 0.8,
      p_rh = 0.4,
      seed = 0,
      lanes = {
        { enabled=true, pitch=36, base_vel=96, accent_vel=118, apply_prob=0.9, accent_prob=0.2 },
        { enabled=true, pitch=38, base_vel=92, accent_vel=116, apply_prob=0.7, accent_prob=0.25 },
        { enabled=true, pitch=42, base_vel=88, accent_vel=112, apply_prob=0.5, accent_prob=0.3 },
      },
    }
  end
end

local function write_cfg(cfg)
  if markovdom and markovdom.save_cfg_to_extstate then
    markovdom.save_cfg_to_extstate(cfg)
  end
end

local function main()
  local ctx = ig.CreateContext("IFLS MarkovRhythm Hub")
  local cfg = read_cfg()
  local visible, open = true, true

  local function loop()
    ig.SetNextWindowSize(ctx, 580, 480, ig.Cond_FirstUseEver)
    visible, open = ig.Begin(ctx, "IFLS MarkovRhythm Hub", true)

    if visible then
      ig.Text(ctx, "Markov Rhythm Engine (Hit/Rest-Pfade)")
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

      local ch_en, en_val = ig.Checkbox(ctx, "Enable MarkovRhythm Pattern (Mode: MARKOV)", cfg.enabled or false)
      if ch_en then cfg.enabled = en_val end

      ig.SameLine(ctx)
      ig.PushItemWidth(ctx, 80)
      local ch_bars, bars_val = ig.InputInt(ctx, "Bars", cfg.bars or 4)
      if ch_bars then cfg.bars = math.max(1, bars_val) end
      ig.SameLine(ctx)
      local ch_steps, steps_val = ig.InputInt(ctx, "Steps/Bar", cfg.steps or 16)
      if ch_steps then cfg.steps = math.max(1, steps_val) end
      ig.PopItemWidth(ctx)

      ig.Separator(ctx)
      ig.Text(ctx, "Markov Core (Hit/Rest Übergänge)")
      ig.Separator(ctx)

      ig.PushItemWidth(ctx, 180)
      local c_shp, shp = ig.SliderDouble(ctx, "Start Hit Probability", cfg.start_hit_prob or 0.5, 0.0, 1.0, "%.2f")
      if c_shp then cfg.start_hit_prob = shp end

      local c_hh, p_hh = ig.SliderDouble(ctx, "P(hit | hit)", cfg.p_hh or 0.8, 0.0, 1.0, "%.2f")
      if c_hh then cfg.p_hh = p_hh end

      local c_rh, p_rh = ig.SliderDouble(ctx, "P(hit | rest)", cfg.p_rh or 0.4, 0.0, 1.0, "%.2f")
      if c_rh then cfg.p_rh = p_rh end
      ig.PopItemWidth(ctx)

      ig.PushItemWidth(ctx, 120)
      local c_seed, seed_val = ig.InputInt(ctx, "Seed (0=random)", cfg.seed or 0)
      if c_seed then cfg.seed = seed_val end
      ig.PopItemWidth(ctx)

      ig.Separator(ctx)
      ig.Text(ctx, "Lanes (Kick / Snare / Hat etc.)")
      ig.Separator(ctx)

      local labels = {"Lane 1", "Lane 2", "Lane 3"}
      for i=1,3 do
        local lane = cfg.lanes[i] or { enabled=false, pitch=36+2*i, base_vel=90, accent_vel=110, apply_prob=0.7, accent_prob=0.2 }
        cfg.lanes[i] = lane

        ig.Text(ctx, labels[i])
        ig.SameLine(ctx)
        local ch_en_l, en_l = ig.Checkbox(ctx, "On##L" .. i, lane.enabled or false)
        if ch_en_l then lane.enabled = en_l end

        ig.PushItemWidth(ctx, 70)
        local c_p, pval = ig.InputInt(ctx, "Pitch##L" .. i, lane.pitch or (35+2*i))
        if c_p then lane.pitch = pval end
        ig.SameLine(ctx)
        local c_bv, bv = ig.InputInt(ctx, "BaseVel##L" .. i, lane.base_vel or 96)
        if c_bv then lane.base_vel = math.max(1, bv) end
        ig.SameLine(ctx)
        local c_av, av = ig.InputInt(ctx, "AccVel##L" .. i, lane.accent_vel or 118)
        if c_av then lane.accent_vel = math.max(1, av) end
        ig.SameLine(ctx)
        ig.PushItemWidth(ctx, 120)
        local c_ap, ap = ig.SliderDouble(ctx, "ApplyProb##L" .. i, lane.apply_prob or 0.8, 0.0, 1.0, "%.2f")
        if c_ap then lane.apply_prob = ap end
        ig.SameLine(ctx)
        local c_acp, acp = ig.SliderDouble(ctx, "AccentProb##L" .. i, lane.accent_prob or 0.2, 0.0, 1.0, "%.2f")
        if c_acp then lane.accent_prob = acp end
        ig.PopItemWidth(ctx)

        ig.Separator(ctx)
      end

      if ig.Button(ctx, "Save Markov Config") then
        write_cfg(cfg)
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, "Reload") then
        cfg = read_cfg()
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, "Generate Markov Pattern") then
        write_cfg(cfg)
        if markovdom and markovdom.generate_from_extstate then
          local bs = beatdom and beatdom.get_state and beatdom.get_state() or nil
          markovdom.generate_from_extstate(bs, nil)
        else
          r.ShowMessageBox("IFLS_MarkovRhythmDomain.lua nicht gefunden oder ungültig.", "IFLS MarkovRhythm Hub", 0)
        end
      end

      ig.Separator(ctx)
      ig.Text(ctx, "Hinweis: PatternMode 'MARKOV' in IFLS_PatternDomain triggert diese Engine.")
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
