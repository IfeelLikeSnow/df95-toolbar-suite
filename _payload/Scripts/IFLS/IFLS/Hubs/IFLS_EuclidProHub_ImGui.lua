-- IFLS_EuclidProHub_ImGui.lua
-- ImGui-Hub für EuclidPro inkl. Ratchets

local r = reaper

package.path = package.path .. ";" .. r.GetResourcePath() .. "/Scripts/?.lua"
package.path = package.path .. ";" .. r.GetResourcePath() .. "/Scripts/?/init.lua"

local ok_imgui, imgui = pcall(require, "imgui")
if not ok_imgui then
  r.ShowMessageBox("ReaImGui nicht gefunden. Bitte über ReaPack installieren.", "IFLS EuclidPro Hub", 0)
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

local NS_EUCLIDPRO = "IFLS_EUCLIDPRO"

local function safe_load_domain(name)
  local ok, mod = pcall(dofile, domain_path .. name .. ".lua")
  if ok and type(mod) == "table" then
    return mod
  end
  return nil
end

local artistdom = safe_load_domain("IFLS_ArtistDomain")
local beatdom   = safe_load_domain("IFLS_BeatDomain")
local euclidpro = safe_load_domain("IFLS_EuclidProDomain")
local euclidprofiles = safe_load_domain("IFLS_EuclidProProfiles")

------------------------------------------------------------
-- State helpers
------------------------------------------------------------

local function ep_num(key, def)
  local s = ext.get_proj(NS_EUCLIDPRO, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function read_state()
  local st = {}
  st.steps        = ep_num("STEPS", 16)
  st.hits         = ep_num("HITS", 5)
  st.rotation     = ep_num("ROTATION", 0)
  st.accent_mode  = ext.get_proj(NS_EUCLIDPRO, "ACCENT_MODE", "none")
  st.hit_prob     = ep_num("HIT_PROB", 1.0)
  st.ghost_prob   = ep_num("GHOST_PROB", 0.0)

  st.ratchet_prob  = ep_num("RATCHET_PROB", 0.0)
  st.ratchet_min   = ep_num("RATCHET_MIN", 2)
  st.ratchet_max   = ep_num("RATCHET_MAX", 4)
  st.ratchet_shape = ext.get_proj(NS_EUCLIDPRO, "RATCHET_SHAPE", "up")

  st.l1_pitch    = ep_num("L1_PITCH", 36)
  st.l1_div      = ep_num("L1_DIV", 1)
  st.l1_base_vel = ep_num("L1_BASE_VEL", 96)
  st.l1_acc_vel  = ep_num("L1_ACCENT_VEL", 118)

  st.l2_pitch    = ep_num("L2_PITCH", 38)
  st.l2_div      = ep_num("L2_DIV", 1)
  st.l2_base_vel = ep_num("L2_BASE_VEL", 90)
  st.l2_acc_vel  = ep_num("L2_ACCENT_VEL", 112)

  st.l3_pitch    = ep_num("L3_PITCH", 42)
  st.l3_div      = ep_num("L3_DIV", 1)
  st.l3_base_vel = ep_num("L3_BASE_VEL", 84)
  st.l3_acc_vel  = ep_num("L3_ACCENT_VEL", 108)

  return st
end

local function write_state(st)
  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end
  local function setstr(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end

  setnum("STEPS",        st.steps)
  setnum("HITS",         st.hits)
  setnum("ROTATION",     st.rotation)
  setstr("ACCENT_MODE",  st.accent_mode)
  setnum("HIT_PROB",     st.hit_prob)
  setnum("GHOST_PROB",   st.ghost_prob)

  setnum("RATCHET_PROB", st.ratchet_prob)
  setnum("RATCHET_MIN",  st.ratchet_min)
  setnum("RATCHET_MAX",  st.ratchet_max)
  setstr("RATCHET_SHAPE", st.ratchet_shape)

  setnum("L1_PITCH",       st.l1_pitch)
  setnum("L1_DIV",         st.l1_div)
  setnum("L1_BASE_VEL",    st.l1_base_vel)
  setnum("L1_ACCENT_VEL",  st.l1_acc_vel)

  setnum("L2_PITCH",       st.l2_pitch)
  setnum("L2_DIV",         st.l2_div)
  setnum("L2_BASE_VEL",    st.l2_base_vel)
  setnum("L2_ACCENT_VEL",  st.l2_acc_vel)

  setnum("L3_PITCH",       st.l3_pitch)
  setnum("L3_DIV",         st.l3_div)
  setnum("L3_BASE_VEL",    st.l3_base_vel)
  setnum("L3_ACCENT_VEL",  st.l3_acc_vel)
end

------------------------------------------------------------
-- UI helpers
------------------------------------------------------------

local function draw_lane(ctx, label, st_pitch, st_div, st_base, st_acc)
  ig.Text(ctx, label)
  ig.SameLine(ctx)
  ig.PushItemWidth(ctx, 70)
  local c1, p  = ig.InputInt(ctx, "Pitch##" .. label, st_pitch)
  ig.SameLine(ctx)
  local c2, dv = ig.InputInt(ctx, "Div##" .. label, st_div)
  ig.SameLine(ctx)
  local c3, bv = ig.InputInt(ctx, "BaseVel##" .. label, st_base)
  ig.SameLine(ctx)
  local c4, av = ig.InputInt(ctx, "AccVel##" .. label, st_acc)
  ig.PopItemWidth(ctx)
  return (c1 or c2 or c3 or c4), p, dv, bv, av
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------

local function main_loop()
  local ctx = ig.CreateContext("IFLS EuclidPro Hub")
  local state = read_state()
  local visible, open = true, true

  local function loop()
    ig.SetNextWindowSize(ctx, 520, 480, ig.Cond_FirstUseEver)
    visible, open = ig.Begin(ctx, "IFLS EuclidPro Hub", true)

    if visible then
      ig.Text(ctx, "EuclidPro Engine (inkl. Ratchets)")
      ig.Separator(ctx)

      -- Context
      if artistdom and artistdom.get_artist_state then
        local a = artistdom.get_artist_state()
        ig.Text(ctx, ("Artist: %s (%s)"):format(a.name or "<unnamed>", a.style_preset or "<none>"))
      end
      if beatdom and beatdom.get_state then
        local bs = beatdom.get_state()
        ig.Text(ctx, ("Beat:  %.1f BPM, %d/%d, Bars=%d"):format(bs.bpm or 0, bs.ts_num or 4, bs.ts_den or 4, bs.bars or 4))
      end

      ig.Separator(ctx)
      ig.Text(ctx, "Core")
      ig.Separator(ctx)
      ig.PushItemWidth(ctx, 100)
      local c_steps, steps = ig.InputInt(ctx, "Steps", state.steps or 16)
      if c_steps then state.steps = math.max(1, steps) end

      local c_hits, hits = ig.InputInt(ctx, "Hits", state.hits or 5)
      if c_hits then state.hits = math.max(0, hits) end

      local c_rot, rot = ig.InputInt(ctx, "Rotation", state.rotation or 0)
      if c_rot then state.rotation = rot end
      ig.PopItemWidth(ctx)

      ig.Separator(ctx)
      ig.Text(ctx, "Accent / Probability")
      ig.Separator(ctx)

      local modes = { "none", "alternate", "downbeat", "cluster" }
      local current_idx = 1
      for i,m in ipairs(modes) do if m == state.accent_mode then current_idx = i break end end
      ig.PushItemWidth(ctx, 140)
      if ig.BeginCombo(ctx, "Accent Mode", modes[current_idx] or "none") then
        for i,m in ipairs(modes) do
          local sel = (i == current_idx)
          if ig.Selectable(ctx, m, sel) then
            current_idx = i
            state.accent_mode = m
          end
        end
        ig.EndCombo(ctx)
      end
      ig.PopItemWidth(ctx)

      ig.PushItemWidth(ctx, 180)
      local ch_hp, hp = ig.SliderDouble(ctx, "Hit Probability", state.hit_prob or 1.0, 0.0, 1.0, "%.2f")
      if ch_hp then state.hit_prob = hp end
      local ch_gp, gp = ig.SliderDouble(ctx, "Ghost Probability", state.ghost_prob or 0.0, 0.0, 1.0, "%.2f")
      if ch_gp then state.ghost_prob = gp end
      ig.PopItemWidth(ctx)

      ig.Separator(ctx)
      ig.Text(ctx, "Ratchets (IDM / Glitch Rolls)")
      ig.Separator(ctx)

      ig.PushItemWidth(ctx, 180)
      local ch_rp, rp = ig.SliderDouble(ctx, "Ratchet Probability", state.ratchet_prob or 0.0, 0.0, 1.0, "%.2f")
      if ch_rp then state.ratchet_prob = rp end
      ig.PopItemWidth(ctx)

      ig.PushItemWidth(ctx, 80)
      local ch_rmin, rmin = ig.InputInt(ctx, "Min Count", state.ratchet_min or 2)
      if ch_rmin then state.ratchet_min = math.max(1, rmin) end
      local ch_rmax, rmax = ig.InputInt(ctx, "Max Count", state.ratchet_max or 4)
      if ch_rmax then state.ratchet_max = math.max(state.ratchet_min or 1, rmax) end
      ig.PopItemWidth(ctx)

      local shapes = { "up", "down", "pingpong", "random" }
      local s_idx = 1
      for i,m in ipairs(shapes) do if m == state.ratchet_shape then s_idx = i break end end
      ig.PushItemWidth(ctx, 140)
      if ig.BeginCombo(ctx, "Shape", shapes[s_idx] or "up") then
        for i,m in ipairs(shapes) do
          local sel = (i == s_idx)
          if ig.Selectable(ctx, m, sel) then
            s_idx = i
            state.ratchet_shape = m
          end
        end
        ig.EndCombo(ctx)
      end
      ig.PopItemWidth(ctx)

      ig.Separator(ctx)
      if euclidprofiles and euclidprofiles.list_profiles then
        ig.Text(ctx, "Ratchet Profiles")
        ig.Separator(ctx)

        local prof_list = euclidprofiles.list_profiles()
        -- einfache statische Auswahl (kein Zustand gespeichert): erster Eintrag als Default
        local current_label = "<choose>"
        if prof_list[1] then
          current_label = prof_list[1].name
        end

        ig.PushItemWidth(ctx, 200)
        if ig.BeginCombo(ctx, "Profile (one-click apply)", current_label) then
          for _,p in ipairs(prof_list) do
            if ig.Selectable(ctx, p.name, false) then
              local ok, err = euclidprofiles.apply_profile(p.key, ext)
              if ok ~= false then
                -- nach apply_profile die Werte neu einlesen, damit Slider korrekt sind
                state = read_state()
              else
                r.ShowMessageBox("Ratchet profile failed: " .. tostring(err), "EuclidPro Profiles", 0)
              end
            end
          end
          ig.EndCombo(ctx)
        end
        ig.PopItemWidth(ctx)

        if #prof_list > 0 then
          ig.SameLine(ctx)
          if ig.Button(ctx, "Random Profile") then
            local idx = math.random(1, #prof_list)
            local p = prof_list[idx]
            local ok, err = euclidprofiles.apply_profile(p.key, ext)
            if ok ~= false then
              state = read_state()
            else
              r.ShowMessageBox("Random Ratchet profile failed: " .. tostring(err), "EuclidPro Profiles", 0)
            end
          end
        end

        ig.Separator(ctx)
      end
      ig.Text(ctx, "Lanes")
      ig.Separator(ctx)

      local ch1, p1, d1, b1, a1 = draw_lane(ctx, "Lane 1", state.l1_pitch, state.l1_div, state.l1_base_vel, state.l1_acc_vel)
      if ch1 then
        state.l1_pitch    = p1
        state.l1_div      = math.max(1, d1)
        state.l1_base_vel = math.max(1, b1)
        state.l1_acc_vel  = math.max(1, a1)
      end

      local ch2, p2, d2, b2, a2 = draw_lane(ctx, "Lane 2", state.l2_pitch, state.l2_div, state.l2_base_vel, state.l2_acc_vel)
      if ch2 then
        state.l2_pitch    = p2
        state.l2_div      = math.max(1, d2)
        state.l2_base_vel = math.max(1, b2)
        state.l2_acc_vel  = math.max(1, a2)
      end

      local ch3, p3, d3, b3, a3 = draw_lane(ctx, "Lane 3", state.l3_pitch, state.l3_div, state.l3_base_vel, state.l3_acc_vel)
      if ch3 then
        state.l3_pitch    = p3
        state.l3_div      = math.max(1, d3)
        state.l3_base_vel = math.max(1, b3)
        state.l3_acc_vel  = math.max(1, a3)
      end

      ig.Separator(ctx)
      if ig.Button(ctx, "Save Config") then
        write_state(state)
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, "Reload") then
        state = read_state()
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, "Generate EuclidPro Pattern") then
        write_state(state)
        if euclidpro and euclidpro.generate_from_extstate then
          local bs = nil
          if beatdom and beatdom.get_state then
            bs = beatdom.get_state()
          end
          euclidpro.generate_from_extstate(bs, nil)
        else
          r.ShowMessageBox("IFLS_EuclidProDomain.lua nicht gefunden oder ungültig.", "IFLS EuclidPro Hub", 0)
        end
      end
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

main_loop()
